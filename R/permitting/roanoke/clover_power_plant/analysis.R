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

elid = 323521 # facility
relid = 252551 # Beaverdam subshed/reservoir
runid=401

# 
runid = 401
hdata <- om_get_rundata(elid, runid, site=omsite)
wr_stats <- om_quantile_table(
  hdata, 
  metrics = c(
    "Qreach", "unmet_demand_mgd", "local_impoundment_use_remain_mg", "available_mgd", "refill_pump_mgd",
    "base_demand_mgd", "wd_mgd", "vwp_max_mgd", "vwp_max_mgy", "Qrandolph"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(wr_stats,'markdown')
hdata[1:5,c("Qreach", "local_impoundment_use_remain_mg", "available_mgd", "base_demand_mgd")]
quantile(hdata$unmet_demand_mgd, probs=c(0,0.25, 0.5, 0.75, 0.9, 0.95, 1.0), na.rm=TRUE)
quantile(hdata$wp_pre, na.rm=TRUE)
hdata[
  which(hdata$local_impoundment_use_remain_mg < hdata$base_demand_mgd),
  c("Qreach", "local_impoundment_use_remain_mg", "available_mgd", "base_demand_mgd", "refill_pump_mgd")
]
hydroTSM::fdc(hdata[,c("Qintake", "Qbypass")])


rdata <- om_get_rundata(relid, runid, site=omsite)
r_stats <- om_quantile_table(
  rdata, 
  metrics = c(
    "Qout", "wd_cumulative_mgd", "impoundment_Qin", "local_channel_Qout", "local_channel_Qin",
    "Runit", "Qlocal"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(r_stats,'markdown')

deets <- as.data.frame(hdata[,c(
  "year", "month", "day", "Qreach", "Qavail_divert", "Qturbine", "Qbypass", "flowby", "Qintake"
)])
