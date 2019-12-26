# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Now do the stuff
elid = 209767    	
runid = 14

omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);

dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
boxplot(as.numeric(dat$Runit) ~ dat$year, ylim=c(0,3))
# QA
dat2k7 <- window(dat, start = as.Date("2007-01-01"), end = as.Date("2007-12-31"));
R2k7 <- mean(as.numeric(dat2k7$Runit) )
R2k7sd <- sd(as.numeric(dat2k7$Runit) )