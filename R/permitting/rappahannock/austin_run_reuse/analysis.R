library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
library("rjson")

basepath='/var/www/R';
source("/var/www/R/config.R")

plat = 38.446360000000 
plon = -77.395470000000
# watershed outlet
out_point = sf::st_sfc(sf::st_point(c(plon, plat)), crs = 4326)
nhd_out <- get_nhdplus(out_point)
m_cat <- plot_nhdplus(list(nhd_out$comid))
