# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Now do the stuff
elid = 351016  # 278660 #345486 #344054     	
runid = 11

omsite = site <- "http://deq2.bse.vt.edu"
# print out some run info 
fn_get_runfile_info(elid, runid, site= omsite)
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE)
mean(as.numeric(dat$Qout) ) / mean(as.numeric(dat$area_sqmi) )
mean(as.numeric(dat$for_agwo), na.rm = TRUE ) 
