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
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_401', metric='l30_Qout',
             runlabel='l30_401', 
             model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_601', metric='l30_Qout',
             runlabel='l30_601', 
             model_version = 'vahydro-1.0')
)
wshed_data <- om_vahydro_metric_grid(metric, dfw)
wshed_case <- sqldf(
  "select * from wshed_data 
   where riverseg like 'J%' 
   and riverseg not like '%0000%' 
  "
)
sqldf("select * from wshed_case where riverseg = 'JL2_6850_6890'")

sqldf(
  "select riverseg, wd_601, wd_401, wdcum_13, l30_401, l30_601 from wshed_case 
   where wd_601 < wd_401
  ")
# since 601 is total permitted + proposed
# and 401 is just total permitted
# 401 flows should almost always > 60 (unless we have an 
#  impoundment with flow augmentation)
sqldf(
  "select riverseg, wd_601, wd_401, wdcum_13, l30_401, l30_601 from wshed_case 
   where l30_601 < l30_401
   order by l30_601
  ")
# the first watershed with large difference shuld be the source of 
# the new impacts, and likely location of a proposed permit
# in this case: JL6_7440_7430
#         riverseg      wd_601      wd_401  wdcum_13   l30_401   l30_601
#    JL6_7440_7430  0.53051932  0.53051932  94.27137 376.97783 372.80251
sqldf(
  "select * from fac_data where 
   riverseg = 'JL6_7440_7430'
   order by riverseg
  ")
# But no obvious demand changes, why? Look at tribs
sqldf("select * from wshed_case where riverseg like '%_7440%'")
sqldf("select * from fac_data where riverseg like '%_7440%'")
sqldf("select * from wshed_case where riverseg like '%harris%'")


sqldf(
  "select riverseg, wd_601, wd_401, wdcum_13, l30_401, l30_601 from wshed_case 
   where l30_401 < l30_601
   order by l30_601
  ")

sqldf(
  "select riverseg, wd_601, wd_401, wdcum_13, l30_401, l30_601 from wshed_case 
   where l30_601 < l30_401
   order by l30_601
  ")

sqldf(
  "select * from fac_data 
   where  (1.005 * wd_601) < wd_401
   order by riverseg
  ")

sqldf(
  "select * from fac_data where 
   riverseg in (
     select riverseg from wshed_case 
   where wd_601 < wd_401
   )
   and wd_601 < wd_401
   order by riverseg
  ")


sqldf(
  "select * from fac_data where 
   riverseg in (
     select riverseg from wshed_case 
   where wd_601 < wd_401
   )
   and wd_401 < wd_601
   order by riverseg
  ")


datjr401 <- om_get_rundata(212527, 401)
datjr601 <- om_get_rundata(212527, 601)


quantile(datjr401$Qout)
quantile(datjr601$Qout)

quantile(datjr401$Qin)
quantile(datjr601$Qin)

quantile(datjr401$Qup)
quantile(datjr601$Qup)

quantile(datjr401$Runit)
quantile(datjr601$Runit)

quantile(datjr401$Qtrib)
quantile(datjr601$Qtrib)


# harris creek
dathc401 <- om_get_rundata(326970, 401)
dathc601 <- om_get_rundata(326970, 601)
quantile(dathc401$Runit)
quantile(dathc601$Runit)


# harris creek channel object
dathcc401 <- om_get_rundata(326976, 401)
dathcc601 <- om_get_rundata(326976, 601)
quantile(dathcc401$Runit)
quantile(dathcc601$Runit)


# harris creek Fac/Imp object
dathcro401 <- om_get_rundata(220197, 401)
dathcro601 <- om_get_rundata(220197, 601)
quantile(dathcro401$impoundment_Qout)
quantile(dathcro601$impoundment_Qout)
