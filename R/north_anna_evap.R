# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

#cbp6_link <- paste0(github_link, "/cbp6/code");
#source(paste0(cbp6_link,"/cbp6_functions.R"))
#source(paste(cbp6_link, "/fn_vahydro-1.0.R", sep = ''))
bechtel_url = 'http://deq1.bse.vt.edu:81/data/proj3/components/lake_anna/lake_anna_evap_wkly1.csv'
bechtel_raw_dat = read.csv(bechtel_url)

la_hist_url =  'http://deq1.bse.vt.edu:81/data/proj3/components/lake_anna/lake_anna_bechtel.csv'
la_hist_dat = read.csv(la_hist_url)
# Bechtel model
elid = 279185
runid = 11
bechtel_dat <- fn_get_runfile(elid, runid, site = omsite,  cached = TRUE);
mode(bechtel_dat) <- 'numeric'
# North Anna Impoundment model
elid = 207925
omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE, use_tz = 'UTC');
mode(dat) <- 'numeric'
amn <- 10.0 * mean(dat$Qin)
#syear = min(dat$year)
#eyear = max(dat$year)
syear = 1984
eyear = 2005 # so we don't have dat outside the bechtel model period
if (syear != eyear) {
  sdate <- as.Date(paste0(syear,"-10-01"))
  edate <- as.Date(paste0(eyear,"-09-30"))
} else {
  sdate <- as.Date(paste0(syear,"-02-01"))
  edate <- as.Date(paste0(eyear,"-12-31"))
}

dat <- window(dat, start = sdate, end = edate);
# Filter out when natevap is zero
dat <- dat[dat$whtf_natevap_mgd > 0]
# get the gage
gage <- gage_import_data_cfs('01671020', sdate, edate)
# get model at the gage
elid = 207885
runid = 11
model_gage <- fn_get_runfile(elid, runid, site = omsite,  cached = FALSE, use_tz = 'UTC');
mode(model_gage) <- 'numeric'

quantile(dat$whtf_natevap_mgd)
quantile(dat$whtf_evap12_mgd)
quantile(dat$whtf_evap123_mgd)

#dat$whtf_natevap_mgd = (as.numeric(dat$et_in) * 0.62473 * 13000 / 12.0) / 3.07
quadratic_model <- lm(
  dat$whtf_evap12_mgd ~ dat$whtf_natevap_mgd + I(dat$whtf_natevap_mgd^2)
)
#dat$whtf_natevap_mgd = (as.numeric(dat$et_in) * 0.62473 * 13000 / 12.0) / 3.07
summary(quadratic_model)

quadratic_model2 <- lm(
  dat$whtf_evap123_mgd ~ dat$whtf_natevap_mgd + I(dat$whtf_natevap_mgd^2)
)
#dat$whtf_natevap_mgd = (as.numeric(dat$et_in) * 0.62473 * 13000 / 12.0) / 3.07
summary(quadratic_model2)

plot(dat$whtf_natevap_mgd, dat$whtf_evap12_mgd, ylim=c(0,110))
points(dat$whtf_natevap_mgd, dat$whtf_evap123_mgd, col='orange')


breg <- lm(as.numeric(dat$whtf_evap12_mgd) ~ as.numeric(dat$et_in))

plot(dat$et_in, dat$whtf_evap12_mgd, ylim=c(0,110))
abline(breg)
loess.smooth(
  x, y, span = 2/3, degree = 1,
  family = c("symmetric", "gaussian"),
  evaluation = 50
)
lines(dat$et_in, dat$whtf_natevap_mgd, col = "tan")
# add quatratic function to the plot
order_id <- order(dat$whtf_natevap_mgd)
lines(x = as.numeric(dat$et_in)[order_id], 
      y = as.numeric(fitted(quadratic_model))[order_id],
      col = "red", 
      lwd = 2) 
