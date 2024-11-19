# **************************************************************#
# Cleaning and Pre-Processing Data R File
# **************************************************************#
library(tidyverse)

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

districts <- read_csv("./Data/pcd11_par11_wd11_lad11_ew_lu.csv")

# **************************************************************#
# Grouping Points Data by Age and Point Totals
# **************************************************************#
group_by_age <- function(data_to_be_grouped) {
  # Grouping data by ages with respective points and providing total no. points
  grouped_ages <- data_to_be_grouped %>%
    mutate(
      # New column of ages as integers
      Age = as.numeric(`...2`)
      ) %>%
    group_by(
      age_band_of_driver  = case_when(
        # Grouping rows by new age column
        Age >= 16 & Age <= 20 ~ "16-20",
        Age >= 21 & Age <= 25 ~ "21-25",
        Age >= 26 & Age <= 35 ~ "26-35",
        Age >= 36 & Age <= 45 ~ "36-45",
        Age >= 46 & Age <= 55 ~ "46-55",
        Age >= 56 & Age <= 65 ~ "56-65",
        Age >= 66 & Age <= 75 ~ "66-75",
        Age > 75 ~ "75+"
      ),
      # Grouping by sex of driver so its retained
      sex_of_driver
    ) %>%
    # Calculating totals of each group
    summarise(across(everything(), ~ sum(as.numeric(.))),
              .groups = "drop")
  
  return(grouped_ages)
}

# Grouping data by number of points and providing total no. points
group_by_points <- function(data_to_be_grouped) {
  grouped_points <- data_to_be_grouped %>%
    # Creating new columns and populating with row sums for specified age groups
    mutate(
      # Selecting points columns so that can be reffered to in summations
      point_columns = (select_if(., is.numeric)),
      # Each point group has hard coded indexes as learnt from exploration
      `1-3 Points` = rowSums(point_columns
                             %>% select(2:4)),
      `5-8 Points` = rowSums(point_columns
                             %>% select(6:9)),
      `9-12 Points` = rowSums(point_columns
                              %>% select(10:13)),
      `12+ Points` = rowSums(select_if(., is.numeric)
                             %>% select(14:ncol(.) - 1))
    ) 
  
  return(grouped_points)
}

# **************************************************************#
# Licenses Gender Data - Producing separate tables for genders
# Age Group, 1-4 Points, 5-8 Points, 9-12 Points, 12+ Points
# **************************************************************#
licenses <- licenses_gender %>%
  # Removing rows and columns that are labels
  slice(2:(n() - 1)) %>%
  select(-1, -"Current Pts") %>%
  # New column to specify gender of row, using hard coded indexes
  mutate(
    sex_of_driver = case_when(
      row_number() <= 86 ~ "Female",
      row_number() > 86 ~ "Male"
    )
  )


all_points_by_age <- group_by_age(licenses)
grouped_points_by_age <- group_by_points(all_points_by_age)

# Finalising data
grouped_points_by_age <- grouped_points_by_age %>%
  # Calculating percentage for each row
  mutate(
    total = `1-3 Points` + `5-8 Points` + `9-12 Points` + `12+ Points`,
    total_point_holders = sum(total),
    percentage = (total / total_point_holders) * 100
  ) %>%
  # Retaining gender, age group, point and total columns only
  select(
    sex_of_driver,
    1,
    `1-3 Points`,
    `5-8 Points`,
    `9-12 Points`,
    `12+ Points`,
    total,
    percentage
  )

write.csv(all_points_by_age, "./Data/Clean/all_points_by_age.csv")
write.csv(grouped_points_by_age, "./Data/Clean/grouped_points_by_age.csv")

# **************************************************************#
# Licenses Location Data - Producing tables for Districts
# district_code, 1-4 Points, 5-8 Points, 9-12 Points, 12+ Points
# **************************************************************#
# Removing labels
licenses_districts <- licenses_location %>%
  slice(2:(n() - 1)) %>%
  select(-"Current Pts")

# Extracting district codes and using regex to keep valid codes
district_code <- unique(substr(licenses_districts[[1]], 1, 2))
valid_district <- district_code[grep("^[A-Za-z]{1,2}$", district_code)]

# Grouping data by postcode district
district_points <- licenses_districts %>%
  # New district column and then filtering using valid outwards as districts
  mutate(district_code = substr(...1, 1, 2)) %>%
  filter(district_code %in% valid_district) %>%
  group_by(district_code) %>%
  # New total column containing totals per district
  summarise(across(`1`:`48`, ~ sum(as.numeric(.)))) %>%
  mutate(Total = rowSums(across(`1`:`42`)))

# Using function from gender data to group the districts by points
grouped_district_points <- group_by_points(district_points) %>%
  # Retaining district, point and total columns only
  select(1, `1-3 Points`, `5-8 Points`, `9-12 Points`, `12+ Points`, Total) %>%
  # Removing anomaly where only 1 penalty point holder
  filter(Total != 1)

