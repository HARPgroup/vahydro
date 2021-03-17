library('hydrotools')
library('zoo')

datbc201 <- om_get_rundata(352078, 201)
datbc301 <- om_get_rundata(352078, 301)
datbc401 <- om_get_rundata(352078, 401)

datbcfac201 <- om_get_rundata(247415, 201)
datbcfac301 <- om_get_rundata(247415, 301)
datbcfac401 <- om_get_rundata(247415, 401)
 

datbc[200:250,c(wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
datbc[0:15,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]

