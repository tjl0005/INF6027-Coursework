# **************************************************************#
# Clustering Drivers based on Districts and Penalities/Collisions
# **************************************************************#
library(tidyverse)
library(dplyr)

# **************************************************************#
# Elbow function to identify optimal num clusters
# **************************************************************#
generate_elbow_plot <- function(clustering_data, topic){
  wss = 10
  
  # Getting wss for upto 15 clusters
  for (k in 1:10) {
    # Perform k-means clustering for the current number of clusters k
    test_clustering <- kmeans(clustering_data, centers = k)
    
    # Storing wss in array at current cluster number index
    wss[k] <- test_clustering$tot.withinss
  }
  
  plot_title = paste("Elbow Plot of WSS for", topic)
  
  # Visualising elbow method to see best number of clusters
  elbow_plot <- ggplot(mapping = aes(x = 1:10, y = wss, nstart = 20)) +
    geom_point() +
    geom_line() +
    labs(title = plot_title,
         x = "Number of Clusters", y = "WSS") +
    theme_minimal()
}

# **************************************************************#
# Function to label clusters
# **************************************************************#
# Assumes 3 clusters representing low, medium and high risk
label_clusters <- function(original_data, clustering_output){
  # Adding cluster labels to data
  original_data$cluster <- clustering_output$cluster

  collision_cluster_order <- order(clustering_output$centers[, 1])
  
  # Labelling clusters
  original_data$cluster_group <- factor(clustering_output$cluster, levels = collision_cluster_order,
                                        labels = c("Low Risk", "Medium Risk", "High Risk"))
  original_data$cluster_rank <- factor(clustering_output$cluster, levels = collision_cluster_order,
                                       labels = c("1", "2", "3"))
  
  return(original_data)
}
# **************************************************************#
# Districts with similar penalty point distributions
# **************************************************************#
penalty_districts <- read_csv("./Data/Clean/grouped_district_points.csv")

# Getting percentages of points held for each district
penalty_percentages <- penalty_districts %>%
  mutate(
    "1-3 Points" = (`1-3 Points` / Total) * 100,
    "5-8 Points" = (`5-8 Points` / Total) * 100,
    "9-12 Points" = (`9-12 Points` / Total) * 100,
    "12+ Points" = (`12+ Points` / Total) * 100
  ) %>%
  select("1-3 Points", "5-8 Points", "9-12 Points", "12+ Points")

# Producing elbow plot to see optimal number of clusters
penalty_elbow_plot <- generate_elbow_plot(penalty_percentages, "Penalty Points")
ggsave("./Visualisations/penalty_elbow_plot.png", penalty_elbow_plot, width=10, height=8)

# Performing clustering with k-means using 3 centers (based on elbow plot)
penalty_clustering <- kmeans(penalty_percentages, centers = 3, nstart = 25)

# Adding cluster labels to data
penalty_districts$cluster <- penalty_clustering$cluster

# Interpreting clusters through the centers, can see low, medium and higher risks
penalty_clustering$centers

# Getting order of clusters
penalty_cluster_order <- order(penalty_clustering$centers[, 1])

# Labelling clusters, can require manual labelling to ensure correct
penalty_districts$penalty_group <- factor(penalty_clustering$cluster, levels = penalty_cluster_order,
                                      labels = c("High Risk", "Medium Risk", "Low Risk"))
penalty_districts$penalty_rank <- factor(penalty_clustering$cluster, levels = penalty_cluster_order,
                                     labels = c("3", "2", "1"))

# Performing PCA as multiple dimensions in data
district_principal_components <- prcomp(penalty_percentages)

# Adding top 2 PCA components to the original data so it can be visualised in 2D
penalty_districts$PCA1 <- district_principal_components$x[, 1]
penalty_districts$PCA2 <- district_principal_components$x[, 2]

write.csv(penalty_districts, "./Data/Findings/district_penalty_risk_levels.csv")

# Visualising clusters using top 2 PCA components
district_point_clusters <- ggplot(penalty_districts, aes(x = PCA1, y = PCA2, colour = as.factor(penalty_group))) +
  geom_point() +
  labs(title="Identified Clusters for Penalty Points by District", 
       # Removing legend title
       colour = "") +
  # Default ordered colours can be misleading given nature of clusters
  scale_colour_manual(values = c("Low Risk" = "#00BA38", "Medium Risk" = "#619CFF", "High Risk" = "#F8766D")) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("./Visualisations/penalty_clusters.png", district_point_clusters, width=10, height=8)

# **************************************************************#
# Districts with similar collision percentages
# **************************************************************#
districts <- read_csv("./Data/pcd11_par11_wd11_lad11_ew_lu.csv")
collisions <- read.csv("./Data/Clean/complete_driver_collisions.csv")

