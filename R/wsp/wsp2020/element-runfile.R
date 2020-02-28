# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Now do the stuff
elid = 211837 #	235379 # 320983  # 236079  # 278660 #345486 #344054     	
runid = 18

omsite = site <- "http://deq2.bse.vt.edu"
finfo <- fn_get_runfile_info( elid, runid, scenid = 37,
                              site = "http://deq2.bse.vt.edu"
)
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE)
mode(dat) <- 'numeric'
mean(as.numeric(dat$Qout) )
quantile(dat$wd_mgd )
quantile(dat$max_mgd )
