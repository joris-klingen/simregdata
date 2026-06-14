# dev/dev.R - developer task runner used by .vscode/tasks.json
#
# Usage: Rscript dev/dev.R <load_all|test|document|check>
#
# Uses a script file (not Rscript -e) on purpose: inline -e can segfault on
# this machine.

args <- commandArgs(trailingOnly = TRUE)
cmd <- if (length(args) > 0) args[[1]] else "test"

suppressMessages(library(devtools))

switch(
  cmd,
  load_all = load_all("."),
  test     = test("."),
  document = document("."),
  check    = check("."),
  stop("Unknown dev command: ", cmd, ". Use load_all | test | document | check.")
)
