# Upper and Middle Potomac cia table for model debugging
# where is the extra water comingfrom in 2040 baseline flows?

library("sqldf")
library("stringr") #for str_remove()

# Load Libraries
basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source("/var/www/R/config.local.private"); 
source(paste(basepath,'config.R',sep='/'))
source(paste(hydro_tools_location,'/R/om_vahydro_metric_grid.R', sep = ''));
folder <- "C:/Workspace/tmp/"

# get the DA, need to grab a model output first in order to insure segments with a channel subcomp
# are included, hence the first column is to look for prop runid_11, Qbaseline, then the next 2 get 
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', '0.%20River%20Channel', 'local_channel'),
  'runlabel' = c('QBaseline_2020', 'comp_da', 'subcomp_da'),
  'metric' = c('Qbaseline', 'drainage_area', 'drainage_area')
)
da_data <- om_vahydro_metric_grid(metric, df, ds = ds)
da_data <- sqldf(
  "select pid, comp_da, subcomp_da,
   CASE
    WHEN comp_da is null then subcomp_da
    ELSE comp_da
    END as da
   from da_data
  ")


df <- data.frame(
  'model_version' = c('vahydro-1.0',  'cbp-6.0',  'cbp-6.1'),
  'runid' = c('runid_11', 'hsp2_2022', 'subsheds'),
  'metric' = c('Qout', 'Qout', 'Qout'),
  'runlabel' = c('Qout_vahydro_11', 'Qout_hsp2', 'Qout_subsheds')
)
all_data <- om_vahydro_metric_grid(metric, df, ds = ds)

all_data$Qdiff_ss <- 100.0 * (all_data$Qout_subsheds - all_data$Qout_hsp2) / all_data$Qout_hsp2
all_data$Qdiff_wsp <- 100.0 * (all_data$Qout_subsheds - all_data$Qout_vahydro_11) / all_data$Qout_vahydro_11
boxplot(all_data$Qdiff_ss, all_data$Qdiff_wsp, ylim=c(-100,100))

# note, this next step removes tidal segments, but it also fixes
# a weird issue where some numeric columns are formatted as scientific notation and others are not
# which sucks, so, run this even if you think you don't need it
wshed_data <- sqldf(
  "select a.*, b.da 
   from all_data as a 
  left outer join da_data as b 
  on (a.pid = b.pid)
  WHERE a.hydrocode not like '%0000'
  and a.riverseg like 'Y%'
  order by da
  ")
boxplot(wshed_data$Qdiff_ss, wshed_data$Qdiff_wsp, ylim=c(-100,100))


