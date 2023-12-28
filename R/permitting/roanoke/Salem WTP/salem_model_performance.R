library("dataRetrieval")
library("zoo")
library("hydrotools")

basepath='/var/www/R'
source('/var/www/R/config.R')
save_directory <- "C:/Users/nrf46657/Desktop/VWP Modeling/City of Salem WTP/August2022/Gage calibration analysis"

elid = 251491 # Upstream Rseg: Roanoke River (Wayside Park)
runid = 2 # Current Conditions (#2)
gageid = '02054530' # Upstream USGS gage

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
gage_loflows <- IHA::group2(gage_flows);

# title_param <- runid
title_param <- "\nCurrent Conditions (runid #2)"
############################################################################################################
# L90
############################################################################################################
model_l90 <- model_loflows["90 Day Min"]
gage_l90 <- gage_loflows["90 Day Min"]

# cmp_l90 <- cbind(gage_loflows$year, gage_loflows["90 Day Min"],  model_loflows["90 Day Min"])
cmp_l90 <- cbind(gage_loflows$year, gage_l90, model_l90)
names(cmp_l90) <- c("Year", "USGS", "Model")
# gage has lowest flow every 30 days in 2002
# 30 day low flow also 2002, but 2008 was close

#set ymax to largest value in the 2 data sets, in order to generate plots with consistent axis limits
ymax_val <- max(c(cmp_l90$USGS,cmp_l90$Model))

png(paste(save_directory,paste0('barplot.l90.',elid, '.',runid, '.png'),sep = '/'), width = 800, height = 500)
barplot(
  cbind(USGS, Model) ~ Year, data=cmp_l90,
  col=c("blue", "black"),
  main=paste("USGS vs VAHydro, 90 Day Low Flow ",title_param,sep=""),
  beside=TRUE,
  ylab = "Streamflow (cfs)",
  ylim = c(0,ymax_val),
  cex.main=1.5,
  cex.axis=1.5,
  cex.lab=1.25
)
legend("topleft",legend=c("USGS", "VAHydro"),fill=c("blue", "black"),cex=1.5)
dev.off()


############################################################################################################
# L30
############################################################################################################
cmp_l30 <- cbind(gage_loflows$year, gage_loflows["30 Day Min"], model_loflows["30 Day Min"])
names(cmp_l30) <- c("Year", "USGS", "Model")
# gage has lowest flow every 30 days in 2002
# 30 day low flow also 2002, but 2008 was close

png(paste(save_directory,paste0('barplot.l30.',elid, '.',runid, '.png'),sep = '/'), width = 800, height = 500)
barplot(
  cbind(USGS, Model) ~ Year, data=cmp_l30,
  col=c("blue", "black"),
  main=paste("USGS vs VAHydro, 30 Day Low Flow ",title_param,sep=""),
  beside=TRUE,
  ylab = "Streamflow (cfs)",
  ylim = c(0,ymax_val),
  cex.main=1.5,
  cex.axis=1.5,
  cex.lab=1.25
)
legend("topleft",legend=c("USGS", "VAHydro"),fill=c("blue", "black"),cex=1.5)
dev.off()


############################################################################################################
# L7
############################################################################################################
cmp_l7 <- cbind(gage_loflows$year, gage_loflows["7 Day Min"], model_loflows["7 Day Min"])
names(cmp_l7) <- c("Year", "USGS", "Model")
# gage has lowest flow every 7 days in 2002
# 7 day low flow also 2002, but 2008 was close

png(paste(save_directory,paste0('barplot.l7.',elid, '.',runid, '.png'),sep = '/'), width = 800, height = 500)
barplot(
  cbind(USGS, Model) ~ Year, data=cmp_l7,
  col=c("blue", "black"),
  main=paste("USGS vs VAHydro, 7 Day Low Flow ",title_param,sep=""),
  beside=TRUE,
  ylab = "Streamflow (cfs)",
  ylim = c(0,ymax_val),
  cex.main=1.5,
  cex.axis=1.5,
  cex.lab=1.25
)
legend("topleft",legend=c("USGS", "VAHydro"),fill=c("blue", "black"),cex=1.5)
dev.off()


############################################################################################################
# L90 Additional Plots
############################################################################################################

lm90 <- lm(model_l90$`90 Day Min` ~ gage_l90$`90 Day Min`)
l90_err <- (model_l90$`90 Day Min` - gage_l90$`90 Day Min`)
l90_err_pct <- 100.0 * (model_l90$`90 Day Min` - gage_l90$`90 Day Min`) / gage_l90$`90 Day Min`

lm_l90_err <- lm(l90_err ~ index(l90_err))
summary(lm_l90_err)

png(paste(save_directory,paste0('error.l90.',elid, '.',runid, '.png'),sep = '/'), width = 500, height = 500)
plot(l90_err ~ gage_loflows$year,
     cex = 1.5,
     col = "blue",
     main=paste("USGS vs VAHydro Error, 90 Day Low Flow ",title_param,sep=""),
     xlab = "Year",
     ylab = "90 Day Low Flow Error"
     )
abline(reg=lm(l90_err ~ gage_loflows$year),lwd=2,col="blue")
abline(0,0,col="black")
# abline(lm_l90_err)
# plot(l90_err)
dev.off()

