#----------------------------------------------
site <- "http://deq1.bse.vt.edu:81/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
library(hydrotools)
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
source(paste(github_location,'r-dh-ecohydro/Analysis/habitat','ifim_wua_change_plot.R',sep='/'))
source(paste(github_location,'r-dh-ecohydro/Analysis/habitat','hab_ts_functions.R',sep='/'))


# INPUTS #######################################################################################
#ifim_featureid <- 397295 #Potomac 8&9
#wshed_featureid <- 68346 #Potomac River Great Falls
#ifim_featureid <- 397301 # Front Royal
#wshed_featureid <- 68296 # SF Shenandoah River @ Front Royal
#ifim_featureid <- 397299 # Lynnwood IFIM
#wshed_featureid <- 68296 # SF Shenandoah River @ Lynnwood VA
ifim_featureid <- 397300 # Luray
wshed_featureid <- 68326 # SF Shenandoah River @ Luray

################################################################################################
# RETRIEVE RSEG MODEL
wshed_model <- om_get_model(base_url, wshed_featureid, 'dh_feature', 'vahydro-1.0', 'any')
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

# RETRIEVE USGS GAGE CODE
inputs = list(varkey = 'usgs_siteid',featureid = ifim_featureid,entity_type = 'dh_feature')
gageprop <- getProperty(inputs,site,prop)
gage <- as.character(gageprop$propcode)
# THIS FACTOR CAN BE USED IF USING GAGE FLOWS INSTEAD OF MODEL FLOWS
# gage_factor <- as.numeric(as.character(gageprop$propvalue))
################################################################################################
################################################################################################
################################################################################################
################################################################################################
################################################################################################
# RETRIEVE RUN 11 MODEL FLOW TIMESERIES (using elid aka om_element_connection)
model_flows_11 <- om_get_rundata(elid, 11)
model_flows_11$Qbaseline <- model_flows_11$Qout + (model_flows_11$wd_cumulative_mgd - model_flows_11$ps_cumulative_mgd ) * 1.547
ts1 <- as.data.frame(model_flows_11[,c('thisdate', 'Qout')])
ts1$thisdate <- as.character(as.Date(index(model_flows_11)))
names(ts1) <- c('Date', 'Flow')
ts1$Flow <- (as.numeric(ts1$Flow)*weighting_factor) #ADJUST MODEL FLOW USING WEIGHTING FACTOR

################################################################################################
# RETRIEVE RUN 13 MODEL FLOW TIMESERIES
model_flows_13 <- om_get_rundata(elid, 13)
model_flows_13$Qbaseline <- model_flows_13$Qout + (model_flows_13$wd_cumulative_mgd - model_flows_13$ps_cumulative_mgd ) * 1.547
ts2 <- as.data.frame(model_flows_13[,c('thisdate', 'Qout')])
ts2$thisdate <- as.character(as.Date(index(model_flows_13)))
names(ts2) <- c('Date', 'Flow')
ts2 <- ts2
ts2$Flow <- (as.numeric(ts2$Flow)*weighting_factor) #ADJUST MODEL FLOW USING WEIGHTING FACTOR

################################################################################################
# PLOT THE HABITAT CHANGE BETWEEN THE 2 MODEL RUNS USING Qout

# ALL FLOWS
# ifim_plot <- ifim_wua_change_plot(ts1, ts2, WUA.df, 1.0,"ifim_da_sqmi" = ifim_da_sqmi,
#                                     runid_a = "11",
#                                     metric_a = "Qout",
#                                     runid_b = "13",
#                                     metric_b = "Qout")
# ifim_plot + ylim(c(-50,50))
# ggsave(paste(export_path,'ifim_boxplot_11Qout_13Qout_ALL_',elid,'.png',sep=""), width = 7, height = 4)


