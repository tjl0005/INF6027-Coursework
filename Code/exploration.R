# **************************************************************#
# Initial Exploration of Data
# **************************************************************#
library(tidyverse)
library(dplyr)

licenses_gender <- read_excel(
  "./Data/Raw/driving-licence-data-sep-2024.xlsx",
  sheet = "DRL0131 - September 2024",
  skip = 24
)
licenses_location <- read_excel(
  "./Data/Raw/driving-licence-data-sep-2024.xlsx",
  sheet = "DRL0132- September 2024",
  skip = 24
)
collisions <- read_csv("./Data/Raw/dft-road-casualty-statistics-collision-last-5-years.csv")
casualties <- read_csv("./Data/Raw/dft-road-casualty-statistics-casualty-last-5-years.csv")

# **************************************************************#
# Summary of the Data
# **************************************************************#
# Checking columns (variables)
names(licenses_gender)
names(licenses_location)
names(collisions)
names(casualties)

# Getting example data
head(licenses_gender)
head(licenses_location)
head(collisions)
head(casualties)

# Summaries of collisions and casualties
summary(collisions)
summary(casualties)

# NOTE: No further exploration in R for licenses data as it is structured in a
# way with no missing data or issue with duplicates.

# **************************************************************#
# Instances of Missing Data
# **************************************************************#
# Looking at cases where data is -1, meaning missing or not provided data.
# NOTE: Function will always open table of missing data, pass FALSE to avoid.
check_missing_data <- function(data, variable, view_data = TRUE) {
  missing_data <- data[data[[variable]] == -1, ]
  
  cat(nrow(missing_data), "instances with missing data")
  
  if (view_data) {
    view(missing_data)
  }
}

# Collision data, checking relevant variables where confirmed there are -1
# instances from summary. This gives an idea of how much data is missing.
check_missing_data(collisions, "local_authority_district", FALSE) # False as unsure of variable relevance and hard to view
check_missing_data(collisions, "road_surface_conditions")

# Casualty data, repeating same process.
check_missing_data(casualties, "sex_of_casualty")
check_missing_data(casualties, "age_band_of_casualty")

# **************************************************************#
# Identifying duplicates
# **************************************************************#
# Provides number of duplicates and can open table showing duplicated rows,
# NOTE: Will always open table of duplicates in R, pass FALSE to avoid.
check_duplicated_variable <- function(data, variable, view_data = TRUE) {
  # Frequency table for variable, only keeping instances where the count is
  # higher than 1 as identified as duplicate.
  instance_count <- data.frame(table(data[[variable]]))
  instance_count[instance_count$Freq > 1, ]
  
  # Taking passed data and only keeping rows where the variable has an instance
  # count higher than 1 (duplicate).
  duplicated_data <- data[data[[variable]] %in% instance_count$Var1[instance_count$Freq > 1], ]
  
  cat(nrow(duplicated_data), "duplicated")
  
  if (view_data) {
    view(duplicated_data)
  }
}

# Collisions are duplicated because accident reference is not unique to the year
duplicate_collisions <- check_duplicated_variable(collisions, "accident_reference")

# Causality reference and class have to be 1 to indicate the driver. Also non-
# unique accident references.
duplicate_casualties <- check_duplicated_variable(casualties, "accident_reference")
