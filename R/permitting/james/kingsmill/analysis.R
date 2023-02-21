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
runid <- 601

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



# test CU
pr_data <- as.data.frame(facdat[,c('month','local_impoundment_Qin', 'local_impoundment_Qout', 'local_impoundment_release','wd_mgd')])
cu_pre_var <- "local_impoundment_Qin"
cu_post_var <- "local_impoundment_Qout"
pr_data$cu_daily <- 100.0 * (
  (pr_data[,cu_post_var] - pr_data[,cu_pre_var]) / pr_data[,cu_pre_var]
)
quantile(pr_data$cu_daily, na.rm=TRUE)

qi_table = om_flow_table(pr_data, 'local_impoundment_Qin', 'month', 3)
qo_table = om_flow_table(pr_data, 'local_impoundment_Qout', 'month', 3)
cu_table = qi_table
cu_table[,2:ncol(cu_table)] <- (qo_table[,2:ncol(qo_table)] - qi_table[,2:ncol(qi_table)]) / qi_table[,2:ncol(qi_table)]

rdat$Qbaseline <- rdat$Qout + (rdat$wd_cumulative_mgd - rdat$ps_cumulative_mgd) * 1.547
rdat$cu_daily <- 100.0 * ( rdat$Qout - rdat$Qbaseline ) / rdat$Qbaseline 
quantile(rdat$cu_daily)

