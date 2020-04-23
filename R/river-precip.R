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
elid = 207927       	
runid = 15

omsite = site <- "http://deq2.bse.vt.edu"
fn_hydro_runfile <- function(
  elid, runid, cached = FALSE, site = 'http://deq2.bse.vt.edu'
) {
  dat <- fn_get_runfile(elid, runid, cached)
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

dat11 <- fn_hydro_runfile(elid, 11)
dat14 <- fn_hydro_runfile(elid, 14)
dat15 <- fn_hydro_runfile(elid, 15)
dat16 <- fn_hydro_runfile(elid, 16)
plot(dat11$Runit ~ dat11$et_in)
points(dat14$Runit ~ dat14$et_in, col='blue')
points(dat15$Runit ~ dat15$et_in, col='red')
points(dat16$Runit ~ dat16$et_in, col='green')

datdf <- as.data.frame(dat)

modat <- sqldf(
  "select year, month, 
     sum(precip_in) as precip_in, 
     avg(Qout)as Qout
   from datdf 
   group by year, month"
)

yrdat <- sqldf(
  "select year,
     sum(precip_in) as precip_in, 
     median(precip_in) as pmed, 
     min(precip_in) as pmin, max(precip_in) as pmax,
     avg(Qout) as Qout, min(Qout) as minQ, max(Qout) as maxQ
   from modat 
   group by year"
)
yma = max(yrdat$pmax)

plot(pmin ~ year, dat=yrdat, ylim=c(0,yma))
points(pmax ~ year, dat=yrdat, col="blue")
pminreg <- lm(pmin ~ year, dat=yrdat)
pmedreg <- lm(pmed ~ year, dat=yrdat)
pmaxreg <- lm(pmax ~ year, dat=yrdat)
abline(pminreg, col="red")
abline(pmaxreg, col="blue")

summary(pminreg)
summary(pmaxreg)

