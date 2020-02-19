library("readxl")
library("kableExtra")
library("sqldf")


folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
data_huc_raw <- read.csv(paste(folder,"wsp2020.fac.all.HUC.csv",sep=""))

###########################################################################
HUC6.sql <- paste('SELECT HUC6_Name,
              HUC6_Code,
              COUNT(Facility_hydroid),
              sum(fac_2020_mgy),
              sum(fac_2040_mgy)
              FROM data_huc_raw 
              GROUP BY HUC6_Code
              ',sep="")
HUC6_summary <- sqldf(HUC6.sql)
###########################################################################
HUC8.sql <- paste('SELECT HUC8_Name,
              HUC8_Code,
              COUNT(Facility_hydroid),
              sum(fac_2020_mgy),
              sum(fac_2040_mgy)
              FROM data_huc_raw 
              GROUP BY HUC8_Code
              ',sep="")
HUC8_summary <- sqldf(HUC8.sql)
###########################################################################
HUC10.sql <- paste('SELECT HUC10_Name,
              HUC10_Code,
              COUNT(Facility_hydroid),
              sum(fac_2020_mgy),
              sum(fac_2040_mgy)
              FROM data_huc_raw 
              GROUP BY HUC10_Code
              ',sep="")
HUC10_summary <- sqldf(HUC10.sql)
###########################################################################