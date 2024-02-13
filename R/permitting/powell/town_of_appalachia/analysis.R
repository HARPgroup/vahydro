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

plat_bb = 36.901388888889; plon_bb = -82.754166666667 # Ben's Branch downstream of impoundment
plat_imp = 36.9022222222; plon_imp = -82.7525 # Impoundment intake
plat = 36.90784; plon = -82.76888 # Powell River intake

# Entuire drainage above Powell confluence
out_point_bb = sf::st_sfc(sf::st_point(c(plon_bb, plat_bb)), crs = 4326)
nhd_out_bb <- memo_get_nhdplus(out_point_bb)
dasqmi_bb <- 0.386102 * nhd_out_bb$totdasqkm
dasqmi_bb
map_bb <- plot_nhdplus((list(nhd_out_bb$comid)), zoom = 14)
nhd_out_bb$comid

# DA Above dam
out_point_imp = sf::st_sfc(sf::st_point(c(plon_imp, plat_imp)), crs = 4326)
nhd_out_imp <- memo_get_nhdplus(out_point_imp)
dasqmi_imp <- 0.386102 * nhd_out_imp$totdasqkm
dasqmi_imp
map_imp <- plot_nhdplus((list(nhd_out_imp$comid)), zoom = 14)
dasqmi_imp / dasqmi_bb

bb_all <- memo_get_nhdplus(map_bb$basin)
map_bb <- plot_nhdplus((list(nhd_out_bb$comid)), zoom = 14)
plot_nhdplus(list(map_bb$flowline$COMID))
wb = nhdplusTools::get_waterbodies(id = nhdplus_id)
wb_wkt = wellknown::sf_convert(wb$geometry)
plot(wb$geometry)
bb_network <- memo_get_UT(nhd_out_bb, nhd_out_bb$comid, distance = NULL)

elid = 353105 # Town of A reservoir
relid = 247367 # Powell River
felid = 351742 # Town of A facility
runid=401
# 
hdata <- om_get_rundata(elid, runid, site=omsite)
wr_stats <- om_quantile_table(
  hdata, 
  metrics = c(
    "Qreach", "release_cfs", "wd_child_mgd", "impoundment_Qin", "ps_refill_pump_mgd"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(wr_stats,'markdown')
hdata[1:5,c("Qreach", "Qintake", "reach_area_sqmi", "intake_drainage_area")]
quantile(hdata$wp_bypass, probs=c(0,0.25, 0.5, 0.75, 0.9, 0.95, 1.0), na.rm=TRUE)
quantile(hdata$wp_pre, na.rm=TRUE)

hydroTSM::fdc(hdata[,c("Qintake", "Qbypass")])


rdata <- om_get_rundata(relid, runid, site=omsite)
r_stats <- om_quantile_table(
  rdata, 
  metrics = c(
    "Qout", "wd_cumulative_mgd", "Qup", "ps_cumulative_mgd"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(r_stats,'markdown')

deets <- as.data.frame(hdata[,c(
  "year", "month", "day", "Qreach", "Qavail_divert", "Qturbine", "Qbypass", "flowby", "Qintake"
)])

# facility
fdata <- om_get_rundata(felid, runid, site=omsite)
f_stats <- om_quantile_table(
  fdata, 
  metrics = c(
    "release", "flowby", "lake_elev", "Qnextdown", "Qintake"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(f_stats,'markdown')

deets <- as.data.frame(mdata[,c(
  "year", "month", "day", "Qin", "Qout", "target", "flowby", "flowby_cov", "min_release", "release"
)])

