# install_github("HARPGroup/hydro-tools", force=TRUE)
library("hydrotools")
library('zoo')
library("knitr")
basepath='/var/www/R';
source("/var/www/R/config.R")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R")


# Set up our data source
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw)

felid <- 347352
relid <- 351963
roelid <- 351959 

bcdatf <- om_get_rundata(felid, 401, site=omsite)
bcdatfd <- as.data.frame(bcdatf)
quantile(bcdatfd$impoundment_use_remain_mg, probs=c(0.01,0.02,0.03,0.04,0.05,0.1,0.25))
quantile(bcdatfd$available_mgd, probs=c(0.01,0.02,0.03,0.04,0.05,0.1,0.25))
quantile(bcdatfd$base_demand_mgd)
quantile(bcdatfd$unmet_demand_mgd, probs=c(0.99,0.98,0.97,0.96,0.95,0.9,0.75))
quantile(bcdatfd$wd_mgd)


bcdatr <- om_get_rundata(relid, 600, site=omsite)
quantile(bcdatr$impoundment_demand * 1.547)
quantile(bcdatr$impoundment_Qout)
quantile(bcdatr$wd_imp_mgd)
quantile(bcdatr$impoundment_Qin)
quantile(bcdatr$child_wd_mgd)
bcdatr$pct_use_remain <- 3.07*bcdatr$impoundment_use_remain_mg / bcdatr$impoundment_max_usable

bcdatr_stats <- om_quantile_table(
  bcdatr, 
  metrics = c(
    "impoundment_demand","impoundment_demand_met_mgd",'impoundment_lake_elev', 'impoundment_release',
    "impoundment_Storage","impoundment_use_remain_mg","impoundment_days_remaining",
    "impoundment_Qin","impoundment_Qout", "local_channel_Qin", "local_channel_Qout",
    "Runit_mode", "release_dgif", "release_rwsa","wd_mgd", "pct_use_remain"
),rdigits = 2)
kable(bcdatr_stats,'markdown')


fn_plot_impoundment_flux(bcdatr,"pct_use_remain","impoundment_Qin", "impoundment_Qout", "wd_mgd")


quantile(bcdatr$wd_mgd)
quantile(bcdatr$release)
quantile(bcdatr$release_dgif)
quantile(bcdatr$release_rwsa)

# 2020 sees the all-time low modeled storage, running out of water.
# the ro data is NOT zero, so the simulation is working
bcdatro <- as.data.frame(om_get_rundata(roelid, 600, site=omsite))
bc_weekly_ro <- sqldf("select year, week, avg(Runit) from bcdatro group by year, week order by year, week")
# is the simulation accurate?  Loook at USGS Mechums 

# USGS gage verify
gage_number = '02031000'
startdate = '1984-10-01'
enddate = '2020-09-30'
# Get and format gage data
gage_data <- gage_import_data_cfs(gage_number, startdate, enddate)
#gage_data <- as.zoo(gage_data, as.POSIXct(gage_data$date,tz="EST"))
gage_data <- as.data.frame(gage_data)
#mode(gage_data) <- 'numeric'
gage_data$year <- year(gage_data$date)
gage_data$month <- month(gage_data$date)
gage_data$week <- week(gage_data$date)
gage_data$Runit <- gage_data$flow / 95.3
bc_gage_weekly_ro <- sqldf("select year, week, avg(Runit) as Runit from gage_data group by year, week order by year, week")

om_flow_table(gage_data, 'flow')
bc_weekly_ro <- sqldf("select year, week, avg(Runit) as Runit from bcdatro group by year, week order by year, week")

bc_yearly <- sqldf(
  "select year, avg(local_channel_Qout), avg(Runit_mode) as Runit 
  from bcdatr 
  group by year
  order by year")

bc_cmp_ro <- sqldf(
  "select a.year, a.week, a.Runit as obs_runit, b.Runit as mod_runit,
    (b.Runit - a.Runit)/a.Runit as pct_error
  from bc_gage_weekly_ro as a
  left outer join bc_weekly_ro as b
  on (a.year = b.year and a.week = b.week)
  where b.Runit is not null
  group by a.year, a.week 
  order by a.year, a.week")

mean(bc_cmp_ro$obs_runit)
mean(bc_cmp_ro$mod_runit)

plot(bc_cmp_ro$obs_runit ~ bc_cmp_ro$mod_runit)
plot(bc_cmp_ro$obs_runit, col="blue")
points(bc_cmp_ro$mod_runit, col="black")

om_quantile_table(
  bc_cmp_ro, 
  metrics = c(
    "obs_runit", "mod_runit"
  ),rdigits = 2)