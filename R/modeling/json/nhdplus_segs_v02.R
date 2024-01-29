library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
library("rjson")
# Load Libraries
basepath='/var/www/R';
# site is specified in system config.local.private so this shouldn;t do anything but confuse stuff?
#site <- "http://deq1.bse.vt.edu:81/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source(paste(basepath,'config.R',sep='/'))
#> Linking to GEOS 3.9.0, GDAL 3.2.1, PROJ 7.2.1

# mechums outlet
out_point = sf::st_sfc(sf::st_point(c(-78.551675, 38.137456)), crs = 4326)
nhd_out <- get_nhdplus(out_point)
m_cat <- plot_nhdplus(list(nhd_out$comid))

# get the nhd flowline dataset  
nhd <- get_nhdplus(m_cat$basin)
nhd_df <- as.data.frame(st_drop_geometry(nhd))

# beaver creek lake comid is 8567221
# Mechums just above the confluence with Moormans is comid = 8566905
comid = 8567221 # 8566905
# the stuff upstream
bc_comids = get_UT(nhd, comid, distance = NULL)
bc_comids = (paste(bc_comids,collapse=', '))
bc_network <- sqldf(str_interp("select * from nhd_df where comid in (${bc_comids}) order by comid"))
bc_network[,c('comid', 'gnis_name','fromnode', 'tonode', 'totdasqkm', 'areasqkm', 'lengthkm')]

# render as simple set of equations
json_out = list()
json_out[['RCHRES_R001']] = list(name='RCHRES_R001', object_class = 'ModelObject', equation='0')
json_rchres = json_out[['RCHRES_R001']]
json_rchres[['area_sqkm']] = list(name = 'area_sqkm', object_class = 'Constant', value=nhd_out$areasqkm)
json_rchres[['area_sqmi']] = list(name = 'area_sqmi', object_class = 'Equation', equation="area_sqkm * 0.386102")
json_rchres[['drainage_area_sqkm']] = list(name = 'drainage_area_sqkm', object_class = 'Constant', value=nhd_out$totdasqkm)
json_rchres[['drainage_area_sqmi']] = list(name = 'drainage_area_sqmi', object_class = 'Equation', equation="drainage_area_sqkm * 0.386102")
# inflow and unit area
json_rchres[['IVOLin']] = list(
  name = 'IVOLin', 
  object_class = 'ModelLinkage',
  right_path = '/STATE/RCHRES_R001/HYDR/IVOL',
  link_type = 2
)
# this is a fudge, only valid for headwater segments
# till we get DSN 10 in place
json_rchres[['Runit']] = list(
  name = 'Runit', 
  object_class = 'Equation', 
  equation='IVOLin / drainage_area_sqmi'
)
# create equation holder for local trib inflow equations
trib_area_eqn = ''
Qtrib_eqn = ''
for (i in 1:nrow(bc_network)) {
  bc_trib = bc_network[i,]
  
  trib_name = paste0('nhd_', bc_trib['comid'])
  
  Q_name = paste0('Q_', trib_name)
  A_name = paste0('area_sqkm_', trib_name)
  
  thisQeqn = list(
    name=Q_name, 
    object_class = 'Equation', 
    equation=paste("Runit *", A_name, "* 0.386102")
  )
  thisAeqn = list(
    name=A_name, 
    object_class = 'Equation', 
    equation=paste(bc_trib$areasqkm,' * 1.0')
  )
  if (i == 1) {
    Qtrib_eqn = Q_name
    trib_area_eqn = A_name
  } else {
    Qtrib_eqn = paste(Qtrib_eqn, '+', Q_name)
    trib_area_eqn = paste(trib_area_eqn, '+', A_name)
  }
  Qtrib_eqn = paste(Qtrib_eqn, '+', Q_name)
  trib_area_eqn = paste(trib_area_eqn, '+', A_name)
  json_rchres[[Q_name]] = thisQeqn
  json_rchres[[A_name]] = thisAeqn
}
# Now add trib area and inflow equations (so execution order will)
json_rchres[['Qtrib']] = list(name = 'Qtrib', object_class = 'Equation', equation=Qtrib_eqn)
json_rchres[['trib_area_sqmi']] = list(
  name='trib_area_sqmi', 
  object_class = 'Equation', 
  equation=paste("0.386102 * (",trib_area_eqn,")")
)
# adding in a 0.8 factor to show manipulation is successful
json_rchres[['Qup']] = list(
  name = 'Qup', 
  object_class = 'Equation', 
  equation='IVOLin * (1.0 - (trib_area_sqmi / drainage_area_sqmi))'
)
json_rchres[['Qin']] = list(
  name = 'Qin', 
  object_class = 'Equation', 
  equation='Qup + Qtrib'
)
json_rchres[['HYDR']] = list(
  name = 'HYDR', 
  object_class = 'ModelObject'
)
json_rchres[['HYDR']][['IVOL']] = list(
  name = 'IVOL', 
  object_class = 'ModelLinkage',
  right_path = 'Qin'
)
json_out[['RCHRES_R001']] = json_rchres

jsonData <- toJSON(json_out)
write(jsonData, paste0("C:/usr/local/home/git/vahydro/R/modeling/nhd/nhd_simple_", nhd_out$comid, ".json"))

