basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library('knitr')
library("hydrotools")

library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
library("rjson")

plat_bb = 36.901388888889; plon_bb = -82.754166666667 # Ben's Branch downstream of impoundment
plat_imp = 36.9022222222; plon_imp = -82.7525 # Impoundment intake
plat = 36.90784; plon = -82.76888 # Powell River intake

# Entuire drainage above Powell confluence
out_point_bb = sf::st_sfc(sf::st_point(c(plon_bb, plat_bb)), crs = 4326)
nhd_out_bb <- get_nhdplus(out_point_bb)
dasqmi_bb <- 0.386102 * nhd_out_bb$totdasqkm
dasqmi_bb
map_bb <- plot_nhdplus((list(nhd_out_bb$comid)))
# DA Above dam
out_point_imp = sf::st_sfc(sf::st_point(c(plon_imp, plat_imp)), crs = 4326)
nhd_out_imp <- get_nhdplus(out_point_imp)
dasqmi_imp <- 0.386102 * nhd_out_imp$totdasqkm
dasqmi_imp
map_imp <- plot_nhdplus((list(nhd_out_imp$comid)))
dasqmi_imp / dasqmi_bb

bb_all <- get_nhdplus(map_bb$basin)
map_bb <- plot_nhdplus((list(nhd_out_bb$comid)))
plot_nhdplus(list(map_bb$flowline$COMID))
wb = nhdplusTools::get_waterbodies(id = nhdplus_id)
wb_wkt = wellknown::sf_convert(wb$geometry)
plot(wb$geometry)
bb_network <- get_UT(nhd_out_bb, nhd_out_bb$comid, distance = NULL)

elid = 257025; pid = 4710411; runid = 1800 # THornton River
runid=1800
gage_number = '01667500' # Rapidan
startdate <- "1984-10-01"
enddate <- "2020-09-30"
pstartdate <- "2008-04-01"
penddate <- "2008-11-30"


runid = 1800
rdata <- om_get_rundata(relid, runid, site=omsite)
r_stats <- om_quantile_table(
  rdata, 
  metrics = c(
    "Qout", "wd_cumulative_mgd", "Qup", "ps_cumulative_mgd"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(r_stats,'markdown')
rdataz <- as.zoo(rdata$Qout, index=(as.Date(rdata$thisdate)))
loflows <- group2(rdataz)
min(loflows$`90 Day Min`)

deets <- as.data.frame(hdata[,c(
  "year", "month", "day", "Qreach", "Qavail_divert", "Qturbine", "Qbypass", "flowby", "Qintake"
)])

# CIA


# GET RIVERSEG l90_Qout DATA
df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_600', 'runid_6001', 'runid_18', 'runid_1800'),
  'metric' = c('l90_Qout','l90_Qout','l90_Qout','l90_Qout'),
  'runlabel' = c('L90 Full Permit', 'L90 FP White Run', 'L90 Exempt', 'L90 Exempt dev')
)
wshed_data <- om_vahydro_metric_grid(
  metric = FALSE, runids = df,
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
wshed_data$exempt_pct <- (wshed_data$L90_Exempt - wshed_data$L90_Full_Permit) / wshed_data$L90_Full_Permit
ru_data = fn_extract_basin(wshed_data,'RU5_6030_0001')

dff <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_600', 'runid_6001', 'runid_18', 'runid_1800'),
  'metric' = c('unmet7_mgd','unmet_demand_mgy','unmet_demand_mgy','unmet7_mgd','unmet_demand_mgy'),
  'runlabel' = c('Unmet7 WSP20','Unmet Full Permit', 'Unmet FP White Run', 'Unmet Exempt mgd', 'Unmet Exempt dev')
)
fac_data <- om_vahydro_metric_grid(
  metric = FALSE, runids = dff, bundle='facility', ftype="all",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
ru_fac_data = fn_extract_basin(fac_data,'RU5_6030_0001')
ru_fac_data_no_wsp <- sqldf("select * from ru_fac_data where hydrocode not like 'wsp%'")

# Detail exempt table
ru_detail <- sqldf(
  "select propname, Unmet_Full_Permit, Unmet_FP_White_Run, Unmet_Exempt 
  from ru_fac_data_no_wsp
  where featureid in (73075, 72734)
")

# Contrast Shenadoah Dry River
dr_fac_data = fn_extract_basin(fac_data,'PS3_5990_6161')
dr_fac_data_no_wsp <- sqldf("select * from dr_fac_data where hydrocode not like 'wsp%'")

wddf <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_600', 'runid_6001', 'runid_18', 'runid_1800'),
  'metric' = c('wd_mgd','wd_mgd','wd_mgd','wd_mgd','wd_mgd'),
  'runlabel' = c('wd_mgd WSP20','wd_mgd Full Permit', 'wd_mgd FP White Run', 'wd_mgd Exempt mgd', 'wd_mgd Exempt dev')
)
fac_wddata <- om_vahydro_metric_grid(
  metric = FALSE, runids = wddf, bundle='facility', ftype="all",
  base_url = paste(site,'entity-model-prop-level-export',sep="/"),
  ds = ds
)
wdr_fac_data = fn_extract_basin(fac_wddata,'PS3_5990_6161')