lines(x = as.numeric(dat$et_in)[order_id], 
      y = as.numeric(fitted(quadratic_model2))[order_id],
      col = "purple", 
      lwd = 2) 
summary(breg)

boxplot( as.numeric(dat$wd12_mgd) ~ dat$month)

dat$br <- as.numeric(breg$coefficients['(Intercept)']) + as.numeric(breg$coefficients['as.numeric(dat$et_in)']) * dat$et_in
dat$qm <- ( as.numeric(quadratic_model$coefficients['(Intercept)']) 
  + as.numeric(quadratic_model$coefficients['dat$whtf_natevap_mgd']) 
  * dat$et_in 
  + as.numeric(quadratic_model$coefficients['I(dat$whtf_natevap_mgd^2)']) 
  * dat$whtf_natevap_mgd ^ 2 )
dat$qm2 <- ( as.numeric(quadratic_model2$coefficients['(Intercept)']) 
             + as.numeric(quadratic_model2$coefficients['dat$whtf_natevap_mgd']) 
             * dat$et_in 
             + as.numeric(quadratic_model2$coefficients['I(dat$whtf_natevap_mgd^2)']) 
             * dat$whtf_natevap_mgd ^ 2 )
datdf <- as.data.frame(dat)
modat <- sqldf("select month, avg(evap_mgd) as evap_mgd, avg(whtf_reg_mgd) as whtf_reg_mgd from datdf group by month")
anndat <- sqldf("select avg(evap_mgd) as evap_mgd, avg(whtf_reg_mgd) as whtf_reg_mgd from datdf")

mot <- t(as.matrix(modat[,c('evap_mgd', 'whtf_reg_mgd')]) )
mode(mot) <- 'numeric'
barplot(
  mot,
  main="Monthly Mean Evap",
  xlab="Month", 
  col=c("darkblue","darkgreen"),
  legend = c(
    paste('Natural Evap',round(anndat$evap_mgd,1)), 
    paste('WHTF Extra',round(anndat$whtf_reg_mgd,1))
  ), beside=TRUE
)


datdf <- as.data.frame(dat)
yrdat <- sqldf(
  "select year,
    round(avg(wd_mgd),2) as wd_mgd, 
    round(avg(release),2) as release, 
    round(avg(Qin),2) as Qin, 
    round(avg(Qout),2) as Qout, 
    round(min(Qout),2) as minout, 
    round(avg(evap_mgd),2) as evap_mgd, 
    round(min(days_remaining)) as min_days, 
    round(min(use_remain_mg),1) as use_remain_mg, 
    round(min(lake_elev),2) as lake_elev
  from datdf
  group by year
  order by year"
)
yrdat

#
dat <- zoo(dat, order.by = as.Date(index(dat), format="%Y-%m-%d h:i:s", tz ='UTC') )
flows <- zoo(as.numeric(as.character( dat$Qout )), order.by = as.Date(index(dat), tz ='UTC') );
la_elevs <- zoo(as.numeric(la_hist_dat$hist_lake_elev), order.by = as.Date(la_hist_dat$thisdate, format="%m/%d/%Y", tz ='UTC') )
gage <- zoo(gage, order.by = as.Date(gage$date, format="%Y-%m-%d", tz ='UTC') )
model_gage <- zoo(model_gage, order.by = as.Date(index(model_gage), format="%Y-%m-%d h:i:s", tz ='UTC') )


