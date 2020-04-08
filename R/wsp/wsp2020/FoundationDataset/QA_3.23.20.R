library("sqldf")
library("xlsx")

folder <- "C:/Users/nrf46657/Desktop/QA_3.23.20/"
data_raw <- read.csv(paste(folder,"mp-to-fac.csv",sep=""))

#agg by fac
data_agg <- paste("SELECT Facility_hydroid,
                  facility_name,
                  sum(mp_2020_mgy) AS 'sum_2020',
                  sum(mp_2040_mgy) AS 'sum_2040'
                  FROM data_raw
                  GROUP By Facility_hydroid")  
data_agg <- sqldf(data_agg)


write.csv(data_agg, paste(folder,"fac_agg.csv",sep=""), row.names = F)
