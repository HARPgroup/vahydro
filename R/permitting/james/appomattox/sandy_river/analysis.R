library('hydrotools')
library('zoo')
library("IHA")
basepath='/var/www/R';
source("/var/www/R/config.R")


################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 352139 
fac_om_id <- 351166 
c_om_id <- 210939 # lake Chesdin impoundment
################################################################################################
################################################################################################

r_elid = 352139  # Sandy River (trib to Appomattox)
fac_elid = 351166  # Facility
#runid <- 11
#runid <- 2011
#runid <- 4011
#runid <- 6011
runid <- 400
runid = 600

rdat <- om_get_rundata(r_elid, runid, site = omsite)
pre_storm <- group4(rdat$local_channel_Qin)
post_storm <- group4(rdat$local_channel_Qout)

boxplot(rdat$impoundment_Qin ~ rdat$year)

quantile(rdat$impoundment_use_remain_mg)
quantile(rdat$release_cfs)
quantile(rdat$wd_mgd)
mean(rdat$impoundment_Qin)
mean(rdat$impoundment_Qout)
quantile(rdat$Qreach)
quantile(rdat$wd_cumulative_mgd)
facdat <- om_get_rundata(fac_elid, runid, site = omsite)
quantile(facdat$vwp_max_mgd)
quantile(facdat$wd_mgd)
quantile(facdat$flowby)
quantile(facdat$impoundment_use_remain_mg)
quantile(facdat$drought_status)

quantile(facdat$unmet_demand_mgd)

kable(om_flow_table(facdat, "refill_pump_mgd"))
kable(om_flow_table(facdat, "available_mgd"))
kable(om_flow_table(facdat, "flowby_current"))
quantile(facdat$local_impoundment_Qin)


om_flow_table(rdat, "impoundment_Qin", "month", 2)
om_flow_table(rdat, "impoundment_Qout", "month", 2)



