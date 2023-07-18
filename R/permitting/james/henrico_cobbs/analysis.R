library('hydrotools')
library('zoo')
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)

jamesc_elid = 211097
henrico_elid = 219573 

# GET VAHydro 1.0 RIVERSEG l90_Qout DATA
df <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0','vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_800', 'runid_401', 'runid_601', 'runid_800', 'runid_401', 'runid_601'),
  'metric' = c('Qout','Qout', 'Qout', 'wd_cumulative_mgd','wd_cumulative_mgd', 'wd_cumulative_mgd'),
  'runlabel' = c('Qout_800', 'Qout_perm', 'Qout_prop', 'wd_800', 'wd_401', 'wd_601')
)
wshed_data <- om_vahydro_metric_grid(
  metric = metric, runids = df,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# Jameas RVA = JL7_7070_0001, James at Cartersville = JL6_6740_7100 
jar_data = fn_extract_basin(wshed_data,'JL6_6740_7100')


# get Jackson
runid = 601
rdat_cobbs <- om_get_rundata(337692, runid, site=omsite)
fdat_henrico <- om_get_rundata(henrico_elid, runid, site=omsite)
quantile(fdat_henrico$wd_mgd)
rdat_james <- om_get_rundata(jamesc_elid, runid, site=omsite)
om_cu_table

james_quants <- om_quantile_table(as.data.frame(rdat_james), metrics = c(
  "Qout","Qtrib", "wd_mgd", "ps_mgd"
),
rdigits = 2
)
kable(james_quants,'markdown')

cobbs_quants <- om_quantile_table(as.data.frame(rdat_cobbs), metrics = c(
  "Qjames","Qout","target","adjusted_max",
  "release","flow_targets_p05", "flow_targets_p30",
  "wd_last_mgd", "ps_last_mgd", "refill_pump_mgd", "impoundment_use_remain_mg"
),
rdigits = 2
)
kable(cobbs_quants,'markdown')
# stash
cobbs_401 = cobbs_quants
cobbs_601 = cobbs_quants
kable(cobbs_401,'markdown')
kable(cobbs_601,'markdown')
mean(rdat_cobbs$refill_pump_mgd)


om_flow_table(rdat_cobbs, "release")
