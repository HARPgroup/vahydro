library("readxl")
library("kableExtra")
library("sqldf")

# Location of source data
source <- "wsp2020.fac.all.csv"
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"

data_raw <- read.csv(paste(folder,source,sep=""))
data_sp <- data_raw


# include: or latitude <1?
sql <- paste('SELECT *
              FROM data_sp 
              WHERE Latitude > 90 OR
              Latitude = 0 OR 
              Longitude = 0 OR 
              Latitude = 99 OR 
              Latitude = -99 OR
              Longitude = 99 OR 
              Longitude = -99
              ORDER BY fac_2020_mgy DESC
              ',sep="")

sql <- paste('SELECT sum(fac_2020_mgy)
              FROM data_sp 
              WHERE Latitude > 90 OR
              Latitude = 0 OR 
              Longitude = 0 OR 
              Latitude = 99 OR 
              Latitude = -99 OR
              Longitude = 99 OR 
              Longitude = -99
              ',sep="")


sql <- paste('SELECT sum(fac_2020_mgy)
              FROM data_sp 
              ',sep="")

data <- sqldf(sql)

