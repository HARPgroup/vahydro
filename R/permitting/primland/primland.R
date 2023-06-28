library('hydrotools')
library('zoo')
library('knitr') # needed for kable()
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")

################################################################################################
# LOAD MODEL IDs:
rseg_om_id <- 252979 # Dan River headwater
fac_om_id <- 307284 # PRIMLAND RESORT:Dan River headwater
runid <- 400
################################################################################################

facdat <- om_get_rundata(fac_om_id, runid, site = omsite)
rsegdat <- om_get_rundata(rseg_om_id, runid, site = omsite)
mstart <- zoo::as.Date(as.POSIXct(min(index(rsegdat)),origin="1970-01-01"))
mend <- zoo::as.Date(as.POSIXct(max(index(rsegdat)),origin="1970-01-01"))

facdat_df <- data.frame(facdat)
rsegdat_df <- data.frame(rsegdat)

# sort(colnames(facdat_df))
#-------------------------------------------------------------------------
# gageid = "02071530"
# area_factor = 0.05/26.3
# historic <- dataRetrieval::readNWISdv(gageid,'00060')
# historic$X_00060_00003 <- historic$X_00060_00003 * area_factor
# gage_flows <- zoo(as.numeric(as.character( historic$X_00060_00003 )), order.by = historic$Date);
# gage_flows <- window(gage_flows, start = mstart, end = mend)
# gagedat_df <- data.frame(gage_flows)
#-------------------------------------------------------------------------
# metrics <- c("Qintake","Runit","Qbent_pre","Qbent_post","flowby","available_mgd","wd_mgd",
#                   "adj_demand_mgd","refill_pump_mgd","wd_net_mgd",
#                   "local_impoundment_Storage","local_impoundment_use_remain_mg",
#                   "Qnatural_below_OldDuck", "Qbelow_OldDuck", "unmet_demand_mgd")
# q_df <- om_quantile_table(metrics)
# kable(q_df, 'markdown')


# Pond4 <- om_quantile_table(c("local_impoundment_Storage","local_impoundment_use_remain_mg"))
# OldDuck <- om_quantile_table(c("Qdivert_Old","OldDuck_Qin","Qbelow_OldDuck","Qnatural_below_OldDuck",
#                                "available_mgd","wd_pond4_mgd","remain_demand_mgd","wd_OldDuck_mgd",
#                                "OldDuck_use_remain_mg","OldDuck_Qout"))

OldDuck <- om_quantile_table(facdat_df, metrics = c("DA_OldDuck","DA_below_OldDuck",
                                                    "Qdivert_Old","OldDuck_Inflow","Qbelow_OldDuck",
                                                    "flowby_below_OldDuck","Qnatural_below_OldDuck",
                                                    "vwp_demand_mgd","adj_demand_mgd","available_mgd",
                                                    "wd_pond4_mgd","wd_max_Pond4","remain_demand_mgd","wd_OldDuck_mgd","wd_max_OldDuck",
                                                    "OldDuck_use_remain_mg","OldDuck_Qout","unmet_demand_mgd",
                                                    "OldDuck_wd_enabled","wd_mgd"),
                             rdigits = 3)
kable(OldDuck,'markdown')
# sort(colnames(facdat_df))
# OldDuck_4012 <- OldDuck
# OldDuck_410 <- OldDuck
# 
# 
# OldDuck_4012
# OldDuck_410
# quantile(facdat_df$OldDuck_wd_enabled)

rsegdat_df$wd_mgd
################################################################################################
################################################################################################
# sort(colnames(rsegdat))
# om_quantile_table(rsegdat, metrics = c("Qout","ps_mgd"))

# unmet_demand_mgd =  base_demand_mgd - wd_pond4_mgd - wd_OldDuck_mgd
# 
# 
# mean(facdat_df$base_demand_mgd)
# mean(facdat_df$wd_pond4_mgd)
# mean(facdat_df$wd_OldDuck_mgd)
# mean(facdat_df$wd_pond4_mgd) + mean(facdat_df$wd_OldDuck_mgd)
# 
# max(facdat_df$base_demand_mgd)
# max(facdat_df$wd_pond4_mgd)
# max(facdat_df$wd_OldDuck_mgd)
# max(facdat_df$wd_pond4_mgd) + max(facdat_df$wd_OldDuck_mgd)
# 
# max(facdat_df$base_demand_mgd) - max(facdat_df$wd_pond4_mgd) - max(facdat_df$wd_OldDuck_mgd)
# 

# verify flowby is working appropriately:
qa <- sqldf("SELECT year,month,day,
                    base_demand_mgd,
                    wd_pond4_mgd,
                    wd_OldDuck_mgd,
                    Qbelow_OldDuck,
                    flowby_below_OldDuck,
                    OldDuck_wd_enabled
             FROM 'facdat_df'")


# check pond withdrawals exceeding permit limits:
qa_pond4 <- sqldf("SELECT year,month,day,
                    base_demand_mgd,
                    wd_pond4_mgd,
                    4.55/31 AS pond4_limit
             FROM 'facdat_df'
             WHERE wd_pond4_mgd > (4.55/31)
            ")

qa_OldDuck <- sqldf("SELECT year,month,day,
                    base_demand_mgd,
                    wd_OldDuck_mgd,
                    wd_max_OldDuck
             FROM 'facdat_df'
             WHERE wd_OldDuck_mgd > wd_max_OldDuck
            ")
# WHERE wd_OldDuck_mgd > ((4.5+0.75)/31)

################################################################################################
################################################################################################
