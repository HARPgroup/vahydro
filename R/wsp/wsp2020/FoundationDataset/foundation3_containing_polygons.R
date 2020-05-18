library("readxl")
library("kableExtra")
library("sqldf")
library("stringr") #for str_remove()

# Location of source data
#source <- "wsp2020.fac.all.csv"
source <- "wsp2020.mp.all.csv"
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
data_raw <- read.csv(paste(folder,source,sep=""))
data_sp <- data_raw


#LOAD FUNCTIONS AND GDB FILES
source("/var/www/R/config.local.private"); 
source(paste(hydro_tools_location,'/GIS_LAYERS/GIS_functions.R', sep = ''));

MinorBasins_path <- paste(hydro_tools_location,'/GIS_LAYERS/MinorBasins.gdb', sep = '')
MinorBasins_layer <- 'MinorBasins'

VAHydro_RSegs_path <- paste(hydro_tools_location,'/GIS_LAYERS/VAHydro_RSegs.gdb', sep = '')
VAHydro_RSegs_layer <- 'VAHydro_RSegs'

# tidal_boundary_path <- 'hydro-tools/GIS_LAYERS/'
# tidal_boundary_layer <- 

#LOAD FIPS CENTROIDS
fips_centroids <- read.csv(paste("https://deq1.bse.vt.edu/d.dh/usafips_centroid_export",sep=""))
###########################################################################
# join fips centroids - explicitly name columns
fips_join <- paste("SELECT a.*,
                  b.fips_hydroid,
                  b.fips_name,
                  b.fips_latitude,
                  b.fips_longitude,
                  b.fips_centroid
                  FROM data_sp AS a
                  LEFT OUTER JOIN fips_centroids AS b
                  ON (a.fips_code = b.fips_code)")  
fips_join <- sqldf(fips_join)
#-----------------------------------------------------------------

# #Remove duplicate fips_code column
# fips_join <- fips_join[,-which(colnames(fips_join)=="fips_code..27")[1]]


#Set geoms equal to fips centroid if NA or outside of VA bounding box 
data_sp <- sqldf("SELECT *,
              CASE
                WHEN Latitude IS NULL THEN fips_latitude
                WHEN Latitude < 35 THEN fips_latitude
                WHEN Latitude > 41 THEN fips_latitude
                ELSE Latitude
              END AS corrected_latitude,
              CASE
                WHEN Longitude IS NULL THEN fips_longitude
                WHEN Longitude > -75 THEN fips_longitude
                WHEN Longitude < -84 THEN fips_longitude
                ELSE Longitude
              END AS corrected_longitude
              FROM fips_join")
#-----------------------------------------------------------------

###########################################################################
coordinates(data_sp) <- c("corrected_longitude", "corrected_latitude") #sp_contain_mb() requires a coordinates column
data_sp_cont <- sp_contain_mb(MinorBasins_path,MinorBasins_layer,data_sp)
data_sp_cont <- data.frame(data_sp_cont)
###########################################################################
# coordinates(data_sp_cont) <- c("corrected_longitude", "corrected_latitude") #sp_contain() requires a coordinates column
# data_sp_cont <- sp_contain(paste(localpath,tidal_boundary_path,sep="/"),tidal_boundary_layer,data_sp_cont)
# data_sp_cont <- data.frame(data_sp_cont)
###########################################################################
coordinates(data_sp_cont) <- c("corrected_longitude", "corrected_latitude") #sp_contain_vahydro_rseg() requires a coordinates column
data_sp_cont <- sp_contain_vahydro_rseg(VAHydro_RSegs_path,VAHydro_RSegs_layer,data_sp_cont)
data_sp_cont <- data.frame(data_sp_cont)
###########################################################################
###########################################################################
###########################################################################
write.csv(data_sp_cont, paste(folder,(str_remove(source,'.csv')),".MinorBasins_RSegs.csv",sep=""), row.names = F)
###########################################################################
###########################################################################
