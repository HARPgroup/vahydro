library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("hydrotools")
library("stringr")
library("rjson")
# Load Libraries
basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source(paste(basepath,'config.R',sep='/'))
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/modeling/json/om_nhd_model_utils.R")
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
ds$get_token(rest_pw)

#> Linking to GEOS 3.9.0, GDAL 3.2.1, PROJ 7.2.1
plon = -1; plat = -1
# Get arguments (or supply defaults)
argst <- commandArgs(trailingOnly=T)
if (length(argst) > 1) {
  outlet_comid <- as.numeric(argst[1])
  if (outlet_comid == -1) {
    plat <- as.numeric(argst[2])
    plon <- as.numeric(argst[3])
    comp_name <- as.character(argst[4])
    skip_arg = 5
  } else {
    comp_name <- as.character(argst[2])
    skip_arg = 3
  }
  comid_skip = as.character(argst[skip_arg])
} else {
  cat("Outlet COMID (press ENTER to query by point):")
  outlet_comid = readLines("stdin",n=1)
  outlet_comid = as.numeric(outlet_comid)
  if ( (outlet_comid == "") | (outlet_comid == "-1")) {
    cat("Outlet latitude:")
    plat = readLines("stdin",n=1)
    plat = as.numeric(plat)
    cat("Outlet longitude:")
    plon = readLines("stdin",n=1)
    plon = as.numeric(plon)
  }
  cat("Component Name (for array key and file - default is [COMID] and [COMID].json):")
  comp_name = readLines("stdin",n=1)
  cat("Comid(s) to omit (comma-separated, will skip all upstream of comid, default=''):")
  comid_skip = readLines("stdin",n=1)
}
skip_comids <- str_split(comid_skip, ",")[[1]]

# if we've supplied a comid assume we know the desired
# nhd network and just grab it
if ( ( (outlet_comid[1] == "") | (outlet_comid[1] == "-1"))) {
  # watershed outlet
  message(paste("Getting outlet location", plon, plat))
  out_point = sf::st_sfc(sf::st_point(c(plon, plat)), crs = 4326)
  nhd_out <- get_nhdplus(out_point)
  outlet_comid = nhd_out$comid
}

# this is how we get the full set of tribs,
#m_cat <- plot_nhdplus(list(nhd_out$comid))
# IS this a workaround to get the same set of tribs without grabbing the map?
message(paste("Getting flowlines that drain to outlet location", plon, plat))
flowline <- memo_navigate_nldi(
  list(featureSource = "comid",
       featureID = outlet_comid, 
       mode = "upstreamTributaries", 
       distance_km = 1000
  )
)
# handle timeout in memo function
if (is.null(flowline)) {
  flowline <- navigate_nldi(
    list(featureSource = "comid",
         featureID = outlet_comid, 
         mode = "upstreamTributaries", 
         distance_km = 1000
    )
  )
}
if (comp_name == "") {
  outfile = paste0(outlet_comid, ".json")
} else {
  outfile = paste0(comp_name, ".json")
}
                 
# get the nhd flowline dataset  
#nhd <- get_nhdplus(m_cat$basin)
message(paste("Retrieving stream and catchment info with get_nhdplus()"))
nhd <- get_nhdplus(comid = flowline$UT_flowlines$nhdplus_comid)
nhd_network <- as.data.frame(st_drop_geometry(nhd))
# find the outlet point of this flowline dataset

json_network = list()
message("Calling nhd_model_network2() to establish base network")
json_network <- nhd_model_network2(as.data.frame(nhd_out), nhd_network, json_network, skip_comids)

# encapsulate in generic container
# and render as a nested set of objects + equations
network_base = 'RCHRES_R001'
json_out = list()
# shift the final outlet to the base of the object
json_out[[network_base]] = json_network[[names(json_network)[1]]]
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

jsonData <- toJSON(json_out)
print(paste("Writing to", outfile))
write(jsonlite::prettify(jsonData), outfile)