if (!is.null(flows)) {
  # this is the 90 day low flow, better for Drought of Record?
  loflows <- group2(flows);
  l90 <- loflows["90 Day Min"];
  ndx = which.min(as.numeric(l90[,"90 Day Min"]));
  l90_flow = round(loflows[ndx,]$"90 Day Min",1);
  l90_year = loflows[ndx,]$"year";
  
  #moflows <- aggregate(flows, function(tt) as.Date(as.yearmon(tt), na.rm = TRUE), mean);
  #ndx = which.min(moflows);
  #x2a <- aggregate(flows, as.Date(as.yearmon(flows), na.rm = TRUE), mean);
  #l90_flow = round(moflows[ndx],2);
  #l90_year = index(moflows[ndx]);
} else {
  l90_flow = 'na';
  l90_year = 1776;
}
# Now plot the historical and the modeled
datpd <- window(
  dat, 
  start = as.Date(paste0(l90_year,"-06-01") ), 
  end = as.Date(paste0(l90_year, "-10-30") )
);
elevpd <- window(
  la_elevs, 
  start = as.Date(paste0(l90_year,"-06-01") ), 
  end = as.Date(paste0(l90_year, "-10-30") )
);
par(mar = c(5,5,2,5))
plot(
#  datpd$lake_elev, 
  elevpd,
  col='red',
  ylim=c(240,255), 
  ylab="Reservoir Surface Elevation (ft. asl)"
)
lines(datpd$lake_elev,col='black')
lines(as.numeric(elevpd),col='orange')
par(new = TRUE)
plot(datpd$Qin,col='blue', axes=FALSE, xlab="", ylab="")
lines(datpd$Qout,col='green')
axis(side = 4)
mtext(side = 4, line = 3, 'Flow (cfs)')

# Now plot the historical and the modeled
datpd2k <- window(
  dat, 
  start = as.Date(paste0(2002,"-06-01") ), 
  end = as.Date(paste0(2002, "-10-30") )
);
elevpd2k <- window(
  la_elevs, 
  start = as.Date(paste0(2002,"-06-01") ), 
  end = as.Date(paste0(2002, "-10-30") )
);
gage2k <- window(
  gage, 
  start = as.Date(paste0(2002,"-06-01") ), 
  end = as.Date(paste0(2002, "-10-30") )
);
model_gage2k <- window(
  model_gage, 
  start = as.Date(paste0(2002,"-06-01") ), 
  end = as.Date(paste0(2002, "-10-30") )
);
bechtel2k <- window(
  bechtel_dat, 
  start = as.Date(paste0(2002,"-06-01") ), 
  end = as.Date(paste0(2002, "-10-30") )
);
par(mar = c(5,5,2,5))
plot(
  #  datpd2k$lake_elev, 
  elevpd2k,
  col='red',
  ylim=c(240,255), 
  ylab="Reservoir Surface Elevation (ft. asl)"
)
lines(elevpd2k,col='orange')
lines(datpd2k$lake_elev,col='black') 
par(new = TRUE)
plot(datpd2k$Qin,col='grey', axes=FALSE, xlab="", ylab="", ylim=c(-50,400))
#plot(datpd2k$Qin,col='grey', xlab="", ylab="")
lines(gage2k$flow,col='blue')
lines(datpd2k$Qout,col='green')
lines(model_gage2k$Qout,col='purple')
lines(bechtel2k$bechtel_inflow_cfs,col='yellow') 
axis(side = 4)
mtext(side = 4, line = 3, 'Flow (cfs)')
gage2kdf = as.data.frame(gage2k)

datpd2kdf <- as.data.frame(datpd2k)
pd2kdat <- sqldf(
  "select year, month,
    round(avg(wd_mgd),2) as wd_mgd, 
    round(avg(release),2) as release, 
    round(avg(Qin),2) as Qin, 
    round(avg(Qout),2) as Qout, 
    round(min(Qout),2) as minout, 
    round(avg(evap_mgd),2) as evap_mgd, 
    round(avg(whtf_reg_mgd ),2) as whtf_reg_mgd , 
    round(avg(whtf_natevap_mgd),2) as whtf_natevap_mgd, 
    round(min(days_remaining)) as min_days, 
    round(min(use_remain_mg),1) as use_remain_mg, 
    round(min(lake_elev),2) as lake_elev
  from datpd2kdf
  group by year, month
  order by year"
)
pd2kdat