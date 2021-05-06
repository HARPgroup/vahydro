library('hydrotools')
library('zoo')

datbc201 <- om_get_rundata(352078, 201)
datbc301 <- om_get_rundata(352078, 301)
datbc401 <- om_get_rundata(352078, 401)
datbc601 <- om_get_rundata(352078, 601)
datbc6011 <- om_get_rundata(352078, 6011)

datbcfac201 <- om_get_rundata(247415, 201)
datbcfac301 <- om_get_rundata(247415, 301)
datbcfac401 <- om_get_rundata(247415, 401)
datbcfac6011 <- om_get_rundata(247415, 6011)
 

datbc[200:250,c(wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
datbc[0:15,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]

