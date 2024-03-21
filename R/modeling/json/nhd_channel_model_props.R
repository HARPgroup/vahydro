# make a full basin model attributes
library(nhdplusTools)
library(memoise)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
library("rjson")
basepath='/var/www/R'
source('/var/www/R/config.R')

# Establish memoise function
#unlink(dir, recursive = TRUE, force = TRUE)

# Get arguments (or supply defaults)
argst <- commandArgs(trailingOnly=T)
if (length(argst) == 1) {
  comid = as.integer(argst[1])
  message(paste("Looking for info on comid", comid))
  nhd_out <- get_nhdplus(comid=comid)
} else {
  if (length(argst) > 1) {
    plat <- as.numeric(argst[1])
    plon <- as.numeric(argst[2])
  } else {
    cat("Outlet latitude:")
    plat = readLines("stdin",n=1)
    plat = as.numeric(plat)
    cat("Outlet longitude:")
    plon = readLines("stdin",n=1)
    plon = as.numeric(plon)
  }
  message(paste("Trying to obtain NHD info for location", plat, plon))
  out_point = sf::st_sfc(sf::st_point(c(plon, plat)), crs = 4326)
  nhd_out <- memo_get_nhdplus(out_point)
  # handle timeout in memo function
  if (is.null(nhd_out)) {
    nhd_out <- get_nhdplus(out_point)
  }
  message(paste("NHD+ outlet: ", nhd_out$comid))
  # 5.358322
  
}
m_cat <- memo_plot_nhdplus(list(nhd_out$comid))
nhd <- memo_get_nhdplus(m_cat$basin)
trib_comids = memo_get_UT(nhd, nhd_out$comid, distance = NULL)
nhd_df <- as.data.frame(st_drop_geometry(nhd))

length_ft = as.numeric(sqldf(paste("select sum(lengthkm) from nhd_df where streamorde =",nhd_out$streamorde ))) * 3280.84
length_mainstem_ft = as.numeric(sqldf(paste0("select sum(lengthkm) from nhd_df where gnis_name = '",nhd_out$gnis_name, "'" ))) * 3280.84

da_sqmi = nhd_out$totdasqkm / 2.58999
cslope = as.numeric(sqldf(paste("select sum(slope * totdasqkm)/sum(totdasqkm) from nhd_df where slope >= 0 and streamorde =",nhd_out$streamorde )))

print(paste("length_ft, da_sqmi, cslope", length_ft, da_sqmi, cslope))
print(paste("Length of mainstem by gnis_name = ", length_mainstem_ft, "ft (compare to stream order method", length_ft,"ft)"))
