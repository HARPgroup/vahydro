# Upper and Middle Potomac cia table for model debugging
# where is the extra water comingfrom in 2040 baseline flows?

library("sqldf")
library("stringr") #for str_remove()
library("hydrotools")

# Load Libraries
#basepath='/var/www/R';
#site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#source("/var/www/R/config.local.private"); 
#source(paste(basepath,'config.R',sep='/'))
#source(paste(hydro_tools_location,'/R/om_vahydro_metric_grid.R', sep = ''));
folder <- "C:/Workspace/tmp/"

# get the DA, need to grab a model output first in order to insure segments with a channel subcomp
# are included
# 
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', '0.%20River%20Channel', 'local_channel'),
  'runlabel' = c('QBaseline_2020', 'comp_da', 'subcomp_da'),
  'metric' = c('Qbaseline', 'drainage_area', 'drainage_area')
)
da_data <- om_vahydro_metric_grid(metric, df)
da_data <- sqldf(
  "select pid, comp_da, subcomp_da,
   CASE
    WHEN comp_da is null then subcomp_da
    ELSE comp_da
    END as da
   from da_data
  ")

df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_13', 'runid_11', 'runid_13', 'runid_11', 'runid_13', 'runid_11', 'runid_13', 'runid_11', 'runid_13'),
  'runlabel' = c('Qbaseline_2020', 'QBaseline_2040', 'L90_2020', 'L90_2040', 'WD_2020', 'WD_2040', 'PS_2020', 'PS_2040', 'PSNX_2020', 'PSNX_2040'),
  'metric' = c('Qbaseline', 'Qbaseline','l90_Qout','l90_Qout','wd_cumulative_mgd','wd_cumulative_mgd','ps_cumulative_mgd','ps_cumulative_mgd','ps_nextdown_mgd','ps_nextdown_mgd')
)
wshed_data <- om_vahydro_metric_grid(metric, df)

wshed_data <- sqldf(
  "select a.*, b.da 
   from wshed_data as a 
  left outer join da_data as b 
  on (a.pid = b.pid)
  order by da
  ")
# filter on watershed major/minor basin
# where hydrocode like 'vahydrosw_wshed_P%'
# and hydrocode not like 'vahydrosw_wshed_PL%'

wshed_data$dl90 <- 100.0 * (wshed_data$L90_2040 - wshed_data$L90_2020) / wshed_data$L90_2020
wshed_data <- sqldf(
  "select * from 
   wshed_data 
   where 
     hydrocode not like '%0000'
  "
)
plot(dl90 ~ da, data=sqldf("select * from wshed_data where da < 200"))

quantile(wshed_case$dl90, probs = c(0, 0.01,0.05, 0.1, 0.25, 0.5), na.rm=TRUE)
wshed_case <- sqldf(
  "select * from 
   wshed_data 
   where 
     (abs(1.0 - (QBaseline_2020/QBaseline_2040)) > 0.01)
   and hydrocode not like '%0000'
  "
)

elid = 229119
pordat <- fn_get_runfile(elid, 11)
pordf <- as.data.frame(pordat)


df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_12', 'runid_13', 'runid_11', 'runid_12', 'runid_13', 'runid_11', 'runid_13'),
  'runlabel' = c('wdc_2020', 'wdc_2030', 'wdc_2040', 'l90_2020', 'l90_2030', 'l90_2040', 'l30_2020', 'l30_2040'),
  'metric' = c('wd_cumulative_mgd', 'wd_cumulative_mgd','wd_cumulative_mgd', 'l90_Qout', 'l90_Qout', 'l90_Qout', 'l30_Qout', 'l30_Qout')
)
wshed_data <- om_vahydro_metric_grid(metric, df)

wshed_data$dl90 <- (wshed_data$l90_2040 - wshed_data$l90_2020) / wshed_data$l90_2020
wshed_data$dl30 <- (wshed_data$l30_2040 - wshed_data$l30_2020) / wshed_data$l30_2020

wshed_data <- sqldf(
  "select a.*, b.da 
   from wshed_data as a 
  left outer join da_data as b 
  on (a.pid = b.pid)
  order by da
  ")

wshed_case <- sqldf(
  "select * from 
   wshed_data 
   where 
     wdc_2040 < wdc_2020
   and hydrocode not like '%0000'
  "
)

# Look for anomalys in run 12
sqldf(
  "select pid, propname, 
     round(wdc_2020,2) as r11, 
     round(wdc_2030,2) as r12, 
     round(wdc_2040,2) as r13 
   from wshed_data 
   where round(wdc_2030,2) <> round(((wdc_2020 + wdc_2040) / 2.0),2) 
   and riverseg not like '%0000%' 
   and not ((wdc_2020 < wdc_2030) and (wdc_2030 < wdc_2040)) 
  "
)

sqldf(
  "select pid, propname, 
     round(wdc_2020,2) as r11, 
     round(wdc_2030,2) as r12, 
     round(wdc_2040,2) as r13,
     l90_2020, l90_2030, l90_2040
   from wshed_data 
   where riverseg like 'OD%' 
   and l90_2020 < l90_2030
  "
)

sqldf(
  "select pid, propname, 
     round(wdc_2020,2) as r11, 
     round(wdc_2030,2) as r12, 
     round(wdc_2040,2) as r13,
     l90_2020, l90_2030, l90_2040
   from wshed_data 
   where 
     ( (propname like 'Smith%' )
     OR  (propname like 'Philpot%' ) )
  "
)


MN_data <- sqldf(
  "select *
   from wshed_data
  where hydrocode like 'vahydrosw_wshed_MN%'
  and riverseg not like '%0000%'
  ")

sqldf("select count(*) from MN_data")
sqldf("select count(*) from MN_data where dl90 < -0.1")
sqldf("select count(*) from MN_data where dl30 < -0.1")


