library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
library("rjson")
# Load Libraries
basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source(paste(basepath,'config.R',sep='/'))
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/modeling/json/om_nhd_model_utils.R")

#> Linking to GEOS 3.9.0, GDAL 3.2.1, PROJ 7.2.1

# Get arguments (or supply defaults)
argst <- commandArgs(trailingOnly=T)
if (length(argst) > 1) {
  outlet_comid <- as.numeric(argst[1])
  if (outlet_comid == -1) {
    plat <- as.numeric(argst[2])
    plon <- as.numeric(argst[3])
  }
  comp_name <- as.character(argst[4])
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

# render as a nested set of objects + equations
json_out = list()
network_base = 'RCHRES_R001'
json_out[[network_base]] = list(name='RCHRES_R001', object_class = 'ModelObject', value='0')
json_network = json_out[[network_base]]
json_network[['area_sqkm']] = list(name = 'area_sqkm', object_class = 'Constant', value=nhd_out$areasqkm)
json_network[['area_sqmi']] = list(name = 'area_sqmi', object_class = 'Equation', value="area_sqkm * 0.386102")
json_network[['drainage_area_sqkm']] = list(name = 'drainage_area_sqkm', object_class = 'Constant', value=nhd_out$totdasqkm)
json_network[['drainage_area_sqmi']] = list(name = 'drainage_area_sqmi', object_class = 'Equation', value="drainage_area_sqkm * 0.386102")
# inflow and unit area
json_network[['IVOLin']] = list(
  name = 'IVOLin', 
  object_class = 'ModelLinkage',
  right_path = '/STATE/RCHRES_R001/HYDR/IVOL',
  link_type = 2
)
# this is a fudge, only valid for headwater segments
# till we get DSN 10 in place
json_network[['Runit']] = list(
  name = 'Runit', 
  object_class = 'Equation', 
  value='IVOLin / drainage_area_sqmi'
)

json_network = list()
json_network <- nhd_model_network(as.data.frame(nhd_out), nhd_network, json_network)


nhd_model_network2 <- function (wshed_info, nhd_network, json_network) {
  comid = wshed_info$comid
  wshed_info$name = paste0('nhd_', comid)
  json_network[[wshed_info$name]] = om_nestable_watershed(wshed_info)
  next_ups <- nhd_next_up(comid, nhd_network)
  num_tribs = nrow(next_ups)
  if (num_tribs > 0) {
    for (n in 1:num_tribs) {
      trib_info = next_ups[n,]
      trib_info$name = paste0('nhd_', trib_info$comid)
      json_network[[wshed_info$name]][[trib_info$name]] = nhd_model_network2(trib_info, nhd_network, json_network[[wshed_info$name]])
    }
  }
  return(json_network)
}
json_network2 = list()
json_network2 <- nhd_model_network2(as.data.frame(nhd_out), nhd_network, json_network)


# Get Upstream model inputs
json_network[[wshed_name]][['read_from_children']] = list(
  name='read_from_children', 
  object_class = 'ModelBroadcast', 
  broadcast_type = 'read', 
  broadcast_channel = 'hydroObject', 
  broadcast_hub = 'self', 
  broadcast_params = list(
    list("Qtrib","Qtrib"),
    list("trib_area_sqmi","trib_area_sqmi")
  )
)
# simulate flows
json_network[[wshed_name]][['Qlocal']] = list(
  name='Qlocal', 
  object_class = 'Equation', 
  value=paste('local_area_sqmi * Runit')
)
json_network[[wshed_name]][['Qin']] = list(
  name='Qin', 
  object_class = 'Equation', 
  equation=paste('Qlocal + Qtrib')
)
# Overwrite IVOL with Qin result for main stem
json_network[['IVOLwrite']] = list(
  name = 'IVOLwrite', 
  object_class = 'ModelLinkage',
  left_path = '/STATE/RCHRES_R001/HYDR/IVOL',
  right_path = '/STATE/RCHRES_R001/Qin',
  link_type = 5
)
json_out[[network_base]] = json_network

jsonData <- toJSON(json_out)
print(paste("Writing to", outfile))
write(jsonlite::prettify(jsonData), outfile)

