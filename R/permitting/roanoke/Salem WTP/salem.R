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

sh_elid = 328321 # Spring Hollow
shfac_elid = 351170 # Spring Hollow WTP
#runid <- 11
#runid <- 2011
#runid <- 4011
#runid <- 6011
runid <- 222

shdat <- om_get_rundata(sh_elid, runid, site = omsite)
quantile(shdat$refill_pump_mgd)
quantile(shdat$wd_mgd)
kable(om_flow_table(shdat, "refill_pump_mgd"))
kable(om_flow_table(shdat, "available_mgd"))
shfacdat <- om_get_rundata(shfac_elid, runid, site = omsite)
quantile(shfacdat$vwp_max_mgd)

facdat <- om_get_rundata(fac_om_id, runid, site = omsite)
rsegdat <- om_get_rundata(rseg_om_id, runid, site = omsite)
om_flow_table(rsegdat, "wd_cumulative_mgd")

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


quantile(facdat_df$Qnatural, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))

################################################################################################
colnames(facdat_df)
fac_qa_6011 <- sqldf("select year,month,day,base_demand_mgd,
                                             wd_mgd,
                                             unmet_demand_mgd,
                                             Qintake/1.547 AS Qintake_mgd,
                                             flowby/1.547 AS flowby_mgd,
                                             available_mgd
                 from facdat_df")


################################################################################################
################################################################################################
# GW
fac_qa_6011 <- sqldf("select year,month,day,base_demand_mgd,
                                             wd_mgd,
                                             unmet_demand_mgd,
                                             Qintake/1.547 AS Qintake_mgd,
                                             flowby/1.547 AS flowby_mgd,
                                             available_mgd,
                                             gw_demand_mgd,
                                             2.6 AS gw_capacity_mgd,
                                             2.6 - gw_demand_mgd AS gw_surplus_mgd,
                                          CASE WHEN (unmet_demand_mgd - (2.6 - gw_demand_mgd) < 1) THEN 0
                		                        ELSE unmet_demand_mgd - (2.6 - gw_demand_mgd)
                                          END AS final_unmet_demand_mgd
                     from facdat_df")

Unmet_Demand_MGY <- (sum(fac_qa_6011$unmet_demand_mgd)/length(fac_qa_6011$unmet_demand_mgd))*365
Final_Unmet_Demand_MGY <- (sum(fac_qa_6011$final_unmet_demand_mgd)/length(fac_qa_6011$final_unmet_demand_mgd))*365

unmet_days <- length(sqldf("SELECT * FROM fac_qa_6011 WHERE unmet_demand_mgd > 0")$unmet_demand_mgd)
final_unmet_days <- length(sqldf("SELECT * FROM fac_qa_6011 WHERE final_unmet_demand_mgd > 0")$final_unmet_demand_mgd)
################################################################################################
# RIVER SEGMENT

colnames(rsegdat_df)
quantile(rsegdat_df$gw_demand_mgd, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))

quantile(rsegdat_df$Runit*380, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
quantile(rsegdat_df$Qout, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))
quantile(rsegdat_df$Qup, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))

quantile(rsegdat_df$Qnatural, probs=c(0,0.1,0.25,0.5,0.75,0.9,1.0))

################################################################################################
#-----------------------------------------------------------------------

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


rmarkdown::render(
  '/usr/local/home/git/vahydro/R/examples/VWP_CIA_Summary.Rmd',
  output_file = '/usr/local/home/git/vahydro/R/permitting/Salem WTP/salem_te_v01.docx',
  params = list(
    doc_title = "VWP CIA Summary - Salem WTP",
    rseg.hydroid = 68327,
    fac.hydroid = 73112,
    runid.list = c("runid_4011","runid_600", "runid_222"),
    intake_stats_runid = 11,
    preferred_runid = "runid_222",
    upstream_rseg_ids=c(67839,68105,442254,68331),
    downstream_rseg_ids=c(68099,68376,68126),
    users_metric = "base_demand_mgy"
  )
)