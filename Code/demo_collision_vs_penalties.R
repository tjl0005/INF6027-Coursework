# **************************************************************************** #
# Visualising relation between collisions and penalty points with demographicgraphics
# **************************************************************************** #
library(tidyverse)

collision_data <- read_csv("./Data/Clean/complete_driver_collisions.csv")
point_data <- read_csv("./Data/Clean/grouped_points_by_age.csv")

# **************************************************************************** #
# Preparing Data for Plotting
# **************************************************************************** #
# Getting collision totals
demographic_collision_percentages <- collision_data %>%
  group_by(age_band_of_driver, sex_of_driver) %>%
  summarise(group_collisions = n(), .groups = 'drop') %>%
  mutate(total_collisions = sum(group_collisions),
         percentage = (group_collisions / total_collisions) * 100)

# Combining collisions and points data
demographic_collisions_and_points <- demographic_collision_percentages %>%
  left_join(point_data, by = c("age_band_of_driver", "sex_of_driver")) %>%
  drop_na() %>%
  # Pivoting so measures in one column, makes plotting easier
  pivot_longer(cols = starts_with("percentage"),
               names_to = "measure",
               values_to = "percentage") %>%
  # Changing for clarity
  mutate(measure = recode(measure, "percentage.x" = "Collisions", "percentage.y" = "Penalty Points"))

write.csv(demographic_collisions_and_points, "demographic_collisions_and_points.csv")

# **************************************************************************** #
# Visualising
# **************************************************************************** #
demo_collision_points_plot <- ggplot(demographic_collisions_and_points, aes(x = age_band_of_driver, y = percentage, colour = measure, group = measure)) +
  geom_line() +
  geom_point() +
  facet_wrap(~ sex_of_driver) + 
  labs(
    title = "Collisions and Penalties by Age Band and Sex of Driver",
    x = "Age Band of Driver",
    y = "Percentage",
    colour = ""
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("./Visualisations/demographic_collisions_and_points.png", demo_collision_points_plot, width = 10, height = 8)

