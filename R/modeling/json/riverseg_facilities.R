library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
library("rjson")
library("hydrotools")
# Load Libraries
basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source(paste(basepath,'config.R',sep='/'))
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/modeling/json/om_nhd_model_utils.R")
#> Linking to GEOS 3.9.0, GDAL 3.2.1, PROJ 7.2.1

# Get arguments (or supply defaults)
argst <- commandArgs(trailingOnly=T)
if (length(argst) > 1) {
  riverseg <- as.character(argst[1])
  wshed_area <- as.numeric(argst[2])
  facility_pid <- as.numeric(argst[3])
  model_version <- as.character(argst[4])
} else {
  cat("Outlet riverseg:")
  riverseg = readLines("stdin",n=1)
  riverseg = as.character(riverseg)
  cat("Local drainage area of riverseg:")
  wshed_area = readLines("stdin",n=1)
  wshed_area = as.numeric(riverseg)
  cat("Facility Model PID (Enter -1 to query REST for contained):")
  fpid = readLines("stdin",n=1)
  fpid = as.numeric(fpid)
  cat("model_version:")
  model_version = readLines("stdin",n=1)
  model_version = as.character(model_version)
  cat(paste0("File Name (default is ", riverseg,".json):"))
  file_name = as.character(readLines("stdin",n=1))
  if (file_name == "") {
    file_name = paste0(riverseg,".json")
  }
  
}
# Test:
# riverseg = "JL1_6562_6560"
# wshed_area = 9.52
# facility_pid = -1 
# model_version = 'vahydro-1.0'

wshed_feature = RomFeature$new(
  ds, list(
    hydrocode = paste0('vahydrosw_wshed_',riverseg),
    bundle = 'watershed',
    ftype = 'vahydro'
  ), TRUE
)
if (facility_pid == -1) {
  # find contained
  fac_url <- paste(site,"contains-mps-model-summary-export",wshed_feature$hydroid,sep='/')
  fac_recs <- ds$auth_read(fac_url)
}

wshed_info = list(
  name = riverseg,
  area_sqmi = wshed_area,
  rchres_id = 'RCHRES_R001'
)

model_list <- om_watershed_container(wshed_info)


if (exists("json_obj_url")) {
  for (i in 1:length(fac_recs)) {
    fac_model <- RomProperty$new(
      ds,
      list(
        featureid = fac_recs[i,]$facility_hydroid,
        entity_type = 'dh_feature',
        propcode = model_version
      ), TRUE
    )
    fac_obj_url <- paste(json_obj_url, fac_model$pid, sep="/")
    fac_model_info <- ds$auth_read(fac_obj_url, "text/json", "")
    fac_model_info <- fromJSON(fac_model_info)
    if (fac_model_info[[1]]$riverseg$value == riverseg) {
      # this matches, add it to the simulation 
      model_list[[fac_model_info$name]] = 
      fac_model_info[[1]]$current_mgy
    }
  }
} else {
  message("Error: json_obj_url is undefined.  Can not retrieve facility information. (Hint: Use config.R to set json_obj_url) ")
  q("n")
}


jsonData <- toJSON(model_list)
print(paste("Writing to", outfile))
write(jsonlite::prettify(jsonData), outfile)

