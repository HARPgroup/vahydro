library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")


################################################################################################
# LOAD MODEL IDs:
r_elid = 212957 # Tidal James JB0_7391_0000
fac_elid = 220401  # Kingsmill
#runid <- 11
#runid <- 2011
#runid <- 4011
#runid <- 6011
runid <- 401

rdat <- om_get_rundata(r_elid, runid, site = omsite)
quantile(rdat$wd_mgd)
quantile(rdat$Runit)
quantile(rdat$rejected_demand_pct)
quantile(rdat$Qlake)
quantile(rdat$Qreach)
quantile(rdat$wd_cumulative_mgd)
quantile(rdat$wd_upstream_mgd)
facdat <- om_get_rundata(fac_elid, runid, site = omsite)
quantile(facdat$vwp_demand_mgd)
quantile(facdat$available_mgd)
quantile(facdat$wd_mgd)
quantile(facdat$wd_net_mgd)
quantile(facdat$Runit)
quantile(facdat$local_impoundment_demand)
quantile(facdat$local_impoundment_Qin)
quantile(facdat$local_impoundment_Qout)

kable(om_flow_table(facdat, "refill_pump_mgd"))
kable(om_flow_table(facdat, "available_mgd"))
kable(om_flow_table(facdat, "flowby_current"))
quantile(facdat$local_impoundment_Qin)

