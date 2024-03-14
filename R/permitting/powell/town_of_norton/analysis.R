basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library('DT')
library("hydrotools")

library(nhdplusTools)
#> USGS Support Package: https://owi.usgs.gov/R/packages.html#support
library(sf)
library("sqldf")
library("stringr")
library("rjson")

#########################
#Town of Norton:
#Subdivide the watershed - Get the NHD area for Town of Norton

#For identifying stream-watershed shape/GIS:
# Town of Norton intake
plat_imp = 36.916388888900; plon_imp = -82.626666666700 

#Find the drainage area of the NHD segments at and above the reservoir. Note
#that this takes the entire NHD segment the coords fall in and all upstream.
#Create an sf object
out_point_imp = sf::st_sfc(sf::st_point(c(plon_imp, plat_imp)), crs = 4326)
#Get the NHD segemnt that this point falls in
nhd_out_imp <- memo_get_nhdplus(out_point_imp)
#Find the total DA in miles
dasqmi_imp <- 0.386102 * nhd_out_imp$totdasqkm
dasqmi_imp
#Plot the basin
map_imp <- plot_nhdplus((list(nhd_out_imp$comid)), zoom = 14)

#map_imp creates a basin object. We can now get all nhd plus segments associated
#with that basin
basin <- get_nhdplus(map_imp$basin)
#From here, we could area weight traits, compare between subsheds, etc.

#The volume weight stage of the dam:
((3215.9-3155) * 182 + (3287.5-3215) * 202) / (182+202)
((3218-3155) * 200 + (3295.5-3215) * 277) / (200+277)


##########################
#Model Analysis runid 401
## Runoff QA
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw = rest_pw)

#The run id
runid <- 401
#The OM element connection ID of the Powell River Segment
plrpid <- 247367 
# Bengees Branch
elid = 353109
# Town of Norton facility model
felid = 247417 

# Town of Norton Facility Model
tonFacModel <- as.data.frame(om_get_rundata(felid, runid, site = omsite))
ton_stats <- om_quantile_table(
  tonFacModel, 
  metrics = c(
    "Qreach", "child_wd_mgd", "child_ps_mgd", "Runit_mode",
    "ps_other_mgd", "available_mgd",
    "impoundment_use_remain_mg", "fac_demand_mgd",
    "discharge_local_mgd"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
ton_stats

# Benges Branch - Town of Norton Reservoir
bbdata <- as.data.frame(om_get_rundata(elid, runid, site = omsite))
bb_stats <- om_quantile_table(
  bbdata, 
  metrics = c(
    "Qout", "Qtrib", "Qlocal", "local_channel_Qout",
    "wd_cumulative_mgd", "ps_mgd", "ps_cumulative_mgd", "ps_nextdown_mgd",
    "wd_upstream_mgd", "wd_mgd"
  ),
  quantiles=c(0,0.01,0.05,0.1,0.25, 0.5, 0.75, 1.0),
  rdigits = 2
)
bbdata
#Flow into the impoundment
bbdata$impoundment_local_inflow[1:20]
#Local inflow is equal to the impoundment DA multiplied by Runit
bbdata$Runit[1:20] * 0.8
#Flow out of the segment should be that from the local channel
bbdata$Qout[1:10]#Why are these NA?
#Local channel flow should be the impoundment Qout  with the drainage for the
#channel e.g. impoundment_Qout + (local_channel_area - impoundment_drainage_area
#- trib_area_sqmi) * Runit_mode  + 1.547 * child_ps_mgd
lcda <- unique(bbdata$local_channel_area)
impda <- unique(bbdata$impoundment_drainage_area)
tribda <- unique(bbdata$trib_area_sqmi)
unique(bbdata$child_ps_mgd)
bbdata$Qlocal[1:10]
bbdata$impoundment_Qout[1:10] + (lcda - impda - tribda) * bbdata$Runit_mode[1:10]
#Withdraw from facility model - MISSING
bbdata$wd_mgd[1:10]
bbdata$child_wd_mgd[1:10]


# Powell River Above Looney Creek
plrdata <- as.data.frame(om_get_rundata(plrpid, runid, site = omsite))
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
plr_stats


