# Roanoke Dan cia tables for model debugging
# where is the extra water coming from in 2030 scenario?

library("sqldf")
library("stringr") #for str_remove()
library("hydrotools")

# Load Libraries
basepath='/var/www/R';
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source("/var/www/R/config.local.private"); 
source(paste(basepath,'config.R',sep='/'))

# get the DA, need to grab a model output first in order to ensure segments with a channel subcomp
# are included
# 

# GET DA
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

# GET RIVERSEG l90_Qout DATA
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_12', 'runid_13'),
  'metric' = c('l90_Qout', 'l90_Qout','l90_Qout'),
  'runlabel' = c('L90_2020', 'L90_2030', 'L90_2040')
)
wshed_data <- om_vahydro_metric_grid(metric, df)

#JOIN DA, AND RESTRICT TO OD ONLY
wshed_data <- sqldf(
  "select a.*, b.da 
   from wshed_data as a 
  left outer join da_data as b 
  on (a.pid = b.pid)
  where hydrocode like 'vahydrosw_wshed_OD%'
  order by da
  ")
# write.csv(wshed_data,paste(export_path,'tables_maps/Xfigures/','wshed_data.csv',sep=""))
#--------------------------------------------------

# GET RIVERSEG DATA
df.props <- data.frame(
  'model_version' = c('vahydro-1.0'),
  'runid' = c('runid_11', 'runid_12', 'runid_13'),
  'metric' = c('wd_cumulative_mgd', 'wd_cumulative_mgd','wd_cumulative_mgd',
               'ps_cumulative_mgd', 'ps_cumulative_mgd','ps_cumulative_mgd',
               'Qout', 'Qout','Qout'),
  'runlabel' = c('wd_cumulative_mgd_2020', 'wd_cumulative_mgd_2030', 'wd_cumulative_mgd_2040',
                 'ps_cumulative_mgd_2020', 'ps_cumulative_mgd_2030', 'ps_cumulative_mgd_2040',
                 'Qout_2020', 'Qout_2030', 'Qout_2040')
)
wshed_data_df_props <- om_vahydro_metric_grid(metric, df.props)

#JOIN
wshed_data <- sqldf(
  paste("select a.*, b.*
   from wshed_data as a
  left outer join wshed_data_df_props as b
  on (a.pid = b.pid)
  order by da
  ",sep=""))

# REMOVE DUPLICATE COLUMNS #pid	propname	hydrocode	featureid	riverseg
wshed_data <- wshed_data[,-(max(which(colnames(wshed_data)=="pid")):max(which(colnames(wshed_data)=="riverseg")))]

write.csv(wshed_data,paste(export_path,'wshed_data.csv',sep=""))






# ccmdat <- sqldf("select a.year, a.month, a.day, b.Qup as Qup_2020, a.Qup as Qup_2030, b.Qout as Q2020, a.Qout as Q2030 from mdatdf as a left outer join cmdatdf as b on (a.year = b.year and a.month = b.month and a.day = b.day) where a.year = 2002")
