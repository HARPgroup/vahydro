library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")
# rmarkdown::render('C:/usr/local/home/git/vahydro/R/examples/VWP_CIA_Summary.Rmd', params = list( rseg.hydroid = 68113, fac.hydroid = 73024, runid.list = c("runid_400","runid_600"), intake_stats_runid = 11,upstream_rseg_ids=c(68113) ))
# river
rpid = 4711947
rhid = 68367
ielid = 211997 # Lake meade reservoir
# facility
fpid = 4824108
fhid = 67337
felid = 347378
# runoff (for checking)
roelid = 279207

datr11 <- om_get_rundata(relid, 11, site = omsite)
quantile(datr11$Runit)
datr401 <- om_get_rundata(relid, 401, site = omsite)
datr601 <- om_get_rundata(relid, 601, site = omsite)
datr801 <- om_get_rundata(relid, 801, site = omsite)
bccc <- as.data.frame(
  datbc602[,
           c("impoundment_use_remain_mg",
             "impoundment_days_remaining",
             "bc_release_cfs")
  ]
)


dati4 <- om_get_rundata(ielid, 401, site = omsite)
quantile(dati4$use_remain_mg)

datf4 <- om_get_rundata(felid, 401, site = omsite)
quantile(datf4$available_mgd)
quantile(datf4$wd_mgd)
quantile(datf4$base_demand_pstatus_mgd)

datf6 <- om_get_rundata(felid, 601, site = omsite)
quantile(datf6$available_mgd)
quantile(datf6$wd_mgd)
quantile(datf6$base_demand_pstatus_mgd)

