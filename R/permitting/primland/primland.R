library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")


################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 252979 # Dan River headwater
fac_om_id <- 307284 # PRIMLAND RESORT:Dan River headwater

runid <- 401

gageid = "02071530"
################################################################################################


facdat <- om_get_rundata(fac_om_id, runid, site = omsite)
rsegdat <- om_get_rundata(rseg_om_id, runid, site = omsite)
mstart <- zoo::as.Date(as.POSIXct(min(index(rsegdat)),origin="1970-01-01"))
mend <- zoo::as.Date(as.POSIXct(max(index(rsegdat)),origin="1970-01-01"))

facdat_df <- data.frame(facdat)
rsegdat_df <- data.frame(rsegdat)

sort(colnames(facdat_df))
#-------------------------------------------------------------------------
area_factor = 0.05/26.3
historic <- dataRetrieval::readNWISdv(gageid,'00060')
historic$X_00060_00003 <- historic$X_00060_00003 * area_factor
gage_flows <- zoo(as.numeric(as.character( historic$X_00060_00003 )), order.by = historic$Date);
gage_flows <- window(gage_flows, start = mstart, end = mend)
gagedat_df <- data.frame(gage_flows)
#-------------------------------------------------------------------------


# om_flow_table(rsegdat_df, "wd_cumulative_mgd")
# hydrotools::om_cu_table(fac_report_info, pr_data, cu_post_var, cu_pre_var, cu_threshold, cu_decimals) 
probs_vector = c(0,0.1,0.25,0.5,0.75,0.9,1.0)
# usgs_gage = quantile(gage_flows, probs=probs_vector)
usgs_gage_at_intake = quantile(gage_flows, probs=probs_vector)

# Qriver_up = quantile(facdat_df$Qriver_up, probs=probs_vector)
# Qintake_new = quantile((facdat_df$Qriver_up * 57.1/34.3), probs=probs_vector)
Qintake = quantile(facdat_df$Qintake, probs=probs_vector)
Qbent_pre = quantile(facdat_df$Qbent_pre, probs=probs_vector)
Qbent_post = quantile(facdat_df$Qbent_post, probs=probs_vector)


# Q90 = quantile(facdat_df$Q90, probs=probs_vector)
# mif_monthly = quantile(facdat_df$mif_monthly, probs=probs_vector)
flowby = quantile(facdat_df$flowby, probs=probs_vector)
available_mgd = quantile(facdat_df$available_mgd, probs=probs_vector)
wd_mgd = quantile(facdat_df$wd_mgd, probs=probs_vector)
adj_demand_mgd = quantile(facdat_df$adj_demand_mgd, probs=probs_vector)
refill_pump_mgd = quantile(facdat_df$refill_pump_mgd, probs=probs_vector)
refill_available = quantile(facdat_df$refill_available, probs=probs_vector)
wd_net_mgd = quantile(facdat_df$wd_net_mgd, probs=probs_vector)
local_impoundment_Storage = quantile(facdat_df$local_impoundment_Storage, probs=probs_vector)
local_impoundment_use_remain_mg = quantile(facdat_df$local_impoundment_use_remain_mg, probs=probs_vector)



stats = round(
  rbind(usgs_gage_at_intake,
    Qintake,
    Qbent_pre,
    Qbent_post,
    flowby,
    available_mgd,
    wd_mgd,
    adj_demand_mgd,
    refill_pump_mgd,
    refill_available,
    wd_net_mgd,
    local_impoundment_Storage,
    local_impoundment_use_remain_mg
  ),
  2
)


sort(colnames(facdat_df))

library('knitr')
kable(stats, 'markdown')
################################################################################################
# qa <- sqldf("SELECT year,month,day,
#             local_impoundment_max_usable,
#             local_impoundment_demand,
#             local_impoundment_demand_met_mgd,
#             local_impoundment_Storage,
#             local_impoundment_use_remain_mg,
#             local_impoundment_Qin,
#             local_impoundment_Qout,
#             local_impoundment_refill_full_mgd
#             FROM facdat_df")
# 
# qa <- sqldf("SELECT year,month,day,
#             Qintake,
#             available_mgd,
#             refill_pump_mgd,
#             flowby,
#             unmet_demand_mgd
#             FROM facdat_df")

################################################################################################
################################################################################################
