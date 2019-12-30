# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Now do the stuff
elid = 343816    	
runid = 11

omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);

dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
boxplot(as.numeric(dat$Qunit) ~ dat$year, ylim=c(0,3))
# QA
dat1997 <- window(dat, start = as.Date("1997-01-01"), end = as.Date("1997-12-31"));
R1997 <- mean(as.numeric(dat1997$Qunit) )
R199sd <- sd(as.numeric(dat1997$Qunit) )

R1997
R199sd
plot(as.numeric(dat1997$Qout), ylim=c(0,250))
