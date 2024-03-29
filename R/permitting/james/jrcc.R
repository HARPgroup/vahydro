library('hydrotools')
library('zoo')

# functions
om_ts_diff <- function(df1, df2, col1, col2, op = "<>") {
  # use "all" for op if just want the df
  df1 <- as.data.frame(df1)
  df2 <- as.data.frame(df2)
  dsql <- paste0(
    "select a.year,a.month,a.day, ",
    "a.", col1, " as v1, b.", col2, " as v2",
    " from df1 as a " ,
    "left outer join df2 as b ",
    " on ( ",
    "a.year = b.year
   and a.month = b.month 
   and a.day = b.day
  ) "
  )
  if (!(op == "all")) {
    dsql <- paste0(
      dsql, " where a.",col1," ", op, " b.", col2
    )
  }
  message(dsql)
  rets <- sqldf(
    dsql
  )
  return(rets)
}

# catawba creek watershed is 210175, WD&PS is 210201
# CC needs to have modernization
datcc400 <- om_get_rundata(210201, 400)
datcc600 <- om_get_rundata(210201, 600)

# CC needs to have modernization
datjrcc400 <- om_get_rundata(219565 , 400)
datjrcc600 <- om_get_rundata(219565 , 600)
om_flow_table(datjrcc600, "Qintake")

df2sum = as.data.frame(datjrcc400)

intake_summary_tbl = data.frame(
  "Month" = character(), 
  'Min' = numeric(),
  '5%' = numeric(),
  '10%' = numeric(),
  '25%' = numeric(), 
  '30%' = numeric(),
  '50%' = numeric(),
  stringsAsFactors = FALSE) ;
for (i in index(month.abb)) {
  moname <- month.abb[i]
  drows <- sqldf(paste("select * from df2sum where month = ", i))
  q_drows <- quantile(drows$Qintake, probs=c(0,0.05,0.1,0.25, 0.3, 0.5), na.rm=TRUE)
  newline = data.frame(
    "Month" = moname,
    'Min' = round(as.numeric(q_drows["0%"]),1),
    '5%' = round(as.numeric(q_drows["5%"]),1),
    '10%' = round(as.numeric(q_drows["10%"]),1),
    '25%' = round(as.numeric(q_drows["25%"]),1), 
    '30%' = round(as.numeric(q_drows["30%"]),1),
    '50%' = round(as.numeric(q_drows["50%"]),1),
    stringsAsFactors = FALSE
  )
  intake_summary_tbl <- rbind(intake_summary_tbl, newline)
}
names(intake_summary_tbl) <- c('Month', 'Min', '5%', '10%', '25%', '30%', '50%')

datsr400 <- om_get_rundata(212303, 400, site = omsite)
datsr600 <- om_get_rundata(212303, 600, site = omsite)
om_ts_diff(datsr400, datsr600, "Qout", "Qout", "<>")

datc400 <- om_get_rundata(210731, 400, site = omsite)
datc600 <- om_get_rundata(210731, 600, site = omsite)
om_ts_diff(datc400, datc600, "Qout", "Qout", "<>")

datbc400 <- om_get_rundata(212451, 400, site = omsite)
datbc600 <- om_get_rundata(212451, 600, site = omsite)
om_ts_diff(datbc400, datbc600, "Qout", "Qout", "<>")
om_ts_diff(datbc400, datbc600, "wd_cumulative_mgd", "wd_cumulative_mgd", "<>")

datjrva400 <- om_get_rundata(209975, 400, site = omsite)
datjrva600 <- om_get_rundata(209975, 600, site = omsite)
om_ts_diff(datjrva400, datjrva600, "Qout", "Qout", "<>")
om_ts_diff(datjrva400, datjrva600, "Qout", "Qout", "> 10 + ")
quantile(datjrva400$wd_cumulative_mgd)
quantile(datjrva600$wd_cumulative_mgd)

datjrh400 <- om_get_rundata(212617, 400, site = omsite)
datjrh600 <- om_get_rundata(212617, 600, site = omsite)
om_ts_diff(datjrh400, datjrh600, "Qout", "Qout", "all")

