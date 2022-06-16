library('hydrotools')
library('zoo')

# BC Rez
# BC Facility
# Watershed outlet

datbc201 <- om_get_rundata(352078, 201)
datbc301 <- om_get_rundata(352078, 301)
datbc401 <- om_get_rundata(352078, 401)
datbc601 <- om_get_rundata(352078, 601)

quantile(datbc601$impoundment_Qin)
mean(datbc601$impoundment_Qin)
mean(datbc601$impoundment_demand)
quantile(datbc601$impoundment_demand)

datbcfac201 <- om_get_rundata(247415, 201)
datbcfac301 <- om_get_rundata(247415, 301)
datbcfac401 <- om_get_rundata(247415, 401)
datbcfac601 <- om_get_rundata(247415, 6012)

 

datbc[200:250,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
datbc601[15:20,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]

datbc601[15:20,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
