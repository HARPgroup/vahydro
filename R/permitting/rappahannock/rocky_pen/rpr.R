library('hydrotools')
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# container
cpid = 4704611
celid = 258449

datc <- list()
datc400 <- om_get_rundata(celid, 400, site = omsite)
datc600 <- om_get_rundata(celid, 600, site = omsite)
quantile(datc400$wd_cumulative_mgd)
quantile(datc600$wd_cumulative_mgd)
rbind(
  quantile(datc400$wd_mgd),
  quantile(datc600$wd_mgd)
)
rbind(
  quantile(datc400$Qout),
  quantile(datc600$Qout)
)

# channel object
chelid = 258453
datch400 <- om_get_rundata(chelid, 400, site = omsite)
datch600 <- om_get_rundata(chelid, 600, site = omsite)
datch900 <- om_get_rundata(chelid, 900, site = omsite)
ddf <- as.data.frame(datch900)
rbind(
  quantile(datch400$Qout),
  quantile(datch600$Qout)
)
rbind(
  quantile(datch400$wd_mgd),
  quantile(datch600$wd_mgd)
)
sss <- as.data.frame(datch600)

# Motts fac
mfelid = 322005
datmf401 <- om_get_rundata(mfelid, 401, site = omsite)

# Rapidan Wilderness
rwelid = 348716
datrw <- om_get_rundata(rwelid, 400, site = omsite)
rwdat <- as.data.frame(
  datrw[,
    c(
     'year', 'month', 'day','vwp_base_mgd', 'vwp_max_mgy',
     'historic_monthly_pct', 'vwp_max_mgd', 'Qintake', 'Qreach14',
     'vwp_drought_pump_red_mgd','vwp_drought_max'
   )
])
# RPR Fac
rprfelid = 347372
datrpf <- om_get_rundata(rprfelid, 400, site=omsite)
quantile(datrpf$wd_mgd)

datm <- om_get_rundata(321848,600, site=omsite)
# RO

datro <- om_get_rundata(258469, 600, site=omsite)

# RPR imp
rprelid = 321848
datrpr <- om_get_rundata(rprelid, 600, site=omsite)
quantile(datrpr$pump_allowed, probs=c(0,0.1,0.25,0.35,0.5, 0.58,0.6,0.75,1.0))
avail_table6 = om_flow_table(datrpr, 'pump_allowed')
kable(avail_table6, 'markdown')

rprdat <- as.data.frame(datrpr[,
                               c(
                                 'year', 'month', 'day','Qreach', 'arcadis_tier_mif',
                                 'impoundment_demand', 'refill_bg', 'refill_730',
                                 'impoundment_refill_full_mgd', 'Qrappdownstream',
                                 'pump_allowed','pump_capacity',
                                 'limit_remaining'
                               )
])
datrpr41 <- om_get_rundata(rprelid, 400, site=omsite, hydrowarmup = FALSE)
avail_table4 = om_flow_table(datrpr41, 'pump_allowed')
kable(avail_table4, 'markdown')

datrpr61 <- om_get_rundata(rprelid, 600, site=omsite, hydrowarmup = FALSE)
datrpr <- om_get_rundata(rprelid, 600, site=omsite, hydrowarmup = FALSE)

# test the regression for intake
round(quantile(datrpr$Qreach * 0.795360 - 31.645))
round(quantile(datrpr$Qintake))
round(quantile(datrpr$Qreach))

rbind(
  quantile(datrpr41$Qreach),
  quantile(datrpr61$Qreach)
)
rbind(
  round(quantile(datrpr41$Qintake),1),
        round(quantile(datrpr61$Qintake),1)
)
pa_table <- rbind(
  round(quantile(datrpr41$pump_allowed),1),
  round(quantile(datrpr61$pump_allowed),1)
)
knitr::kable(pa_table)

rbind(
  mean(datrpr41$pump_allowed),
  mean(datrpr61$pump_allowed)
)

rbind(
  round(quantile(datrpr41$impoundment_use_remain_mg),1),
  round(quantile(datrpr61$impoundment_use_remain_mg),1)
)
rbind(
  quantile(datrpr41$pump_allowed),
  quantile(datrpr61$pump_allowed)
)

