################################
#### *** Water Supply Element
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
elid = 351450    
runid = 208

omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);
mode(dat) <- 'numeric'
amn <- 10.0 * mean(as.numeric(dat$Qriver))

dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
boxplot(as.numeric(dat$Qriver) ~ dat$year, ylim=c(0,amn))

datdf <- as.data.frame(dat)
modat <- sqldf("select month, avg(wd_mgd) as wd_mgd, avg(discharge_mgd) as ps_mgd from datdf group by month")
mot <- t(as.matrix(modat[,c('wd_mgd', 'ps_mgd')]) )
mode(mot) <- 'numeric'
barplot(
  mot,
  main="Monthly Mean Withdrawals",
  xlab="Month", 
  col=c("darkblue","darkgreen"),
  legend = c('Withdrawal', 'Discharge'), beside=TRUE
)

quantile(dat$adj_demand_mgd, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$base_demand_mgd, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$available_mgd, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$flowby, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$rejected_demand_pct, c(0.9,0.95, 0.97,0.98,0.99, 1.0))
quantile(dat$adj_demand_mgd, c(0.0,0.01,0.05, 0.1,0.2,0.3),na.rm=TRUE)
quantile(dat$wd_mgd, c(0.01,0.05, 0.1,0.2,0.3))

