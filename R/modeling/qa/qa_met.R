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


# Land seg NLDAS2 met2date QA data only for Phase 5
rodf <- data.frame(
  'model_version' = c('cbp-5.3.2', 'cbp-5.3.2', 'cbp-5.3.2', 'cbp-5.3.2', 'cbp-5.3.2', 'cbp-5.3.2'),
  'runid' = c('met2date', 'met2date', 'met2date', 'met2date', 'met2date', 'met2date'),
  'metric' = c('PRC_anomaly_count','PRC_daily_error_count', 'precip_annual_max_in', 'precip_annual_max_year', 'precip_annual_min_in', 'precip_annual_min_year'),
  'runlabel' = c('PRC_anomaly_count', 'PRC_daily_error_count', 'Max_Precip_in', 'Max_Precip_year', 'Min_Precip_in', 'Min_Precip_year')
)
# ftype options,
# sova: cbp532_lrseg
# others: cbp6_lrseg
ro_data <- om_vahydro_metric_grid(
  metric = metric, runids = rodf, bundle = "landunit", ftype = "cbp532_landseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# Land seg NLDAS2 met2date QA data only for Phase 6
rodf6 <- data.frame(
  'model_version' = c('cbp-6.0', 'cbp-6.0', 'cbp-6.0', 'cbp-6.0', 'cbp-6.0', 'cbp-6.0'),
  'runid' = c('met2date', 'met2date', 'met2date', 'met2date', 'met2date', 'met2date'),
  'metric' = c('PRC_anomaly_count','PRC_daily_error_count', 'precip_annual_max_in', 'precip_annual_max_year', 'precip_annual_min_in', 'precip_annual_min_year'),
  'runlabel' = c('PRC_anomaly_count', 'PRC_daily_error_count', 'Max_Precip_in', 'Max_Precip_year', 'Min_Precip_in', 'Min_Precip_year')
)
# ftype options,
# sova: cbp532_lrseg
# others: cbp6_lrseg
ro_data6 <- om_vahydro_metric_grid(
  metric = metric, runids = rodf6, bundle = "landunit", ftype = "cbp6_landseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# QA for rerun
sqldf(
  "select \"Max_Precip_year\", count(*) 
   from ro_data6 
   where \"Max_Precip_in\" > 100 
   group by \"Max_Precip_year\"
")
# QA for rerun p5
reruns5 <- sqldf(
  "select \"Max_Precip_year\", hydrocode
   from ro_data 
   where \"Max_Precip_in\" > 100 
   order by \"Max_Precip_year\"
")
# print in a format that can be easily tossed into a CSV (with minimal editing)
cat(sprintf("%i %s\n\r", reruns5$Max_Precip_year, reruns5$hydrocode))


# QA for rerun p6
reruns <- sqldf(
  "select \"Max_Precip_year\", hydrocode
   from ro_data6 
   where \"Max_Precip_in\" > 100 
   order by \"Max_Precip_year\"
")
cat(sprintf("%i %s\n\r", reruns$Max_Precip_year, reruns$hydrocode))
