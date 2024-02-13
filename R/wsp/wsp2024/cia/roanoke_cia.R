options(scipen=999)
library('hydrotools')
library('zoo')
library("knitr")
library("rapportools")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)

# GET VAHydro 1.0 RIVERSEG l90_Qout DATA
df <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0','vahydro-1.0', 'vahydro-1.0','vahydro-1.0'),
  'runid' = c('runid_11', 'runid_0', 'runid_11', 'runid_0', 'runid_11', 'runid_0', 'runid_110'),
  'metric' = c('Qout','Qout', 'wd_cumulative_mgd', 'wd_cumulative_mgd','l30_Qout', 'l30_Qout', 'wd_cumulative_mgd'),
  'runlabel' = c('Qout_11', 'Qout_0', 'wd_11', 'wd_0', 'l30_11', 'l30_0', 'wd_110')
)
wshed_data <- om_vahydro_metric_grid(
  metric = metric, runids = df,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# because the cbp nomenclature for wshed connectivity stops at the TN border
# we cannot use the normal fn_extrac_basin() method, so just a SQL like
#powell_data = fn_extract_basin(wshed_data,'OR3_7740_8271')
powell_data = sqldf("select * from wshed_data where riverseg like 'TU%'")

# Get cbp-6.0 data for water balance comparison

# GET RIVERSEG l90_Qout DATA
df6 <- data.frame(
  'model_version' = c('cbp-6.1',  'cbp-6.1'),
  'runid' = c('subsheds', 'subsheds'),
  'metric' = c('Qout','wd_cumulative_mgd'),
  'runlabel' = c('Qout_cbp6', 'wd_cbp6')
)
wshed_data6 <- om_vahydro_metric_grid(
  metric = metric, runids = df6,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
or_data6 = fn_extract_basin(wshed_data6,'OR3_7740_8271')
