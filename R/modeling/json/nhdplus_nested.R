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

# Get arguments (or supply defaults)
argst <- commandArgs(trailingOnly=T)
if (length(argst) > 1) {
  outlet_comid <- as.numeric(argst[1])
  if (outlet_comid == -1) {
    plat <- as.numeric(argst[2])
    plon <- as.numeric(argst[3])
    comp_name <- as.character(argst[4])
  } else {
    comp_name <- as.character(argst[2])
  }
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
  cat("File Name (default is [COMID].json):")
  comp_name = readLines("stdin",n=1)
  cat("Comid(s) to omit (comma-separated, will skip all upstream of comid, default=''):")
  comid_skip = readLines("stdin",n=1)
}
# if we've supplied a comid assume we know the desired
# nhd network and just grab it
if ( !( (outlet_comid == "") | (outlet_comid == "-1"))) {
  # we have been given a comid so pull the location data from NHD+
  pc = nhdplusTools::get_nhdplus(comid=outlet_comid)
  # Get centroid of NHD catchment
  p_cent = st_centroid(pc$geometry)
  # get lat and lon
  plon = p_cent[[1]][[1]]
  # [1] -78.66296
  plat = p_cent[[1]][[2]]
}

# watershed outlet
out_point = sf::st_sfc(sf::st_point(c(plon, plat)), crs = 4326)
nhd_out <- get_nhdplus(out_point)
wshed_name = nhd_out$comid
m_cat <- plot_nhdplus(list(nhd_out$comid))
if (comp_name == "") {
  fname = paste0(nhd_out$comid, ".json")
} else {
  fname = paste0(comp_name, ".json")
}
outfile = paste0(fname)
                 
# get the nhd flowline dataset  
nhd <- get_nhdplus(m_cat$basin)
nhd_df <- as.data.frame(st_drop_geometry(nhd))
# find the outlet point of this flowline dataset

# beaver creek lake comid is 8567221
# Mechums just above the confluence with Moormans is comid = 8566905
comid = nhd_out$comid  # 8567221 # 8566905
# the stuff upstream
bc_comids = get_UT(nhd, comid, distance = NULL)
bc_comids = (paste(bc_comids,collapse=', '))
nhd_network <- sqldf(str_interp("select * from nhd_df where comid in (${bc_comids}) order by comid"))
nhd_network[,c('comid', 'gnis_name','fromnode', 'tonode', 'totdasqkm', 'areasqkm', 'lengthkm')]


json_network = list()
message("Calling nhd_model_network2() to establish base network")
json_network <- nhd_model_network2(as.data.frame(nhd_out), nhd_network, json_network)
# 
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

