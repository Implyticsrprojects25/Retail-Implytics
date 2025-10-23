# scripts/01_setup_renv.R
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
renv::init(bare = TRUE)
# Core packages you can adjust
pkgs <- c(
  "tidyverse","janitor","lubridate","skimr","here",
  "readr","readxl","stringr","forcats","ggplot2",
  "knitr","rmarkdown"
)
install.packages(setdiff(pkgs, installed.packages()[,1]))
renv::snapshot(prompt = FALSE)
message("renv initialized. Restart R and call renv::activate() for future sessions.")