# FLOWS BELOW THE 0.05 PERCENTILE
ifim_plot05 <- ifim_wua_change_plot(ts1, ts2, WUA.df, 0.05,"ifim_da_sqmi" = ifim_da_sqmi,
                                    runid_a = "11",
                                    metric_a = "Qout",
                                    runid_b = "13",
                                    metric_b = "Qout")
ifim_plot05 + ylim(c(-50,50))
ggsave(paste(export_path,'ifim_boxplot_11Qout_13Qout_05_',elid,'.png',sep=""), width = 7, height = 4)

################################################################################################
# PLOT THE HABITAT CHANGE BETWEEN Qbaseline AND Qout FOR THE SECOND MODEL RUN

runid = 11

ts2base <- as.data.frame(model_flows_13[,c('thisdate', 'Qbaseline')])
ts2base$thisdate <- as.character(as.Date(index(model_flows_13)))
names(ts2base) <- c('Date', 'Flow')

ts2base$Flow <- (as.numeric(ts2base$Flow)*weighting_factor)
ifim_plot05 <- ifim_wua_change_plot(ts2base, ts2, WUA.df, 0.05,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "13",metric_a = "Qbaseline",runid_b = "13",metric_b = "Qout")
ifim_plot05 + ylim(c(-50,50))
ggsave(paste(export_path,'ifim_boxplot_13QQbaseline_13Qout_05_',elid,'.png',sep=""), width = 7, height = 4)

ifim_plot10 <- ifim_wua_change_plot(ts2base, ts2, WUA.df, 0.1,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "13",metric_a = "Qbaseline",runid_b = "13",metric_b = "Qout")
ifim_plot10 + ylim(c(-50,50))
ggsave(paste(export_path,'ifim_boxplot_13QQbaseline_13Qout_10_',elid,'.png',sep=""), width = 7, height = 4)

ifim_plot20 <- ifim_wua_change_plot(ts2base, ts2, WUA.df, 0.2,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "13",metric_a = "Qbaseline",runid_b = "13",metric_b = "Qout")
ifim_plot20 + ylim(c(-50,50))
ggsave(paste(export_path,'ifim_boxplot_13QQbaseline_13Qout_20_',elid,'.png',sep=""), width = 7, height = 4)

################################################################################################



model_flows_17 <- om_get_rundata(elid, 17)
ts3 <- as.data.frame(model_flows_17[,c('thisdate', 'Qout')])
ts3$thisdate <- as.character(as.Date(index(model_flows_17)))
names(ts3) <- c('Date', 'Flow')
ts1cc_daterange <- sqldf("select * from ts1 where Date <= '2000-09-30' ")
ifim_plot10cc <- ifim_wua_change_plot(ts1cc_daterange, ts3, WUA.df, 0.1,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "11",metric_a = "Qout",runid_b = "17",metric_b = "Qout")
ifim_plot10cc + ylim(c(-50,50))
ggsave(paste(export_path,'ifim_boxplot_11Qout_17Qout_10_',elid,'.png',sep=""), width = 7, height = 4)

# do the how much percent decrease analysis (was the original for this )
runid = 11
tsrun <- om_get_rundata(elid, runid, site = omsite)
ts1 <- as.data.frame(tsrun[,c('thisdate', 'Qout')])
ts1$thisdate <- as.character(as.Date(index(tsrun)))
names(ts1) <- c('Date', 'Flow')
ts2 <- ts1
ts2$Flow <- 0.9 * ts1$Flow
ts3 <- ts1
ts3$Flow <- 0.8 * ts1$Flow
ts4 <- ts1
ts4$Flow <- 0.7 * ts1$Flow

# add a zero line for withdrawals below the observed threshold
wua_zero <- rbind(
  WUA.df[0,],
  c(0,0,0,0,0,0,0,0,0),
  WUA.df
)

ifim_plot10 <- ifim_wua_change_plot(ts1, ts2, wua_zero, 0.1,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "11",metric_a = "Qbaseline",runid_b = "11",metric_b = "Qout")
ifim_plot10 + ylim(c(-50,50))

