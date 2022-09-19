###############################################
# GET dat (see https://github.com/HARPgroup/om/blob/master/R/summarize/waterSupplyModelNode.R)
###############################################
# ----------------------------------------------
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
#
#site <- base_url    #Specify the site of interest, either d.bet OR d.dh, taken from the config.R
# this is now set in config.local.R
#
source(paste(om_location,'R/summarize','rseg_elfgen.R',sep='/'))
library(stringr)
# dirs/URLs
save_directory <- "/var/www/html/data/proj3/out"
library(hydrotools)
# authenticate
ds <- RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)


# # Read Args
# argst <- commandArgs(trailingOnly=T)
# pid <- as.integer(argst[1])
# elid <- as.integer(argst[2])
# runid <- as.integer(argst[3])
# Read Args
pid <- 6540930 # Rseg model "South Fork Powell River - Below Big Cherry Reservoir"
elid <- 352123 # om_element_connection "South Fork Powell River - Below Big Cherry Reservoir"
runid <- 400
# runid <- 600
save_url <- "C:/Users/nrf46657/Desktop/VWP Modeling/Big Stone Gap WTP/September2022_Coordination"

finfo <- fn_get_runfile_info(site= omsite,elid, runid)
remote_url <- finfo$remote_url
# Note: when we migrate to om_get_rundata()
# we must insure that we do NOT use the auto-trim to water year
# as we want to have the model_run_start and _end for scenario storage
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE)
mode(dat) <- 'numeric'

# Hourly to Daily flow timeseries
#dat = aggregate(
#  dat,
#  as.POSIXct(
#    format(
#      time(dat),
#      format='%Y/%m/%d'),
#    tz='UTC'
#  ),
#  'mean'
#)
syear = as.integer(min(dat$year))
eyear = as.integer(max(dat$year))
model_run_start <- min(dat$thisdate)
model_run_end <- max(dat$thisdate)
if (syear < (eyear - 2)) {
  sdate <- as.Date(paste0(syear,"-10-01"))
  edate <- as.Date(paste0(eyear,"-09-30"))
  flow_year_type <- 'water'
} else {
  sdate <- as.Date(paste0(syear,"-02-01"))
  edate <- as.Date(paste0(eyear,"-12-31"))
  flow_year_type <- 'calendar'
}
dat <- window(dat, start = sdate, end = edate);
mode(dat) <- 'numeric'
scen.propname<-paste0('runid_', runid)

# GETTING SCENARIO PROPERTY FROM VA HYDRO
sceninfo <- list(
  varkey = 'om_scenario',
  propname = scen.propname,
  featureid = pid,
  entity_type = "dh_properties",
  bundle = "dh_properties"
)
scenprop <- RomProperty$new( ds, sceninfo, TRUE)
scenprop$startdate <- model_run_start
scenprop$enddate <- model_run_end

# POST PROPERTY IF IT IS NOT YET CREATED
# if (is.na(scenprop$pid) | is.null(scenprop$pid) ) {
#   # create
#   scenprop$save(TRUE)
# }

# Post link to run file
# vahydro_post_metric_to_scenprop(scenprop$pid, 'external_file', remote_url, 'logfile', NA, ds)

# does this have an impoundment sub-comp and is imp_off = 0?
cols <- names(dat)
imp_off <- NULL# default to no impouhd
if ("imp_off" %in% cols) {
  imp_off <- as.integer(median(dat$imp_off))
} else {
  if( (is.null(imp_off)) && ("impoundment" %in% cols) ) {
    # imp_off is NOT in the cols but impoundment IS
    # therefore, we assume that the impoundment is active by intention
    # and that it is a legacy that lacked the imp_off convention
    imp_off = 0
  } else {
    imp_off <- 1 # default to no impoundment
  }
}
wd_mgd <- mean(as.numeric(dat$wd_mgd) )
if (is.na(wd_mgd)) {
  wd_mgd = 0.0
}
wd_imp_child_mgd <- mean(as.numeric(dat$wd_imp_child_mgd) )
if (is.na(wd_imp_child_mgd)) {
  wd_imp_child_mgd = 0.0
}
# combine these two for reporting
wd_mgd <- wd_mgd + wd_imp_child_mgd

