# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Now do the stuff 343332 210327 Occ: 229569
elid = 251349       	
runid = 13
tyear = '1997'

dat <- om_get_rundata(elid,11)
boxplot(as.numeric(dat$Runit) ~ dat$year, ylim=c(0,3))
dat <- om_get_rundata(elid,12)
boxplot(as.numeric(dat$Runit) ~ dat$year, ylim=c(0,3))
dat <- om_get_rundata(elid,13)
boxplot(as.numeric(dat$Runit) ~ dat$year, ylim=c(0,3))
# QA
dat2k7 <- window(dat, start = as.Date(paste0(tyear,"-01-01") ), end = as.Date(paste0(tyear, "-12-31") ) );
Rt <- mean(as.numeric(dat2k7$Runit) )
Rt
Rt <- mean(as.numeric(dat2k7$Qcbp6_unit) )
Rt

datdf <- as.data.frame(dat)
Qyear <- sqldf("select year, avg(Runit) from datdf group by year order by year")

