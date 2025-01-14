# INF6027-Coursework
## Summary
This repository contains the R code and visualisations produced that were completed as coursework for the INF6027 module at the University of Sheffield. The particular purpose of this project is to analyse data with a set aim.

Project Aim: -	To understand and identify dangerous drivers in the UK.

The research questions are as follows: 
1.	Is it possible to identify groups of drivers with higher risk?
2.	Can collisions and penalty points be used as metrics for driver risk?
3.	How has driving changed since the COVID-19 pandemic?

For each of the R files there is a section below which covers the purpose of the file and how to use it.

## Data
The data used is not directly available in this repository due to it's size but it can be recreated using the provided links to the original data and running with the R files in this repository.

The driving license data used in this project is available at: https://www.data.gov.uk/dataset/d0be1ed2-9907-4ec4-b552-c048f6aec16a/gb-driving-licence-data. (For this project only the sheets for penalty points across gender, ages and location are used.)

The collisions and casualty data is available at: https://www.data.gov.uk/dataset/cb7ae6f0-4be6-4935-9277-47e5ce24a11f/road-safety-data.

## Visualisations
This folder contains the visualisations produced for the project.

## Running the code
The intended use of the code is that each line should be ran one after the other or the file as whole. 

Three folders are used in this process, the expecation is that the referenced data will stored under "./Data/Raw", the processed data will then be stored under "./Data/Clean", which will be used for analysis. The results of the analysis includes both data and visualisations which are stored under "./Data/Findings" and "./Visualisations".

### Exploration
The first file to be used is "exploration.R", which provides a summary of the data, the available variables and the ranges as well as detecting missing and duplicated data.

### Pre-Processing
Then there is "preprocessing.R", which is used to prepare the data for the analysis. This code groups the licence data into age groups and gender by the number of peantly points. For the casualty and collision data this file resolves duplicated and dmissing data, redfines the age groups to match those of the penalty points data and merges the the collision and casualty data to create a comprehensive driver and collision dataset.

### Time-Series analysis
The first analysis explored was in "time_series.R". This code produces three visualisations using the processed data showing the yearly, hourly and combined trends of collisions from the last five years (2019-2023).

Full details of findings and exploration of the literature surrounding this are available within the report.

### Clustering analysis
The second analyis explored in "district_clustering.R" was to understand driving risk in different areas. 

The code uses K-means clustering and Within-Cluster-Sum of Squared Errors (WSS) with an elbow plot to identify the optimal clusters. When ran this code will generate two elbow plots and perform the clustering algorithm on both penalty point and collision data. The default number of clusters is three as identified in the elbow plot. 

Both of the clusters are visualised although only principal components for penalty points, with the code handling cluster labelling. The code will also output statistics to compare both sets of clusters through their distributions of risk, shared districts and shared risk levels. Finally an overall risk level was explored by merging the two groups and the code will produce a visualisation to show the district breakdown of overall risk.

### Demographic Comparison
The third and final analysis explored in "demo_collision_vs_penalties.R" was a comparison of the relationships of sex and age with collisions and penalty points.

The code for this uses the processed data to the percentage share for each gender across different age groups for the different risk metrics (Collisions and penalty points). This data is then visualised so that the trends and differences can be analysed.

## Findings
A full discussion of the findings and literature are available within the report completed for this project. 

Some key findings are displayed here:

* Time, gender, age and location have a measurable influence on driving risk.
* Driving is safer since the COVID-19 pandemic.
* Rush-hour traffic peaks at 08:00 and 18:00 and continued during lockdowns despite many people working from home.
* There is a limited relationship between penalty points and collisions suggesting they are applicable metrics to assessing driving risk.
* After ages 36-45, driver risk significantly decreases in both metrics and continues to do so with age, suggesting older people are safer.
* Penalty points are an effective deterrent for dangerous driving with collision risk decreasing as penalty points increase.

## Intended File Structure
```
+---------------------------------------------------------------------------------------------------------------------------+
|   .gitignore
|   .RData
|   .Rhistory
|   INF6027-Coursework.Rproj
|   README.md
+---Code
|       .Rhistory
|       demo_collision_vs_penalties.R
|       district_clustering.R
|       exploration.R
|       prediction.R
|       preprocessing.R
|       time_series.R
|       
+---Data
|   |   dft-road-casualty-statistics-road-safety-open-dataset-data-guide-2023.xlsx
|   |   pcd11_par11_wd11_lad11_ew_lu.csv
|   |   
|   +---Clean
|   |       all_points_by_age.csv
|   |       complete_driver_collisions.csv
|   |       grouped_district_points.csv
|   |       grouped_points_by_age.csv
|   |       
|   +---Findings
|   |       collisions_per_hour_per_year.csv
|   |       demographic_collisions_and_points.csv
|   |       district_collision_risk_levels.csv
|   |       district_penalty_risk_levels.csv
|   |       district_risk_levels.csv
|   |       
|   \---Raw
|           .gitignore
|           dft-road-casualty-statistics-casualty-last-5-years.csv
|           dft-road-casualty-statistics-collision-last-5-years.csv
|           dft-road-casualty-statistics-vehicle-last-5-years.csv
|           driving-licence-data-sep-2024.xlsx
|           
\---Visualisations
        collisions_per_hour.png
        collisions_per_hour_and_year.png
        collisions_per_year.png
        collision_clusters_plot.png
        collision_elbow_plot.png
        demographic_collisions_and_points.png
        overall_district_risk.png
        penalty_clusters.png
        penalty_elbow_plot.png
+---------------------------------------------------------------------------------------------------------------------------+
```