

basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

elid = 244101  # MN5_8161_8160
gage_number = '02047000' #USGS NOTTOWAY RIVER NEAR SEBRELL, VA
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
summary(s90)


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
  xlab = 'Year'
)
myear <- as.integer(min(uiflows$year))
uiflows$yindex <- uiflows$year - myear
s90 <- lm(uiflows$`90 Day Min` ~ uiflows$yindex)
abline(s90)
summary(s90)
medl90 <- median(uiflows$'90 Day Min')
buiflows <- sqldf(paste('select * from uiflows where "90 Day Min" <= ', medl90))
bs90 <- lm(buiflows$`90 Day Min` ~ buiflows$yindex)
abline(bs90)
summary(bs90)


uiflows$bfq <- (qm * uiflows$`Base index`)
bflm <- lm(`Base index` ~ year, data = uiflows)
summary(bflm)
l90s <- uiflows[,c('year', '90 Day Min', 'bfq')]
names(l90s) <- c('year', 'l90', 'bfq')
bflm <- lm(bfq ~ year, data = l90s)
summary(bflm)
bp<- ggplot(l90s, aes(x=year, y=l90)) +
  geom_bar(stat = "identity",color="blue", fill=rgb(0.1,0.4,0.5,0.7))
bp + labs(
  title = 'Nottoway River',
  #subtitle = subverbiage,
  x = 'Year',
  y = 'Lowest 90 Day Flow (cfs)'
) + 
  geom_smooth(method='lm') + 
  geom_smooth(
    aes(y = bfq),
    method='lm',
    fill = 'red',
    alpha = 0.2
  )
