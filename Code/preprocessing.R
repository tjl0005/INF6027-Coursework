# **************************************************************#
# Cleaning and Pre-Processing Data R File
# **************************************************************#
library(tidyverse)
library(dplyr)
library(readxl)

# **************************************************************#
# Reading Data
# **************************************************************#
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
# Licenses Gender Data - Producing separate tables for genders
# Age Group, 1-4 Points, 5-8 Points, 9-12 Points, 12+ Points
# **************************************************************#
group_by_age <- function(data_to_be_grouped) {
  # Grouping data by ages with respective points and providing total no. points
  # Does require data passed to have first column as ages.
  grouped_ages <- data_to_be_grouped %>%
    mutate(Age = as.numeric(`...2`)) %>% # New column of ages as integers
    group_by(
      Age_Group = case_when(
        # Grouping rows by new age column
        Age >= 16 & Age <= 20 ~ "16-20",
        Age >= 21 & Age <= 25 ~ "21-25",
        Age >= 26 & Age <= 35 ~ "26-35",
        Age >= 36 & Age <= 45 ~ "36-45",
        Age >= 46 & Age <= 55 ~ "46-55",
        Age >= 56 & Age <= 65 ~ "56-65",
        Age >= 66 & Age <= 75 ~ "66-75",
        Age > 75 ~ "75+"
      )
    ) %>%
    select(-`...2`, -"Age") %>%  # Removing extra columns before totals
    summarise(across(everything(), ~ sum(as.numeric(.)))) # Calculating totals of each group
  
  return(grouped_ages)
}

# Grouping data by number of points and providing total no. points
group_by_points <- function(data_to_be_grouped) {
  grouped_points <- data_to_be_grouped %>%
    # Creating new columns and populating with row sums for specified age groups
    mutate(
      `1-3 Points` = rowSums(select_if(., is.numeric) %>% select(1:3)),
      `5-8 Points` = rowSums(select_if(., is.numeric) %>% select(5:8)),
      `9-12 Points` = rowSums(select_if(., is.numeric) %>% select(9:12)),
      `12+ Points` = rowSums(select_if(., is.numeric) %>% select(13:ncol(.)))
    ) %>%
    # Retaining descriptive, point and total columns only
    select(1, `1-3 Points`, `5-8 Points`, `9-12 Points`, `12+ Points`, Total)
  
  return(grouped_points)
}

# Removing irrelevant data
licenses <- licenses_gender %>%
  slice(2:(n() - 1)) %>% # Removing first and last row as they are labels
  select(-1, -"Current Pts") # Removing "Current Pts" column

# Splitting data by gender, row indexes hard coded as known from original data
# NOTE: May change to dynamic so different time-periods can be handled
females <- licenses %>%
  slice(1:86)
males <- licenses %>%
  slice(87:172)

# Female Tables
female_ages <- group_by_age(females)
female_points <- group_by_points(female_ages)

write.csv(female_ages, "./Data/Clean/female_ages.csv")
write.csv(female_points, "./Data/Clean/female_points.csv")

# Male Tables
male_ages <- group_by_age(males)
male_points <- group_by_points(male_ages)

write.csv(male_ages, "./Data/Clean/male_ages.csv")
write.csv(male_points, "./Data/Clean/male_points.csv")

# Cominbed Tables
all_ages <- group_by_age(licenses)
all_points <- group_by_points(all_ages)

write.csv(all_ages, "./Data/Clean/all_ages.csv")
write.csv(all_points, "./Data/Clean/all_points.csv")

# **************************************************************#
# Licenses Location Data - Producing tables for Districts
# Outward, 1-4 Points, 5-8 Points, 9-12 Points, 12+ Points
# **************************************************************#
# Removing irrelevant data
licenses_districts <- licenses_location %>%
  slice(2:(n() - 1)) %>% # Removing first and last row as they are labels
  select(-"Current Pts") # Removing "Current Pts" column

# Extracting outward codes and using regex to keep valid codes
outward <- unique(substr(licenses_districts[[1]], 1, 2))
valid_outward <- outward[grep("^[A-Za-z]{1,2}$", outward)]

# Grouping data by postcode outwards
grouped_district_points <- licenses_districts %>%
  mutate(Outward = substr(...1, 1, 2)) %>% # New outward column containing first two chars of district
  filter(Outward %in% valid_outward) %>% # Filter using identified valid outwards
  mutate(across(`1`:`48`, as.numeric)) %>% # Converting point columns to numeric for calculation
  group_by(Outward) %>%
  summarise(across(`1`:`48`, sum)) %>%  # Summing the points per outward group
  mutate(Total = rowSums(across(`1`:`42`))) # Adding a Total column

# Using function from gender data to group the districts by points
grouped_district_points <- group_by_points(grouped_district_points)

write.csv(grouped_district_points,
          "./Data/Clean/grouped_district_points.csv")

