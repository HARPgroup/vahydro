# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Now do the stuff
elid = 	351939  # 236079  # 278660 #345486 #344054     	
runid = 11

omsite = site <- "http://deq2.bse.vt.edu"

source(paste('C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/hydro-tools/VAHydro-1.0','fn_vahydro-1.0.R',sep='/'))

dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE)
mean(as.numeric(dat$Qout))

tail(dat)
