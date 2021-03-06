# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Camp Creek - 279191
elid = 241783
runid = 13

omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);
mode(dat) <- 'numeric'
amn <- 10.0 * mean(as.numeric(dat$Qout))

dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));

plot(as.numeric(dat$Qout), ylim=c(0,amn))

boxplot(as.numeric(dat$Qout) ~ dat$year, ylim=c(0,amn))
boxplot(as.numeric(dat$Qin) ~ dat$month, ylim=c(0,amn))
boxplot(as.numeric(dat$Qout) ~ dat$month, ylim=c(0,amn))
boxplot(as.numeric(dat$Runit) ~ dat$month, ylim=c(0,10))

ddat <- window(dat, start = as.Date("2002-08-01"), end = as.Date("2002-09-30"));
ddatdf <- as.data.frame(ddat)
dmx = max(ddat$Qout)
plot(ddat$Qout, ylim=c(0,dmx))
lines(ddat$Qin, col='purple')
lines(ddat$demand, col='orange')
lines(ddat$demand + ddat$rejected_demand_mgd * 1.547, col='blue')
lines(ddat$rejected_demand_mgd * 1.547, col='red')

quantile(dat$Qout, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$Qin, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$demand, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$wd_mgd, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$rejected_demand_mgd, c(0.9,0.95, 0.97,0.98,0.99, 1.0))
quantile(dat$rejected_demand_pct, c(0.9,0.95, 0.97,0.98,0.99, 1.0))
