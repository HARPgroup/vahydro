# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Now do the stuff
elid = 	236597 #297938 # 236079  # 278660 #345486 #344054     	
runid = 18

omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE)
mode(dat) <- 'numeric'
mean(dat$Qriver)
quantile(dat$Qriver, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$wd_last_mgd, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$wd_mgd, c(0.01,0.05, 0.1,0.2,0.3))
