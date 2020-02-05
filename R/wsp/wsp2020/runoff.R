# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Now do the stuff 343332 210327 Occ: 229569
elid = 207935     	
runid = 11
tyear = '1997'

omsite = site <- "http://deq2.bse.vt.edu"
finfo <- fn_get_runfile_info( elid, runid, scenid = 37,
  site = "http://deq2.bse.vt.edu"
)
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = TRUE);

dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
boxplot(as.numeric(dat$Runit) ~ dat$year, ylim=c(0,3))
# QA
dat2k7 <- window(dat, start = as.Date(paste0(tyear,"-01-01") ), end = as.Date(paste0(tyear, "-12-31") ) );
Rt <- mean(as.numeric(dat2k7$Runit) )
Rt
Rt <- mean(as.numeric(dat2k7$Qcbp6_unit) )
Rt

datdf <- as.data.frame(dat)
Qyear <- sqldf("select year, avg(Runit) from datdf group by year order by year")

