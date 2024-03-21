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

#For identifying stream-watershed shape/GIS:
plat_bb = 36.901388888889; plon_bb = -82.754166666667 # Ben's Branch downstream of impoundment
plat_imp = 36.9022222222; plon_imp = -82.7525 # Impoundment intake
plat = 36.90784; plon = -82.76888 # Powell River intake

# Entire drainage above Powell confluence
out_point_bb = sf::st_sfc(sf::st_point(c(plon_bb, plat_bb)), crs = 4326)
nhd_out_bb <- memo_get_nhdplus(out_point_bb)
dasqmi_bb <- 0.386102 * nhd_out_bb$totdasqkm
dasqmi_bb
map_bb <- plot_nhdplus((list(nhd_out_bb$comid)), zoom = 14)
nhd_out_bb$comid

# DA Above dam
out_point_imp = sf::st_sfc(sf::st_point(c(plon_imp, plat_imp)), crs = 4326)
nhd_out_imp <- memo_get_nhdplus(out_point_imp)
dasqmi_imp <- 0.386102 * nhd_out_imp$totdasqkm
dasqmi_imp
map_imp <- plot_nhdplus((list(nhd_out_imp$comid)), zoom = 14)
dasqmi_imp / dasqmi_bb

bb_all <- memo_get_nhdplus(map_bb$basin)
map_bb <- plot_nhdplus((list(nhd_out_bb$comid)), zoom = 14)
plot_nhdplus(list(map_bb$flowline$COMID))
wb = nhdplusTools::get_waterbodies(id = nhdplus_id)
wb_wkt = wellknown::sf_convert(wb$geometry)
plot(wb$geometry)
bb_network <- memo_get_UT(nhd_out_bb, nhd_out_bb$comid, distance = NULL)
############

elid = 353105 # Town of A reservoir
relid = 247367 # Powell River
felid = 351742 # Town of A facility
plelid = 353107 # Powell River above Looney Creek (App res is tributary)
bgbelid = 353109 # Benges Branch river/reservoir
runid=601
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")

hdata <- om_get_rundata(elid, runid, site=omsite)
wr_stats <- om_quantile_table(
  hdata, 
  metrics = c(
    "Qreach", "child_wd_mgd", "child_ps_mgd", "Runit_mode",
    "refill_allowed_mgd", "available_mgd","max_mgd","refill_plus_demand",
    "impoundment_Qin", "impoundment_Qout", "refill_flowby",
    "impoundment_use_remain_mg", "impoundment_lake_elev", "impoundment_local_inflow",
    "ps_refill_pump_mgd", "release_cfs", "refill_max_mgd",
    "ps_bsg_mgd", "ps_nextdown_mgd",
    "ps_refill_pump_mgd", "release_cfs", "refill_max_mgd","refill_flowby"
  ),
  quantiles=c(0,0.01,0.05,0.1, 0.5, 0.75, 1.0),
  rdigits = 2
)
knitr::kable(wr_stats,'markdown')
hdata[1360:1450,c("Qreach", "impoundment_area", "impoundment_Qin", "refill_flowby")]
hdata_df <- as.data.frame(hdata)
sqldf("select max(annual_refill) from (select year, sum(ps_refill_pump_mgd) as annual_refill from hdata_df group by year) as foo")

# Benges Branch (Norton water source)
bgdata <- om_get_rundata(bgbelid, runid, site=omsite)


