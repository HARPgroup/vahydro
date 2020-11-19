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
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_203', 'runid_203', 'runid_203', 'runid_203', 'runid_203', 'runid_203'),
  'runlabel' = c('Mean_Q', 'x7Q10', 'Low_Flow_30d', 'Low_Flow_90d', 'Total_WD', 'Total_PS'),
  'metric' = c('Qout', '7q10','l30_Qout','l90_Qout','wd_cumulative_mgd','ps_cumulative_mgd')
)
# choose one to test
#df <- as.data.frame(df[3,])
metric = FALSE 
wshed_data <- om_vahydro_metric_grid(metric, df)
# get drainage areas
# @todo: replace this with a faster, single view retrieval routine
#   get properties for view based on hydroid (default = all), bundle, ftype,
if (!exists('wshed_da')) {
  da_url <- 'http://deq2.bse.vt.edu/d.dh/entity-model-prop-level-export/all/dh_feature/watershed/vahydro/vahydro-1.0/0.%20River%20Channel/drainage_area'
  da_data <- read.csv(da_url)
  wshed_da = da_data[,c('pid', 'attribute_value')]
  names(wshed_da) <- c('pid', 'da')
}

wshed_data$cu_mgd <- wshed_data$Total_WD - wshed_data$Total_PS
wshed_data <- sqldf("select a.*, b.da from wshed_data as a left outer join wshed_da as b on a.pid = b.pid")
runid = 203
minor_basin_list = c('P', 'PM')
# Save the metric specific file
for (minor_basin in minor_basin_list) {
  mbdata <- sqldf(
    paste0(
      "select * from wshed_data where hydrocode like 'vahydrosw_wshed_",
      minor_basin,
      "%'
      ORDER BY da"
    )
  )
  filename <- paste0(folder,"cia_", minor_basin, '_', runid, ".csv")
  write.csv(mbdata,filename)
}
