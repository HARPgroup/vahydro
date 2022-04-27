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
wua_gf <- t(ifim_dataframe)
targets <- colnames(wua_gf)[-1]

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
ifim_plot6_20 <- ifim_wua_change_plot(ts3base, ts3, wua_gf, pctile,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "6",metric_a = "Qbaseline",runid_b = "6",metric_b = "Qout")
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
ifim_plot6_20 <- ifim_wua_change_plot(ts3base, ts3, wua_gf, 0.05,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "6",metric_a = "Qbaseline",runid_b = "6",metric_b = "Qout")
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
icprb_monthly_lf <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/lfalls_nat_monthly_data.csv")
icprb_monthly_prod <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/wma_production.csv")
icprb_monthly_prod$month <- month(as.Date(icprb_monthly_prod$thisdate,format="%m/%d/%Y"))
icprb_monthly_prod$year <- year(as.Date(icprb_monthly_prod$thisdate,format="%m/%d/%Y"))

# monthly mean flows from ICPRB
da_por <- 9651.0 # https://waterdata.usgs.gov/nwis/uv?site_no=01638500
da_gf <- 11549.4 # d.dh/admin/content/dh_features/manage/68346/dh_properties
da_lf <- 11586.6 # d.dh/admin/content/dh_features/manage/68363/dh_properties

nat_gf <- historic[c("Date", "X_00060_00003", "year", "month")]
colnames(nat_gf) <- c('Date', 'Flow', "year", "month")
nat_gf$Flow <- (da_gf / da_por) * nat_gf$Flow

icprb_prod_max <- sqldf(
  "
   select month,
     max(wssc_pot) as wssc_pot,
     max(wa_gf) as  wa_gf,
     max(wa_lf) as wa_lf,
     max(fw_pot) as fw_pot,
     max(rville) as rville,
     max(up_cu) as up_cu
   from icprb_monthly_prod where year >= 2015
   group by month
  "
)

alt_gf <- sqldf(
  "
   select a.Date, a.year, a.month, (a.Flow - 1.547 * (b.wssc_pot + b.wa_gf)) as Flow
   from nat_gf as a
   left outer join icprb_prod_max as b
   on (
     a.month = b.month
   )
  "
)

# now calc wua separately so we can look at a single species
wua_nat_gf <- wua.at.q_fxn(nat_gf[c("Date", "Flow")],wua_gf)
wua_nat_gf$Date <- nat_gf$Date
wua_nat_gf$Flow <- nat_gf$Flow
wua_alt_gf <- wua.at.q_fxn(alt_gf[c("Date", "Flow")],wua_gf)
wua_alt_gf$Date <- alt_gf$Date
wua_alt_gf$Flow <- alt_gf$Flow

# just look at the box plot
ifim_icprb_maxwd_gf <- ifim_wua_change_plot(
  nat_gf[c('Date', 'Flow')],
  alt_gf[c('Date', 'Flow')],
  wua_gf, 0.1,
  "ifim_da_sqmi" = ifim_da_sqmi,
  runid_a = "6",
  metric_a = "Qbaseline",
  runid_b = "6",metric_b = "Qout"
)
ifim_icprb_maxwd_gf +
  labs(title = "Habitat Change, ICPRB Max Demand Great Falls") +
  ylim(c(-50,50))

ifim_icprb_maxwd_gf$data$pctchg <- round(ifim_plot6_20$data$pctchg, 2)
ifim_icprb_maxwd_gf$data[is.na(ifim_icprb_maxwd_gf$data$pctchg),]$pctchg <- 0.0
ifim_sumdata_all <- xtabs(pctchg ~ metric + flow, data = ifim_icprb_maxwd_gf$data)
ifim_mat <- as.data.frame.matrix(ifim_sumdata_all)
ifim_mat <- cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
ifim_icprb_maxwd_gf$data.formatted <-  cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
tbls5pct <- as.data.frame(ifim_icprb_maxwd_gf$data.formatted)

