# Upper and Middle Potomac cia table for model debugging
# where is the extra water comingfrom in 2040 baseline flows?

library("sqldf")
library("stringr") #for str_remove()
library("hydrotools") #for str_remove()

# Load Libraries
basepath='/var/www/R';
#site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source("/var/www/R/config.R");
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
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_13', 'runid_17', 'runid_11', 'runid_13'),
  'metric' = c('l90_Qout', 'l90_Qout','l90_Qout','consumptive_use_frac','consumptive_use_frac'),
  'runlabel' = c('L90_2020', 'L90_2040', 'L90_dry', 'cu_2020', 'cu_2040')
)
cc_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu/d.dh/entity-model-prop-level-export"
)

cc_data <- sqldf(
  "select a.*, b.da
   from cc_data as a
  left outer join da_data as b
  on (a.pid = b.pid)
  where hydrocode like 'vahydrosw_wshed_PS%'
  order by da
  ")


dat_gage <- readNWISdv('01628500','00060')
dat_gage$month <- month(dat_gage$Date)
gflows <- om_flow_table(dat_gage, 'X_00060_00003')
gflows

# Facility analysis
dff <- data.frame(runid='runid_13', metric='wd_mgd',
                  runlabel='wd_13',
                  model_version = 'vahydro-1.0'
)
dff <- rbind(
  dff,
  data.frame(runid='runid_17', metric='wd_mgd',
             runlabel='wd_17',
             model_version = 'vahydro-1.0')
)
dff <- rbind(
  dff,
  data.frame(runid='runid_13', metric='unmet30_mgd',
             runlabel='unmet30_13',
             model_version = 'vahydro-1.0')
)
dff <- rbind(
  dff,
  data.frame(runid='runid_17', metric='unmet30_mgd',
             runlabel='unmet30_17',
             model_version = 'vahydro-1.0')
)

fac_data <- om_vahydro_metric_grid(
  metric, dff, 'all', 'dh_feature', 'facility','all',
  "vahydro-1.0","http://deq1.bse.vt.edu/d.dh/entity-model-prop-level-export"
)

fac_case <- sqldf(
  "select * from fac_data
   where  riverseg like 'PS%'
  "
)

fac_unmet_cc <- sqldf(
  "select propname, riverseg, 'demand 2040' as scenario, sum(unmet30_13) as mgd, count(*)
    from fac_case
    WHERE unmet30_13 > unmet30_17
    and wd_13 > 0
    group by propname, riverseg
   UNION
    select propname, riverseg, 'CC 2040' as scenario, sum(unmet30_17) as mgd, count(*)
    from fac_case
    WHERE unmet30_13 < unmet30_17
    and wd_13 > 0
    group by propname, riverseg
  "
)


# Rivers with LOWER CC flow than 13 flow
# - Riverton (pid = 4711544, elid = 239063 )
#   - l30 year is 1992,and l90 year is 1999, so good comparison of
#     apples to apples with impact of change in ET/Precip

# River segments with HIGHER CC flow than 13 flow
# - Front Royal (pid = 4713879, elid = )
