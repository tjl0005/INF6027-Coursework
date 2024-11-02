# INF6027-Coursework
### Summary
This repository contains the R code and visualisations produced that were completed as coursework for the INF6027 module at the University of Sheffield. The particular purpose of this project is to analyse a set of data to answer research questions. 

The research questions are as follows: 
1.	Using penalty points and number of collisions is it possible to identify demographic factors (age, location and gender) which have a higher association with dangerous driving?
2.	Is there a direct relationship between drivers with a higher number of penalty points to those with a higher number of collisions? 
3.	Which is more relevant in identifying driving risks, demographic data or road conditions (lighting, road surface and weather)?

For each of the R files there is a section below which covers the purpose of the file and how to use it.

### Data
The data used is not directly available due to it's size but can be recreated using the provided links to the original data in junction with the R files in this repository.

The driving license data used in this project is available at: https://www.data.gov.uk/dataset/d0be1ed2-9907-4ec4-b552-c048f6aec16a/gb-driving-licence-data. For this project only the datasheets pertaining to penalty points across gender, ages and location are used.

The collisions and casualty data is available at: https://www.data.gov.uk/dataset/cb7ae6f0-4be6-4935-9277-47e5ce24a11f/road-safety-data.

### Visualisations
This folder contains the visualisations produced for the project.

### Running the code
The intended use of the code is to go file by file, line by line. The first file to use is "exploration".r. This file is used to provide a summary of the data to the user, so what variables are available and their ranges. It is also used for the initial identification of duplicates and missing data.

Then there is "preprocessing.r", which is focused on cleaning and preparing the data for the analysis. This file can be used to group the licenses data into age groups, genders and number of points, which can then be used in analysis. For the casualty and collision data the file can be used to resolve the identified duplicates and missing data from exploration, un-enconding variables for readability and merging this data to form a complete driver dataset.
