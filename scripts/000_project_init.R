# Project: NYC road safety
library(data.table)
library(parallel)
library(nabor)
library(jsonlite)
library(arrow)
library(geosphere)
library(sf)
library(lubridate)
library(tidyverse)
library(readxl)
library(glue)
library(fasttime)
library(fixest)
library(nanoparquet)

source('scripts/functions/jk_utils.R')


# Suppress Rplots.pdf when running non-interactively (e.g. via source() in pipeline)
if (!interactive()) pdf(NULL)

# helper to save plots
save_plot <- function(filename, width = 10, height = 6, dpi = 300) {
  ggsave(file.path('output/figures', filename),
         width = width, height = height, dpi = dpi)
}

# ensure output directories exist
for(d in c('output/figures', 'output/maps', 'output/tables', 'output/dta_files',
           'output/values', 'data/interim', 'data/spatial')) {
  if(!dir.exists(d)) dir.create(d, recursive = TRUE)
}


#### Parameters
data_years  <- 2021:2025
  
proj_start <- '2022-01-01'
proj_end <- '2025-11-01'
max_date <- '2025-08-01'


iStartYear <- min(data_years)
iEndYear <- max(data_years)
  

# colors ----
jk_colors <- c("#004699", "#009dec", "#6cbd74", "#bed200", "#d48fb9", "#ff9100", "#ec0000", "#ffe600", "#fdb0cb")

options(
  ggplot2.discrete.fill = list(jk_colors),
  ggplot2.discrete.colour = list(jk_colors)
  )



#### Functions ####

## Make regression tables from Stargazer page wide
TableWidener <- function(sPath, NrOfRegs){
  vTable <- readLines(sPath)
  iFirstTabularLine <- which(grepl("tabular", vTable))[1]
  vTable <- gsub("\\^\\{\\*", "\\$\\^\\{\\*", vTable)
  vTable <- gsub("\\*\\}", "\\*\\}\\$ ", vTable)
  vTable <- gsub("\\{tabular\\}", "\\{tabular*\\}", vTable)
  vTable[iFirstTabularLine] <- paste0("\\begin{tabular*}{\\textwidth}{@{\\extracolsep{\\fill}} l",
                                      paste(rep("c",NrOfRegs),collapse = ""),"}" )
  
  vTable[length(vTable)-3] <- "%"
  
  iDepVarLine <- which(grepl("multicolumn", vTable))[1]
  vTable <- c(vTable[1:iDepVarLine],"\\vspace{-1em}", vTable[iDepVarLine:length(vTable)])
  
  vStarts <- gregexpr("\\{c\\}", vTable[iDepVarLine + 2])[[1]]+4
  vEnds <- gregexpr("} ", vTable[iDepVarLine + 2])[[1]]-1
  
  for(i in length(vStarts):1){
    sFirstPart <- substring(vTable[iDepVarLine + 2],1, vStarts[i]-1)    
    sLastPart <- substring(vTable[iDepVarLine + 2],vEnds[i]+1, nchar(vTable[iDepVarLine + 2]))
    vTable[iDepVarLine + 2] <- paste0(sFirstPart, "\\hrulefill", sLastPart)
    writeLines(vTable,sPath )
  }
}

## Make descriptive tables from Stargazer page wide
TableWidenerDesc <- function(sPath, NrOfCols){
  vTable <- readLines(sPath)
  iFirstTabularLine <- which(grepl("tabular", vTable))[1]
  vTable <- gsub("\\^\\{\\*", "\\$\\^\\{\\*", vTable)
  vTable <- gsub("\\*\\}", "\\*\\}\\$ ", vTable)
  vTable <- gsub("\\{tabular\\}", "\\{tabular*\\}", vTable)
  vTable[iFirstTabularLine] <- paste0("\\begin{tabular*}{\\textwidth}{@{\\extracolsep{\\fill}} l",
                                      paste(rep("c",NrOfCols),collapse = ""),"}" )
  writeLines(vTable, sPath)
}

  ## match points to segment using Heron's formula, based on coordinates and knn algorithm.
