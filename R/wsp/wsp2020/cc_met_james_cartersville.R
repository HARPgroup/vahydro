#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
cbp6_location <- 'https://raw.githubusercontent.com/HARPgroup/cbp6/master'
data.location <- paste0(cbp6_location,'/Data/CBP6_Temp_Prcp_Data/')

anndat <- function (dfname, sd, ed) {
  sqlstr <- paste0(
    "select year, sum(evap) as evap, sum(prcp) as prcp 
       from (
         select strftime('%Y', thisdate) as year, * from ", dfname,  
    " where thisdate >= '", sd,
    "' and thisdate <= '", ed,
    "' ) as foo 
    group by year 
    order by year"
  )
  message(sqlstr)
  df <- sqldf(
    sqlstr
  )
  mode(df$year) <- 'numeric'
  ymin <- min(df$year)
  df$yindex <- df$year - ymin
  return(df)
}
# Raw meteorological data from WDMs
p6dat <- 'http://deq2.bse.vt.edu/p6/p6_gb604/out/climate/'
lseg <- 'N51049'
fname <- paste0(lseg, '_1000-2000.csv')
p10_met <- read.csv(paste(p6dat,'5545HS10CA2_and_55R45KK1095',fname,sep='/'))
p50_met <- read.csv(paste(p6dat,'5545HS50CA2_and_5545KK50AA',fname,sep='/'))
p90_met <- read.csv(paste(p6dat,'5545HS90CA2_and_55R45KK9095',fname,sep='/'))
pbase_met <- read.csv(paste(p6dat,'N20150521J96_and_PRC20170731',fname,sep='/'))
# now extract just the cc time period
sd = '1990-01-01'
ed = '2000-12-31'
# annualize them in inches
p10_ann <- anndat('p10_met', sd, ed)
p10_all_ann <- anndat('p10_met', '1984-01-01', '2014-12-31')
p50_ann <- anndat('p50_met', sd, ed)
p90_ann <- anndat('p90_met', sd, ed)
pbase_ann <- anndat('pbase_met', sd, ed)
pbase_all_ann <- anndat('pbase_met', '1984-01-01', '2014-12-31')
eylm <- lm(evap ~ yindex, dat=as.data.frame(pbase_all_ann))
summary(eylm) 
bp<- ggplot(pbase_all_ann, aes(x=year, y=evap)) +
  geom_point(color="blue", fill=rgb(0.1,0.4,0.5,0.7))
bp + labs(
  title = paste('Evaporation in Land Segment', lseg),
  #subtitle = subverbiage,
  x = 'Year',
  y = 'Evaporation (inches)'
) +  ylim(0,40) +
  geom_smooth(method='lm') + 
  geom_smooth(
    aes(y = evap),
    method='lm',
    fill = 'red',
    alpha = 0.2
  )

pylm <- lm(prcp ~ yindex, dat=as.data.frame(pbase_all_ann))
summary(pylm) 
bp<- ggplot(pbase_all_ann, aes(x=year, y=prcp)) +
  geom_point(color="blue", fill=rgb(0.1,0.4,0.5,0.7))
bp + labs(
  title = paste('Rainfall in Land Segment', lseg),
  #subtitle = subverbiage,
  x = 'Year',
  y = 'Rainfall (inches)'
) +  ylim(0,40) +
  geom_smooth(method='lm') + 
  geom_smooth(
    aes(y = precip),
    method='lm',
    fill = 'red',
    alpha = 0.2
  )

# Use CC which has alternate evap method -- or does the base we are using alrady include this method?
# this only goes to 2005 which may be problematic?
eylm <- lm(evap ~ yindex, dat=as.data.frame(p10_all_ann))
summary(eylm) 
bp<- ggplot(p10_all_ann, aes(x=year, y=evap)) +
  geom_point(color="blue", fill=rgb(0.1,0.4,0.5,0.7))
bp + labs(
  title = paste('Evaporation in Land Segment', lseg),
  #subtitle = subverbiage,
  x = 'Year',
  y = 'Evaporation (inches)'
) +  ylim(0,40) +
  geom_smooth(method='lm') + 
  geom_smooth(
    aes(y = evap),
    method='lm',
    fill = 'red',
    alpha = 0.2
  )

# summarize
p10_et <- mean(p10_ann$evap)
p10_p <- mean(p10_ann$prcp)
p50_et <- mean(p50_ann$evap)
p50_p <- mean(p50_ann$prcp)
p90_et <- mean(p90_ann$evap)
p90_p <- mean(p90_ann$prcp)
pbase_et <- mean(pbase_ann$evap)
pbase_p <- mean(pbase_ann$prcp)
# 99 drought info
p10_y99 <- sqldf("select * from p10_ann where year = 1999")
p50_y99 <- sqldf("select * from p50_ann where year = 1999")
p90_y99 <- sqldf("select * from p90_ann where year = 1999")
pbase_y99 <- sqldf("select * from pbase_ann where year = 1999")
p10_y91 <- sqldf("select * from p10_ann where year = 1991")

p10_dp <- 100.0 * (p10_p - pbase_p) / pbase_p
p50_dp <- 100.0 * (p50_p - pbase_p) / pbase_p
p90_dp <- 100.0 * (p90_p - pbase_p) / pbase_p

p10_det <- 100.0 * (p10_et - pbase_et) / pbase_et
p50_det <- 100.0 * (p50_et - pbase_et) / pbase_et
p90_det <- 100.0 * (p90_et - pbase_et) / pbase_et

p10_x <- p10_p - p10_et
p50_x <- p50_p - p50_et
p90_x <- p90_p - p90_et
pbase_x <- pbase_p - pbase_et
# mix and matchL
mix_base_et50p_x <- pbase_p - p50_et
mix_base_et90p_x <- pbase_p - p90_et

p10_dx <- p10_x - pbase_x
p50_dx <- p50_x - pbase_x
p90_dx <- p90_x - pbase_x
# the 50th et plus base precip
mix50et_dx <- mix_base_et50p_x - pbase_x
mix90et_dx <- mix_base_et90p_x - pbase_x