write.csv(grouped_district_points, "./Data/Clean/grouped_district_points.csv")

# **************************************************************#
# Resolving Duplicates (Identified in Exploration)
# **************************************************************#
# Re-using function from exploration to get duplicates
check_duplicated_variable <- function(data, variable, view_data = TRUE) {
  # Only keeping variables with more than one instance (duplicated)
  instance_count <- data.frame(table(data[[variable]]))
  instance_count[instance_count$Freq > 1, ]
  
  # Only keeping rows where there have been multiple instances identified
  duplicated_data <- data[data[[variable]] %in% instance_count$Var1[instance_count$Freq > 1], ]
  
  # Number of duplicates
  cat(nrow(duplicated_data), "duplicates")
  
  if (view_data) {
    view(duplicated_data)
  }
}

# Able to identify drivers by reference and class being 1, otherwise causality
drivers <- casualties[casualties[["casualty_reference"]] == 1 &
                        casualties[["casualty_class"]] == 1, ]

# Checking for remaining duplicates, can see due to different years
duplicate_drivers <- check_duplicated_variable(drivers, "accident_reference")

# New id from accident_year and accident_reference, applying to both
# drivers and collisions. Using year for better readability.
unique_drivers <- drivers %>%
  mutate(id = paste0(accident_reference, accident_year)) %>%
  rename(sex_of_driver = sex_of_casualty, age_band_of_driver = age_band_of_casualty, )

unique_collisions <- collisions %>%
  mutate(id = paste0(accident_reference, accident_year))

# Final check for duplicates, not viewing as no duplicates to be viewed.
check_duplicated_variable(unique_drivers, "id", FALSE)
check_duplicated_variable(unique_collisions, "id", FALSE)

# **************************************************************#
# Resolving Missing Values (Identified in Exploration)
# **************************************************************#
# Removing rows in collisions without relevant data
full_collisions <- unique_collisions %>%
  filter(
    light_conditions != -1,
    !weather_conditions %in% c(-1, 8, 9),
    !road_surface_conditions %in% c(-1, 9)
  )

# Removing rows in drivers without relevant data
full_drivers <- unique_drivers %>%
  filter(
    sex_of_driver != -1,
    age_band_of_driver != -1
  )

# **************************************************************#
# Finalising variables
# **************************************************************#
# Decoding condition variables into safe, questionable, unsafe
decoded_collisions <- full_collisions %>%
  mutate(
    light_conditions = case_when(
      light_conditions == 1 ~ "0",
      light_conditions == 4 ~ "1",
      light_conditions == 5 ~ "2",
      light_conditions == 6 ~ "2",
      light_conditions == 7 ~ "1"
    ),
    weather_conditions = case_when(
      weather_conditions == 1 ~ "0",
      weather_conditions == 2 ~ "1",
      weather_conditions == 3 ~ "2",
      weather_conditions == 4 ~ "1",
      weather_conditions == 5 ~ "3",
      weather_conditions == 6 ~ "3",
      weather_conditions == 7 ~ "1"
    ),
    road_surface_conditions = case_when(
      road_surface_conditions == 1 ~ "0",
      road_surface_conditions == 2 ~ "1",
      road_surface_conditions == 3 ~ "2",
      road_surface_conditions == 4 ~ "2",
      road_surface_conditions == 5 ~ "2",
      road_surface_conditions == 6 ~ "2",
      road_surface_conditions == 7 ~ "1"
    )
  )

# Decoding variables to match license data and improve readability
decoded_drivers <- full_drivers %>%
  mutate(
    sex_of_driver = case_when(
      sex_of_driver == 1 ~ "Female", 
      sex_of_driver == 2 ~ "Male"),
    age_band_of_driver = case_when(
      age_band_of_driver == 4 ~ "16-20",
      age_band_of_driver == 5 ~ "21-25",
      age_band_of_driver == 6 ~ "26-35",
      age_band_of_driver == 7 ~ "36-45",
      age_band_of_driver == 8 ~ "46-55",
      age_band_of_driver == 9 ~ "56-65",
      age_band_of_driver == 10 ~ "66-75",
      age_band_of_driver == 11 ~ "75+"
    )
  )

# Setting to substring to represent the hour
decoded_collisions$time <- substr(decoded_collisions$time, 1, 2)

# **************************************************************#
# Merging Collision and casualty Data
# **************************************************************#
# Selecting relevant columns to keep in drivers and collisions
final_collisions <- decoded_collisions %>%
  select(
    id,
    accident_year,
    time,
    date,
    accident_severity,
    local_authority_ons_district,
    light_conditions,
    weather_conditions,
    road_surface_conditions
  )

final_drivers <- decoded_drivers %>%
  select(id,
         sex_of_driver,
         age_band_of_driver
  )

complete_driver_collisions <- merge(final_collisions, final_drivers, by = "id")

write.csv(complete_driver_collisions, "./Data/Clean/complete_driver_collisions.csv")

# **************************************************************#
# Checking processed data
# **************************************************************#
list.files("./Data/Clean")

