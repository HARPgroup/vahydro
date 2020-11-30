library("sqldf")
library("stringr") #for str_remove()

# Load Libraries
basepath='/var/www/R';
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source("/var/www/R/config.local.private"); 
source(paste(basepath,'config.R',sep='/'))
source(paste(hydro_tools_location,'/R/om_vahydro_metric_grid.R', sep = ''));
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
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

runid = 13
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
  order by da
  ")

wshed_data$cu_mgd <- wshed_data$Total_WD - wshed_data$Total_PS
wshed_data <- sqldf("select a.*, b.da from wshed_data as a left outer join wshed_da as b on a.pid = b.pid")

minor_basin_list = c('P', 'PM')
# Save the metric specific file
for (minor_basin in minor_basin_list) {
  mbdata <- sqldf(
    paste0(
      "select * from wshed_data where hydrocode like 'vahydrosw_wshed_",
      minor_basin,
      "%'
      AND hydrocode not like '%0000'
      ORDER BY da"
    )
  )
  filename <- paste0(folder,"cia_", minor_basin, '_', runid, ".csv")
  write.csv(mbdata,filename)
}
