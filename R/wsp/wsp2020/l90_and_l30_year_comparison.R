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
  'runid' = c('runid_11', 'runid_11'),
  'runlabel' = c('L90 Year', 'L30 Year'),
  'metric' = c('l90_year', 'l30_year')
)
wshed_data <- om_vahydro_metric_grid(metric, df)

dsame <- sqldf(
  'select count(*) 
   from wshed_data as a 
   where L90_Year = L30_Year
  ')
ddiff <- sqldf(
  'select count(*) 
   from wshed_data as a 
   where L90_Year <> L30_Year
  ')

print(
  paste(
    "# of watersheds with L90 and L30 occuring in same year =", dsame, 
    "and", ddiff, "watersheds had L90 and L30 in different years."
  )
)



df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_13', 'runid_11', 'runid_13', 'runid_11', 'runid_13'),
  'runlabel' = c('l30_2020', 'l30_2040', 'L90_2020', 'L90_2040', 'wdc_2020', 'wdc_2040'),
  'metric' = c('l30_Qout', 'l30_Qout','l90_Qout','l90_Qout', 'wd_cumulative_mgd', 'wd_cumulative_mgd')
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

wshed_data$dl30 <- round((wshed_data$l30_2040 - wshed_data$l30_2020) / wshed_data$l30_2020,4)
wshed_data$dl90 <- round((wshed_data$L90_2040 - wshed_data$L90_2020) / wshed_data$L90_2020,4)
wshed_case <- sqldf(
  "select * from 
   wshed_data 
   where 
     hydrocode not like '%0000'
  "
)

wshed_wu <- sqldf(
  "select * from 
   wshed_data 
   where 
     hydrocode not like '%0000'
     and wdc_2020 > 0
     and wdc_2040 > 0
  "
)

ql90_all <- quantile(wshed_case$dl90, probs = c(0, 0.01,0.05, 0.1, 0.25, 0.5), na.rm=TRUE)
ql30_all <- quantile(wshed_case$dl30, probs = c(0, 0.01,0.05, 0.1, 0.25, 0.5), na.rm=TRUE)

ql90_haswd <- quantile(wshed_wu$dl90, probs = c(0, 0.01,0.05, 0.1, 0.25, 0.5), na.rm=TRUE)
ql30_haswd <- quantile(wshed_wu$dl30, probs = c(0, 0.01,0.05, 0.1, 0.25, 0.5), na.rm=TRUE)

ql_table <- as.data.frame(rbind(ql90_all, ql30_all, ql90_haswd, ql30_haswd))
knitr(ql_table)
