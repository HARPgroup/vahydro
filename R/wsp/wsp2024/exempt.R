options(scipen=999)
library('hydrotools')
library('zoo')
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)

# GET VAHydro 1.0 RIVERSEG l90_Qout DATA
df <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0','vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_0', 'runid_18', 'runid_11', 'runid_11', 'runid_18'),
  'metric' = c('Qout','Qout', 'wd_cumulative_mgd', 'wd_cumulative_mgd','l30_Qout', 'l30_Qout'),
  'runlabel' = c('Qout_11', 'Qout_18', 'wd_11', 'wd_18', 'l30_11', 'l30_18')
)
wshed_data <- om_vahydro_metric_grid(
  metric = metric, runids = df,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
smith_data <- fn_extract_basin(wshed_data,'OD3_8720_8900')



# Get Runoff Data for QA
facdf <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_400', 'runid_11', 'runid_11', 'runid_18', 'runid_18'),
  'metric' = c('wd_mgd', 'unmet30_mgd', 'wd_mgd', 'unmet30_mgd', 'wd_mgd', 'unmet30_mgd'),
  'runlabel' = c('demand_vwp', 'U30_vwp', 'demand_2020', 'U30_2020','demand_exempt', 'U30_exempt')
)
fac_data <- om_vahydro_metric_grid(
  metric = metric, runids = facdf, ftype='all', bundle = "facility",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
fac_data <- sqldf("select * from fac_data where riverseg not like '%_0000'")
smith_unmet <- fn_extract_basin(fac_data,'OD3_8720_8900')
sqldf(
  "select sum(demand_vwp) as demand_vwp, 
     sum(demand_2020) as demand_2020, sum(demand_exempt) as wd_exempt 
   from smith_unmet
  ")

all_probs <- sqldf("select * from fac_data where demand_exempt <= 1.2 * demand_2020 and U7_exempt >= 0.3 * demand_exempt ")
all_probs <- sqldf("select * from fac_data where demand_exempt <= 1.5 * demand_vwp and demand_vwp > 0 ")
all_probs <- sqldf("select * from fac_data where U7_exempt >= 0.3 * demand_vwp and U7_exempt <= U7_vwp and demand_vwp > 1.0")

all_probs <- sqldf("select * from fac_data where U7_exempt >= 0.3 * demand_vwp and U7_exempt <= U7_vwp and demand_vwp > 1.0")
all_probs <- sqldf("select * from fac_data where U7_exempt >= 0.3 * demand_vwp and U7_exempt <= U7_vwp and demand_vwp > 1.0")
