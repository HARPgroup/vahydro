################################
#### *** Impoundment
################################
library(pander);
library(httr);
library(hydroTSM);
library(sqldf);
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.local.private',sep='/'));
source(paste(hydro_tools,"VAHydro-2.0/rest_functions.R", sep = "/")); 
source(paste(hydro_tools,"VAHydro-1.0/fn_vahydro-1.0.R", sep = "/"));  
source(paste(hydro_tools,"LowFlow/fn_iha.R", sep = "/"));  
#retrieve rest token - DISABLED
#fxn_locations <-  '/usr/local/home/git/r-dh-ecohydro/ELFGEN';
#source(paste(fxn_locations,"elf_rest_token.R", sep = "/"));   
#elf_rest_token (site, token)
# to run in knit'r, need to preload token
#token = 'W-THcwwvstkINd9NIeEMrmNRls-8kVs16mMEcN_-jOA';
source(paste(hydro_tools,"auth.private", sep = "/"));#load rest username and password, contained in auth.private file
token <- rest_token(site, token, rest_uname, rest_pw);
options(timeout=1200); # set timeout to twice default level to avoid abort due to high traffic

# Camp Creek - 279187, South Anna - 207771
elid = 231301
runid = 11

omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE);
amn <- 10.0 * mean(as.numeric(dat$Qin))

dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
boxplot(as.numeric(dat$Qin) ~ dat$year, ylim=c(0,amn))
boxplot(as.numeric(dat$Qout) ~ dat$year, ylim=c(0,amn))

datdf <- as.data.frame(dat)
modat <- sqldf("select month, avg(wd_mgd) as wd_mgd from datdf group by month")
barplot(wd_mgd ~ month, data=modat)


fdc(dat[,c('Qin', 'Qout')], main=paste("Flow Duration"), log='y', xlab="Flow Exceedence",
    ylab="Q cfs", verbose=FALSE
);
