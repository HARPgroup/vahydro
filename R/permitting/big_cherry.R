library('hydrotools')
library('zoo')

# river
pid = 5831933
elid = 352078
runid = 6011 

# facility
pid = 4826467
elid = 247415
runid = 6014


datbc201 <- om_get_rundata(352078, 201, site = omsite)
datbc301 <- om_get_rundata(352078, 301, site = omsite)
datbc401 <- om_get_rundata(352078, 401, site = omsite)
datbc601 <- om_get_rundata(352078, 601, site = omsite)
datbc6011 <- om_get_rundata(352078, 6011, site = omsite)
datbc6014 <- om_get_rundata(352078, 6014, site = omsite)

datbcfac201 <- om_get_rundata(247415, 201, site = omsite)
datbcfac301 <- om_get_rundata(247415, 301, site = omsite)
datbcfac401 <- om_get_rundata(247415, 401, site = omsite)
datbcfac6011 <- om_get_rundata(247415, 6011, site = omsite)
datbcfac6014 <- om_get_rundata(247415, 6014, site = omsite)

ro6014 <- om_get_rundata(247387,  6014, site = omsite)
 

datbc[200:250,c(wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
datbc[0:15,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]

