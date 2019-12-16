# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Now do the stuff
#pid = 4823212
#elid = 233571	
#runid = 11
argst <- commandArgs(trailingOnly=T)
pid <- as.integer(argst[1])
elid <- as.integer(argst[2])
runid <- as.integer(argst[3])

omsite = "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);

dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
boxplot(as.numeric(dat$Runit) ~ dat$year, ylim=c(0,3))
# QA
dat2k7 <- window(dat, start = as.Date("2007-01-01"), end = as.Date("2007-12-31"));
R2k7 <- mean(as.numeric(dat2k7$Runit) )

# get feature attached to this element id using REST
element <- getProperty(list(pid=pid), base_url, prop)
# Post up a run summary for this runid
scen.propname<-paste0('runid_', runid)

# GETTING SCENARIO PROPERTY FROM VA HYDRO
sceninfo <- list(
  varkey = 'om_scenario',
  propname = scen.propname,
  featureid = pid,
  entity_type = "dh_properties"
)
scenprop <- getProperty(sceninfo, site, scenprop)
# POST PROPERTY IF IT IS NOT YET CREATED
if (identical(scenprop, FALSE)) {
  # create
  sceninfo$pid = NULL
} else {
  sceninfo$pid = scenprop$pid
}
scenprop = postProperty(inputs=sceninfo,base_url=base_url,prop)
scenprop <- getProperty(sceninfo, site, scenprop)

# POSTING METRICS TO SCENARIO PROPERTIES ON VA HYDRO
r2k7prop <- vahydro_post_metric_to_scenprop(scenprop$pid, 'om_class_Constant', NULL, 'R2k7', R2k7, site, token)
