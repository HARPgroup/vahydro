# Roanoke Dan cia tables for model debugging
# where is the extra water coming from in 2030 scenario?

library("sqldf")
library("stringr") #for str_remove()
library("hydrotools")
library("openmi.om")

# Load Libraries
basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#source("/var/www/R/config.local.private");
source(paste(basepath,'config.R',sep='/'))
ds = RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)
# get the DA, need to grab a model output first in order to ensure segments with a channel subcomp
# are included
#

# GET DA
df_area <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', '0.%20River%20Channel', 'local_channel'),
  'runlabel' = c('QBaseline_2020', 'comp_da', 'subcomp_da'),
  'metric' = c('Qbaseline', 'drainage_area', 'drainage_area')
)
da_data <- om_vahydro_metric_grid(
  metric = metric, runids = df_area,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
da_data <- sqldf(
  "select pid, propname, riverseg, comp_da, subcomp_da,
   CASE
    WHEN comp_da is null then subcomp_da
    ELSE comp_da
    END as da
   from da_data
  ")

# GET RIVERSEG l90_Qout DATA
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_600', 'runid_400', 'runid_600'),
  'metric' = c('l90_Qout','l90_Qout', 'ps_cumulative_mgd', 'ps_cumulative_mgd'),
  'runlabel' = c('L90_perm', 'L90_prop', 'psc_400', 'psc_600')
)
wshed_data <- om_vahydro_metric_grid(
  metric = metric, runids = df,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# Examples of fn_extract_basin
# Appomattox
appomattox_data <- fn_extract_basin(wshed_data,'JA5_7480_0001')
fn_extract_basin(wshed_data,'JL2_6852_6850')
# Jackson River
jackson_data = fn_extract_basin(wshed_data,'JU4_7330_7000')
# James above Rivanna confluence
jar_data = fn_extract_basin(wshed_data,'JL6_6970_6740')

# Appomattox
fn_extract_basin(wshed_data,'JA5_7480_0001')
fn_extract_basin(da_data,'JA1_7640_7280')
fn_extract_basin(wshed_data,'JA1_7640_7280')
dssa = read.csv("http://deq1.bse.vt.edu:81/d.dh/entity-model-prop-level-export/all/dh_feature/watershed/vahydro/vahydro-1.0/runid_400/l90_Qout")
fn_extract_basin(dssa,'JA1_7640_7280')