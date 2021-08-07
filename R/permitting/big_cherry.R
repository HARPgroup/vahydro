library('hydrotools')
library('zoo')
basepath='/var/www/R';
source('/var/www/R/config.R');

datbc201 <- om_get_rundata(352078, 201, site = omsite)
datbc301 <- om_get_rundata(352078, 301, site = omsite)
datbc401 <- om_get_rundata(352078, 401, site = omsite)
datbc601 <- om_get_rundata(352078, 601, site = omsite)
datbc6011 <- om_get_rundata(352078, 6011, site = omsite)

datbcfac201 <- om_get_rundata(247415, 201, site = omsite)
datbcfac301 <- om_get_rundata(247415, 301, site = omsite)
datbcfac401 <- om_get_rundata(247415, 401, site = omsite)
datbcfac6011 <- om_get_rundata(247415, 6011, site = omsite)
 

datbc[200:250,c(wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
datbc[0:15,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]

