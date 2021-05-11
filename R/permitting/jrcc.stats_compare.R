# jrcc
library(httr)
library(hydrotools)
site <- "http://deq2.bse.vt.edu/d.dh"   
basepath <- '/var/www/R/'
source('/var/www/R/config.R')
options(timeout=1200)

################################################################################################
# USER INPUTS
################################################################################################
rseg.hydroid = 462757   #South Fork Powell River - Big Cherry Reservoir
fac.hydroid = 72672     #BIG STONE GAP WTP

runid.list <- c('runid_201','runid_401','runid_6011','runid_6012')
fac.metric.list <- c('unmet1_mgd','unmet7_mgd','unmet30_mgd','unmet90_mgd','wd_mgd','ps_mgd')
rseg.metric.list <- c('remaining_days_p0','remaining_days_p10','remaining_days_p50','l30_Qout',
                      'l90_Qout','consumptive_use_frac','wd_cumulative_mgd','ps_cumulative_mgd','Qbaseline','Qout')

################################################################################################
# RETRIEVE FAC & RSEG MODEL STATS
################################################################################################
rseg.model <- om_get_model(site, rseg.hydroid)
rseg.elid <- om_get_prop(site, rseg.model$pid, entity_type = 'dh_properties','om_element_connection')$propvalue

fac_summary <- data.frame()
rseg_summary <- data.frame()
#i <- 1
for (i in 1:length(runid.list)){
  runid.i <- runid.list[i]
  run.i <- sub("runid_", "", runid.i)
  
  # RETRIEVE FAC MODEL STATS 
  fac.metrics.i <- data.frame('model_version' = c('vahydro-1.0'),'runid' = c(runid.i),'runlabel' = fac.metric.list,'metric' = fac.metric.list)
  fac_summary.i <- om_vahydro_metric_grid(metric, 'bundle' = 'facility','ftype' = 'all',fac.metrics.i)
  fac_summary.i <- sqldf(paste("SELECT '",run.i,"' AS runid, * FROM 'fac_summary.i' WHERE featureid = ",fac.hydroid,sep=""))
  fac_summary <- rbind(fac_summary,fac_summary.i)
  
  # RETRIEVE RSEG MODEL STATS
  rseg.info.i <- fn_get_runfile_info(rseg.elid,run.i)
  rseg.metrics.i <- data.frame('model_version' = c('vahydro-1.0'),'runid' = c(runid.i),'runlabel' = rseg.metric.list,'metric' = rseg.metric.list)
  rseg_summary.i <- om_vahydro_metric_grid(metric, rseg.metrics.i)
  rseg_summary.i <- sqldf(paste("SELECT * FROM 'rseg_summary.i' WHERE featureid = ",rseg.hydroid,sep=""))
  rseg_summary.i <- cbind("runid" = run.i,"run_date" = rseg.info.i$run_date,"starttime" = str_remove(rseg.info.i$starttime," 00:00:00"),"endtime" = str_remove(rseg.info.i$endtime," 00:00:00"),rseg_summary.i)
  rseg_summary <- rbind(rseg_summary,rseg_summary.i)
}

################################################################################################
# JOIN FAC AND RSEG MODEL STATS INTO SINGLE TABLE
################################################################################################
rseg.met.list <- paste(rseg.metric.list, collapse = ",")
fac.met.list <- paste(fac.metric.list, collapse = ",")
fac_rseg_stats <- sqldf(paste("SELECT a.runid, a.run_date, a.starttime, a.endtime, a.riverseg,' ' AS Rseg_Stats,", rseg.met.list,",' ' AS Facility_Stats,",fac.met.list,"
                              FROM rseg_summary AS a 
                              LEFT OUTER JOIN fac_summary AS b 
                              ON a.runid = b.runid",sep=""))

#TRANSPOSE DATAFRAME, IF DESIRED
fac_rseg_stats.T <- as.data.frame(t(fac_rseg_stats[,-1]))
colnames(fac_rseg_stats.T) <- fac_rseg_stats[,1]
View(fac_rseg_stats.T)

#write.csv(fac_rseg_stats.T,paste(export_path,'fac_rseg_stats.T.',gsub(":","",Sys.time()),'.csv',sep=''))
################################################################################################
################################################################################################
