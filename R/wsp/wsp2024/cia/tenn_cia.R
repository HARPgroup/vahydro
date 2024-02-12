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
  'model_version' = c('vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0','vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_0', 'runid_11', 'runid_0', 'runid_11', 'runid_0'),
  'metric' = c('Qout','Qout', 'wd_cumulative_mgd', 'wd_cumulative_mgd','l30_Qout', 'l30_Qout'),
  'runlabel' = c('Qout_11', 'Qout_0', 'wd_11', 'wd_0', 'l30_11', 'l30_0')
)
wshed_data <- om_vahydro_metric_grid(
  metric = metric, runids = df,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# because the cbp nomenclature for wshed connectivity stops at the TN border
# we cannot use the normal fn_extrac_basin() method, so just a SQL like
#powell_data = fn_extract_basin(wshed_data,'TU4_9260_0000')
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
jar_data6 = fn_extract_basin(wshed_data6,'NR6_8000_0000')

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
jar_rodata = fn_extract_basin(ro_data,'JL7_7070_0001')

# QA details
felid = 351316
runid = 111
fdata <- om_get_rundata(felid, runid, site = omsite)
quantile(fdata$fac_demand_mgy)
m_stats <- om_quantile_table(
  mdata, 
  metrics = c(
    "fac_demand_mgy", "Qintake", "available_mgd", "flowby", "flowby_cov", "min_release", "release"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(m_stats,'markdown')
