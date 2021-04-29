library(pander);
library(httr);
library(hydroTSM);
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

# Local Runoff Inflows container
elid = 258615
runid = 601

omsite = site <- "http://deq2.bse.vt.edu"
dat <-  om_get_rundata(elid, runid)
boxplot(as.numeric(dat$Runit) ~ dat$year, ylim=c(0,3))
quantile(dat$Runit)

# Individual land river seg
elid = 343864 # 258615
runid = 401

omsite = site <- "http://deq2.bse.vt.edu"
dat <-  om_get_rundata(elid, runid)
dat$Runit <- dat$Qout / dat$area_sqmi
boxplot(as.numeric(dat$Runit) ~ dat$year, ylim=c(0,3))
quantile(dat$Runit)
