library("sqldf")
library("stringr") #for str_remove()

# Load Libraries
basepath='/var/www/R';
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source("/var/www/R/config.local.private"); 
source(paste(basepath,'config.R',sep='/'))
source(paste(hydro_tools_location,'/R/om_vahydro_metric_grid.R', sep = ''));
#folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
#folder <- "C:/Workspace/tmp/"

# Uses the function om_vahydro_metric_grid()
# See vahydro/R/cia_tables.R for more examples
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

runid = 11
run_name = paste0('runid_', runid)
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c(run_name, run_name, run_name, run_name, run_name, run_name),
  'runlabel' = c('Mean_Q', 'x7Q10', 'Low_Flow_30d', 'Low_Flow_90d', 'Total_WD', 'Total_PS'),
  'metric' = c('Qout', '7q10','l30_Qout','l90_Qout','wd_cumulative_mgd','ps_cumulative_mgd')
)
wshed_data <- om_vahydro_metric_grid(metric, df)

wshed_data <- sqldf(
  "select a.*, b.da 
   from wshed_data as a 
  left outer join da_data as b 
  on (a.pid = b.pid)
  WHERE a.hydrocode not like '%0000'
  order by da
  ")
wshed_data$ua_Q0 <- wshed_data$Mean_Q / wshed_data$da
wshed_data$ua_7q10 <- wshed_data$x7Q10 / wshed_data$da
wshed_data$ua_l30 <- wshed_data$Low_Flow_30d / wshed_data$da
wshed_data$ua_l90 <- wshed_data$Low_Flow_90d / wshed_data$da

boxplot(
#  wshed_data$ua_Q, 
  wshed_data$ua_l90 * 100.0, 
  wshed_data$ua_l30 * 100.0, 
  wshed_data$ua_7q10 * 100.0,
  ylim=c(0,80)
)

boxplot(
  #  wshed_data$ua_Q, 
  wshed_data$ua_l90, 
  wshed_data$ua_l30, 
  wshed_data$ua_7q10,
  names = c('90-day', '30-day', '7Q10'),
  ylab = 'Flow per Unit of Watershed Area cfs/sqmi',
  main = 'Comparison of Unit Area Flows for Low Flow Metrics (current)'
)

hist(wshed_data$ua_l90, plot = TRUE)
hist(wshed_data$ua_l30, plot = TRUE)
hist(wshed_data$ua_7q10, plot = TRUE)

boxplot(
  #  wshed_data$ua_Q, 
  wshed_data$Low_Flow_90, 
  wshed_data$Low_Flow_30d, 
  wshed_data$x7Q10
)

sqldf(
  "select count(*) from wshed_data 
   where ua_l30 < ua_7q10
")

sqldf(
  "select count(*) from wshed_data 
   where ua_7q10 <= ua_l30
")

quantile(wshed_data$ua_l30, na.rm=TRUE)
quantile(wshed_data$ua_7q10, na.rm=TRUE)
