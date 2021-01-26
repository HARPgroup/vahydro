# Upper and Middle Potomac cia table for model debugging
# where is the extra water comingfrom in 2040 baseline flows?

library("sqldf")
library("stringr") #for str_remove()

# Load Libraries
basepath='/var/www/R';
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source("/var/www/R/config.local.private"); 
source(paste(basepath,'config.R',sep='/'))
source(paste(hydro_tools_location,'/R/om_vahydro_metric_grid.R', sep = ''));
folder <- "C:/Workspace/tmp/"

df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_13'),
  'metric' = c('unmet7_mgd', 'unmet7_mgd', 'unmet30_mgd', 'unmet30_mgd', 'unmet90_mgd', 'unmet90_mgd'),
  'runlabel' = c('unmet7_mgd_2020', 'unmet7_mgd_2040', 'unmet30_mgd_2020', 'unmet30_mgd_2040', 'unmet90_mgd_2020', 'unmet90_mgd_2040')
)
fac_data <- om_vahydro_metric_grid( metric, df, 'all', 'dh_feature', 'facility','all')
fac_case <- sqldf("select * from fac_data where riverseg not like '%0000%' ")

sqldf(
  "select sum(unmet7_mgd_2020) as u7_2020, 
   sum(unmet7_mgd_2040) as u7_2040, 
   sum(unmet30_mgd_2020) as u30_2020, 
   sum(unmet30_mgd_2040) as u30_2040, 
   sum(unmet90_mgd_2020) as u90_2020, 
   sum(unmet90_mgd_2040) as u90_2040
   from fac_case
  "
)
