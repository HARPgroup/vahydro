source(paste(hydro_tools_location,'/R/om_vahydro_metric_grid.R', sep = ''));

df <- data.frame(
  'model_version' = c('vahydro-1.0', 'usgs-1.0',  'CFBASE30Y20180615', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_11', 'runid_11', 'runid_1151', 'runid_1153', 'runid_13', 'runid_13'),
  'runlabel' = c('VAH Daily', 'USGS', 'CBP6', 'VAH 6 hr', 'VAH 3 hr', 'VAH Daily 2040', 'wd 2040'),
  'metric' = c('l90_Qout','90 Day Min Low Flow','90 Day Min Low Flow','l90_Qout','l90_Qout','l90_Qout', 'wd_mgd')
)
# choose one to test
#df <- as.data.frame(df[3,])

wshed_data <- om_vahydro_metric_grid(metric, df)
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
# Specific watershed with some gage data
sqldf(
  "select propname, USGS, VAH_Daily, CBP6, VAH_Daily_2040, flow_alter,
  case 
    when cbp_err is not null then flow_alter * (cbp_err+ 1.0)
    WHEN vah_err is not null then flow_alter * (vah_err+ 1.0)
    ELSE NULL
  END as adj_alter
  from wshed_data 
  where hydrocode like '%OR%' and vah_err is not null"
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
# find where vah better than cbp
sqldf(
  "select * from wshed_data 
   where abs(cbp_err) >  abs(vah_err)
  ")
# THIS REALLY MATTERS!!! How many do we have?
# Actually, only 5
sqldf(
  "select * from wshed_data 
   where abs(flow_alter) > 0.1
  and USGS is not null"
)