datccr400 <- om_get_rundata(337692, 400, site = omsite)
datccr600 <- om_get_rundata(337692, 600, site = omsite)
om_ts_diff(datccr400, datccr600, "ps_refill_pump_mgd", "ps_refill_pump_mgd", "all")
 

datrva400 <- om_get_rundata(219639, 400, site = omsite)
datrva600 <- om_get_rundata(219639, 600, site = omsite)

r600 <- as.data.frame(datrva600)

datjack400 <- om_get_rundata(214595, 400, site = omsite)
datjack600 <- om_get_rundata(214595, 600, site = omsite)
cov400 <- om_get_rundata(320768, 400, site = omsite)
cov600 <- om_get_rundata(320768, 600, site = omsite)
bc600 <- om_get_rundata(327124, 600, site = omsite)

datbc[200:250,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
datbc[0:15,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]

# Facility analysis
dff <- data.frame(runid='runid_400', metric='wd_mgd',
                  runlabel='wd_400', 
                  model_version = 'vahydro-1.0'
)
dff <- rbind(
  dff, 
  data.frame(runid='runid_600', metric='wd_mgd',
             runlabel='wd_600', 
             model_version = 'vahydro-1.0')
)
dff <- rbind(
  dff, 
  data.frame(runid='runid_400', metric='unmet30_mgd',
             runlabel='unmet30_400', 
             model_version = 'vahydro-1.0')
)
dff <- rbind(
  dff, 
  data.frame(runid='runid_600', metric='unmet30_mgd',
             runlabel='unmet30_600', 
             model_version = 'vahydro-1.0')
)
dff <- rbind(
  dff, 
  data.frame(runid='runid_13', metric='wd_mgd',
             runlabel='wd_13', 
             model_version = 'vahydro-1.0')
)

fac_data <- om_vahydro_metric_grid(
  metric, dff, 'all', 'dh_feature', 'facility','all',
  "vahydro-1.0","http://deq1.bse.vt.edu/d.dh/entity-model-prop-level-export"
)

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
sqldf("select * from fac_case where wd_600 > wd_400")
sqldf("select * from fac_case where wd_600 < wd_400")
sqldf("select * from fac_case where riverseg in ('JL3_7020_7100', 'JL3_7090_7150')")
sqldf("select * from fac_case where unmet30_600 > 0")

# choose one to test
#df <- as.data.frame(df[3,])


dfw <- data.frame(runid='runid_400', metric='wd_mgd',
                  runlabel='wd_400', model_version = 'vahydro-1.0'
)
dfw <- rbind(
  dfw,
  data.frame(runid='runid_600', metric='wd_mgd',
             runlabel='wd_600', model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_400', metric='wd_cumulative_mgd',
             runlabel='wdcum_400', 
             model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_600', metric='wd_cumulative_mgd',
             runlabel='wdcum_600', 
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
  data.frame(runid='runid_13', metric='wd_mgd',
             runlabel='wd_13', 
             model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_400', metric='l30_Qout',
             runlabel='l30_400', 
             model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_600', metric='l30_Qout',
             runlabel='l30_600', 
             model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_400', metric='l90_Qout',
             runlabel='l90_400', 
             model_version = 'vahydro-1.0')
)
dfw <- rbind(
  dfw, 
  data.frame(runid='runid_600', metric='l90_Qout',
             runlabel='l90_600', 
             model_version = 'vahydro-1.0')
)
wshed_data <- om_vahydro_metric_grid(
  metric, dfw, "all", "dh_feature", 
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu/d.dh/entity-model-prop-level-export"
)

wshed_case <- sqldf(
  "select * from wshed_data 
   where riverseg like 'J%' 
   and riverseg not like '%0000%' 
  "
)
# Now, target segments where wd600 < wd400 and l90600 > l90400
  
sqldf(
  "select riverseg, wd_600, wd_400, wd_13, l90_400, l90_600 from wshed_case 
   where l90_600 < l90_400
   order by l90_400
  ")
sqldf(
  "select riverseg, wd_600, wd_400, wd_13, l90_400, l90_600 from wshed_case 
   where l90_600 > l90_400
   order by l90_400
  ")


sqldf(
  "select * from wshed_case
   where  (1.005 * wd_400) < wd_600
   order by riverseg
  ")
# Find river seg facilities: JU3_6950_7330  
sqldf("select * from fac_data where riverseg = 'JU3_6950_7330'")
# Find river seg facilities: JU3_6950_7330  
sqldf("select * from wshed_case where riverseg = 'JU3_6950_7330'")


# since 600 is total permitted + proposed
# and 400 is just total permitted
# 400 flows should almost always > 60 (unless we have an 
#  impoundment with flow augmentation)
sqldf(
  "select riverseg, wd_600, wd_400, wd_13, l30_400, l30_600 from wshed_case 
   where l30_600 < l30_400
   order by l30_600
  ")
# the first watershed with large difference shuld be the source of 
# the new impacts, and likely location of a proposed permit
# in this case: JL6_7440_7430
#         riverseg      wd_600      wd_400  wdcum_13   l30_400   l30_600
#    JL6_7440_7430  0.53051932  0.53051932  94.27137 376.97783 372.80251
sqldf(
  "select * from fac_data where 
   riverseg = 'JL6_7440_7430'
   order by riverseg
  ")
# But no obvious demand changes, why? Look at tribs
# trib container for willis 214481 listens to children for "wd_cumulative_mgd", b
#  but, children send wd_uptream_mgd
# Convention on main segments is to pass "wd_upstream_mgd", which is sensible.
# it is not necessarily bad to keep track of "wd_trib_mgd" separately, but for the 
# purpose of having a full cumulative accounting, this is not ideal.
sqldf("select * from wshed_case where riverseg in ('JL3_7020_7100', 'JL3_7090_7150')")
sqldf("select * from wshed_case where wdcum_400 = 0.36")
sqldf("select * from fac_data where riverseg like '%_7440%'")
sqldf("select * from wshed_case where riverseg like '%harris%'")
sqldf("select * from wshed_case where riverseg like '%black%'")


sqldf(
  "select riverseg, wd_600, wd_400, wdcum_13, l30_400, l30_600 from wshed_case 
   where l30_400 < l30_600
   order by l30_600
  ")

sqldf(
  "select riverseg, wd_600, wd_400, wdcum_13, l30_400, l30_600 from wshed_case 
   where l30_600 < l30_400
   order by l30_600
  ")

sqldf(
  "select * from fac_data 
   where  (1.005 * wd_600) < wd_400
   order by riverseg
  ")

sqldf(
  "select * from fac_data 
   where  (1.005 * wd_400) < wd_600
   order by riverseg
  ")

sqldf(
  "select * from fac_data where 
   riverseg in (
     select riverseg from wshed_case 
   where wd_600 < wd_400
   )
   and wd_600 < wd_400
   order by riverseg
  ")


sqldf(
  "select * from fac_data where 
   riverseg in (
     select riverseg from wshed_case 
   where wd_600 < wd_400
   )
   and wd_400 < wd_600
   order by riverseg
  ")


datjr400 <- om_get_rundata(212527, 400)
datjr600 <- om_get_rundata(212527, 600)


quantile(datjr400$Qout)
quantile(datjr600$Qout)

quantile(datjr400$Qin)
quantile(datjr600$Qin)

quantile(datjr400$Qup)
quantile(datjr600$Qup)

quantile(datjr400$Runit)
quantile(datjr600$Runit)

quantile(datjr400$Qtrib)
quantile(datjr600$Qtrib)


# harris creek
dathc400 <- om_get_rundata(326970, 400)
dathc600 <- om_get_rundata(326970, 600)
quantile(dathc400$Runit)
quantile(dathc600$Runit)


# harris creek channel object
dathcc400 <- om_get_rundata(326976, 400)
dathcc600 <- om_get_rundata(326976, 600)
quantile(dathcc400$Runit)
quantile(dathcc600$Runit)


# harris creek Fac/Imp object
dathcro400 <- om_get_rundata(220197, 400)
dathcro600 <- om_get_rundata(220197, 600)
quantile(dathcro400$impoundment_Qout)
quantile(dathcro600$impoundment_Qout)
