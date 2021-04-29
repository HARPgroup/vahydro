library(pander);
library(httr);
library(hydroTSM);
library(zoo);
library(hydrotools);
library(plotly);
# save_directory should be set in config.local.private which gets loaded below in config.R
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
omsite = site

# Load Libraries
basepath='/var/www/R';
source('/var/www/R/config.R');
options(timeout=1200); # set timeout to twice default level to avoid abort due to high traffic

################################################################################################
# USER INPUTS
################################################################################################
rseg.elid = 352078     #Riverseg Model: South Fork Powell River - Big Cherry Reservoir
fac.elid = 247415      #Facility:Riverseg Model: BIG STONE GAP WTP:Powell River

rseg.pid = 5831933
fac.pid = 4826467 

rseg.hydroid = 462757
fac.hydroid = 72672

fac.metric.list <- c('unmet1_mgd','unmet7_mgd','unmet30_mgd','unmet90_mgd','wd_mgd','ps_mgd')
rseg.metric.list <- c('remaining_days_p0','remaining_days_p10','remaining_days_p50','l30_Qout',
                      'l90_Qout','consumptive_use_frac','wd_cumulative_mgd','ps_cumulative_mgd','Qbaseline','Qout')
################################################################################################


################################################################################################
# RETRIEVE FAC:RSEG MODEL STATS
################################################################################################
fac.metrics.401 <- data.frame('model_version' = c('vahydro-1.0'),'runid' = c('runid_401'),'runlabel' = fac.metric.list,'metric' = fac.metric.list)
fac_summary.401 <- om_vahydro_metric_grid(metric, 'bundle' = 'facility','ftype' = 'all',fac.metrics.401)
fac_summary.401 <- sqldf(paste("SELECT 401 AS runid, '0.5 MGD' AS flowby, * FROM 'fac_summary.401' WHERE featureid = ",fac.hydroid,sep=""))

fac.metrics.6011 <- data.frame('model_version' = c('vahydro-1.0'),'runid' = c('runid_6011'),'runlabel' = fac.metric.list,'metric' = fac.metric.list)
fac_summary.6011 <- om_vahydro_metric_grid(metric, 'bundle' = 'facility','ftype' = 'all',fac.metrics.6011)
fac_summary.6011 <- sqldf(paste("SELECT 6011 AS runid, '90%' AS flowby, * FROM 'fac_summary.6011' WHERE featureid = ",fac.hydroid,sep=""))

fac.metrics.6012 <- data.frame('model_version' = c('vahydro-1.0'),'runid' = c('runid_6012'),'runlabel' = fac.metric.list,'metric' = fac.metric.list)
fac_summary.6012 <- om_vahydro_metric_grid(metric, 'bundle' = 'facility','ftype' = 'all',fac.metrics.6012)
fac_summary.6012 <- sqldf(paste("SELECT 6012 AS runid, '40%' AS flowby, * FROM 'fac_summary.6012' WHERE featureid = ",fac.hydroid,sep=""))

fac_summary <- rbind(fac_summary.401,fac_summary.6011,fac_summary.6012)
################################################################################################
################################################################################################
################################################################################################


################################################################################################
# RETRIEVE RSEG MODEL STATS
################################################################################################
rseg.info.401 <- fn_get_runfile_info(rseg.elid,401)

metrics.401 <- data.frame('model_version' = c('vahydro-1.0'),'runid' = c('runid_401'),'runlabel' = rseg.metric.list,'metric' = rseg.metric.list)
rseg_summary.401 <- om_vahydro_metric_grid(metric, metrics.401)
rseg_summary.401 <- sqldf(paste("SELECT * FROM 'rseg_summary.401' WHERE featureid = ",rseg.hydroid,sep=""))
rseg_summary.401 <- cbind("runid" = 401,
                          "run_date" = rseg.info.401$run_date,
                          "starttime" = str_remove(rseg.info.401$starttime," 00:00:00"),
                          "endtime" = str_remove(rseg.info.401$endtime," 00:00:00"),
                          rseg_summary.401)
#-----------------------------------------------------------------------------------------------
rseg.info.6011 <- fn_get_runfile_info(rseg.elid,6011)

metrics.6011 <- data.frame('model_version' = c('vahydro-1.0'),'runid' = c('runid_6011'),'runlabel' = rseg.metric.list,'metric' = rseg.metric.list)
rseg_summary.6011 <- om_vahydro_metric_grid(metric, metrics.6011)
rseg_summary.6011 <- sqldf(paste("SELECT * FROM 'rseg_summary.6011' WHERE featureid = ",rseg.hydroid,sep=""))
rseg_summary.6011 <- cbind("runid" = 6011,
                           "run_date" = rseg.info.6011$run_date,
                           "starttime" = str_remove(rseg.info.6011$starttime," 00:00:00"),
                           "endtime" = str_remove(rseg.info.6011$endtime," 00:00:00"),
                           rseg_summary.6011)
#-----------------------------------------------------------------------------------------------
rseg.info.6012 <- fn_get_runfile_info(rseg.elid,6012)

metrics.6012 <- data.frame('model_version' = c('vahydro-1.0'),'runid' = c('runid_6012'),'runlabel' = rseg.metric.list,'metric' = rseg.metric.list)
rseg_summary.6012 <- om_vahydro_metric_grid(metric, metrics.6012)
rseg_summary.6012 <- sqldf(paste("SELECT * FROM 'rseg_summary.6012' WHERE featureid = ",rseg.hydroid,sep=""))
rseg_summary.6012 <- cbind("runid" = 6012,
                           "run_date" = rseg.info.6012$run_date,
                           "starttime" = str_remove(rseg.info.6012$starttime," 00:00:00"),
                           "endtime" = str_remove(rseg.info.6012$endtime," 00:00:00"),
                           rseg_summary.6012)
#-----------------------------------------------------------------------------------------------
rseg_summary <- rbind(rseg_summary.401,rseg_summary.6011,rseg_summary.6012)
################################################################################################
################################################################################################
################################################################################################


################################################################################################
# JOIN FAC AND RSEG MODEL STATS
################################################################################################
rseg.met.list <- paste(rseg.metric.list, collapse = ",")
fac.met.list <- paste(fac.metric.list, collapse = ",")

fac_rseg_stats <- sqldf(paste("SELECT a.runid,b.flowby, a.run_date, a.starttime, a.endtime, 
                                a.riverseg,", rseg.met.list,",'-'AS SPACE,",fac.met.list,"
                              FROM rseg_summary AS a
                              LEFT OUTER JOIN fac_summary AS b
                              ON a.runid = b.runid
                              ",sep=""))

#TRANSPOSE DATAFRAME, IF DESIRED
fac_rseg_stats.T <- as.data.frame(t(fac_rseg_stats[,-1]))
colnames(fac_rseg_stats.T) <- fac_rseg_stats[,1]
View(fac_rseg_stats.T)
################################################################################################
################################################################################################
################################################################################################
# write.csv(fac_rseg_stats.T, paste(save_directory,"/fac_rseg_stats.T_",fac.elid,".csv",sep=""))

################################################################################################
################################################################################################
################################################################################################