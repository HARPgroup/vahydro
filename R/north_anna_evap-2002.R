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
bechtel_url = 'http://deq2.bse.vt.edu/data/proj3/components/lake_anna/lake_anna_evap_wkly1.csv'
bechtel_raw_dat = read.csv(bechtel_url)

la_hist_url =  'http://deq2.bse.vt.edu/data/proj3/components/lake_anna/lake_anna_bechtel.csv'
la_hist_dat = read.csv(la_hist_url)
# Bechtel model
elid = 279185
runid = 201
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
syear = 2000
eyear = 2002 # so we don't have dat outside the bechtel model period
sdate <- as.Date(paste0(syear,"-10-01"))
edate <- as.Date(paste0(eyear,"-12-31"))
dat <- window(dat, start = sdate, end = edate);
# Filter out when natevap is zero
dat <- dat[dat$whtf_natevap_mgd > 0]
# get the gage
gage <- gage_import_data_cfs('01671020', sdate, edate)
# get model at the gage
elid = 207885
runid = 201
model_gage <- fn_get_runfile(elid, runid, site = omsite,  cached = FALSE, use_tz = 'UTC');
mode(model_gage) <- 'numeric'


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
lines(datpd2k$lake_elev,col='black') 
par(new = TRUE)
plot(datpd2k$Qin,col='grey', axes=FALSE, xlab="", ylab="", ylim=c(-50,400))
#plot(datpd2k$Qin,col='grey', xlab="", ylab="")
lines(gage2k$flow,col='blue')
lines(datpd2k$Qout,col='green')
lines(model_gage2k$Qout,col='purple')
lines(elevpd2k,col='orange')
lines(bechtel2k$bechtel_inflow_cfs,col='yellow') 
axis(side = 4)
mtext(side = 4, line = 3, 'Flow (cfs)')
gage2kdf = as.data.frame(gage2k)


plot(gage2k$flow,col='blue', ylim=c(-50,400))
lines(model_gage2k$Qout,col='purple')
plot(model_gage2k$Qout,col='purple', ylim=c(-50,400))

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
    round(min(area),1) as area, 
    round(min(lake_elev),2) as lake_elev
  from datpd2kdf
  group by year, month
  order by year"
)
pd2kdat