# **************************************************************#
# Resolving Duplicates (Identified in Exploration)
# **************************************************************#
# Re-using function from exploration
check_duplicated_variable <- function(data, variable, view_data = TRUE) {
  # Frequency table for passed variable, only keeping instances where the count
  # is higher than 1 as identified as duplicate.
  instance_count <- data.frame(table(data[[variable]]))
  instance_count[instance_count$Freq > 1, ]
  
  # Taking passed data and only keeping rows where the passed variable has an
  # instance count higher than 1 (duplicate).
  duplicated_data <- data[data[[variable]] %in% instance_count$Var1[instance_count$Freq > 1], ]
  
  cat(nrow(duplicated_data), "duplicated") # Print number of duplicates
  
  if (view_data) {
    view(duplicated_data)
  }
}

# Able to identify relevant casualties (the drivers at time of collision)
# through reference and class being 1.
drivers <- casualties[casualties[["casualty_reference"]] == 1 &
                        casualties[["casualty_class"]] == 1, ]

# Checking for remaining duplicates
duplicate_drivers <- check_duplicated_variable(drivers, "accident_reference")

# New id from accident_year and accident_reference, applying to both
# drivers and collisions. Using year for better readability.
drivers <- drivers %>%
  mutate(id = paste0(accident_reference, accident_year)) %>%
  rename(sex_of_driver = sex_of_casualty, age_band_of_driver = age_band_of_casualty, )

collisions <- collisions %>%
  mutate(id = paste0(accident_reference, accident_year))

# Final check for duplicates, not viewing as no duplicates to be viewed.
duplicate_drivers <- check_duplicated_variable(drivers, "id", FALSE)
duplicate_collisions <- check_duplicated_variable(collisions, "id", FALSE)

# **************************************************************#
# Resolving Missing Values (Identified in Exploration)
# **************************************************************#
# Missing collision data
collisions <- collisions[collisions$light_conditions != -1, ]
collisions <- collisions[!collisions$weather_conditions %in% c(-1, 8, 9), ]
collisions <- collisions[!collisions$road_surface_conditions %in% c(-1, 9), ]

# Missing driver data
drivers <- drivers[drivers$sex_of_driver != -1, ]
drivers <- drivers[drivers$age_band_of_driver != -1, ]

# **************************************************************#
# Collisions
# **************************************************************#
# Selecting relevant columns to keep
collisions <- collisions %>% select(
  id,
  accident_severity,
  local_authority_district,
  light_conditions,
  weather_conditions,
  road_surface_conditions
)

# Decoding readability
collisions <- collisions %>%
  mutate(
    accident_severity = case_when(
      accident_severity == 1 ~ "Slight",
      accident_severity == 2 ~ "Serious",
      accident_severity == 3 ~ "Fatal",
    ),
    light_conditions = case_when(
      light_conditions == 1 ~ "Daylight",
      light_conditions == 4 ~ "Darkness - lights lit",
      light_conditions == 5 ~ "Darkness - lights unlit",
      light_conditions == 6 ~ "Darkness - no lighting",
      light_conditions == 7 ~ "Darkness - lighting unknown"
    ),
    weather_conditions = case_when(
      weather_conditions == 1 ~ "Fine no high winds",
      weather_conditions == 2 ~ "Raining no high winds",
      weather_conditions == 3 ~ "Snowing no high winds",
      weather_conditions == 4 ~ "Fine + high winds",
      weather_conditions == 5 ~ "Raining + high winds",
      weather_conditions == 6 ~ "Snowing + high winds",
      weather_conditions == 7 ~ "Fog or Mist"
    ),
    road_surface_conditions = case_when(
      road_surface_conditions == 1 ~ "Dry",
      road_surface_conditions == 2 ~ "Wet or Damp",
      road_surface_conditions == 3 ~ "Snow",
      road_surface_conditions == 4 ~ "Frost or Ice",
      road_surface_conditions == 5 ~ "Flood, over 3cm deep",
      road_surface_conditions == 6 ~ "Oil or Diesel",
      road_surface_conditions == 7 ~ "Mud"
    )
  )

write.csv(collisions, "./Data/Clean/collisions.csv")

# **************************************************************#
# Drivers
# **************************************************************#
# Specifying variables to keep
drivers <- drivers %>% select(id, sex_of_driver, age_band_of_driver, casualty_severity)

# Decoding variables to match license data and improve readability
drivers <- drivers %>%
  mutate(
    sex_of_driver = case_when(sex_of_driver == 1 ~ "Female", sex_of_driver == 2 ~ "Male", ),
    casualty_severity = case_when(
      casualty_severity == 1 ~ "Slight",
      casualty_severity == 2 ~ "Serious",
      casualty_severity == 3 ~ "Fatal",
    ),
    age_band_of_driver = case_when(
      age_band_of_driver == 4 ~ "16-20",
      age_band_of_driver == 5 ~ "21-25",
      age_band_of_driver == 6 ~ "26-35",
      age_band_of_driver == 7 ~ "46-55",
      age_band_of_driver == 8 ~ "56-65",
      age_band_of_driver == 9 ~ "66-75",
    )
  )

write.csv(drivers, "./Data/Clean/drivers")

# **************************************************************#
# Merging Collision and casualty Data
# **************************************************************#
complete_driver_collisions <- merge(drivers, collisions, by = "id")

view(complete_driver_collisions)

# **************************************************************#
# Checking processed data
# **************************************************************#
list.files("./Data/Clean")
