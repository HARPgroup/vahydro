library("knitr")
library("kableExtra")
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R") #Used until fac_utils is packaged
library()

basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#source("/var/www/R/config.local.private");
source(paste(basepath,'config.R',sep='/'))
ds = RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)

# Tinker Intake
elid_tinker = 328319
dat_tinker_222 <- om_get_rundata(elid_tinker , 222, site = omsite)
dat_tinker_222av <- om_flow_table(dat_tinker_222, 'avail_tinker')
kable(dat_tinker_222av, 'markdown')

# Salem WTP (Roanoke River Intake)
elid_salem = 306768
# dat_salem_616 <- om_get_rundata(elid_salem , 616, site = omsite)
# dat_salem_616av <- om_flow_table(dat_salem_616, 'available_mgd')
dat_salem_222 <- om_get_rundata(elid_salem , 222, site = omsite)
dat_salem_222av <- om_flow_table(dat_salem_222, 'available_mgd')
# kable(dat_salem_222av)
kable(dat_salem_222av, 'markdown')

# Spring Hollow (Roanoke River Intake)
elid_SH = 328321
dat_SH_222 <- om_get_rundata(elid_SH , 222, site = omsite)
dat_SH_222av <- om_flow_table(dat_SH_222, 'available_mgd')
kable(dat_SH_222av, 'markdown')


