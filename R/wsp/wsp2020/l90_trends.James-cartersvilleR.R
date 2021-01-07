

basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

elid = 210731   # 
gage_number = '02035000' #USGS James River Cartersville, VA
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
datdf <- as.data.frame(dat)
yflows <- sqldf(
  "select year, avg(Qout) as Qout 
   from datdf 
   group by year 
   order by year"
)
# Low Flows 
iflows <- zoo(as.numeric(dat$Qout), order.by = index(dat));
uiflows <- group2(iflows, 'water')
barplot(
  uiflows$`90 Day Min` ~ uiflows$year, 
  ylab = '90 Day Low Flow (cfs)',
  xlab = 'Year',
  main = "Low Flows by Year, James River Cartersville"
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

uiflows$bfq <- (qm * uiflows$`Base index`)
bflm <- lm(`Base index` ~ year, data = uiflows)
summary(bflm)
l90s <- uiflows[,c('year', '90 Day Min', 'Base index', 'bfq')]
names(l90s) <- c('year', 'l90', 'bfi', 'bfq')
bflows <- sqldf(
  "select a.year, 
     a.bfi * b.Qout as bfq, 
     a.l90
   from l90s as a
   left outer join yflows as b
   on (a.year = b.year)
  ")
bflm <- lm(bfq ~ year, data = l90s)
summary(bflm)
bp<- ggplot(l90s, aes(x=year, y=l90)) +
  geom_bar(stat = "identity",color="blue", fill=rgb(0.1,0.4,0.5,0.7))
bp + labs(
  title = 'James River, Cartersville',
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