# L90 Scatterplot
m90 <- max(c(max(model_l90$`90 Day Min`), max(gage_l90$`90 Day Min`)))
png(paste(save_directory,paste0('scatter.l90.',elid, '.',runid, '.png'),sep = '/'), width = 500, height = 500)
plot(model_l90$`90 Day Min` ~ gage_l90$`90 Day Min`, ylim=c(0,m90), xlim=c(0,m90),
     cex = 1.5,
     col = "blue",
     main=paste("USGS vs VAHydro, 90 Day Low Flow ",title_param,sep=""),
     xlab = "USGS 90 Day Low Flow",
     ylab = "VAHydro 90 Day Low Flow"
     )
abline(lm90,lwd=2,col="blue")
abline(0,1,col="black")
dev.off()
summary(lm90)

############################################################################################################
# L30 Additional Plots
############################################################################################################
model_l30 <- model_loflows["30 Day Min"]
gage_l30 <- gage_loflows["30 Day Min"]

lm30 <- lm(model_l30$`30 Day Min` ~ gage_l30$`30 Day Min`)
l30_err <- (model_l30$`30 Day Min` - gage_l30$`30 Day Min`)
l30_err_pct <- 100.0 * (model_l30$`30 Day Min` - gage_l30$`30 Day Min`) / gage_l30$`30 Day Min`

lm_l30_err <- lm(l30_err ~ index(l30_err))
summary(lm_l30_err)

png(paste(save_directory,paste0('error.l30.',elid, '.',runid, '.png'),sep = '/'), width = 500, height = 500)
plot(l30_err ~ gage_loflows$year,
     cex = 1.5,
     col = "blue",
     main=paste("USGS vs VAHydro Error, 30 Day Low Flow ",title_param,sep=""),
     xlab = "Year",
     ylab = "30 Day Low Flow Error"
)
abline(reg=lm(l30_err ~ gage_loflows$year),lwd=2,col="blue")
abline(0,0,col="black")
# abline(lm_l30_err)
# plot(l30_err)
dev.off()

# L30 Scatterplot
lm30 <- lm(model_l30$`30 Day Min` ~ gage_l30$`30 Day Min`)
m30 <- max(c(max(model_l30$`30 Day Min`), max(gage_l30$`30 Day Min`)))
png(paste(save_directory,paste0('scatter.l30.',elid, '.',runid, '.png'),sep = '/'), width = 500, height = 500)
plot(model_l30$`30 Day Min` ~ gage_l30$`30 Day Min`, ylim=c(0,m30), xlim=c(0,m30),
     cex = 1.5,
     col = "blue",
     main=paste("USGS vs VAHydro, 30 Day Low Flow ",title_param,sep=""),
     xlab = "USGS 30 Day Low Flow",
     ylab = "VAHydro 30 Day Low Flow"
)
abline(lm30,lwd=2,col="blue")
abline(0,1,col="black")
dev.off()
summary(lm30)


############################################################################################################
# L7 Additional Plots
############################################################################################################
model_l7 <- model_loflows["7 Day Min"]
gage_l7 <- gage_loflows["7 Day Min"]

lm7 <- lm(model_l7$`7 Day Min` ~ gage_l7$`7 Day Min`)
l7_err <- (model_l7$`7 Day Min` - gage_l7$`7 Day Min`)
l7_err_pct <- 100.0 * (model_l7$`7 Day Min` - gage_l7$`7 Day Min`) / gage_l7$`7 Day Min`

lm_l7_err <- lm(l7_err ~ index(l7_err))
summary(lm_l7_err)

png(paste(save_directory,paste0('error.l7.',elid, '.',runid, '.png'),sep = '/'), width = 500, height = 500)
plot(l7_err ~ gage_loflows$year,
     cex = 1.5,
     col = "blue",
     main=paste("USGS vs VAHydro Error, 7 Day Low Flow ",title_param,sep=""),
     xlab = "Year",
     ylab = "7 Day Low Flow Error"
)
abline(reg=lm(l7_err ~ gage_loflows$year),lwd=2,col="blue")
abline(0,0,col="black")
# abline(lm_l7_err)
# plot(l7_err)
dev.off()

# L7 Scatterplot
lm7 <- lm(model_l7$`7 Day Min` ~ gage_l7$`7 Day Min`)
m7 <- max(c(max(model_l7$`7 Day Min`), max(gage_l7$`7 Day Min`)))
png(paste(save_directory,paste0('scatter.l7.',elid, '.',runid, '.png'),sep = '/'), width = 500, height = 500)
plot(model_l7$`7 Day Min` ~ gage_l7$`7 Day Min`, ylim=c(0,m7), xlim=c(0,m7),
     cex = 1.5,
     col = "blue",
     main=paste("USGS vs VAHydro, 7 Day Low Flow ",title_param,sep=""),
     xlab = "USGS 7 Day Low Flow",
     ylab = "VAHydro 7 Day Low Flow"
)
abline(lm7,lwd=2,col="blue")
abline(0,1,col="black")
dev.off()
summary(lm7)
############################################################################################################
