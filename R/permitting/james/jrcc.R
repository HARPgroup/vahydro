library('hydrotools')
library('zoo')

# catawba creek watershed is 210175, WD&PS is 210201
# CC needs to have modernization
datcc400 <- om_get_rundata(210201, 400, site = omsite)
datcc600 <- om_get_rundata(210201, 600, site = omsite)

# CC needs to have modernization
datjrcc400 <- om_get_rundata(219565 , 400, site = omsite)
datjrcc600 <- om_get_rundata(219565 , 600, site = omsite)
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
datjrva13 <- om_get_rundata(209975, 13, site = omsite)
om_flow_table(datjrva13, "Qout")
mean(datjrva13$wd_cumulative_mgd)
om_flow_table(datjrva400, "Qout")
mean(datjrva400$wd_cumulative_mgd)

om_ts_diff(datjrva400, datjrva600, "Qout", "Qout", "<>")
om_ts_diff(datjrva400, datjrva600, "Qout", "Qout", "> 10 + ")
quantile(datjrva400$wd_cumulative_mgd)
quantile(datjrva600$wd_cumulative_mgd)

# soom in on 2007

c413 <- om_ts_diff(datjrva400, datjrva13, "Qout", "Qout", "all")
sqldf("select * from c413 where year = 2007")

datjbr400 <- om_get_rundata(211097, 400, site = omsite)
datjbr600 <- om_get_rundata(211097, 600, site = omsite)
quantile(datjbr400$Q)

datmr400 <- om_get_rundata(352109, 400, site = omsite)

datjrh400 <- om_get_rundata(212617, 400, site = omsite)
datjrh600 <- om_get_rundata(212617, 600, site = omsite)
om_ts_diff(datjrh400, datjrh600, "Qout", "Qout", "all")

datccr400 <- om_get_rundata(337692, 400, site = omsite)
datccr600 <- om_get_rundata(337692, 600, site = omsite)
om_ts_diff(datccr400, datccr600, "ps_refill_pump_mgd", "ps_refill_pump_mgd", "all")
quantile(datccr400$refill_pump_mgd)
quantile(datccr400$impoundment_release, na.rm = TRUE)
quantile(datccr600$refill_pump_mgd)

datrva400 <- om_get_rundata(219639, 400, site = omsite)
datrva600 <- om_get_rundata(219639, 600, site = omsite)

r600 <- as.data.frame(datrva600)
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

# Look for suspect data
sqldf("select * from wshed_case where l30_400 > 500 or l30_600 > 500")

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
   where  (1.005 * wdcum_400) < wdcum_600
   order by riverseg
  ")
sqldf(
  "select * from wshed_case
   where  wd_400 < wd_600
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

fn_from_node_format <- function(seglist, segcol = "riverseg") {
  node_sql <- paste(
    "select substring(", segcol, ",5,4) as from_node, ",
    "  substring(", segcol, ",10,4) as to_node, ",
    segcol, " as riverseg",
    "from seglist "
  )
  message(node_sql)
  ft_node <- sqldf(
    node_sql
  )
  return(ft_node)
}


fn_upstream2 <- function(riverseg, seg_list, seg_col = "riverseg", debug = FALSE) {
  node_id <- substr(riverseg,5,8)
  up_sql <- paste0(
    "select * from seg_list ",
    "where substring(", seg_col, ",10,4) = '", node_id, "'",
    " and length(riverseg) = 13"
  )
  if (debug) {
    message(up_sql)
  }
  up_list <- sqldf(up_sql)
  # handle non-conforming subwatersheds
  trib_sql <- paste0(
    "select * from seg_list ",
    "where substring(", seg_col, ",1,13) = '", riverseg, "'",
    " and length(riverseg) > 13"
  )
  if (debug) {
    message(trib_sql)
  }
  trib_list <- sqldf(trib_sql)
  if (nrow(trib_list) > 0) {
    up_list <- rbind(up_list, trib_list)
  }
  return(up_list)
}

fn_check_wdc <- function(outlet, all_segments, wd_col, wdc_col) {
  
  riverseg <- as.character(outlet$riverseg)
  #if (str_length(riverseg) > 13) {
  #  message(paste("Can not handle non-conforming riverseg ", riverseg))
  #  return(FALSE)
  #}
  outlet_wdc_mgd <- as.numeric(outlet[wdc_col])
  outlet_wd_mgd <- as.numeric(outlet[wd_col])
  upstream_segments <- fn_upstream2(riverseg, all_segments)
  sum_ups <- as.numeric(
    sqldf(
      paste("select sum(", wdc_col, ") as sum_ups from upstream_segments" )
    )$sum_ups
  )
  if (!is.na(sum_ups)) {
    lhs <- round(outlet_wdc_mgd,2)
    rhs <- round(outlet_wd_mgd + sum_ups,2)
    if (lhs != rhs) {
      message(paste("Problem with sums on ",riverseg))
      message(
        paste(
          "Outlet wd_cumulative_mgd (", lhs,") 
      = upstream wd_cumulative (  ", sum_ups, " ) 
      + local wd (", outlet_wd_mgd,")",
          " = ", rhs
        )
      )
    } else {
      message(paste(riverseg, "OK", lhs,"=",rhs))
    }
  } else {
    #message(paste(riverseg, "is a headwater"))
  }
}

# JL6_7160_7440
sqldf(
  "select * from fac_data 
   where  (1.005 * wd_600) < wd_400
   order by riverseg
  ")
# JL6_7160_7440
sqldf(
  "select * from wshed_case
   where  (1.005 * wd_600) < wd_400
   order by riverseg
  ")

# find segments whose upstream wd_cumulative_mgd + their local wd_mgd <> the local wd_cumulative_mgd
wdc_col <- "wdcum_400"
wd_col <- "wd_400"
outlets <- sqldf("select * from wshed_case where substring(riverseg,10,4) = '0001' ")
# Test
outlets <- sqldf("select * from wshed_case where riverseg = 'JL6_7160_7440'")
outlets <- wshed_case[which(wshed_case$riverseg == 'JL2_6440_6441_buck_mtn_creek'),]
outlets <- sqldf("select * from wshed_case order by wdcum_600") 
for(i in 1:nrow(outlets)) {
  fn_check_wdc(outlets[i,], wshed_case, "wd_400", "wdcum_400")
  #  fn_check_wdc(outlets[i,], wshed_case, "wd_600", "wdcum_600")
}

fn_check_wdc(
  wshed_case[which(wshed_case$riverseg == 'JL7_7100_7030'),],
  wshed_case, wd_col, wdc_col)
fn_upstream2('JL7_7100_7030', all_segments)




fct <- sqldf(
  "select propname, riverseg, wd_400, wdcum_400, wd_600, wdcum_600, l30_400, l30_600 from wshed_case 
   order by wdcum_600
  ")
