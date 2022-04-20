#----------------------------------------------
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
library(hydrotools)
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
source(paste("https://raw.githubusercontent.com/HARPgroup/r-dh-ecohydro",'master/Analysis/habitat','ifim_wua_change_plot.R',sep='/'))
source(paste("https://raw.githubusercontent.com/HARPgroup/r-dh-ecohydro",'master/Analysis/habitat','hab_ts_functions.R',sep='/'))
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/VAHydro-2.0/rest_functions.R") #Used during development
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/VAHydro-2.0/find_name.R") #Used during development
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R") #Used until fac_utils is packaged

gageid = '01638500'
historic <- dataRetrieval::readNWISdv(gageid,'00060')
historic$month <- month(historic$Date)
historic$year <- year(historic$Date)
gage_sum_historic <- om_flow_table(historic, "X_00060_00003")

# INPUTS #######################################################################################
ifim_featureid <- 397295 #Potomac 8&9
wshed_featureid <- 68346 #Potomac River Great Falls
pprunid <- 13 # will have this set to 6 once draft run is confirmed
pctile <- 0.1

################################################################################################
# RETRIEVE RSEG MODEL
ds <- RomDataSource$new(site, 'restws_admin')
ds$get_token(rest_pw)
wshed_model <- RomProperty$new(ds,list(featureid = wshed_featureid, entity_type = 'dh_feature', propcode = 'vahydro-1.0'), TRUE)
elid <- om_get_model_elementid(base_url, wshed_model$pid)

################################################################################################
# RETRIEVE IFIM SITE FEATURE
ifim_site <- getFeature(list(hydroid = ifim_featureid), token, site, feature)
ifim_site_name <- as.character(ifim_site$name)

################################################################################################
# RETRIEVE WUA TABLE
ifim_dataframe <- vahydro_prop_matrix(ifim_featureid, 'dh_feature','ifim_habitat_table')
WUA.df <- t(ifim_dataframe)
targets <- colnames(WUA.df)[-1]

################################################################################################
# DERIVE MULTIPLYING FACTOR FOR AREA-WEIGHTING FLOWS AT MODEL OUTLET TO IFIM SITE LOCATION

# RETRIEVE IFIM SITE DA SQMI
ifim_da_sqmi <- getProperty(list(varkey = 'nhdp_drainage_sqmi',featureid = ifim_featureid,entity_type = 'dh_feature'),site,prop)
ifim_da_sqmi <- as.numeric(ifim_da_sqmi$propvalue)
# RETRIEVE RSEG DA SQMI
rseg_da_sqmi <- getProperty(list(varkey = 'wshed_drainage_area_sqmi',featureid = wshed_featureid,entity_type = 'dh_feature'),site,prop)
rseg_da_sqmi <- as.numeric(rseg_da_sqmi$propvalue)

weighting_factor <- ifim_da_sqmi/rseg_da_sqmi
if (weighting_factor == 0) {
  weighting_factor = 1.0
  ifim_da_sqmi <- rseg_da_sqmi
}

################################################################################################
# RETRIEVE RUN 600 MODEL FLOW TIMESERIES, Full PErmitted + Proposed
model_flows_6 <- om_get_rundata(elid, pprunid, omsite)
model_flows_6$Qbaseline <- model_flows_6$Qout + (model_flows_6$wd_cumulative_mgd - model_flows_6$ps_cumulative_mgd ) * 1.547
ts3 <- as.data.frame(model_flows_6[,c('thisdate', 'Qout')])
ts3$thisdate <- as.character(as.Date(index(model_flows_6)))
names(ts3) <- c('Date', 'Flow')
ts3 <- ts3
ts3$Flow <- (as.numeric(ts3$Flow)*weighting_factor) #ADJUST MODEL FLOW USING WEIGHTING FACTOR

ts3base <- as.data.frame(model_flows_6[,c('thisdate', 'Qbaseline')])
ts3base$thisdate <- as.character(as.Date(index(model_flows_6)))
names(ts3base) <- c('Date', 'Flow')
ts3base$Flow <- (as.numeric(ts3base$Flow)*weighting_factor)


# Plot the changes for the 20% since it is not a short run
ifim_plot6_20 <- ifim_wua_change_plot(ts3base, ts3, WUA.df, pctile,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "6",metric_a = "Qbaseline",runid_b = "6",metric_b = "Qout")
ifim_plot6_20 +
  labs(title = "Habitat Change, Full Permitted + Proposed") +
  ylim(c(-50,50))
# TBD: this could be part of the analysis script since it could produce a nicely formatted summary
#      that would be returned in the single ggplot object without penalty
ifim_plot6_20$data$pctchg <- round(ifim_plot6_20$data$pctchg, 2)
ifim_sumdata_6 <- xtabs(pctchg ~ metric + flow, data = ifim_plot6_20$data)
ifim_mat <- as.data.frame.matrix(ifim_sumdata_6)
ifim_mat <- cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
ifim_plot6_20$data.formatted <-  cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
ifim_plot6_20$data.formatted
names(ifim_plot6_20$data.formatted)
# Note: must manually edit this to add the "Species" column label.
write.table(
  ifim_plot6_20$data.formatted,
  file = paste(export_path,'ifim_table_6Qbaseline_6Qout_20_',elid,'.csv',sep=""),
  sep = ","
)

ggsave(paste(export_path,'ifim_boxplot_6Qbaseline_6Qout_20_',elid,'.png',sep=""), width = 7, height = 4)




# Plot the changes for the 20% since it is not a short run
ifim_plot6_20 <- ifim_wua_change_plot(ts3base, ts3, WUA.df, 0.05,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "6",metric_a = "Qbaseline",runid_b = "6",metric_b = "Qout")
ifim_plot6_20 +
  labs(title = "Habitat Change, Full Permitted + Proposed") +
  ylim(c(-50,50))
# TBD: this could be part of the analysis script since it could produce a nicely formatted summary
#      that would be returned in the single ggplot object without penalty
ifim_plot6_20$data$pctchg <- round(ifim_plot6_20$data$pctchg, 2)
ifim_sumdata_6 <- xtabs(pctchg ~ metric + flow, data = ifim_plot6_20$data)
ifim_mat <- as.data.frame.matrix(ifim_sumdata_6)
ifim_mat <- cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
ifim_plot6_20$data.formatted <-  cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
tbls5pct <- as.data.frame(ifim_plot6_20$data.formatted)
names(ifim_plot6_20$data.formatted)
# Note: must manually edit this to add the "Species" column label.
write.table(
  ifim_plot6_20$data.formatted,
  file = paste(export_path,'ifim_boxplot_6Qbaseline_6Qout_05_',elid,'.csv',sep=""),
  sep = ","
)

ggsave(paste(export_path,'ifim_boxplot_6Qbaseline_6Qout_05_',elid,'.png',sep=""), width = 7, height = 4)





# load PoR time series from Gage and ICPRB
# compare PoR gage time series with
# monthly mean flows from ICPRB

# WUA time series
wua_ts1 <- wua.at.q_fxn(ts3,WUA.df)
#wua_ts1 <- wua.at.q_fxn(ts3)
wua_ts1 <- data.frame(ts3,wua_ts1)
wua_ts1$month <- month(wua_ts1$Date)
wua_ts1$year <- year(wua_ts1$Date)
wua_ts1$month <- month(wua_ts1$Date)

usgs1930 <- sqldf(
 "
  select year, month, avg(X_00060_00003)
  from historic
  where year = 1930
  group by year, month
"
)
