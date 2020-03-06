# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Camp Creek - 279191
elid = 236595
runid = 208

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

quantile(dat$Qout, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$Qin, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$demand, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$wd_mgd, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$rejected_demand_mgd, c(0.9,0.95, 0.97,0.98,0.99, 1.0))
quantile(dat$rejected_demand_pct, c(0.9,0.95, 0.97,0.98,0.99, 1.0))