PointSegmMatcher <- function(dtSegments, dtPoints, iGridSize=100){
  # input
  # dtSegments: data.table with straight (!) segments, coords should be called lon_start lat_start, lat_end, lon_end
  # dtPoints: data.table with points, and an ID,

  ## extract all segment points and refine on grid
  dtSegPoints <- dtSegments[, .(SegmID, segm_length, 
                                segm_lat = lat_start, 
                                segm_lon = lon_start, 
                                lat_diff = lat_end - lat_start,
                                lon_diff = lon_end - lon_start)]
  
  # add intermediate points by expanding
  dtSegPoints[, Splits:=ceiling(segm_length/iGridSize)]
  dtSegPoints <- dtSegPoints[, .(SplitNr=0:Splits), by=names(dtSegPoints)]
  dtSegPoints[, segm_lat := segm_lat + (SplitNr/Splits) * (lat_diff), SegmID]
  dtSegPoints[, segm_lon := segm_lon + (SplitNr/Splits) * (lon_diff), SegmID]

  #remove helper columns
  dtSegPoints[, c("lat_diff", "lon_diff", "Splits", "SplitNr"):=NULL]
  
  #remove errors in coordinates
  dtSegPoints <- dtSegPoints[segm_lat > -90 & segm_lat < 90 &
                             segm_lon < 180 & segm_lon > -180 ]
  dtPoints <- dtPoints[lat > -90 & lat < 90 & 
                         lon < 180 & lon > -180 ]
  
  #find nearest neighbors 
  mKnn.idx <- knn(dtSegPoints[, .(segm_lon, segm_lat)], dtPoints[, .(lon, lat)],  k=1)$nn.idx
  
  #add closest segment  to points
  dtPointsTemp <- cbind(dtPoints, dtSegPoints[mKnn.idx[, 1], .(SegmID)])
  
  #add start and end point of matched segment
  dtPointsTemp <- merge(dtPointsTemp, 
                        dtSegments[, .(SegmID, SL=segm_length, 
                                       lat_start, lon_start, lat_end, lon_end)])
  
  #calculate distances: Dist to A (DA), Dist to B (DB)...
  dtPointsTemp[, DA := distHaversine(.SD[, .(lon, lat)],.SD[, .(lon_start, lat_start)])]
  dtPointsTemp[, DB := distHaversine(.SD[, .(lon, lat)],.SD[, .(lon_end, lat_end)])]
  
  #remove cases for which the maximum distance to either segment node (A or B) exceeds segment length
  dtPointsTemp <- dtPointsTemp[pmax(DA, DB) < 1.05 *SL ]
  
  #calculate shortest distance between point and segment using Heron's formula
  #...see https://en.wikipedia.org/wiki/Heron%27s_formula
  dtPointsTemp[, DistToSegment:= (2 * (1/4)*sqrt( (DA+DB+SL)*(-DA+DB+SL)*(DA-DB+SL)*(DA+DB-SL) ))/SL ]
  
  #keep only essential  cols
  vRemoveCols <- names(dtPointsTemp)[! names(dtPointsTemp) %in% c("SegmID", "PointID", "PointName", "DistToSegment")]
  dtPointsTemp[, (vRemoveCols):=NULL]
  
  return(dtPointsTemp)
}



