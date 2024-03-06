library('hydrotools')
library('zoo')
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)

rodf <- data.frame(
  'model_version' = c('cbp-6.0', 'cbp-6.0'),
  'runid' = c('mash', 'mash'),
  'metric' = c('PRC_anomaly_count','PRC_daily_error_count'),
  'runlabel' = c('PRC_anomaly_count', 'PRC_daily_error_count')
)
ro_data <- om_vahydro_metric_grid(
  metric = metric, runids = rodf, bundle = "landunit", ftype = "cbp6_landseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)


# Land seg NLDAS2 QA data only for Phase 5
rodf <- data.frame(
  'model_version' = c('cbp-5.3.2', 'cbp-5.3.2', 'cbp-5.3.2', 'cbp-5.3.2', 'cbp-5.3.2'),
  'runid' = c('met2date', 'met2date', 'met2date', 'met2date', 'met2date'),
  'metric' = c('PRC_anomaly_count','PRC_daily_error_count', 'precip_annual_max_in', 'precip_annual_min_in', 'precip_annual_min_year'),
  'runlabel' = c('PRC_anomaly_count', 'PRC_daily_error_count', 'Max_Precip_in', 'Min_Precip_in', 'Min_Precip_year')
)
# ftype options,
# sova: cbp532_lrseg
# others: cbp6_lrseg
ro_data <- om_vahydro_metric_grid(
  metric = metric, runids = rodf, bundle = "landunit", ftype = "cbp532_landseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
