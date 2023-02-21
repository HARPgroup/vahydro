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
#> Linking to GEOS 3.9.0, GDAL 3.2.1, PROJ 7.2.1

# Get arguments (or supply defaults)
argst <- commandArgs(trailingOnly=T)
if (length(argst) > 0) {
  plat <- as.numeric(argst[1])
  plon <- as.numeric(argst[2])
  comp_name <- as.character(argst[4])
} else {
  plat = as.numeric(readline("Outlet latitude:"))
  plon = as.numeric(readline("Outlet longitude:"))
  comp_name = readline("File Name (default is COMID):")
}

nhd_next_up <- function (comid, nhd_network) { 
  next_ups <- sqldf(
    paste(
      "select * from nhd_network 
       where tonode in (
         select fromnode from nhd_network 
         where comid = ", comid,
      ")"
    )
  )
  return(next_ups)
}

# watershed outlet
out_point = sf::st_sfc(sf::st_point(c(plon, plat)), crs = 4326)
nhd_out <- get_nhdplus(out_point)
m_cat <- plot_nhdplus(list(nhd_out$comid))

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

# render as a nested set ofobjects + equations
json_out = list()
network_base = 'RCHRES_R001'
json_out[[network_base]] = list(name='RCHRES_R001', object_class = 'ModelObject', equation='0')
json_network = json_out[[network_base]]
json_network[['area_sqkm']] = list(name = 'area_sqkm', object_class = 'Constant', value=nhd_out$areasqkm)
json_network[['area_sqmi']] = list(name = 'area_sqmi', object_class = 'Equation', equation="area_sqkm * 0.386102")
json_network[['drainage_area_sqkm']] = list(name = 'drainage_area_sqkm', object_class = 'Constant', value=nhd_out$totdasqkm)
json_network[['drainage_area_sqmi']] = list(name = 'drainage_area_sqmi', object_class = 'Equation', equation="drainage_area_sqkm * 0.386102")
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
  equation='IVOLin / drainage_area_sqmi'
)
# create equation holder for local trib inflow equations
trib_area_eqn = ''
Qtrib_eqn = ''
finished = FALSE
currid = comid
curr_path = root_path

nhd_model_network <- function (wshed_info, nhd_network, json_network) {
  comid = wshed_info$comid
  wshed_name = paste0('nhd_', comid)
  json_network[[wshed_name]] = list(
    name=wshed_name, 
    object_class = 'MicroWatershedModel'
  )
  json_network[[wshed_name]][['drainage_area_sqmi']] = list(
    name='drainage_area_sqmi', 
    object_class = 'Equation', 
    equation=paste(wshed_info$areasqkm,' * 0.386102')
  )
  next_ups <- nhd_next_up(comid, nhd_network)
  num_tribs = nrow(next_ups)
  if (num_tribs > 0) {
    for (n in 1:num_tribs) {
      trib_info = next_ups[n,]
      json_network[[wshed_name]] = nhd_model_network(trib_info, nhd_network, json_network[[wshed_name]])
    }
  }
  return(json_network)
}

json_network = list()
json_network <- nhd_model_network(as.data.frame(nhd_out), nhd_network, json_network)

json_out[[network_base]] = json_network

jsonData <- toJSON(json_out)
write(jsonlite::prettify(jsonData), paste0("C:/usr/local/home/git/vahydro/R/modeling/nhd/nhd_simple_", nhd_out$comid, ".json"))

