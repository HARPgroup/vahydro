# make a full basin model attributes
library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
library("rjson")


out_point = sf::st_sfc(sf::st_point(c(-77.639166666700, 38.351666666700)), crs = 4326)
nhd_out <- get_nhdplus(out_point)
# 5.358322
m_cat <- plot_nhdplus(list(nhd_out$comid))
nhd <- get_nhdplus(m_cat$basin)
trib_comids = get_UT(nhd, comid, distance = NULL)
nhd_df <- as.data.frame(st_drop_geometry(nhd))

length_ft = as.numeric(sqldf(paste("select sum(lengthkm) from nhd_df where streamorde =",nhd_out$streamorde ))) * 3280.84
da_sqmi = nhd_out$totdasqkm / 2.58999
cslope = as.numeric(sqldf(paste("select sum(slope * totdasqkm)/sum(totdasqkm) from nhd_df where streamorde =",nhd_out$streamorde )))

print(paste("length_ft, da_sqmi, cslope", length_ft, da_sqmi, cslope))