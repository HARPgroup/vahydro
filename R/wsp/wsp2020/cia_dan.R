# Upper and Middle Potomac cia table for model debugging
# where is the extra water comingfrom in 2040 baseline flows?

library("sqldf")
library("stringr") #for str_remove()
library("hydrotools")

# Load Libraries
basepath='/var/www/R';
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source("/var/www/R/config.local.private"); 
source(paste(basepath,'config.R',sep='/'))

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
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_12', 'runid_13'),
  'metric' = c('l90_Qout', 'l90_Qout','l90_Qout'),
  'runlabel' = c('L90_2020', 'L90_2030', 'L90_2040')
)
wshed_data <- om_vahydro_metric_grid(metric, df)

wshed_data <- sqldf(
  "select a.*, b.da 
   from wshed_data as a 
  left outer join da_data as b 
  on (a.pid = b.pid)
  where hydrocode like 'vahydrosw_wshed_OD%'
  order by da
  ")

ccmdat <- sqldf("select a.year, a.month, a.day, b.Qup as Qup_2020, a.Qup as Qup_2030, b.Qout as Q2020, a.Qout as Q2030 from mdatdf as a left outer join cmdatdf as b on (a.year = b.year and a.month = b.month and a.day = b.day) where a.year = 2002")