wd_cumulative_mgd <- mean(as.numeric(dat$wd_cumulative_mgd) )
if (is.na(wd_cumulative_mgd)) {
  wd_cumulative_mgd = 0.0
}
ps_mgd <- mean(as.numeric(dat$ps_mgd) )
if (is.na(ps_mgd)) {
  ps_mgd = 0.0
}
ps_cumulative_mgd <- mean(as.numeric(dat$ps_cumulative_mgd) )
if (is.na(ps_cumulative_mgd)) {
  ps_cumulative_mgd = 0.0
}
ps_nextdown_mgd <- mean(as.numeric(dat$ps_nextdown_mgd) )
if (is.na(ps_nextdown_mgd)) {
  ps_nextdown_mgd = 0.0
}
Qout <- mean(as.numeric(dat$Qout) )
if (is.na(Qout)) {
  Qout = 0.0
}
net_consumption_mgd <- wd_cumulative_mgd - ps_cumulative_mgd
if (is.na(net_consumption_mgd)) {
  net_consumption_mgd = 0.0
}
dat$Qbaseline <- dat$Qout +
  (dat$wd_cumulative_mgd - dat$ps_cumulative_mgd ) * 1.547
# alter calculation to account for pump store
if (imp_off == 0) {
  if("impoundment_Qin" %in% cols) {
    if (!("ps_cumulative_mgd" %in% cols)) {
      dat$ps_cumulative_mgd <- 0.0
    }
    dat$Qbaseline <- dat$impoundment_Qin +
      (dat$wd_cumulative_mgd - dat$ps_cumulative_mgd) * 1.547
  }
}

Qbaseline <- mean(as.numeric(dat$Qbaseline) )
if (is.na(Qbaseline)) {
  Qbaseline = Qout +
    (wd_cumulative_mgd - ps_cumulative_mgd ) * 1.547
}
# The total flow method of CU calculation
consumptive_use_frac <- 1.0 - (Qout / Qbaseline)
dat$consumptive_use_frac <- 1.0 - (dat$Qout / dat$Qbaseline)
# This method is more appropriate for impoundments that have long
# periods of zero outflow... but the math is not consistent with elfgen
daily_consumptive_use_frac <-  mean(as.numeric(dat$consumptive_use_frac) )
if (is.na(daily_consumptive_use_frac)) {
  daily_consumptive_use_frac <- 1.0 - (Qout / Qbaseline)
}
datdf <- as.data.frame(dat)









###############################################
# RSEG FDC
###############################################
base_var <- "Qbaseline" #BASE VARIABLE USED IN FDCs AND HYDROGRAPHS
comp_var <- "Qout" #VARIABLE TO COMPARE AGAINST BASE VARIABLE, DEFAULT Qout

# FOR TESTING 
# save_directory <- 'C:/Users/nrf46657/Desktop/GitHub/om/R/summarize'
datpd <- datdf
fname <- paste(
  save_directory,
  paste0(
    'fdc.',
    elid, '.', runid, '.png'
  ),
  sep = '/'
)
# FOR TESTING 
# save_url <- save_directory
furl <- paste(
  save_url,
  paste0(
    'fdc.',
    elid, '.', runid, '.png'
  ),
  sep = '/'
)


# png(fname, width = 700, height = 700)
png(furl, width = 700, height = 700)
legend_text = c("Baseline Flow","Scenario Flow")
fdc_plot <- hydroTSM::fdc(
  cbind(datpd[names(datpd)== base_var], datpd[names(datpd)== comp_var]),
  # yat = c(0.10,1,5,10,25,100,400),
  # yat = c(round(min(datpd),0),500,1000,5000,10000),
  # yat = seq(round(min(datpd),0),round(max(datpd),0), by = 500),
  # yat = seq(round(min(c(datpd$Qbaseline,datpd$Qout)),0),round(max(c(datpd$Qbaseline,datpd$Qout)),0), by = 10),
  yat = c(0.10,1,5,10,25,100,400),
  leg.txt = legend_text,
  main=paste("Flow Duration Curve","\n","(Model Flow Period ",sdate," to ",edate,")",sep=""),
  ylab = "Flow (cfs)",
  # ylim=c(1.0, 5000),
  # ylim=c(min(datpd), max(datpd)),
  ylim=c(min(c(datpd$Qbaseline,datpd$Qout)), max(c(datpd$Qbaseline,datpd$Qout))),
  cex.main=1.75,
  cex.axis=1.50,
  leg.cex=2,
  cex.sub = 1.2
)
dev.off()


# datpd.Qbaseline = datpd[names(datpd)== base_var]
# datpd.Qout = datpd[names(datpd)== comp_var]
# 
# min(datpd.Qbaseline)
# min(datpd.Qout)
# 
# min(c(datpd$Qbaseline,datpd$Qout))
# max(c(datpd$Qbaseline,datpd$Qout))



# print(paste("Saved file: ", fname, "with URL", furl))
# vahydro_post_metric_to_scenprop(scenprop$pid, 'dh_image_file', furl, 'fig.fdc', 0.0, ds)
###############################################
###############################################