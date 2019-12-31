# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Now do the stuff 343332 343742
elid = 345162    	
runid = 14

omsite = site <- "http://deq2.bse.vt.edu"
finfo <- fn_get_runfile_info(
  elid, runid, scenid = 37,
  site = "http://deq2.bse.vt.edu"
)
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);
dat$Runit <- as.numeric(dat$Qout) / as.numeric(dat$area_sqmi)
dat <- window(dat, start = as.POSIXct("1984-10-01"), end = as.POSIXct("2000-09-30"));
boxplot(as.numeric(dat$Runit) ~ dat$year, ylim=c(0,3))
# QA
dat1997 <- window(dat, start = as.POSIXct("1997-01-01"), end = as.POSIXct("1997-12-31"));
R1997 <- mean(as.numeric(dat1997$Runit) )
R199sd <- sd(as.numeric(dat1997$Runit) )

R1997
R199sd
plot(as.numeric(dat1997$Qout), ylim=c(0,250))
