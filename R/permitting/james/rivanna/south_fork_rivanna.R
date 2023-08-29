# install_github("HARPGroup/hydro-tools", force=TRUE)
library("hydrotools")
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# Set up our data source
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw)

sffelid <- 347350 # SF facility
sfrelid <- 352054 # SF River seg
bmelid <- 337728 # Buck Mountain Creek
icelid <-  # Ivy Creek
shelid <- 337718 # Sugar Hollow
mrelid <- 337720 # Moorman's River
roelid <- 352020 # runoff 
rmelid <- 337726 # Ragged Mtn
nfelid <- 337712 # North Rivanna
relid <- 337730 # Rivanna 
rjelid <- 214993 # Rivanna at James confluence

roelid <- 351983 # 
rodatr4 <- om_get_rundata(roelid, 801, site=omsite)

rdatr4 <- om_get_rundata(relid, 801, site=omsite)
rjdatr4 <- om_get_rundata(rjelid, 801, site=omsite)

sfdatf <- om_get_rundata(sffelid, 600, site=omsite)
sfdatf_stats <- om_quantile_table(
  sfdatf, 
  metrics = c(
    "wd_mgd", "base_demand_mgd", "vwp_max_mgy", "vwp_prop_max_mgy"
  ),rdigits = 2)
kable(sfdatf_stats,'markdown')

sfdatr2 <- om_get_rundata(sfrelid, 200, site=omsite)
sfdatr4 <- om_get_rundata(sfrelid, 400, site=omsite)

nfdatr <- om_get_rundata(nfelid, 601, site=omsite)
nfdatr_stats <- om_quantile_table(
  nfdatr, 
  metrics = c(
    "wd_rm_mgd", "wd_nf_mgd", "wd_sf_mgd", "Qout", "wd_mgd"
  ),rdigits = 2)
kable(nfdatr_stats,'markdown')

sfdatr <- om_get_rundata(sfrelid, 600, site=omsite, hydrowarmup = TRUE)
sfdatr_stats <- om_quantile_table(
  sfdatr, 
  metrics = c(
    "system_storage_bg","child_wd_mgd",'prop_rm', 'prop_sh', 'S_rm', 'S_sh', 'impoundment_release',
    "impoundment_Qin", "impoundment_Qout","Q30", "Q50", "Q70", "impoundment_use_remain_mg","impoundment_days_remaining",
    "wd_rm_mgd", "wd_nf_mgd", "wd_sf_mgd", "system_demand_mgd", "Wmax_nf",
    "permit_tier"
  ),rdigits = 2, quantiles = c(0.0, 0.05, 0.1, 0.25, 0.5, 0.75, 1.0))
kable(sfdatr_stats,'markdown')
fn_plot_impoundment_flux(sfdatr,"pct_sys_storage","impoundment_Qin", "impoundment_Qout", "wd_mgd")
sfdatrdf <- as.data.frame(sfdatr)
sqldf(
  "select year, month, min(pct_sys_storage), max(pct_sys_storage)
   from sfdatrdf 
   where year >= 2001
   group by year, month
   order by year, month
  "
)
# critical drought is September 1,2001 to October 31, 2022


mean(sfdatr$system_demand_mgd)
mean(sfdatr$child_wd_mgd)

quantile(sfdatr$impoundment_Storage)
quantile(sfdatr4$system_storage_bg)
quantile(sfdatr$impoundment_use_remain_mg, probs=c(0,0.01,0.05,0.1,0.25,0.5,1.0))
quantile(sfdatr4$drought_status, probs=c(0,0.01,0.05,0.1,0.25,0.5,1.0))
quantile(sfdatr4$system_storage_bg)
quantile(sfdatr4$pct_sys_storage)
quantile(sfdatr4$Smax_sh)
quantile(sfdatr4$Smax_rm)
quantile(sfdatr4$impoundment_max_usable)

mrdatr <- om_get_rundata(mrelid, 600, site=omsite, hydrowarmup = FALSE)
mrdatr_stats <- om_quantile_table(
  mrdatr, 
  metrics = c(
    "system_storage_bg","child_wd_mgd",'prop_rm', 'prop_sh', 'S_rm', 'S_sh', 'impoundment_release',
    "impoundment_Qin","impoundment_use_remain_mg","impoundment_days_remaining",
    "wd_rm_mgd", "wd_nf_mgd", "wd_sf_mgd", "system_demand_mgd", "Wmax_nf",
    "permit_tier", "Qup", "Qlocal"
  ),rdigits = 2)
kable(mrdatr_stats,'markdown')
mean(mrdatr$Qup + mrdatr$Qlocal)

quantile(sfdatr6$system_storage_bg)

om_flow_table(sfdatr2, "Qout")
om_flow_table(sfdatr6, "Qout")
om_flow_table(sfdatr6, "local_channel_Qout")


mean(sfdatr4$Runit_mode)
mean(sfdatr4$Qlocal)
quantile(sfdatr4$Qout)
mean(sfdatr4$Qout)
om_vahydro_metric_grid

