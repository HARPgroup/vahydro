library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")


################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 210815
fac_om_id <- 351042
runid <- 601

gageid = "02036500"
################################################################################################


facdat <- om_get_rundata(fac_om_id, runid, site = omsite)
rsegdat <- om_get_rundata(rseg_om_id, runid, site = omsite)
mstart <- zoo::as.Date(as.POSIXct(min(index(rsegdat)),origin="1970-01-01"))
mend <- zoo::as.Date(as.POSIXct(max(index(rsegdat)),origin="1970-01-01"))


facdat_df <- data.frame(facdat)
rsegdat_df <- data.frame(rsegdat)

#-------------------------------------------------------------------------
area_factor = 1
historic <- dataRetrieval::readNWISdv(gageid,'00060')
historic$X_00060_00003 <- historic$X_00060_00003 * area_factor
gage_flows <- zoo(as.numeric(as.character( historic$X_00060_00003 )), order.by = historic$Date);
gage_flows <- window(gage_flows, start = mstart, end = mend)
gagedat_df <- data.frame(gage_flows)
usgs_02036500 <- quantile(gage_flows, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
#-------------------------------------------------------------------------


# om_flow_table(rsegdat_df, "wd_cumulative_mgd")
# hydrotools::om_cu_table(fac_report_info, pr_data, cu_post_var, cu_pre_var, cu_threshold, cu_decimals) 

Qintake = quantile(facdat_df$Qintake, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
mif_monthly = quantile(facdat_df$mif_monthly, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
available_mgd = quantile(facdat_df$available_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
wd_mgd = quantile(facdat_df$wd_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
adj_demand_mgd = quantile(facdat_df$adj_demand_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
refill_pump_mgd = quantile(facdat_df$refill_pump_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
wd_net_mgd = quantile(facdat_df$wd_net_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
local_impoundment_Storage = quantile(facdat_df$local_impoundment_Storage, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))


round(
  rbind(usgs_02036500,
    Qintake,
    mif_monthly,
    available_mgd,
    wd_mgd,
    adj_demand_mgd,
    refill_pump_mgd,
    wd_net_mgd,
    local_impoundment_Storage
  ),
  2
)


################################################################################################
SwiftCreekLake_om_id <- 212129
SwiftCreekLakedat <- om_get_rundata(SwiftCreekLake_om_id, runid, site = omsite)
SwiftCreekLakedat_df <- data.frame(SwiftCreekLakedat)
colnames(SwiftCreekLakedat_df)

lake_elev = quantile(SwiftCreekLakedat_df$lake_elev, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
Storage = quantile(SwiftCreekLakedat_df$Storage, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
pct_use_remain = quantile(SwiftCreekLakedat_df$pct_use_remain, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))

round(
  rbind(lake_elev,
        Storage,
        pct_use_remain
  ),
  2
)

maxcapacity = unique(SwiftCreekLakedat_df$maxcapacity)









