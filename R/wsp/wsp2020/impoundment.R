################################
#### *** Impoundment
################################
# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Camp Creek - 279187, South Anna - 207771
elid = 251331 
runid = 12

omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);
mode(dat) <- 'numeric'
amn <- 10.0 * mean(as.numeric(dat$Qin))

dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
mode(dat) <- 'numeric'
dat$precip_mgd <- (dat$area * dat$precip_in / 12.0 / 86400.0) * 28157.7; 
precip = mean(dat$precip_mgd, na.rm=TRUE);
et = mean(dat$evap_mgd, na.rm=TRUE)
netprecip = precip - et
netprecip

boxplot(as.numeric(dat$Qin) ~ dat$year, ylim=c(0,amn))
boxplot(as.numeric(dat$Qout) ~ dat$year, ylim=c(0,amn))

datdf <- as.data.frame(dat)
modat <- sqldf("select month, avg(wd_mgd) as wd_mgd, avg(demand) as demand from datdf group by month")
barplot(wd_mgd ~ month, data=modat)


datdf <- as.data.frame(dat, stringsAsFactors = FALSE)
modat <- sqldf(
  "select year, month, 
    round(avg(wd_mgd),2) as wd_mgd, 
    round(avg(release),2) as release, 
    round(avg(Qout),2) as Qin, 
    round(min(days_remaining)) as min_days, 
    round(min(use_remain_mg),1) as use_remain_mg, 
    round(min(evap_mgd),1) as evap_mgd, 
    round(min(lake_elev),2) as lake_elev
  from datdf 
  group by year, month
  order by year, month"
)
modat

datpd <- window(
  dat, 
  start = as.Date("2002-01-01"), 
  end = as.Date("2002-11-30")
);
datpdf <- as.data.frame(datpd)
modatpd <- sqldf(
  "select year, month, 
    round(avg(wd_mgd),2) as wd_mgd, 
    round(avg(release),2) as release, 
    round(avg(Qin),2) as Qin, 
    round(avg(Qout),2) as Qout, 
    round(min(Qout),2) as minout, 
    round(avg(evap_mgd),2) as evap_mgd, 
    round(avg(precip_mgd),2) as precip_mgd, 
    round(min(days_remaining)) as min_days, 
    round(min(use_remain_mg)) as use_remain_mg, 
    round(min(lake_elev),2) as lake_elev
  from datpdf 
  group by year, month
  order by year, month"
)
modatpd
plot(datpd$Qin, ylim=c(-0.1,15))
lines(datpd$Qout,col='blue')

par(mar = c(5,5,2,5))
plot(
  datpd$lake_elev, 
  ylim=c(245,255), 
  ylab="Reservoir Surface Elevation (ft. asl)"
)
par(new = TRUE)
plot(datpd$Qin,col='blue', axes=FALSE, xlab="", ylab="")
lines(datpd$Qout,col='green')
axis(side = 4)
mtext(side = 4, line = 3, 'Flow (cfs)')

yrdat <- sqldf(
  "select year,
    round(avg(wd_mgd),2) as wd_mgd, 
    round(avg(release),2) as release, 
    round(avg(Qin),2) as Qin, 
    round(avg(Qout),2) as Qout, 
    round(min(Qout),2) as minout, 
    round(min(days_remaining)) as min_days, 
    round(min(use_remain_mg)) as use_remain_mg, 
    round(min(lake_elev)) as lake_elev
  from datdf
  group by year
  order by year"
)
yrdat

fdc(dat[,c('Qin', 'Qout')], main=paste("Flow Duration"), log='y', xlab="Flow Exceedence",
    ylab="Q cfs", verbose=FALSE
);