ifim_plot20 <- ifim_wua_change_plot(ts1, ts3, wua_zero, 0.1,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "11",metric_a = "Qbaseline",runid_b = "11",metric_b = "Qout")
ifim_plot20 + ylim(c(-50,50))

ifim_plot30 <- ifim_wua_change_plot(ts1, ts4, wua_zero, 0.1,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "11",metric_a = "Qbaseline",runid_b = "11",metric_b = "Qout")
ifim_plot30 + ylim(c(-50,50))

ifim_plot1020 <- ifim_wua_change_plot(ts1, ts3, WUA.df, 0.1,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "11",metric_a = "Qbaseline",runid_b = "11",metric_b = "Qout")
ifim_plot1020 + ylim(c(-50,50))
ifim_plot1020

ifim_plot1020z <- ifim_wua_change_plot(ts1, ts3, wua_zero, 0.1,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "11",metric_a = "Qbaseline",runid_b = "11",metric_b = "Qout")
ifim_plot1020z + ylim(c(-50,50))
ifim_plot1020z

ifim_plot1030z <- ifim_wua_change_plot(ts1, ts4, wua_zero, 0.5,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "11",metric_a = "Qout",runid_b = "11",metric_b = "Qout")
ifim_plot1030z + ylim(c(-50,50))
ifim_plot1030z

ts18 <- om_get_rundata(elid, 18, site = omsite)
tsex <- as.data.frame(ts18[,c('thisdate', 'Qout')])
tsex$thisdate <- as.character(as.Date(index(ts18)))
names(tsex) <- c('Date', 'Flow')
ifim_plotexz100 <- ifim_wua_change_plot(ts1, tsex, wua_zero, 1.0,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "11",metric_a = "Qout",runid_b = "11",metric_b = "Qout")
ifim_plotexz100 + ylim(c(-50,50))
ifim_plotexz100
ifim_plotexz50 <- ifim_wua_change_plot(ts1, tsex, wua_zero, 0.5,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "11",metric_a = "Qout",runid_b = "11",metric_b = "Qout")
ifim_plotexz50 + ylim(c(-50,50))
ifim_plotexz50
ifim_plotexz10 <- ifim_wua_change_plot(ts1, tsex, wua_zero, 0.1,"ifim_da_sqmi" = ifim_da_sqmi,runid_a = "11",metric_a = "Qout",runid_b = "18",metric_b = "Qout")
ifim_plotexz10 + ylim(c(-50,50))
ifim_plotexz10


om_flow_table(tsrun, 'Qout')
om_flow_table(ts18, 'Qout')
pctile_data <- ifim_plotexz10$all_pctile_data
july_data <- sqldf("select * from pctile_data where month = 'Jul'")
sep_data <- sqldf("select * from pctile_data where month = 'Sep'")


# changes

df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_13', 'runid_17', 'runid_18'),
  'metric' = c('l90_Qout', 'l90_Qout','l90_Qout','l90_Qout'),
  'runlabel' = c('L90_2020', 'L90_2040', 'L90_dry', 'l90_Ex')
)
shen_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu/d.dh/entity-model-prop-level-export"
)

shen_data <- sqldf(
  "select a.*
   from shen_data as a
  where (
    hydrocode like '%PS4_6360_5840%'
    OR hydrocode like '%PS4_5840_5240%'
    OR hydrocode like '%PS5_5240_5200%'
  )
    order by L90_2020
  "
)



library('elfgen')
data <- elfgen::elfdata('02070005')
elfgen_output <- elfgen::elfgen(data,0.9)
# using xval = DA at IFIM site
# this gives the % of richness change
elfgen::richness_change(elfgen_output$stats,20, ifim_da_sqmi)
# using no xval, so gives the number of species change
elfgen::richness_change(elfgen_output$stats,20)
