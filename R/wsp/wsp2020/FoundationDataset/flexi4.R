vahydro_foundation4_export <- function (
  metric,
  runids,
  folder,
  save_to_file = TRUE,
  featureid = 'all',
  entity_type = 'dh_feature',
  bundle = 'watershed',
  ftype = 'vahydro',
  model_version = 'vahydro-1.0',
  base_url = "http://deq2.bse.vt.edu/d.dh/entity-model-prop-level-export"
) {
  alldata = NULL
  for (i in 1:nrow(runids)) {
    runinfo = runids[i,]
    if (is.data.frame((runinfo))) {
      print("Found info")
      print(runinfo)
      # user is passing in other params in data frame format
      runid = as.character(runinfo$runid)
      if (!is.null(runinfo$model_version)) model_version = as.character(runinfo$model_version)
      if (!is.null(runinfo$metric)) metric = as.character(runinfo$metric)
      if (!is.null(runinfo$runlabel)) runlabel = as.character(runinfo$runlabel)
    } else {
      # only runid is passed in
      runid = runinfo
      runlabel = runid
    }
    runlabel <- str_replace_all(runlabel, '-', '_')
    runlabel <- str_replace_all(runlabel, ' ', '_')
    params <- paste(featureid,entity_type,bundle,ftype,model_version, runid, metric,sep="/")
    url <- paste(base_url,params,sep="/")
    print(paste("retrieving ", url))
    rawdata <- read.csv(url)
    if (is.null(alldata) ) {
      alldata = sqldf(
        paste(
          "select a.pid, a.propname, a.hydrocode, a.featureid, a.riverseg, a.attribute_value as ",
          runlabel, 
          "from rawdata as a "
        )
      )
    } else {
      mergeq = paste(
        "select a.*, b.attribute_value as ",
        runlabel, 
        "from alldata as a 
        left outer join rawdata as b 
        on (
          a.featureid = b.featureid
        )"
      )
      message(mergeq)
      alldata = sqldf(
        mergeq
      )
    }
  }
  # Save the metric specific file
  if (save_to_file == TRUE) {
    filename <- paste0(folder,"metrics_", bundle, "_", metric,".csv")
    write.csv(alldata,filename)
  }
  return(alldata)
}


df <- data.frame(
  'model_version' = c('vahydro-1.0', 'usgs-1.0',  'CFBASE30Y20180615', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_11', 'runid_11', 'runid_1151', 'runid_1153', 'runid_13'),
  'runlabel' = c('VAH Daily', 'USGS', 'CBP6', 'VAH 6 hr', 'VAH 3 hr', 'VAH Daily 2040'),
  'metric' = c('l90_Qout','90 Day Min Low Flow','90 Day Min Low Flow','l90_Qout','l90_Qout','l90_Qout')
)
# choose one to test
#df <- as.data.frame(df[3,])

wshed_data <- vahydro_foundation4_export(metric, df, folder, save_to_file = TRUE)
wshed_data$vah_err <- (wshed_data$VAH_Daily - wshed_data$USGS) / wshed_data$USGS
wshed_data$cbp_err <- (wshed_data$CBP6 - wshed_data$USGS) / wshed_data$USGS
wshed_data$modmod_error <- (wshed_data$VAH_Daily - wshed_data$CBP6) / wshed_data$CBP6
wshed_data$flow_alter <- (wshed_data$VAH_Daily_2040 - wshed_data$VAH_Daily) / wshed_data$VAH_Daily

calib_data <- sqldf(
  "select * from wshed_data 
   where USGS is not null 
   and CBP6 is not null
  ")
big_calib_data <- sqldf(
  "select * from wshed_data 
   where USGS is not null 
   and CBP6 is not null
   and USGS > 10.0"
  )
modmod_error_data <- sqldf(
  "select * from wshed_data 
   where abs(modmod_error) > 0.2
   and abs(vah_err) < abs(cbp_err) 
   and abs(flow_alter) > 0.05
  "
)
sqldf(
  "select * from wshed_data 
   where abs(flow_alter) > 0.05
   and abs(modmod_error) > 0.1
  "
)
sqldf(
  "select * from wshed_data 
   where abs(modmod_error) > 0.1
  "
)
boxplot(
  calib_data$cbp_err, calib_data$vah_err, 
  names = c('CBP', 'VAHydro'), 
  xlab = '90 day low-flow model error',
  main=paste('All Data, n =', nrow(calib_data))
)
boxplot(
  big_calib_data$cbp_err, big_calib_data$vah_err, 
  names = c('CBP', 'VAHydro'), 
  xlab = '90 day low-flow model error',
  main=paste('Watersheds > 50sqmi, n =', nrow(big_calib_data))
)
quantile(calib_data$cbp_err)
quantile(calib_data$vah_err)
quantile(big_calib_data$cbp_err)
quantile(big_calib_data$vah_err)
plot(calib_data$CBP6 ~ calib_data$USGS)
plot(log(calib_data$CBP6) ~ log(calib_data$USGS))
exp(4)
# find some examples
sqldf(
  "select * from wshed_data 
   where abs(cbp_err) > 0.4 
   and abs(cbp_err) < 0.9
  ")
# THIS REALLY MATTERS!!! How many do we have?
# Actually, only 6
sqldf(
  "select * from wshed_data 
   where abs(flow_alter) > 0.1
  and CBP6 is not null"
)
# get drainage areas
# @todo: replace this with a faster, single view retrieval routine
wshed_data$da <- 0.0
for (segix in index(wshed_data)) {
  seg <- wshed_data[segix,]
  print(seg$featureid)
  inputs <- list (
    propname = 'wshed_drainage_area_sqmi',
    featureid = seg$featureid,
    entity_type = 'dh_feature'
  )
  daprop <- getProperty(inputs, site, daprop)
  if (!is.logical(daprop)) {
    da <- as.numeric(daprop$propvalue)
    wshed_data[segix,'da'] <- da
  } else {
    wshed_data[segix,'da'] <- 0
  }
}
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_13', 'runid_13', 'runid_13', 'runid_13', 'runid_13'),
  'runlabel' = c('x7Q10', 'Low Flow 30d', 'Low Flow 90d', 'Total WD', 'Total PS'),
  'metric' = c('7q10','l30_Qout','l90_Qout','wd_cumulative_mgd','ps_cumulative_mgd')
)
# choose one to test
#df <- as.data.frame(df[3,])
metric = FALSE 
wshed_data2 <- vahydro_foundation4_export(metric, df, folder, save_to_file = TRUE)

df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_12', 'runid_13', 'runid_17', 'runid_18'),
  'runlabel' = c('Current', 'Year 2030', 'Yar 2040', 'CC', 'Exempt'),
  'metric' = c('Qout','Qout','Qout','Qout','Qout')
)
# choose one to test
#df <- as.data.frame(df[3,])
metric = FALSE 
wshed_data2 <- vahydro_foundation4_export(metric, df, folder, save_to_file = TRUE)
wshed_data2 <- sqldf("select a.*, b.da from wshed_data2 as a left outer join wshed_data as b on (a.featureid = b.featureid)")