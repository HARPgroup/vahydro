suppressPackageStartupMessages(library(nhdplusTools))
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
suppressPackageStartupMessages(library(sf))
suppressPackageStartupMessages(library("sqldf"))
suppressPackageStartupMessages(library("stringr"))
suppressPackageStartupMessages(library("rjson"))
suppressPackageStartupMessages(library("hydrotools"))
suppressPackageStartupMessages(library("rgeos"))
# Load Libraries
basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source(paste(basepath,'config.R',sep='/'))
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/modeling/json/om_nhd_model_utils.R")
#> Linking to GEOS 3.9.0, GDAL 3.2.1, PROJ 7.2.1
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
ds$get_token(rest_pw)

# Get arguments (or supply defaults)
argst <- commandArgs(trailingOnly=T)
if (length(argst) > 1) {
  riverseg <- as.character(argst[1])
  wshed_area <- as.numeric(argst[2])
  facility_pid <- as.numeric(argst[3])
} else {
  cat("Outlet riverseg:")
  riverseg = readLines("stdin",n=1)
  riverseg = as.character(riverseg)
  cat("Local drainage area of riverseg:")
  wshed_area = readLines("stdin",n=1)
  wshed_area = as.numeric(riverseg)
  cat("Facility Model PID (todo: option to query REST):")
  fpid = readLines("stdin",n=1)
  fpid = as.numeric(fpid)
  cat(paste0("File Name (default is ", riverseg,".json):"))
  file_name = as.character(readLines("stdin",n=1))
  if (file_name == "") {
    file_name = paste0(riverseg,".json")
  }
  
}
# Test:
# riverseg = "JL1_6562_6560"
# wshed_area = 9.52
# facility_pid = 7118959


wshed_info = list(
  name = riverseg,
  area_sqmi = wshed_area,
  rchres_id = 'RCHRES_R001'
)

json_out <- om_watershed_container(wshed_info)


if (exists("json_obj_url")) {
  fac_obj_url <- paste(json_obj_url, facility_pid, sep="/")
  fac_model_info <- ds$auth_read(fac_obj_url, "text/json", "")
  fac_model_info <- fromJSON(fac_model_info)
} else {
  message("Error: json_obj_url is undefined.  Can not retrieve facility information. (Hint: Use config.R to set json_obj_url) ")
  q("n")
}


jsonData <- toJSON(json_out)
print(paste("Writing to", outfile))
write(jsonlite::prettify(jsonData), outfile)


