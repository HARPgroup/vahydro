library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
library("rjson")
library("hydrotools")
# Load Libraries
basepath='/var/www/R';
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
  file_name <- as.character(argst[5])
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
no_results = 1 # only the model atributes not results
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

wshed_info = list(
  name = riverseg,
  area_sqmi = wshed_area,
  rchres_id = 'RCHRES_R001',
  run_mode = 6
)

model_list <- om_nestable_watershed(wshed_info) #ustabe: model_list <- om_watershed_container(wshed_info)

if (facility_pid == -1) {
  # find contained
  fac_url <- paste(site,"contains-mps-model-summary-export",wshed_feature$hydroid,sep='/')
  fac_recs <- ds$auth_read(fac_url)
  
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
      fac_obj_url <- paste(json_obj_url, fac_model$pid, 'json', no_results, sep="/")
      fac_model_info <- ds$auth_read(fac_obj_url, "text/json", "")
      fac_model_info <- fromJSON(fac_model_info)
      if (fac_model_info[[1]]$riverseg$value == riverseg) {
        # this matches, add it to the simulation 
        model_list[[fac_model_info[[1]]$name]] = fac_model_info[[1]]
      }
    }
  } else {
    message("Error: json_obj_url is undefined.  Can not retrieve facility information. (Hint: Use config.R to set json_obj_url) ")
    q("n")
  }
} else {
  fac_model <- RomProperty$new(
    ds,
    list(
      pid = facility_pid
    ), TRUE
  )
  if (is.na(fac_model$propname)) {
    # did not find quit
    message(paste("Error: requested facility model pid", facility_pid,"does not exist"))
  }
  fac_obj_url <- paste(json_obj_url, fac_model$pid, 'json', no_results, sep="/")
  fac_model_info <- ds$auth_read(fac_obj_url, "text/json", "")
  fac_model_info <- fromJSON(fac_model_info)
  if (fac_model_info[[1]]$riverseg$value == riverseg) {
    # this matches, add it to the simulation 
    model_list[[fac_model_info[[1]]$name]] = fac_model_info[[1]]
  }
}


# encapsulate in generic container
# and render as a nested set of objects + equations
network_base = 'RCHRES_R001'
json_out = list()
# shift the final outlet to the base of the object
json_out[[network_base]] = model_list
json_out[[network_base]][["name"]] = network_base
json_out[[network_base]][["object_class"]] = 'ModelObject'
json_out[[network_base]][["value"]] ='0'
# Now add inflow and unit area
json_out[[network_base]][['IVOLin']] = list(
  name = 'IVOLin', 
  object_class = 'ModelLinkage',
  right_path = '/STATE/RCHRES_R001/HYDR/IVOL',
  link_type = 2
)
# this is a fudge, only valid for headwater segments
# till we get DSN 10 in place
json_out[[network_base]][['Runit']] = list(
  name = 'Runit', 
  object_class = 'Equation', 
  value='IVOLin / drainage_area_sqmi'
)

json_out[[network_base]][['run_mode']] = list(
  name = 'run_mode', 
  object_class = 'Constant', 
  value = wshed_info$run_mode
)

jsonData <- toJSON(json_out)
print(paste("Writing to", file_name))
write(jsonlite::prettify(jsonData), file_name)