datrpr9 <- om_get_rundata(rprelid, 900, site=omsite)
datrpr4 <- om_get_rundata(rprelid, 400, site=omsite)
datrpr6 <- om_get_rundata(rprelid, 600, site=omsite)
ddf <- as.data.frame(datrpr9)
sqldf("select sum(ps_refill_pump_mgd) as refill_mgd,
        sum(wd_mgd) as wd_mgd,
        sum(Qout)/1.547 as release_mgd,
        min(impoundment_use_remain_mg) as min_usable,
        max(impoundment_use_remain_mg) as max_usable
      from ddf
      where year = 2002
      ")
rbind(
  quantile(datrpr4$Qreach),
  quantile(datrpr6$Qreach)
)
rbind(
  quantile(datrpr4$impoundment_use_remain_mg),
  quantile(datrpr6$impoundment_use_remain_mg)
)
rbind(
  quantile(datrpr4$pump_allowed, probs=c(0,0.05,0.1,0.5)),
  quantile(datrpr6$pump_allowed, probs=c(0,0.05,0.1,0.5))
)
rbind(
  quantile(datrpr4$ps_refill_pump_mgd, probs=c(0,0.05,0.1,0.5)),
  quantile(datrpr6$ps_refill_pump_mgd, probs=c(0,0.05,0.1,0.5))
)
rbind(
  quantile(datrpr4$limit_remaining, probs=c(0,0.01,0.03,0.05)),
  quantile(datrpr6$limit_remaining, probs=c(0,0.01,0.03,0.05))
)
# river
rapelid = 258123 # Rapidan
datrap <- om_get_rundata(rapelid, 400, site = omsite)
rpid = 6605616
hrelid = 352159
mrelid = 352157
dathr401 <- om_get_rundata(hrelid, 401, site = omsite)
datmr401 <- om_get_rundata(mrelid, 401, site = omsite)
quantile(datmr401$wd_hr_mgd)
quantile(datmr401$wd_mr_mgd)
quantile(datmr401$wd_hr_mgd + datmr401$wd_mr_mgd)
quantile(datmr401$child_wd_mgd)
quantile(datmr401$system_urm)
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', '0.%20River%20Channel', 'local_channel'),
  'runlabel' = c('QBaseline_2020', 'comp_da', 'subcomp_da'),
  'metric' = c('Qbaseline', 'drainage_area', 'drainage_area')
)
da_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu/d.dh/entity-model-prop-level-export"
)
da_data <- sqldf(
  "select pid, comp_da, subcomp_da,
   CASE
    WHEN comp_da is null then subcomp_da
    ELSE comp_da
    END as da
   from da_data
  ")

df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_600', 'runid_900', 'runid_400', 'runid_600', 'runid_900'),
  'metric' = c('wd_cumulative_mgd', 'wd_cumulative_mgd','wd_cumulative_mgd','l90_Qout','l90_Qout','l90_Qout'),
  'runlabel' = c('wdc_permit', 'wdc_prop', 'wdc_ex', 'L90_permi', 'L90_prop', 'L90_exe')
)

df <- rbind(
  df,
  data.frame(
    model_version = 'vahydro-1.0',
    runid = 'runid_901',
    metric = 'wd_cumulative_mgd',
    runlabel = 'wdc_ex'
  )
)

df <- rbind(
  df,
  data.frame(
    model_version = 'vahydro-1.0',
    runid = 'runid_901',
    metric = 'l90_Qout',
    runlabel = 'L90_ex'
  )
)
df <- rbind(
  df,
  data.frame(runid='runid_901', metric='wd_mgd',
             runlabel='wd_ex',
             model_version = 'vahydro-1.0')
)

wshed_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu/d.dh/entity-model-prop-level-export"
)

wshed_data <- sqldf(
  "select a.*, b.da
   from wshed_data as a
  left outer join da_data as b
  on (a.pid = b.pid)
  where hydrocode like 'vahydrosw_wshed_R%'
  and hydrocode not like 'vahydrosw_wshed_RL%'
  order by da
  ")

outlets <- sqldf("select * from wshed_data order by wdc_ex")
for(i in 1:nrow(outlets)) {
  fn_check_cumulative(outlets[i,], wshed_data,  'wd_ex', 'wdc_ex')

}
fn_check_cumulative(
  wshed_data[which(wshed_data$riverseg == 'RU5_6030_0001'),],
  wshed_data, 'wd_ex', 'wdc_ex')

rps901 <- om_get_rundata(303920, 901, site = omsite)
quantile(rps901$wd_mgd)




df <- data.frame(
  'model_version' = c('usgs-1.0',  'CFBASE30Y20180615',  'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_11', 'runid_11'),
  'metric' = c(URLencode('90 Day Min Low Flow'), URLencode('90 Day Min Low Flow'),'l90_Qout'),
  #'metric' = c('7q10', '7q10','7q10'),
  'runlabel' = c('L90_usgs', 'L90_cbp6', 'L90_vahydro')
)

df <- rbind(
  df,
  data.frame(
    model_version = 'vahydro-1.0',
    runid = 'runid_11',
    metric = 'wd_cumulative_mgd',
    runlabel = 'wdc_ex'
  )
)

gcal_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu/d.dh/entity-model-prop-level-export"
)

gcal_data <- sqldf(
  "select a.*, b.da
   from gcal_data as a
  left outer join da_data as b
  on (a.pid = b.pid)
  where hydrocode like 'vahydrosw_wshed_R%'
  and hydrocode not like 'vahydrosw_wshed_RL%'
  order by da
  ")
gcal_data



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

fac_data <- sqldf("select * from fac_data where riverseg like 'R%'")
sqldf("select * from fac_data where unmet30_400 > 0")
