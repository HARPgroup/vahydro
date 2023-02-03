# Upper and Middle Potomac cia table for model debugging
# where is the extra water comingfrom in 2040 baseline flows?

library("sqldf")
library("stringr") #for str_remove()
library("hydrotools")

# Load Libraries
basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source("/var/www/R/config.local.private"); 
source(paste(basepath,'config.R',sep='/'))
ds <- RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)
source(paste(hydro_tools_location,'/R/om_vahydro_metric_grid.R', sep = ''));
# folder <- "C:/Workspace/tmp/"



df <- data.frame(
  'model_version' = c('cbp-6.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('hsp2_2022', '0.%20River%20Channel', 'local_channel'),
  'metric' = c('Qout', 'drainage_area', 'drainage_area'),
  'runlabel' = c('Qout_hsp2', 'comp_da', 'subcomp_da')
)
da_data <- om_vahydro_metric_grid(metric, df, ds = ds)


qa_data <- sqldf("
SELECT pid, propname, hydrocode, Qout_hsp2,
       CASE
           WHEN comp_da is null then subcomp_da
           ELSE comp_da
       END as da
FROM da_data
WHERE hydrocode LIKE '%P%'
ORDER BY da;
")
##############################################




##############################################
df <- data.frame(
  'model_version' = c('cbp-6.0'),
  'runid' = c('hsp2_2022'),
  'metric' = c('Qout'),
  'runlabel' = c('Qout_hsp2')
)
wshed_data <- om_vahydro_metric_grid(metric, df, ds = ds)

qa_data <- sqldf(
"SELECT pid, hydrocode, Qout_hsp2
 FROM wshed_data
 WHERE hydrocode LIKE '%P%'
")


##############################################



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
  'model_version' = c('vahydro-1.0',  'cbp-6.0',  'cbp-6.0'),
  'runid' = c('runid_11', 'hsp2_2022', 'subsheds'),
  'metric' = c('Qout', 'Qout', 'Qout'),
  'runlabel' = c('Qout_vahydro_11', 'Qout_hsp2', 'Qout_subsheds')
)
wshed_data <- om_vahydro_metric_grid(metric, df, ds = ds)

# note, this next step removes tidal segments, but it also fixes
# a weird issue where some numeric columns are formatted as scientific notation and others are not
# which sucks, so, run this even if you think you don't need it
wshed_data <- sqldf(
  "select a.*, b.da 
   from wshed_data as a 
  left outer join da_data as b 
  on (a.pid = b.pid)
  WHERE a.hydrocode not like '%0000'
  order by da
  ")