rmdat <- om_get_rundata(rmelid, 601, site=omsite)
quantile(rmdat$permit_tier)
quantile(rmdat$impoundment_refill)
quantile(rmdat$impoundment_use_remain_mg)
quantile(rmdat$impoundment_demand)
quantile(rmdat$impoundment_Qin)

# test 
finfo = fn_get_runfile_info(shelid, 6011, 37, omsite)
host_site <- paste0('http://',finfo$host)


shdatf4 <- om_get_rundata(shelid, 600, site=omsite, hydrowarmup = FALSE)
om_quantile_table(
  shdatf4, metrics = c(
    "impoundment_demand","impoundment_release",'impoundment_lake_elev',
    "impoundment_Storage","impoundment_use_remain_mg","impoundment_days_remaining",
    "impoundment_Qin","impoundment_Qout", "release_tier1", "imp_elev", 
    "release_tier2", "release_tier4", "release_tier3", 
    "release_tier5", "release", "RMS_bg", "Qrecharge", "Qlocal",
    "Runit_mode", "p_tier",
    "wd_rm_mgd", "wd_nf_mgd", "wd_sf_mgd"
),rdigits = 3)
mean(shdatf4$impoundment_lake_elev,probs=c(0.7,0.8))
mean(shdatf4$ps_refill_pump_mgd)
mean(shdatf4$release_tier3 - shdatf4$release_tier5)
mean(shdatf4$release_tier3 - shdatf4$release)

fn_plot_impoundment_flux(shdatf4,"impoundment_pct_use_remain","impoundment_Qin", "impoundment_Qout", "wd_mgd")

shdatf6 <- om_get_rundata(shelid, 6011, site=omsite, hydrowarmup = FALSE)
om_quantile_table(
  shdatf6, metrics = c(
    "impoundment_demand","impoundment_release",'impoundment_lake_elev',
    "impoundment_Storage","impoundment_use_remain_mg","impoundment_days_remaining",
    "impoundment_Qin","impoundment_Qout", "release_tier1", "imp_elev", 
    "release_tier2", "release_tier4", "release_tier3", 
    "release_tier5", "release", "RMS_bg", "Qrecharge", "Qlocal",
    "Runit_mode", "p_tier",
    "wd_rm_mgd", "wd_nf_mgd", "wd_sf_mgd"
  ),rdigits = 3)

fn_plot_impoundment_flux(shdatf6,"impoundment_pct_use_remain","impoundment_Qin", "impoundment_Qout", "wd_mgd")


rech <- as.data.frame(shdatf4)
sqldf(
  "select year, month, avg(Qrecharge),
  avg(local_channel_Qin) as Qin,
  release_tier5, avg(R10_r_q) as r_q, avg(R10_r_last_q) as r_last_q
  from rech group by year, month 
  order by year, month
")

quantile(shdatf4$permit_tier)
quantile(shdatf4$R10_r_last_q)


sfdatf4 <- om_get_rundata(sffelid, 401, site=omsite)

bcdatf4 <- om_get_rundata(felid, 401, site=omsite)

bcdatr4 <- om_get_rundata(relid, 401, site=omsite)

bcdatro4 <- om_get_rundata(roelid, 401, site=omsite)

bmdat4 <- om_get_rundata(bmelid, 401, site=omsite)


df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', '0.%20River%20Channel', 'local_channel'),
  'runlabel' = c('QBaseline_2020', 'comp_da', 'subcomp_da'),
  'metric' = c('Qbaseline', 'drainage_area', 'drainage_area')
)
da_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu:81/d.dh/entity-model-prop-level-export"
)
da_data <- sqldf(
  "select pid, comp_da, subcomp_da,
   CASE
    WHEN comp_da is null then subcomp_da
    ELSE comp_da
    END as da
   from da_data
  ")


df <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_400', 'runid_600', 'runid_600', 'runid_600'),
  'metric' = c('l90_Qout', 'wd_cumulative_mgd','l90_Qout', 'wd_mgd', 'wd_cumulative_mgd'),
  'runlabel' = c('L90_400', 'wdc_mgd_400', 'l90_600', 'wd_mgd_600', 'wdc_mgd_600')
)
cc_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu:81/d.dh/entity-model-prop-level-export", ds = ds
)


riv_data = fn_extract_basin(cc_data,'JL4_6710_6740')

# print a tble for the issue queue
knitr::kable(riv_data,'markdown')

# summaries since landseg data *COULD BE* summarized in the database.
rodf <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_801'),
  'metric' = c('Runit','Runit'),
  'runlabel' = c('Runit_perm', 'Runit_801')
)
ro_data <- om_vahydro_metric_grid(
  metric = metric, runids = rodf, bundle = "landunit", ftype = "cbp6_lrseg",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)

# RO too small, check for missing lrseg: JU2_7140_7330, JU2_7450_7360
# - in these, a single Landseg was missing, from WV: N54063 
riv_rodata = fn_extract_basin(ro_data,'JL4_6710_6740')
