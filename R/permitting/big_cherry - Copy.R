library('hydrotools')
library('zoo')
basepath='/var/www/R'
source('/var/www/R/config.R')

# datbc201 <- om_get_rundata(352078, 201)
# datbc301 <- om_get_rundata(352078, 301)
# datbc401 <- om_get_rundata(352078, 401, site = omsite)
# datbc401 <- data.frame(datbc401)
# datbc401[0:200,c('impoundment_days_remaining','bc_demand_mgd')]
# 
# datbc601 <- om_get_rundata(352078, 601)
# datbc6011 <- om_get_rundata(352078, 6011)
# 
# datbcfac201 <- om_get_rundata(247415, 201)
# datbcfac301 <- om_get_rundata(247415, 301)
# datbcfac401 <- om_get_rundata(247415, 401, site = omsite)
# datbcfac6011 <- om_get_rundata(247415, 6011)
#  
# 
# #datbc[200:250,c(wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
# #datbc[0:15,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
# 
# dat.belowbc.6011 <- om_get_rundata(elid = 352123, runid = 6011, site = omsite)
# dat.belowbc.6011 <- data.frame(dat.belowbc.6011)

###############################################################################################
#FACILITY MODEL
dat.bcfac.401 <- om_get_rundata(elid = 247415, runid = 401, site = omsite)
dat.bcfac.401[0:200,c('available_mgd','Qintake','impoundment_release','Qlocal_below_bc')]
dat.bcfac.401[0:200,c('vwp_prop_base_mgd')]
dat.bcfac.401[0:200,c('wd_mgd','Qintake','flowby','impoundment_release','Qlocal_below_bc','bc_release_cfs')]
dat.bcfac.401 <- data.frame(dat.bcfac.401)

#BIG CHERRY MODEL
datbc401 <- om_get_rundata(352078, 401, site = omsite)
datbc401 <- data.frame(datbc401)
datbc401[0:200,c('impoundment_Qout','bc_release_cfs','impoundment_days_remaining','bc_demand_mgd')]






