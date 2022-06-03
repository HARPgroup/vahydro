library("DataRetrieval")
library("zoo")
library("hydrotools")

elid = 251491
runid = 2
gageid = '02054530'
model_flows <- om_get_rundata(elid, runid, site=omsite)
model_flows <- zoo(as.numeric(as.character( model_flows$Qout )), order.by = index(model_flows) );
mstart <- as.Date(min(index(model_flows)))
mend <- as.Date(max(index(model_flows)))

historic <- dataRetrieval::readNWISdv(gageid,'00060')
gage_flows <- zoo(as.numeric(as.character( historic$X_00060_00003 )), order.by = historic$Date);
gage_flows <- window(gage_flows, start = mstart, end = mend)
gstart <- as.Date(min(index(gage_flows)))
gend <- as.Date(max(index(gage_flows)))
model_flows <- window(model_flows, start = gstart, end = gend)

# compare means
mean(model_flows)
mean(gage_flows)


# now do IHA
model_loflows <- IHA::group2(model_flows);
model_l90 <- model_loflows["90 Day Min"];
gage_loflows <- IHA::group2(gage_flows);
gage_l90 <- gage_loflows["90 Day Min"]

cmp_l90 <- cbind(gage_loflows$year, gage_l90, model_l90)
names(cmp_l90) <- c("Year", "USGS", "Model")
# gage has lowest flow every 30 days in 2002
# 30 day low flow also 2002, but 2008 was close
barplot(
  cbind(USGS, Model) ~ Year, data=cmp_l90,
  col=c("blue", "black"),
  main=paste("USGS vs VAHydro 90 Day Low Flow (", runid,")"),
  beside=TRUE
)
cmp_l30 <- cbind(gage_loflows$year, gage_loflows["30 Day Min"], model_loflows["30 Day Min"])
names(cmp_l30) <- c("Year", "USGS", "Model")
# gage has lowest flow every 30 days in 2002
# 30 day low flow also 2002, but 2008 was close
barplot(
  cbind(USGS, Model) ~ Year, data=cmp_l30,
  col=c("blue", "black"),
  main=paste("USGS vs VAHydro 30 Day Low Flow (", runid,")"),
  beside=TRUE
)
cmp_l7 <- cbind(gage_loflows$year, gage_loflows["7 Day Min"], model_loflows["7 Day Min"])
names(cmp_l7) <- c("Year", "USGS", "Model")
# gage has lowest flow every 7 days in 2002
# 7 day low flow also 2002, but 2008 was close
barplot(
  cbind(USGS, Model) ~ Year, data=cmp_l7,
  col=c("blue", "black"),
  main=paste("USGS vs VAHydro 7 Day Low Flow (", runid,")"),
  beside=TRUE
)

cmp90 <- cbind(gage_loflows$year,gage_l90, model_l90)
names(cmp90) <- c('year', 'gage', 'model')
plot(cmp90$model ~ cmp90$gage)
plot(cmp90$gage, col='blue')
points(cmp90$model, col="black")

model_df <- as.data.frame(model_flows)
gage_df <- as.data.frame(historic)
cmp <- cbind(
  model_df$year,
  model_df$month,
  model_df$day,
  gage_df$X_00060_00003,
  model_df$Qout
)
cmp$year <- as.data.frame(year(gage_df$Date))

for (myear in c(1998, 2019)) {

  gage2019 <- window(
    gage_flows,
    start = as.Date(paste0(myear,'-01-01')),
    end = as.Date(paste0(myear,'-12-31'))
  )
  model2019 <- window(
    model_flows,
    start = as.Date(paste0(myear,'-01-01')),
    end = as.Date(paste0(myear,'-12-31'))
  )
  plot(as.numeric(model2019), main=myear, col='black', ylim=c(0,1000))
  points(as.numeric(gage2019), col='blue')

}
lm90 <- lm(model_l90$`90 Day Min` ~ gage_l90$`90 Day Min`)
l90_err <- (model_l90$`90 Day Min` - gage_l90$`90 Day Min`)
l90_err_pct <- 100.0 * (model_l90$`90 Day Min` - gage_l90$`90 Day Min`) / gage_l90$`90 Day Min`

lm_l90_err <- lm(l90_err ~ index(l90_err))
summary(lm_l90_err)
plot(l90_err ~ gage_loflows$year)
abline(lm_l90_err)
plot(l90_err)
m90 <- max(c(max(model_l90$`90 Day Min`), max(gage_l90$`90 Day Min`)))
plot(model_l90$`90 Day Min` ~ gage_l90$`90 Day Min`, ylim=c(0,m90), xlim=c(0,m90))
abline(lm90)
summary(lm90)
