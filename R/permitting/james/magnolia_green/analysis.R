library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")


################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 249169
fac_om_id <- 306768
################################################################################################
################################################################################################

r_elid = 210815 # Swift Creek
fac_elid = 351042 # Magnolia Green
#runid <- 11
#runid <- 2011
#runid <- 4011
#runid <- 6011
runid <- 401

rdat <- om_get_rundata(r_elid, runid, site = omsite)
quantile(rdat$wd_mgd)
quantile(rdat$Qlake)
quantile(rdat$Qreach)
quantile(rdat$wd_cumulative_mgd)
facdat <- om_get_rundata(fac_elid, runid, site = omsite)
quantile(facdat$vwp_max_mgd)
quantile(facdat$flowby)

kable(om_flow_table(facdat, "refill_pump_mgd"))
kable(om_flow_table(facdat, "available_mgd"))
kable(om_flow_table(facdat, "flowby_current"))
quantile(facdat$local_impoundment_Qin)

