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
json_out[['trib_area_sqmi']] = list(name='trib_area_sqmi', object_class = 'Equation', equation='0')
json_out[['area_sqkm']] = nhd_out$totdasqkm
json_out[['area_sqmi']] = list(name = 'area_sqmi', object_class = 'Equation', equation="areasqkm * 0.386102")
# create equation holder for local trib inflow
json_out[['Qtrib']] = list(name = 'Qtrib', object_class = 'Equation', equation='0')
# make a short name copy of this for clarity
Qtrib_eqn = json_out[['Qtrib']]['equation']
trib_area_eqn = json_out[['trib_area_sqmi']]['equation']
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
  
  Qtrib_eqn = paste(Qtrib_eqn, '+', Q_name)
  trib_area_eqn = paste(trib_area_eqn, '+', A_name)
}
json_out[['Qtrib']]['equation'] = Qtrib_eqn
json_out[['area_sqmi']]['equation'] = paste("0.386102 * (",trib_area_eqn,")")

json_out[['Qup']] = list(
  name = 'Qup', 
  object_class = 'Equation', 
  equation='Qivol * (1.0 - (trib_area_sqmi / area_sqmi))'
)
json_out[['Qin']] = list(
  name = 'Qin', 
  object_class = 'Equation', 
  equation='Qup + Qtrib'
)
json_out[['HYDR']] = list(
  name = 'HYDR', 
  object_class = 'ModelObject'
)
json_out[['HYDR']][['IVOL']] = list(
  name = 'IVOL', 
  object_class = 'ModelLinkage',
  right_path = 'Qin'
)


jsonData <- toJSON(json_out)
write(jsonData, paste0(export_path,"nhd_simple_", nhd_out$comid, ".json"))