# Note: must manually edit this to add the "Species" column label.
write.table(
  ifim_icprb_maxwd_gf$data.formatted,
  file = paste(export_path,'ifim_great_falls_icprb_all',elid,'.csv',sep=""),
  sep = ","
)
# Box Plot for 2002
nat_gf_2002 <- sqldf("select * from nat_gf where year = 2002")
alt_gf_2002 <- sqldf("select * from alt_gf where year = 2002")

# just look at the box plot
ifim_icprb_maxwd_gf <- ifim_wua_change_plot(
  nat_gf_2002[c('Date', 'Flow')],
  alt_gf_2002[c('Date', 'Flow')],
  wua_gf, 1.0,
  "ifim_da_sqmi" = ifim_da_sqmi,
  runid_a = "6",
  metric_a = "Qbaseline",
  runid_b = "6",metric_b = "Qout"
)
ifim_icprb_maxwd_gf +
  labs(title = "Habitat Change, ICPRB Max Demand Great Falls, 2002 only.") +
  ylim(c(-50,50))

# Box Plot for 1931
nat_gf_1930 <- sqldf("select * from nat_gf where year = 1930")
alt_gf_1930 <- sqldf("select * from alt_gf where year = 1930")
plot(nat_gf_1930$Flow ~ nat_gf_1930$Date, col='blue', ylim=c(0,5000))
points(alt_gf_1930$Flow ~ nat_gf_1930$Date, col='red')

# just look at the box plot
ifim_icprb_maxwd_gf_1930 <- ifim_wua_change_plot(
  nat_gf_1930[c('Date', 'Flow')],
  alt_gf_1930[c('Date', 'Flow')],
  wua_gf, 1.0,
  "ifim_da_sqmi" = ifim_da_sqmi,
  runid_a = "6",
  metric_a = "Qbaseline",
  runid_b = "6",metric_b = "Qout"
)
ifim_icprb_maxwd_gf_1930 +
  labs(title = "Habitat Change, ICPRB Max Demand Great Falls, 1930 only.") +
  ylim(c(-50,50))

ifim_icprb_maxwd_gf_1930$data$pctchg <- round(ifim_plot6_20$data$pctchg, 2)
ifim_icprb_maxwd_gf_1930$data[is.na(ifim_icprb_maxwd_gf_1930$data$pctchg),]$pctchg <- 0.0
ifim_sumdata_1930 <- xtabs(pctchg ~ metric + flow, data = ifim_icprb_maxwd_gf_1930$data)
ifim_mat <- as.data.frame.matrix(ifim_sumdata_1930)
ifim_mat <- cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
ifim_icprb_maxwd_gf_1930$data.formatted <-  cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
tbls5pct <- as.data.frame(ifim_icprb_maxwd_gf_1930$data.formatted)

# WUA time series - flow ts should be 2 columns: Date, Flow
wua_ts1 <- wua.at.q_fxn(ts3,wua_gf)
#wua_ts1 <- wua.at.q_fxn(ts3)
wua_ts1 <- data.frame(ts3,wua_ts1)
wua_ts1$month <- month(wua_ts1$Date)
wua_ts1$year <- year(wua_ts1$Date)
wua_ts1$month <- month(wua_ts1$Date)

usgs_monthly <- sqldf(
 "
  select year, month, avg(X_00060_00003) as usgs_por
  from historic
  group by year, month
"
)


sqldf(
  "
   select a.month, avg(usgs_por) as usgs_por,
     avg(b.lfalls_nat) as icprb_lfalls,
     avg(b.lfalls_nat)/avg(usgs_por) as da_fact
   from usgs_monthly as a
   left outer join icprb_monthly_lf as b
   on (
     a.year = b.cyear
     and a.month = b.month
   )
   where a.year = 1930
   group by a.month
   order by a.month
  "
)
