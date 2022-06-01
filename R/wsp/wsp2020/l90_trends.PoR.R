basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

elid = 233997  # PM7_4290_4200
gage_number = '01638500' #USGS  POTOMAC RIVER AT POINT OF ROCKS, MD
gage_data <- gage_import_data_cfs(gage_number, '1895-10-01', '2020-09-30')
iflows <- zoo(as.numeric(gage_data$flow), order.by = gage_data$date);
uiflows <- group2(iflows, 'calendar')
barplot(
  uiflows$`90 Day Min` ~ uiflows$year,
  ylab = '90 Day Low Flow (cfs)',
  xlab = 'Year'
)
myear <- as.integer(min(uiflows$year))
uiflows$yindex <- uiflows$year - myear
s90 <- lm(uiflows$`90 Day Min` ~ uiflows$yindex)
abline(s90)

# 30 day
barplot(
  uiflows$`30 Day Min` ~ uiflows$year,
  ylab = '30 Day Low Flow (cfs)',
  xlab = 'Year'
)
myear <- as.integer(min(uiflows$year))
uiflows$yindex <- uiflows$year - myear
s30 <- lm(uiflows$`30 Day Min` ~ uiflows$yindex)
abline(s30)

# 7 day
barplot(
  uiflows$`7 Day Min` ~ uiflows$year,
  ylab = '7 Day Low Flow (cfs)',
  xlab = 'Year'
)
myear <- as.integer(min(uiflows$year))
uiflows$yindex <- uiflows$year - myear
s7 <- lm(uiflows$`7 Day Min` ~ uiflows$yindex)
abline(s7);


alt_gfz <- zoo(as.numeric(alt_gf$Flow_curr), order.by = alt_gf$Date);
gfflows <- group2(alt_gfz, 'calendar')

# 7 day
barplot(
  gfflows$`7 Day Min` ~ gfflows$year,
  ylab = '7 Day Low Flow (cfs)',
  xlab = 'Year'
)
myear <- as.integer(min(gfflows$year))
gfflows$yindex <- gfflows$year - myear
s7 <- lm(gfflows$`7 Day Min` ~ gfflows$yindex)
abline(s7);

runid = 11
finfo = fn_get_runfile_info(elid, runid, 37, site= omsite)
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE)
mode(dat) <- 'numeric'
# Low Flows
iflows <- zoo(as.numeric(dat$Qout), order.by = index(dat));
uiflows <- group2(iflows, 'calendar')
barplot(
  uiflows$`90 Day Min` ~ uiflows$year,
  ylab = '90 Day Low Flow (cfs)',
  xlab = 'Year',
  main = "Low Flows by Year, Potomac River Point of Rocks"
)
myear <- as.integer(min(uiflows$year))
uiflows$yindex <- uiflows$year - myear
s90 <- lm(uiflows$`90 Day Min` ~ uiflows$yindex)
abline(s90)
summary(s90)
subverbiage <- paste("Adj R2 = ",signif(summary(s90)$adj.r.squared, 5),
      "Intercept =",signif(s90$coef[[1]],5 ),
      " Slope =",signif(s90$coef[[2]], 5),
      " P =",signif(summary(s90)$coef[2,4], 5))

l90s <- uiflows[,c('year', '90 Day Min')]
names(l90s) <- c('year', 'l90')
bp<- ggplot(l90s, aes(x=year, y=l90)) +
  geom_bar(stat = "identity",color="blue", fill=rgb(0.1,0.4,0.5,0.7))
bp + labs(
  title = 'Potomac River Point of Rocks',
  subtitle = subverbiage,
  x = 'Year',
  y = 'Lowest 90 Day Flow (cfs)'
)  + geom_smooth(method='lm')


uiflows$bfq <- (qm * uiflows$`Base index`)
bflm <- lm(bfq ~ year, data = uiflows)
summary(bflm)
l90s <- uiflows[,c('year', '90 Day Min', 'bfq')]
names(l90s) <- c('year', 'l90', 'bfq')
bp<- ggplot(l90s, aes(x=year, y=l90)) +
  geom_bar(stat = "identity",color="blue", fill=rgb(0.1,0.4,0.5,0.7))
bp + labs(
  title = 'Potomac River Point of Rocks',
  subtitle = 'Including 90 Day Low Flow Trend Lines',
  x = 'Year',
  y = 'Lowest 90 Day Flow (cfs)'
) +
  geom_smooth(method='lm')
#+
#  geom_smooth(
#    aes(y = bfq),
#    method='lm',
#    fill = 'red',
#    alpha = 0.2
#  )