# facility
fdata <- om_get_rundata(felid, runid, site=omsite)
f_stats <- om_quantile_table(
  fdata, 
  metrics = c(
    "release", "lake_elev", "Qnextdown", "Qintake", 
    "flowby", "flowby_proposed", "mif_powell",
    "refill_proposed", "refill_current", "refill_max_mgd",
    "ps_other_mgd", "base_demand_mgd", "available_mgd", "impoundment_use_remain_mg"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(f_stats,'markdown')


hdata[1:5,c("Qreach", "impoundment_area", "impoundment_drainage_area")]
quantile(hdata$wp_bypass, probs=c(0,0.25, 0.5, 0.75, 0.9, 0.95, 1.0), na.rm=TRUE)
quantile(hdata$wp_pre, na.rm=TRUE)

hydroTSM::fdc(hdata[,c("Qintake", "Qbypass")])


rdata <- om_get_rundata(relid, runid, site=omsite)
r_stats <- om_quantile_table(
  rdata, 
  metrics = c(
    "Qout", "wd_cumulative_mgd", "Qup", 
    "ps_cumulative_mgd",
    "wd_upstream_mgd", "wd_mgd", "wd_trib_mgd"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(r_stats,'markdown')

deets <- as.data.frame(hdata[,c(
  "year", "month", "day", "Qreach", "Qavail_divert", "Qturbine", "Qbypass", "flowby", "Qintake"
)])

# Powell above Looney
plrdata <- om_get_rundata(plelid, 0, site=omsite)
plr_stats <- om_quantile_table(
  plrdata, 
  metrics = c(
    "Qout", "Qtrib", "Qlocal", "local_channel_Qout",
    "wd_cumulative_mgd", "ps_mgd", "ps_cumulative_mgd", "ps_nextdown_mgd",
    "wd_upstream_mgd", "wd_mgd"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
knitr::kable(plr_stats,'markdown')
om_flow_table(plrdata, "Qout")
plrdata[which(plrdata$Qout < 1.5),c("local_channel_Qin", "Qtrib", "Qlocal", "Qout", "wd_mgd", "ps_mgd")]
# show select columns when flow goes elow a given threshold, AND the day before and after
ddates <- as.POSIXct(
  rbind(
    index(plrdata[which(plrdata$Qout < 1.5),]), 
    index(plrdata[which(plrdata$Qout < 1.5),]) - days(2), 
    index(plrdata[which(plrdata$Qout < 1.5),]) - days(1), 
    index(plrdata[which(plrdata$Qout < 1.5),]) + days(1)
  ), origin="1970-01-1"
)
plrdata$I2 <- plrdata$local_channel_Qin
zcols = c("local_channel_last_S", "local_channel_Storage", "I2", "local_channel_demand", "local_channel_Qout", "local_channel_its")
zdata <- as.data.frame(plrdata[ddates,zcols])
names(zdata) <- c("last_S", "Storage", "Qin", "demand", "Qout", "its")
target_start = "1999-12-16"
target_ix = which(index(plrdata) == target_start)
target_day_range = 5
tdata <- as.data.frame(plrdata[(target_ix - target_day_range):(target_ix + target_day_range),zcols])
plot(tdata$local_channel_Qout, type='l', lwd=5)

# facility Norton
fndata <- om_get_rundata(247417, runid, site=omsite)
fn_stats <- om_quantile_table(
  fndata, 
  metrics = c(
    "wd_mgd",
    "discharge_mgd"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
kable(fn_stats,'markdown')


deets <- as.data.frame(mdata[,c(
  "year", "month", "day", "Qin", "Qout", "target", "flowby", "flowby_cov", "min_release", "release"
)])


tribs = om_get_rundata(247403, runid, site=omsite)
bsg_data <- om_get_rundata(247415, runid, site=omsite)
bc_data <- om_get_rundata(352078, runid, site=omsite) 
bbc_data <- om_get_rundata(352123, runid, site=omsite) 

quantile(bc_data$child_wd_mgd)
quantile(bsg_data$wd_mgd)
quantile(bbc_data$ps_mgd)
quantile(bbc_data$wd_mgd)
quantile(bc_data$ps_mgd)
# note: example of a good use of broadcasts, this object has a separate broadcast to send 
#       ps_bsg_wwtp_mgd to the parent container, as ps_nextdown_mgd using the hydroTools channel
#       which results in the point source hitting the 3rd downstream container, which is the proper destination.

quantile(bc_data$ps_bsg_wwtp_mgd) 
quantile(bbc_data$ps_nextdown_mgd)


deets <- as.data.frame(mdata[,c(
  "year", "month", "day", "Qin", "Qout", "target", "flowby", "flowby_cov", "min_release", "release"
)])



## Runoff QA
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
  'runid' = c('runid_0', 'runid_2', 'runid_401','runid_0', 'runid_401'),
  'metric' = c('Runit','Runit','Runit', 'l90_RUnit', 'l90_RUnit'),
  'runlabel' = c('Runit_0', 'Runit_2', 'Runit_401', 'l90_RUnit_0', 'l90_RUnit_401')
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
pr_rodata = fn_extract_basin(ro_data,'TU3_8880_9230')



toaID = 353105 # Town of A reservoir
toaData <- om_get_rundata(toaID, 600, site = omsite)
View(toaData[ddates,c("local_channel_Qin","local_channel_Qout", "Qtrib", "Qlocal", "Qout",
                      "local_channel_Storage","local_channel_last_S",
                      "wd_mgd", "ps_mgd")])
#Where does the minimum storage occur?
index(toaData[which.min(toaData$impoundment_Storage),])
#Add dates and convert to data frame:
toaDataDF <- toaData
toaDataDF$thisdate <- as.Date(index(toaDataDF))
toaDataDF <- as.data.frame(toaDataDF)
#Isolate the climate year of the minimum storage:
toaDataDF_drought <- toaDataDF[toaDataDF$thisdate >= as.Date("2007-04-01") & 
                                 toaDataDF$thisdate <= as.Date("2008-03-31"),]
#Create a plot tat shows the storage vs. inflow into the impoundment
png(paste0(export_path,"refillPlot.PNG"),width = 6,height = 4,units = "in",res = 300)
par(mar=c(3, 4, 1, 6))
plot(as.Date(toaDataDF_drought$thisdate),
     toaDataDF_drought$impoundment_Storage,
     type = "l", axes = FALSE, bty = "n",
     xlab = "", ylab = "",col = "darkblue",
     lwd = 2)
axis(side = 4, at = pretty(range(toaDataDF_drought$impoundment_Storage)))
mtext("Imp. Storage (MG)", side = 4, line = 3, cex.lab = 1)
par(new = TRUE)
# plot(as.Date(toaDataDF_drought$thisdate),
#      toaDataDF_drought$Qreach,
#      type = "l",lwd = 2,xlab = "", ylab = "Powell River Flow (cfs)")
plot(as.Date(toaDataDF_drought$thisdate),
     (toaDataDF_drought$impoundment_Qin + 
        toaDataDF_drought$ps_refill_pump_mgd * 1000000 * 231 / 12 / 12 / 12 / 24 / 3600),col = "black",type = "l",
     ylab = "Imp. Inflow + Refill (cfs)",xlab = "",lwd = 2)
points(as.Date(toaDataDF_drought$thisdate[toaDataDF_drought$Qreach <= 8]),
       rep(0,length(toaDataDF_drought$Qreach[toaDataDF_drought$Qreach <= 8])),
       col = "red",pch = 16)
lines(as.Date(toaDataDF_drought$thisdate),
      toaDataDF_drought$impoundment_Qin,lwd = 2,col = "darkgreen")
par(new = TRUE)
legend("topleft",c("Imp. Inflow + Refill (cfs)","Imp. Storage (MG)","Imp. Qin (cfs)"),col = c("black","darkblue","darkgreen"),
       lty = 1, lwd = 1,y.intersp = 0.75,cex = 0.5)
dev.off()

