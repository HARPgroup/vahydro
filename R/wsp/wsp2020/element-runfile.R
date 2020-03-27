# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Now do the stuff
elid = 284801   	#347363 #297938 # 236079  # 278660 #345486 #344054     	
runid = 203

omsite = "http://deq2.bse.vt.edu"
finfo <- fn_get_runfile_info(elid, runid)
dat <- fn_get_runfile(elid, runid,site = "http://deq2.bse.vt.edu", cached = FALSE)
mode(dat) <- 'numeric'
mean(dat$Qreach)


quantile(dat$Qreach, c(0.01,0.05, 0.1,0.2,0.3))
quantile(dat$wd_last_mgd, c(0.01,0.05, 0.1,0.2,0.3, 0.75, 0.9))
quantile(dat$wd_mgd, c(0.01,0.05, 0.1,0.2,0.3, 0.75, 0.9))

