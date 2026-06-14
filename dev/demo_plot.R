# dev/demo_plot.R - mock plots to test the VSCode httpgd plot viewer.
#
# In VSCode: open an R terminal, then source this file (Ctrl+Shift+S) or run
# it line by line. Each plot appears in the Plots tab; use the < > arrows in
# that tab to page through all four.

library(data.table)
library(ggplot2)

set.seed(42)

# Mock "population" sample (no simulation engine needed - just illustrative)
n <- 2000L
dt <- data.table(
  age    = pmin(pmax(round(rnorm(n, 42, 18)), 0L), 99L),
  income = round(rlnorm(n, log(32000), 0.5)),
  region = sample(c("Noord", "Oost", "Zuid", "West", "Randstad"), n,
                  replace = TRUE, prob = c(1, 1, 1.2, 1.1, 2.5)),
  ev     = NA
)
dt[, ev := rbinom(.N, 1L, plogis((income - 30000) / 25000))]

# 1. Base R histogram
hist(dt[, age], breaks = 30, col = "steelblue", border = "white",
     main = "Age distribution (mock)", xlab = "Age")

# 2. ggplot - income density (note: print() so it renders when sourced)
p2 <- ggplot(dt, aes(income)) +
  geom_density(fill = "darkorange", alpha = 0.5) +
  scale_x_continuous(labels = scales::comma) +
  labs(title = "Income density (mock)", x = "Income (EUR)", y = "Density") +
  theme_minimal()
print(p2)

# 3. ggplot - EV ownership rate by region
rate <- dt[, .(ev_rate = mean(ev)), by = region][order(-ev_rate)]
p3 <- ggplot(rate, aes(reorder(region, ev_rate), ev_rate)) +
  geom_col(fill = "seagreen") +
  scale_y_continuous(labels = scales::percent) +
  coord_flip() +
  labs(title = "EV ownership by region (mock)", x = NULL, y = "Share with EV") +
  theme_minimal()
print(p3)

# 4. ggplot - income vs age, coloured by EV
p4 <- ggplot(dt, aes(age, income, colour = factor(ev))) +
  geom_point(alpha = 0.4) +
  scale_y_continuous(labels = scales::comma) +
  scale_colour_manual(values = c("0" = "grey70", "1" = "firebrick"),
                      name = "EV", labels = c("No", "Yes")) +
  labs(title = "Income vs age (mock)", x = "Age", y = "Income (EUR)") +
  theme_minimal()
print(p4)

# Tip: this data.table is now in your global environment - look at the
# R "Workspace" panel (R icon in the Activity Bar) and click `dt` to open
# the grid data viewer. Or run:  View(dt)
cat("Done - 4 plots sent to the Plots tab. `dt` is in your workspace.\n")
