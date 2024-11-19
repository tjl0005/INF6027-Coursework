library(tidyverse)

collisions <- read_csv("./Data/Clean/complete_driver_collisions.csv")

# **************************************************************************** #
# Yearly Trend (2019-2023)
# **************************************************************************** #
# Getting collisions per year 
yearly_collisions <- collisions %>%
  group_by_at("accident_year") %>%
  summarise(no_collisions = n())

# Connected line plot for colllisions per year
yearly_collisions_plot <- ggplot(yearly_collisions, aes(x = accident_year, y = no_collisions)) +
  geom_line() + 
  geom_point() + 
  labs(title = "Collisions by Year",
       x = "Year",
       y = "Number of Collisions") +
  theme_minimal()

ggsave("./Visualisations/collisions_per_year.png", yearly_collisions_plot, width = 10, height = 8)

# **************************************************************************** #
# Hourly Trend (00-23)
# **************************************************************************** #
# Collisions by hour
hourly_collisions <- collisions %>%
  group_by_at("time") %>%
  summarise(no_collisions = n())

hourly_collisions_plot <- ggplot(hourly_collisions, aes(x = time, y = no_collisions, group=1)) +
  geom_line() +
  geom_point() +
  labs(title = "Collisions by Hour",
       x = "Hour of Day",
       y = "Number of Collisions") +
  theme_minimal()

ggsave("./Visualisations/collisions_per_hour.png", hourly_collisions_plot, width = 10, height = 8)

# **************************************************************************** #
# Hourly and Yearly Trends
# **************************************************************************** #
# Getting the number of collisions for each combination of year and hour
hour_per_year_collisions <- collisions %>%
  group_by(accident_year, time) %>%
  summarise(no_collisions = n(), .groups = "drop")

# Plotting the trend of years and hours together
hour_per_year_collisions_plot <- ggplot(hour_per_year_collisions, aes(x = time, y = no_collisions, color = as.factor(accident_year), group = accident_year)) +
  geom_line() + 
  geom_point() +
  labs(title = "No. Collisions by Hour and Year",
       x = "Hour of Day",
       y = "Number of Collisions",
       colour = "Year") +
  theme_minimal() +
  theme(legend.position = "bottom")

write.csv(hour_per_year_collisions, "./Data/Findings/collisions_per_hour_per_year.csv")

ggsave("./Visualisations/collisions_per_hour_and_year.png", hour_per_year_collisions_plot, width = 10, height = 8)