points_to_street <- function(s_points, 
                             points, 
                             point_coords, 
                             id_names = c('SegmentID', 'StreetCode'), 
                             dist_name = 'distance', 
                             max_dist = 10){
  
  # temp rename lat and lon
  setnames(points, old = point_coords, new = c('lon', 'lat'))
  
  
  # remove errors in coords
  s_points <- s_points[lat > -90 & lat < 90 & lon < 180 & lon > -180 ]
  points <- points[lat > -90 & lat < 90 & lon < 180 & lon > -180 ]
  
  mKnn.idx <- knn(s_points[, .(lon, lat)], points[, .(lon, lat)],  k = 1)$nn.idx
  
  # add closest street point to points
  points <- cbind(points, s_points[mKnn.idx[, 1], .(SegmentID, StreetCode, lat_temp = lat, lon_temp = lon)])
  
  # calc distance to closest point
  points[, dist_temp := distHaversine(.SD[, .(lon, lat)], .SD[, .(lon_temp, lat_temp)])]
  
  points[, lat_temp := NULL]
  points[, lon_temp := NULL]
  
  
  # revert rename lat and lon
  setnames(points, c('lon', 'lat'), point_coords)
  
  points_out <- copy(points)
  points_out <- points_out[dist_temp < max_dist]
  
  setnames(points_out, c('SegmentID', 'StreetCode', 'dist_temp'), c(id_names, dist_name))
  
  return(points_out)
  
}




  
  
  
##invert wind direction defined as abbreviated bounds (e.g. nort bound is NB)
InvertWD <- function(WD){
  ifelse(WD =="EB", "WB", 
         ifelse(WD =="WB", "EB",
                ifelse(WD=="SB", "NB", "SB"))) 
}

CalcWD <- function(Dir){
  #calculate wind direction from direction in degrees
  ifelse(Dir %in% -45:45, "WB", 
         ifelse(Dir %in% 45:135, "NB", 
                ifelse(Dir %in% -45:-135, "SB", "EB")))
}

FindMode <- function(x) {
  #calculate the mode (most frequent occurance in a vector)  
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

  

first_last_dir <- function(xy){
  geosphere::bearing(xy[1,1:2], xy[nrow(xy),1:2])
}

get_orientation <- function(lines){
  pts = data.frame(sf::st_coordinates(lines))
  pts = split(pts, pts$L2)
  bearing = sapply(pts, first_last_dir)
  bearing    
}



dd2dmslat <-
  function (decdeg) 
  {
  #from biogeo package to convert lon lat dec into minutes
    
  dd <- floor(abs(decdeg))
    m1 <- (abs(decdeg) - dd) * 60
    mm <- floor(m1)
    ss <- round((m1 - floor(m1)) * 60, 1)
    for (i in 1:length(ss)) {
      if (ss[i] >= 60) {
        mm[i] <- mm[i] + 1
        ss[i] <- 0
      }
    }
    for (i in 1:length(mm)) {
      if (mm[i] >= 60) {
        dd[i] <- dd[i] + 1
        mm[i] <- 0
      }
    }
    ns <- ifelse(abs(decdeg) - decdeg == 0, "N", "W")
  
    dms <- paste0(dd,"°", mm,"'",ss,'"', ns)
    
  }


# function to rename geometry
rename_geometry <- function(g, name){
  
  current = attr(g, "sf_column")
  
  names(g)[names(g) == current] = name
  
  st_geometry(g) = name
  
  return(g)
}

tcat <- function(...){
  cat(substr(Sys.time(), 12, 19), ...)
}

ntcat <- function(...){
  cat(substr(Sys.time(), 12, 19), ..., '\n')
}


# function to import all trips from parquet trip collection

get_ttrips <- function(files = list.files("data/normalized/taxi_trips", pattern = 'parquet', full.names = T), 
                       columns, 
                       conditions = NULL,
                       verbose = F) {
  
  list_trips <- vector("list", length(files))
  
  for (i in seq_along(files)) {
    
    # if(verbose){
    #   ntcat("import", i, "out of", length(files))
    #   }
    
    dt_lazy <- open_dataset(files[i]) %>%
      select(all_of(columns))
    
    # Apply lazy filters if conditions exist
    if (!is.null(conditions)) {
      dt_lazy <- dt_lazy %>%
        filter(!!!conditions)
    }
    
    # Only now collect
    dt_temp <- dt_lazy %>% collect()
    
    list_trips[[i]] <- dt_temp
  }
  
  # Bind all into one data.table
  dt <- rbindlist(list_trips, use.names = TRUE, fill = TRUE)
  return(dt)
}

