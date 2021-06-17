# Upper and Middle Potomac cia table for model debugging
# where is the extra water comingfrom in 2040 baseline flows?

library("sqldf")
library("stringr") #for str_remove()
library("hydrotools") #for str_remove()

# Load Libraries
basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source("/var/www/R/config.local.private"); 
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
da_data <- om_vahydro_metric_grid(
  metric, df,'all',
   entity_type = 'dh_feature',
  bundle = 'watershed',
  ftype = 'vahydro',
  model_version = 'vahydro-1.0',
  base_url = paste(site,"entity-model-prop-level-export", sep="/")
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
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_13', 'runid_11', 'runid_13', 'runid_11', 'runid_13', 'runid_11', 'runid_13', 'runid_11', 'runid_13'),
  'metric' = c('Qbaseline', 'Qbaseline','l90_Qout','l90_Qout','wd_cumulative_mgd','wd_cumulative_mgd','ps_cumulative_mgd','ps_cumulative_mgd','ps_nextdown_mgd','ps_nextdown_mgd'),
  'runlabel' = c('Qbaseline_2020', 'QBaseline_2040', 'L90_2020', 'L90_2040', 'WD_2020', 'WD_2040', 'PS_2020', 'PS_2040', 'PSNX_2020', 'PSNX_2040')
)
wshed_data <- om_vahydro_metric_grid(metric, df)

wshed_data <- sqldf(
  "select a.*, b.da 
   from wshed_data as a 
  left outer join da_data as b 
  on (a.pid = b.pid)
  where hydrocode like 'vahydrosw_wshed_P%'
  and hydrocode not like 'vahydrosw_wshed_PL%'
  order by da
  ")

wshed_cu <- sqldf(
  "select propname, riverseg, WD_2020, PS_2020, (WD_2020 - PS_2020)*1.547 as CU_2020_cfs, 
  WD_2040, PS_2040, (WD_2040 - PS_2040)*1.547 as CU_2040_cfs
  from wshed_data 
  where riverseg in ('PM7_4200_4410', 'PM7_4410_4620', 'PM7_4620_4580', 'PM7_4580_4820', 'PM7_4820_0001')
  "
)
wshed_case <- sqldf(
  "select * from 
  wshed_data 
  where 
    (abs(1.0 - (QBaseline_2020/QBaseline_2040)) > 0.001)
    or riverseg = 'PM7_4200_4410' 
    or riverseg = 'PM7_4410_4620'
  ")

elid = 229119
pordat <- fn_get_runfile(elid, 201)
pordf <- as.data.frame(pordat)


# 
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_13'),
  'metric' = c('consumptive_use_frac', 'consumptive_use_frac'),
  'runlabel' = c('CU_2020', 'CU_2040')
)
wshed_data <- om_vahydro_metric_grid(metric, df)

P_data <- sqldf(
  "select a.*, b.da 
   from wshed_data as a 
  left outer join da_data as b 
  on (a.pid = b.pid)
  where hydrocode like 'vahydrosw_wshed_P%'
  and hydrocode not like 'vahydrosw_wshed_PU%'
  and riverseg not like '%0000%'
  order by da
  ")

sqldf("select count(*) from P_data")
sqldf("select count(*) from P_data where CU_2040 > 0.1")
