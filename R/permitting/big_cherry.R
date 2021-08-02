library('hydrotools')
library('zoo')
basepath='/var/www/R'
source('/var/www/R/config.R')
###############################################################################################

runid <- 401
runid <- 201
runid <- 6011
runid <- 6012

#FACILITY MODEL
dat.fac <- om_get_rundata(elid = 247415, runid = runid, site = omsite)
dat.fac <- data.frame(dat.fac)
# dat.fac[0:200,c('available_mgd','Qintake','impoundment_release','Qlocal_below_bc')]
# dat.fac[0:200,c('vwp_prop_base_mgd')]
# dat.fac[0:200,c('wd_mgd','adj_demand_mgd','Qintake','flowby','impoundment_release','Qlocal_below_bc','bc_release_cfs')]

dat.fac[0:200,c('bc_release_cfs','adj_demand_mgd','flowby','Qlocal_below_bc')]
tail(dat.fac[0:200,c('bc_release_cfs','adj_demand_mgd','flowby','Qlocal_below_bc')])
dat.fac[0:length(dat.fac[,1]),c('wd_mgd')]

#BIG CHERRY MODEL
dat.rseg.BC <- om_get_rundata(352078, runid, site = omsite)
dat.rseg.BC <- data.frame(dat.rseg.BC)
# dat.rseg.BC[0:200,c('impoundment_Qout','bc_release_cfs','impoundment_days_remaining','bc_demand_mgd','Qlocal_below_bc')]



