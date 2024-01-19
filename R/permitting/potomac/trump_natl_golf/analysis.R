options(scipen=999)
library('hydrotools')
library('zoo')
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)

tfid <- 351274 
hc_elid <- 326970 # 
ro_omid <- 213265 
runid = 601
tfdat <- om_get_rundata(tfid, runid, site=omsite)
quantile(tfdat$Runit)
quantile(tfdat$et_in)
quantile(tfdat$refill_pump_mgd)
quantile(tfdat$precip_in)
mean(tfdat$wd_river_pond_mgd)
mean(365.0 * tfdat$rc_runoff_cfs / 1.547)

tf_stats <- om_quantile_table(
  tfdat, 
  metrics = c(
    "Qriver", "local_impoundment_use_remain_mg","wd_mgd",'base_demand_mgd', 'unmet_demand_mgd',
    "rc_runoff_cfs", "river_course_pond_pct_use_remain","refill_pump_mgd",
    "river_course_pond_use_remain_mg",
    "river_course_pond_evap_mgd", "river_course_pond_precip_mgd", "river_course_pond_demand", "local_impoundment_demand"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.9, 1.0),
  rdigits = 3)
kable(tf_stats,'markdown')

tfdat[which(tfdat$Qriver < 815)]
quantile(tfdat$Qriver)
