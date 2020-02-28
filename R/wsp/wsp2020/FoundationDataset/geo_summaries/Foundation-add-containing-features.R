library("readxl")
library("kableExtra")
library("sqldf")

# Location of source data
source <- "wsp2020.fac.all.csv"
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
data_raw <- read.csv(paste(folder,source,sep=""))
data_sp <- data_raw

# Location of GIS_functions and gdb
localpath <-"C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/"
source(paste(localpath,'hydro-tools/GIS_LAYERS','GIS_functions.R',sep='/'));

fips_centroids <- read.csv(paste("https://deq1.bse.vt.edu/d.dh/usafips_centroid_export",sep=""))

MinorBasins_path <- "hydro-tools/GIS_LAYERS/MinorBasins.gdb"
MinorBasins_layer <- 'MinorBasins'

VAHydro_RSegs_path <- "hydro-tools/GIS_LAYERS/VAHydro_RSegs.gdb"
VAHydro_RSegs_layer <- 'VAHydro_RSegs'

###########################################################################
# join fips centroids 
fips_join <- paste("SELECT *
                  FROM data_sp AS a
                  LEFT OUTER JOIN fips_centroids AS b
                  ON (a.fips_code = b.fips_code)")  
fips_join <- sqldf(fips_join)


#-----------------------------------------------------------------
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
data_sp_cont <- sp_contain_mb(paste(localpath,MinorBasins_path,sep=""),MinorBasins_layer,data_sp)
data_sp_cont <- data.frame(data_sp_cont)
###########################################################################
coordinates(data_sp_cont) <- c("corrected_longitude", "corrected_latitude") #sp_contain_vahydro_rseg() requires a coordinates column
data_sp_cont <- sp_contain_vahydro_rseg(paste(localpath,VAHydro_RSegs_path,sep=""),VAHydro_RSegs_layer,data_sp_cont)
data_sp_cont <- data.frame(data_sp_cont)
###########################################################################





###########################################################################

###########################################################################
###########################################################################
write.csv(data_sp_cont, paste(folder,"wsp2020.fac.all.MinorBasins_RSegs.csv",sep=""))
###########################################################################
###########################################################################
