# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Camp Creek - 279187, South Anna - 207771, James River - 214907, Rapp above Hazel confluence 257471
# Rapidan above Rapp - 258123
elid = 303684       	
runid = 13

omsite = site <- "http://deq2.bse.vt.edu"
fn_hydro_runfile <- function(
  elid, runid, cached = FALSE, site = 'http://deq2.bse.vt.edu'
) {
  dat <- fn_get_runfile(elid, runid, 37, site, cached)
  syear = min(dat$year)
  eyear = max(dat$year)
  if (syear != eyear) {
    sdate <- as.Date(paste0(syear,"-10-01"))
    edate <- as.Date(paste0(eyear,"-09-30"))
  } else {
    sdate <- as.Date(paste0(syear,"-01-01"))
    edate <- as.Date(paste0(eyear,"-12-31"))
  }
  dat <- window(dat, start = sdate, end = edate);
  mode(dat) <- 'numeric'
  return(dat)
}

dat <- fn_hydro_runfile(elid, runid)

