##https://deq1.bse.vt.edu/d.dh/ows-awrr-map-export-batch/wd_mgy?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=1982-01-01&tstime%5Bmax%5D=2020-12-31&bundle%5B0%5D=transfer&hydroid=
  
library(rgeos) #readWKT()
library(rgdal) #readOGR()
library(raster) #bind()
library('httr')
library('sqldf')
library('dplyr')
library('tidyr')
library(maptools)
library("beepr")
# USER INPUTS #########################################################################
#WKT_layer <- read.csv('C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/GIS_LAYERS/MinorBasins.csv')

#load variables
syear = 1982
eyear = 2022

## LOAD CONFIG FILE ###################################################################
source(paste("/var/www/R/config.local.private", sep = ""))
localpath <- paste(github_location,"/USGS_Consumptive_Use", sep = "")

#LOAD from_vahydro() FUNCTION
source(paste(localpath,"/Code/VAHydro to NWIS/from_vahydro.R", sep = ""))
datasite <- "http://deq1.bse.vt.edu:81/d.dh"

#PART 1 RETRIEVE ANNUAL WITHDRAWAL DATA FOR ALL TRANSFERS #########################
all_transfer_data <- list()

mgy_vars <- c("dl_mgy", "rl_mgy")
for (m in mgy_vars) {
  
    print(paste0("PROCESSING YEAR(S): ", syear," - ", eyear))
    startdate <- paste(syear, "-01-01",sep='')
    enddate <- paste(eyear, "-12-31", sep='')
    
    #with power
    export_view <- paste0("ows-awrr-map-export/",m,"?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",syear,"&tstime%5Bmax%5D=",eyear,"&bundle%5B0%5D=transfer")
    output_filename <- "dl_mgy_export.csv"
    transfer_annual <- from_vahydro(datasite,export_view,localpath,output_filename)
    
    all_transfer_data <- rbind(all_transfer_data, transfer_annual)
}

# sqldf('SELECT DISTINCT "MP.Name", Facility, Facility_hydroid
#         FROM all_transfer_data
#         ')
#remove duplicates - GROUP BY USING MAX
transfer_ann <- sqldf('SELECT "MP_hydroid","Hydrocode","Source.Type","MP.Name","Facility_hydroid","Facility","Use.Type","Year",max("Water.Use.MGY") AS "Water.Use.MGY","Latitude","Longitude","Locality","FIPS.Code" 
               FROM all_transfer_data
               WHERE Facility != "DALECARLIA WTP"
               GROUP BY "MP_hydroid","Hydrocode","Source.Type","MP.Name","Facility_hydroid","Facility","Use.Type","Year","Latitude","Longitude","Locality","FIPS.Code"
                ORDER BY "Water.Use.MGY" DESC ')

write.csv(transfer_ann, "C:/Users/ejp42531/Documents/OWS_transfer_mgy_1982-2022.csv", row.names = F)

#PART 2 RETRIEVE ANNUAL WITHDRAWAL DATA FROM SPECIFIC FACILITIES OUTLINED IN EMAIL #########################
transfer_annual_data <- list()

## Facility HydroID range
#66937 = Norfolk City of Utilities Four Suffolk Wells
#74327 = LAKE GASTON WTP
mgy_vars <- c("dl_mgy", "rl_mgy", "wd_mgy")
hydroid_range <- c(74125, 71827, 73172, 74111, 74122, 74103, 74123, 74327, 66937, 73126, 72302, 73705, 73210)

for (m in mgy_vars) {
  for (h in hydroid_range) {
    print(paste0("PROCESSING YEAR(S): ", syear," - ", eyear))
    startdate <- paste(syear, "-01-01",sep='')
    enddate <- paste(eyear, "-12-31", sep='')
    
    #with power
    export_view <- paste0("ows-awrr-map-export/",m,"?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",syear,"&tstime%5Bmax%5D=",eyear,"&bundle%5B0%5D=transfer&hydroid=",h)
    output_filename <- "dl_mgy_export.csv"
    transfer_annual <- from_vahydro(datasite,export_view,localpath,output_filename)
    
    transfer_annual_data <- rbind(transfer_annual_data, transfer_annual)
  }
}

sqldf('SELECT DISTINCT "MP.Name", Facility, Facility_hydroid
        FROM transfer_annual_data
        ')
#remove duplicates - GROUP BY USING MAX
transfer_ann <- sqldf('SELECT "MP_hydroid","Hydrocode","Source.Type","MP.Name","Facility_hydroid","Facility","Use.Type","Year",max("Water.Use.MGY") AS "Water.Use.MGY","Latitude","Longitude","Locality","FIPS.Code" 
               FROM transfer_annual_data
               WHERE Facility != "DALECARLIA WTP"
               GROUP BY "MP_hydroid","Hydrocode","Source.Type","MP.Name","Facility_hydroid","Facility","Use.Type","Year","Latitude","Longitude","Locality","FIPS.Code"
                ORDER BY "Water.Use.MGY" DESC ')
