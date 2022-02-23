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

#runid <- 11
#runid <- 2011
#runid <- 4011
runid <- 6011

facdat <- om_get_rundata(fac_om_id, runid, site = omsite)
rsegdat <- om_get_rundata(rseg_om_id, runid, site = omsite)

facdat_df <- data.frame(facdat)
rsegdat_df <- data.frame(rsegdat)
################################################################################################
# FACILITY
# fac_qa <- sqldf("select year,month,day, wd_mgd, discharge_mgd, consumption
#                  from 'facdat_df' WHERE year = 1999 AND month = 1")
fac_qa_2011 <- sqldf("select year,month,day, wd_mgd, discharge_mgd, consumption, 
                 current_mgd,
                 gw_demand_mgd
                 from 'facdat_df'")

colnames(facdat_df)
quantile(facdat_df$gw_demand_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))

facdat_df$gw_sw_factor
facdat_df$unmet_demand_mgd
quantile(facdat_df$unmet_demand_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))

################################################################################################
# RIVER SEGMENT

colnames(rsegdat_df)
quantile(rsegdat_df$gw_demand_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))



# calibration comparison
# Wayside Park river segment & Glenvar Gage
wrelid <- 251491
datwr11 <- om_get_rundata(wrelid, 11, site = omsite)

usgs_salem <- dataRetrieval::readNWISdv('02054530','00060')
usgs_salem$month <- month(usgs_salem$Date)
om_flow_table(usgs_salem, 'X_00060_00003')
om_flow_table(datwr11, 'Qout')


usgs_roan <- dataRetrieval::readNWISdv('02055000','00060')
usgs_roan$month <- month(usgs_roan$Date)
om_flow_table(usgs_roan, 'X_00060_00003')


xcsam <- as.data.frame(
  datwr11[,c(
    "Qout",
    "wd_cumulative_mgd",
    "ps_cumulative_mgd",
    "wd_mgd",
    "ps_mgd")]
)