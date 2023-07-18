library('hydrotools')
library('zoo')
library("knitr")
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
  'model_version' = c('vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_600'),
  'metric' = c('Runit','Runit'),
  'runlabel' = c('Runit_perm', 'Runit_600')
)
ro_data <- om_vahydro_metric_grid(
  metric = metric, runids = rodf, bundle = "landunit", ftype = "cbp6_lrseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# RO too small, check for missing lrseg: JU2_7140_7330, JU2_7450_7360
# - in these, a single Landseg was missing, from WV: N54063 
jar_rodata = fn_extract_basin(ro_data,'JL7_7070_0001')
