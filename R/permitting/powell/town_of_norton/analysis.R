basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library('knitr')
library("hydrotools")

library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
library("rjson")

#########################
#Town of Norton:
#Subdivide the watershed - Get the NHD area for Town of Norton

#For identifying stream-watershed shape/GIS:
# Town of Norton intake
plat_imp = 36.916388888900; plon_imp = -82.626666666700 

#Find the drainage area of the NHD segments at and above the reservoir. Note
#that this takes the entire NHD segment the coords fall in and all upstream.
#Create an sf object
out_point_imp = sf::st_sfc(sf::st_point(c(plon_imp, plat_imp)), crs = 4326)
#Get the NHD segemnt that this point falls in
nhd_out_imp <- memo_get_nhdplus(out_point_imp)
#Find the total DA in miles
dasqmi_imp <- 0.386102 * nhd_out_imp$totdasqkm
dasqmi_imp
#Plot the basin
map_imp <- plot_nhdplus((list(nhd_out_imp$comid)), zoom = 14)

#map_imp creates a basin object. We can now get all nhd plus segments associated
#with that basin
basin <- get_nhdplus(map_imp$basin)
#From here, we could area weight traits, compare between subsheds, etc.

#The volume weight stage of the dam:
((3215.9-3155) * 182 + (3287.5-3215) * 202) / (182+202)
((3218-3155) * 200 + (3295.5-3215) * 277) / (200+277)

