library('hydrotools')
library('zoo')
# catawba creek watershed is 210175, WD&PS is 210201
# CC needs to have modernization
datcc401 <- om_get_rundata(210201, 401)
datcc601 <- om_get_rundata(210201, 601)

datjr401 <- om_get_rundata(209975, 401)
datjr601 <- om_get_rundata(209975, 601)

datrva401 <- om_get_rundata(219639, 401)
datrva601 <- om_get_rundata(219639, 601)

datbc[200:250,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
datbc[0:15,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]

# Facility analysis
dff <- data.frame(runid='runid_401', metric='wd_mgd',
             runlabel='wd_pmax', 
             model_version = 'vahydro-1.0'
)
dff <- rbind(
  dff, 
  data.frame(runid='runid_601', metric='wd_mgd',
             runlabel='wd_pmax_pp', 
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
sqldf("select * from fac_case where wd_pmax_pp > wd_pmax")
sqldf("select * from fac_case where wd_pmax_pp < wd_pmax")
sqldf("select * from fac_case where riverseg = 'JU1_7750_7560'")

# choose one to test
#df <- as.data.frame(df[3,])


dfw <- data.frame(runid='runid_401', metric='wd_mgd',
             runlabel='wd_mgd_pmax', model_version = 'vahydro-1.0'
)
dfw <- rbind(
  dfw,
  data.frame(runid='runid_701', metric='wd_mgd',
             runlabel='wd_mgd_pmax_pp', model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_401', metric='wd_cumulative_mgd',
             runlabel='wdcum_pmax', 
             model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_601', metric='wd_cumulative_mgd',
             runlabel='wdcum_pmax_pp', 
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
  "select riverseg, wdcum_pmax_pp, wdcum_pmax from wshed_case 
   where wdcum_pmax_pp < wdcum_pmax
  ")
sqldf(
  "select * from wshed_case 
   where riverseg = 'JU1_7750_7560'
  ")
