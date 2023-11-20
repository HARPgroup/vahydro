library('hydrotools')
library('zoo')
library("knitr")
library("rapportools")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)

# Get Runoff Data for QA - this loads lrseg model elements
# this will not apply to new hsp2/hspf model as LRsegs are not stored explicitly
# in the database, however, that is a potential.  IN the future we should add 
# the ability to query the lang segments for a given river seg, then show those
# summaries since landseg data *COULD BE* summarized in the database.
rodf <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_0', 'runid_2', 'runid_400','runid_0', 'runid_400'),
  'metric' = c('Runit','Runit','Runit', 'l90_RUnit', 'l90_RUnit'),
  'runlabel' = c('Runit_0', 'Runit_2', 'Runit_400', 'l90_RUnit_0', 'l90_RUnit_400')
)
# ftype options,
# sova: cbp532_lrseg
# others: cbp6_lrseg
ro_data <- om_vahydro_metric_grid(
  metric = metric, runids = rodf, bundle = "landunit", ftype = "cbp532_lrseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# RO too small, check for missing lrseg: JU2_7140_7330, JU2_7450_7360
# - in these, a single Landseg was missing, from WV: N54063 
jar_rodata = fn_extract_basin(ro_data,'OR7_8490_0000')

sqldf("select * from jar_rodata where abs((Runit_2 - Runit_0) / Runit_0) > 0.05")