# Getting distinct district codes from data
districts <- districts %>%
  distinct(lad11cd, .keep_all = TRUE)

# Getting district codes
districts_codes <- districts %>%
  mutate(district_code = ifelse(grepl("^[A-Za-z]{1}[0-9]{1}", pcd7), substr(pcd7, 1, 1), substr(pcd7, 1, 2))) %>%
  select(
    district_code,
    lad11cd
  )

# Joining outwards onto collision data
collision_districts <- left_join(collisions, districts_codes, 
                                 by = c("local_authority_ons_district" = "lad11cd"))

# Percentage of total collisions by district
collision_percentages <- collision_districts %>% 
  group_by(district_code) %>% 
  summarise(no_collisions = n()) %>% 
  mutate(total_collisions = sum(no_collisions),
         percentage = (no_collisions / total_collisions) * 100) %>%
  filter(!is.na(district_code))

# Using elbow to identify optimal number of clusters and saving plot
collisions_elbow_plot <- generate_elbow_plot(collision_percentages$percentage, "Collisions")
ggsave("./Visualisations/collision_elbow_plot.png", collisions_elbow_plot, width=10, height=8)

# Performing clustering with k-means with 3 centers (based on elbow plot)
collision_clustering <- kmeans(collision_percentages$percentage, centers = 3, nstart = 30)

# Interpreting cluster meanings through their centers
collision_clustering$centers

collision_cluster_order <- order(collision_clustering$centers[, 1])

# Labelling clusters
collision_percentages$collision_group <- factor(collision_clustering$cluster, levels = collision_cluster_order,
                                                   labels = c("Low Risk", "Medium Risk", "High Risk"))
collision_percentages$collision_rank <- factor(collision_clustering$cluster, levels = collision_cluster_order,
                                                  labels = c("1", "2", "3"))

write.csv(collision_percentages, "./Data/Findings/district_collision_risk_levels.csv")

# Visualising clusters, same as previous visualisation
district_collisions_clusters <- ggplot(collision_percentages, aes(x = percentage, y = district_code, colour = as.factor(collision_group))) +
  geom_point() +
  labs(title="Identified Clusters for No. Collisions by District", ,
       colour = "",
       x = "Percentage",
       y = "District") +
  # Default ordered colours can be misleading given nature of clusters
  scale_colour_manual(values = c("Low Risk" = "#00BA38", "Medium Risk" = "#619CFF", "High Risk" = "#F8766D")) +
  theme_minimal() +
  # Y labels to large by default
  theme(axis.text.y = element_text(size = 5)) +
  theme(legend.position = "bottom")

ggsave("./Visualisations/collision_clusters_plot.png", district_collisions_clusters, width=10, height=8)

# *****************************************************************************#
# Comparing identified clusters
# *****************************************************************************#
# Risk distributions for both sets of clusters
table(penalty_districts$penalty_group)
table(collision_percentages$collision_group)

# Shared districts
district_risk_levels <- inner_join(penalty_districts, collision_percentages, 
                                 by = "district_code") %>%
  select(district_code, penalty_group, penalty_rank, collision_group, collision_rank)

# Relation of risk types 
district_risk_levels %>%
  count(penalty_group, collision_group)

# *****************************************************************************#
# Overall risk level
# *****************************************************************************#
# New data frame with overall risk and districts for plotting
district_risks <- district_risk_levels %>%
  mutate(
    overall_risk = ceiling(
      (as.numeric(district_risk_levels$penalty_rank) +
         as.numeric(district_risk_levels$collision_rank)) / 2
    ),
    overall_risk = case_when(
      overall_risk == 1 ~ "Low",
      overall_risk == 2 ~ "Medium",
      overall_risk == 3 ~ "High"
    ),
    overall_risk = factor(overall_risk, levels = c("Low", "Medium", "High"))
  )

# Saving findings
write.csv(district_risks, "./Data/Findings/district_risk_levels.csv")

# Plotting overall risk by district and saving it, not a nice plot but can be reworked (hopefully)
overall_district_risk <- ggplot(district_risks, aes(y = overall_risk, x = district_code, fill = overall_risk)) +
  geom_col() +
  labs( title = "Overall Risk by District",
    x = "Risk Level",
    y = "District",
    fill = "") +
  theme_minimal() +
  scale_fill_manual(values = c("Low" = "#00BA38", "Medium" = "#619CFF", "High" = "#F8766D")) +
  # Making it a horizontal bar chart
  coord_flip() +
  # Y labels to large by default so reducing
  theme(axis.text.y = element_text(size = 6)) +
  theme(legend.position = "bottom")

ggsave("./Visualisations/overall_district_risk.png", overall_district_risk, width=10, height=8)

