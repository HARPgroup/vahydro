# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Camp Creek - 279187, South Anna - 207771
elid = 209791
runid = 14

omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);
amn <- 10.0 * mean(as.numeric(dat$area))

dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
boxplot(as.numeric(dat$Qout) ~ dat$year, ylim=c(0,amn))
boxplot(as.numeric(dat$Qout) ~ dat$month, ylim=c(0,amn))
boxplot(as.numeric(dat$Runit) ~ dat$month, ylim=c(0,10))

datdf <- as.data.frame(dat)
modat <- sqldf("select month, avg(wd_mgd) as wd_mgd, avg(wd_cumulative_mgd) as wd_cumulative_mgd from datdf group by month")
barplot(wd_cumulative_mgd ~ month, data=modat)
barplot(wd_mgd ~ month, data=modat)
