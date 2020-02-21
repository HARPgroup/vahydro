# library(ggplot2)
# library(rgeos)
# library(ggsn)
# library(rgdal)
# library(dplyr)
# library(sf) # needed for st_read()
# library(sqldf)


library(readr) #needed for read_tsv()
library(rgdal) #nneded for writeOGR()

#huc6 <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/HUC6.tsv', sep = '\t', header = TRUE)
#MinorBasins <- read.table(file = 'C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/MinorBasins.tsv', sep = '\t', header = TRUE)
MinorBasins <- read_tsv('C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/MinorBasins.tsv', col_names = TRUE)
#MinorBasins.df <- data.frame(MinorBasins)
class(MinorBasins)

#onehuc <- huc6.csv[1,]
MinorBasins_sp <- as(MinorBasins, "Spatial")

writeOGR(MinorBasins, "C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/tmpfile", driver="ESRI Shapefile")

#writeOGR(cities, td, "cities", driver="ESRI Shapefile")


#fgdb_path <- file.path("C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS", "test_data.gdb")
#arc.write(file.path(fgdb_path, "tlb"), data=list('f1'=c(23,45), 'f2'=c('hello', 'bob')))