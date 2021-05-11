library('hydrotools')
library('zoo')

datbc201 <- om_get_rundata(352078, 201)
datbc301 <- om_get_rundata(352078, 301)
datbc401 <- om_get_rundata(352078, 401)
datbc601 <- om_get_rundata(352078, 601)
datbc6011 <- om_get_rundata(352078, 6011)
datbc6012 <- om_get_rundata(352078, 6012)
datbc6013 <- om_get_rundata(352078, 6013)
quantile(datbc6012$release)
quantile(datbc6013$release)

datbcfac201 <- om_get_rundata(247415, 201)
datbcfac301 <- om_get_rundata(247415, 301)
datbcfac401 <- om_get_rundata(247415, 401)
datbcfac6011 <- om_get_rundata(247415, 6011)
datbcfac6012 <- om_get_rundata(247415, 6012)
datbcfac6013 <- om_get_rundata(247415, 6013)

quantile(datbcfac6012$bc_release_cfs)
quantile(datbcfac6013$bc_release_cfs)


datbc[200:250,c(wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]
datbc[0:15,c('wd_channel_cfs', 'Qlocal_channel', 'bc_release_cfs', 'impoundment_Qout')]

