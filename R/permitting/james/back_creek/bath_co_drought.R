rodat <- om_get_rundata(209767, 901, site = omsite) # 209767 , 345776

damdat <- om_get_rundata(209793 , 901, site = omsite) 

dam_wb <- as.data.frame(damdat[,c('Qin','Qout', 'flowby', 'pct_use_remain')])


rodf <- as.data.frame(rodat)
sqldf(
  "select year, avg(Qout), min(Qout), max(Qout)
  from rodf 
  group by year
  "
)

model_flows <- om_get_rundata(209799, 901, site = omsite) 
gageid = "02011460"
pd_start = "2021-10-01"
historic <- dataRetrieval::readNWISdv(gageid,'00060', pd_start)
gage_flows <- zoo(as.numeric(as.character( historic$X_00060_00003 )), order.by = historic$Date);
mstart <- as.Date(min(index(model_flows)))
mend <- as.Date(max(index(model_flows)))
gage_flows <- window(gage_flows, start = mstart, end = mend)
gstart <- as.Date(min(index(gage_flows)))
gend <- as.Date(max(index(gage_flows)))
model_flows <- window(model_flows, start = gstart, end = gend)

plot(as.numeric(model_flows$Qout), main=myear, col='black', ylim=c(0,1000))
points(as.numeric(gage_flows), col='blue')
