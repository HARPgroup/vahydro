library('hydrotools')
library('zoo')
# catawba creek watershed is 210175, WD&PS is 210201
# CC needs to have modernization
datcc401 <- om_get_rundata(210201, 401)
datcc601 <- om_get_rundata(210201, 601)

# CC needs to have modernization
datjrcc401 <- om_get_rundata(219565 , 401)
datjrcc601 <- om_get_rundata(219565 , 601)

datjr401 <- om_get_rundata(209975, 401)
datjr601 <- om_get_rundata(209975, 601)

datrva401 <- om_get_rundata(219639, 401)
datrva601 <- om_get_rundata(219639, 601)

datbc[200:250,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
datbc[0:15,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]

# Facility analysis
dff <- data.frame(runid='runid_401', metric='wd_mgd',
             runlabel='wd_401', 
             model_version = 'vahydro-1.0'
)
dff <- rbind(
  dff, 
  data.frame(runid='runid_601', metric='wd_mgd',
             runlabel='wd_601', 
             model_version = 'vahydro-1.0')
)
dff <- rbind(
  dff, 
  data.frame(runid='runid_401', metric='unmet30_mgd',
             runlabel='unmet30_401', 
             model_version = 'vahydro-1.0')
)
dff <- rbind(
  dff, 
  data.frame(runid='runid_601', metric='unmet30_mgd',
             runlabel='unmet30_601', 
             model_version = 'vahydro-1.0')
)
dff <- rbind(
  dff, 
  data.frame(runid='runid_13', metric='wd_mgd',
             runlabel='wd_13', 
             model_version = 'vahydro-1.0')
)

fac_data <- om_vahydro_metric_grid( metric, dff, 'all', 'dh_feature', 'facility','all')
fac_case <- sqldf(
  "select * from fac_data 
   where (
     riverseg like 'J%' 
     or riverseg = 'OR3_7740_8271_catawba'
   )
   and riverseg not like '%0000%'
   and hydrocode not in ('vwuds_0231', 'Dickerson_Generating_Station')
  "
)
sqldf("select * from fac_case where wd_601 > wd_401")
sqldf("select * from fac_case where wd_601 < wd_401")
sqldf("select * from fac_case where riverseg = 'JU1_7750_7560'")
sqldf("select * from fac_case where unmet30_601 > 0")

# choose one to test
#df <- as.data.frame(df[3,])


dfw <- data.frame(runid='runid_401', metric='wd_mgd',
             runlabel='wd_401', model_version = 'vahydro-1.0'
)
dfw <- rbind(
  dfw,
  data.frame(runid='runid_601', metric='wd_mgd',
             runlabel='wd_601', model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_401', metric='wd_cumulative_mgd',
             runlabel='wdcum_401', 
             model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_601', metric='wd_cumulative_mgd',
             runlabel='wdcum_601', 
             model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_13', metric='wd_cumulative_mgd',
             runlabel='wdcum_13', 
             model_version = 'vahydro-1.0')
)
wshed_data <- om_vahydro_metric_grid(metric, dfw)
wshed_case <- sqldf(
  "select * from wshed_data 
   where riverseg like 'J%' 
   and riverseg not like '%0000%' 
  "
)
sqldf(
  "select riverseg, wdcum_601, wdcum_401, wdcum_131 from wshed_case 
   where wd_601 < wdcum_401
  ")
sqldf(
  "select riverseg, wd_601, wd_401, wdcum_131 from wshed_case 
   where wd_601 < wd_401
  ")
sqldf(
  "select riverseg, wdcum_601, wdcum_401, wdcum_131 from wshed_case 
   where wdcum_601 > wdcum_401
  ")

sqldf(
  "select riverseg, round(wdcum_601) as vwp, round(wdcum_401) as vwp_proposed, round(wdcum_131) as wsp_2040 from wshed_case 
   order by wdcum_131 DESC LIMIT 1"
)

sqldf(
  "select * from wshed_case 
   where riverseg = 'JL6_7150_6890'
  ")


