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
  'runid' = c('runid_11', 'runid_0', 'runid_18', 'runid_11', 'runid_0', 'runid_11', 'runid_0'),
  'metric' = c('Qout','Qout', 'wd_cumulative_mgd', 'wd_cumulative_mgd','l30_Qout', 'l30_Qout'),
  'runlabel' = c('Qout_11', 'Qout_0', 'wd_11', 'wd_0', 'l30_11', 'l30_0')
)
wshed_data <- om_vahydro_metric_grid(
  metric = metric, runids = df,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

strasburg_data = fn_extract_basin(wshed_data6,'PS3_5100_5080')

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
strasburg_data6 = fn_extract_basin(wshed_data6,'PS3_5100_5080')

# Get Runoff Data for QA
rodf <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_600', 'runid_800'),
  'metric' = c('Runit','Runit'),
  'runlabel' = c('Runit_perm', 'Runit_800')
)
ro_data <- om_vahydro_metric_grid(
  metric = metric, runids = rodf, bundle = "landunit", ftype = "cbp6_lrseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# RO too small, check for missing lrseg: JU2_7140_7330, JU2_7450_7360
# - in these, a single Landseg was missing, from WV: N54063 
strasburg_rodata = fn_extract_basin(ro_data,'PS3_5100_5080')


stras_river_dat <- om_get_rundata(230671, 11, site=omsite)
plot(
  stras_river_dat$depth ~ stras_river_dat$Qout, 
  ylim=c(0,1.75), xlim=c(0,100)
)


# Get Runoff Data for QA
facdf <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_400', 'runid_11', 'runid_11', 'runid_18', 'runid_18'),
  'metric' = c('wd_mgd', 'unmet7_mgd', 'wd_mgd', 'unmet7_mgd', 'wd_mgd', 'unmet7_mgd'),
  'runlabel' = c('demand_vwp', 'U7_vwp', 'demand_2020', 'U7_2020','demand_exempt', 'U7_exempt')
)
fac_data <- om_vahydro_metric_grid(
  metric = metric, runids = facdf, ftype='all', bundle = "facility",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# RO too small, check for missing lrseg: JU2_7140_7330, JU2_7450_7360
# - in these, a single Landseg was missing, from WV: N54063 
strasburg_facdata = fn_extract_basin(fac_data,'PS3_5100_5080')

all_probs <- sqldf("select * from fac_data where demand_exempt <= 1.2 * demand_2020 and U7_exempt >= 0.3 * demand_exempt ")
all_probs <- sqldf("select * from fac_data where demand_exempt <= 1.5 * demand_vwp and demand_vwp > 0 ")
all_probs <- sqldf("select * from fac_data where U7_exempt >= 0.3 * demand_vwp and U7_exempt <= U7_vwp and demand_vwp > 1.0")

all_probs <- sqldf("select * from fac_data where U7_exempt >= 0.3 * demand_vwp and U7_exempt <= U7_vwp and demand_vwp > 1.0")
all_probs <- sqldf("select * from fac_data where U7_exempt >= 0.3 * demand_vwp and U7_exempt <= U7_vwp and demand_vwp > 1.0")
