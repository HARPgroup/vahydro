

basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

elid = 252625  # PM7_4290_4200
gage_number = '02056000' #USGS ROANOKE RIVER AT NIAGARA, VA
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

