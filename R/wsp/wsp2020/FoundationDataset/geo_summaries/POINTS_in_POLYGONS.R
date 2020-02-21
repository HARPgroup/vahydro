library("readxl")
library("kableExtra")
library("sqldf")

# Location of source data
source <- "wsp2020.fac.all.csv"
#source <- "wsp2020.mp.all.csv"
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"

# Location of GIS_functions and gdb
localpath <-"C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/"
source(paste(localpath,'hydro-tools/GIS_LAYERS','GIS_functions.R',sep='/'));

gdb_path <- "hydro-tools/GIS_LAYERS/WBD.gdb"
layer_name <- 'WBDHU6' 

fips_centroids <- read.csv(paste("https://deq1.bse.vt.edu/d.dh/usafips_centroid_export",sep=""))

data_raw <- read.csv(paste(folder,source,sep=""))
data_sp <- data_raw

###########################################################################
# join fips centroids 
fips_join <- paste("SELECT *
                  FROM data_sp AS a
                  LEFT OUTER JOIN fips_centroids AS b
                  ON (a.fips_code = b.fips_code)")  
fips_join <- sqldf(fips_join)

#Set geoms equal to fips centroid if NA or outside of VA bounding box 
data_sp <- sqldf("SELECT *,
              CASE
                WHEN Latitude IS NULL THEN fips_latitude
                WHEN Latitude > 35 THEN fips_latitude
                WHEN Latitude < 41 THEN fips_latitude
                ELSE Latitude
              END AS corrected_latitude,
              CASE
                WHEN Latitude IS NULL THEN fips_longitude
                WHEN Longitude > -75 THEN fips_longitude
                WHEN Longitude < -84 THEN fips_longitude
                ELSE Longitude
              END AS corrected_longitude
              FROM fips_join")
###########################################################################
coordinates(data_sp) <- c("corrected_longitude", "corrected_latitude") #sp_contain() requires a coordinates column
data_sp_cont <- sp_contain(paste(localpath,gdb_path,sep=""),layer_name,data_sp)
data_sp_cont <- data.frame(data_sp_cont)
###########################################################################
###########################################################################
data_huc <- paste('SELECT Facility_hydroid, 
                                  Poly_Name as HUC6_Name, 
                                  Poly_Code as HUC6_Code
                          FROM data_sp_cont
                          ',sep="")
data_huc <- sqldf(data_huc)
###########################################################################
###########################################################################
data_sp_raw <- data_sp_cont
data_query <- paste("SELECT *
                  FROM data_sp_raw AS a
                  LEFT OUTER JOIN data_huc AS b
                  ON (a.Facility_hydroid = b.Facility_hydroid)")  
data_HUCs <- sqldf(data_query)
###########################################################################
###########################################################################
write.csv(data_HUCs, paste(folder,"wsp2020.fac.all.HUC.csv",sep=""))
###########################################################################
###########################################################################
