options(scipen=999)
library('hydrotools')
library('zoo')
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)

sw_elid <- 353103 
runid = 201
swdat <- om_get_rundata(sw_elid, runid, site=omsite)
quantile(swdat$local_channel_Qin)

sw_stats <- om_quantile_table(
  swdat, 
  metrics = c(
    "local_channel_Qin",  "local_channel_Qout", 
    "impoundment_use_remain_mg", "lake_elev", "outflow_elev_cfs",
    "impoundment_Qin", "impoundment_Qout", "impoundment_release"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.9, 1.0),
  rdigits = 1)
kable(sw_stats,'markdown')
quantile(swdat$lake_elev)
