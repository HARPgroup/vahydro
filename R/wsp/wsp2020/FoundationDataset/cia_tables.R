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
  'runid' = c('runid_13', 'runid_13', 'runid_13', 'runid_13', 'runid_13', 'runid_13'),
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
wshed_data$da <- 0.0
for (segix in index(wshed_data)) {
  seg <- wshed_data[segix,]
  print(seg$featureid)
  inputs <- list (
    propname = 'wshed_drainage_area_sqmi',
    featureid = seg$featureid,
    entity_type = 'dh_feature'
  )
  daprop <- getProperty(inputs, site, daprop)
  if (!is.logical(daprop)) {
    da <- as.numeric(daprop$propvalue)
    wshed_data[segix,'da'] <- da
  } else {
    wshed_data[segix,'da'] <- 0
  }
}

wshed_data$cu_mgd <- wshed_data$Total_WD - wshed_data$Total_PS

runid = 13
minor_basin_list = c('PU', 'OR', 'JU', 'JL')
# Save the metric specific file
for (minor_basin in minor_basin_list) {
  mbdata <- sqldf(
    paste0(
      "select * from wshed_data where hydrocode like 'vahydrosw_wshed_",
      minor_basin,
      "%'"
    )
  )
  filename <- paste0(folder,"cia_", minor_basin, '_', runid, ".csv")
  write.csv(mbdata,filename)
}
