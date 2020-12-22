#Q THis analysis looks at a case study in the north Anna dam
# where precip and et combine to model Runit
# summer is isolated, and explains about 1/3 of summer in general
# and about 1/2 during drought years
# ET is more important during drought, though the 
# winter base flow is still half

#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

melid = 207959 # meteorology element id
elid = 207927 # River Channel object in North Anna

mdatbase <- om_get_rundata(melid, 11)
plm <- lm(mdatbase$cbp6_precip_in ~ mdatbase$cbp_precip_in)
elm <- lm(mdatbase$cbp6_et_in ~ mdatbase$cbp_et_in)
summary(plm)
summary(elm)

# Comparing at rive rseg level to use runoff
datbase <- om_get_rundata(elid, 11)
datbase$net_precip <- datbase$precip_in - datbase$et_in

datcc <- om_get_rundata(elid, 17)
datcc$net_precip <- datcc$precip_in - datcc$et_in

# Net precip analysis
boxplot(net_precip ~ month, data=datbase)
boxplot(net_precip ~ month, data=datcc)
# make data frames
dfbase <- as.data.frame(datbase)
dfcc <- as.data.frame(datcc)

annstats <- sqldf(
   "select year, sum(precip_in) as precip, sum(et_in) as evap 
   from dfbase 
   group by year
   "
)

totals <- sqldf(
   "select avg(precip), avg(evap) 
   from annstats
   "
)

sumdatbase <- sqldf(
  "select * from dfbase 
   where month in (7,8,9)
   and precip_in < 1.0 "
)
sumdatcc <- sqldf(
  "select * from dfcc 
  where month in (7,8,9)
   and precip_in < 1.0 "
)

modatbase <- sqldf(
  "select year, month, 
   case when month in (1,2,3) then 1
     when month in (4,5,6) then 2
     when month in (7,8,9) then 3
     else 4
   end season,
   sum(precip_in) as precip_in, 
   sum(et_in) as et_in
   from dfbase 
   group by year, month "
)
modatcc <- sqldf(
  "select year, month, 
   case when month in (1,2,3) then 1
     when month in (4,5,6) then 2
     when month in (7,8,9) then 3
     else 4
   end season,
   sum(precip_in) as precip_in, 
   sum(et_in) as et_in
   from dfcc 
   group by year, month "
)

wintercomp <- sqldf(
  "select a.year, a.month, 
   a.precip_in as prec_now, 
   b.precip_in as prec_2055, 
   a.et_in as et_now, 
   b.et_in as et_2055 
   from modatbase as a
   left outer join modatcc as b 
   on ( 
     a.year = b.year and a.month = b.month
   ) 
   where a.season = 1 "
)
moreg = lm(prec_2055 ~ prec_now, dat=wintercomp)
summary(moreg)
plot(prec_2055 ~ prec_now, dat=wintercomp, ylim = c(0,10))
abline(moreg)
moreg = lm(et_2055 ~ et_now, dat=wintercomp)
summary(moreg)
plot(et_2055 ~ et_now, dat=wintercomp, ylim = c(0,4))
abline(moreg)



rechargecomp <- sqldf(
  "select a.year, a.month, 
   a.precip_in as prec_now, 
   b.precip_in as prec_2055 
   from modatbase as a
   left outer join modatcc as b 
   on ( 
     a.year = b.year and a.month = b.month
   ) 
   where a.month in (11,12,1,2) "
)

baselm <- lm(Runit ~ precip_in + et_in, data=sumdatbase)
summary(baselm)
baselm <- lm(Runit ~ net_precip, data=sumdatbase)
summary(baselm)

cclm <- lm(Runit ~ precip_in + et_in, data=sumdatcc)
summary(cclm)


subaselm99 <- lm(Runit ~ net_precip + et_in, data=sumdatbase99)
summary(baselm99)
mdatbase99 <- sqldf(
  "select * from sumdatbase where year = 1999"
)
sumdatcc99 <- sqldf("select * from sumdatcc where year = 1999")
sumdatcc92 <- sqldf("select * from sumdatcc where year = 1992")

baselm99 <- lm(Runit ~ precip_in + et_in, data=sumdatbase99)
summary(baselm99)

cclm99 <- lm(Runit ~ precip_in + et_in, data=sumdatcc99)
summary(cclm99)

cclm92 <- lm(Runit ~ precip_in + et_in, data=sumdatcc92)
summary(cclm92)
# Coefficients:
baselm99$coefficients
cclm99$coefficients
baselm$coefficients
cclm$coefficients

quantile(sumdatbase99$et_in)
quantile(sumdatbase99$precip_in)
mean(sumdatbase99$et_in)
mean(sumdatbase99$precip_in)
sumdatbase99$net_precip <- sumdatbase99$precip_in - sumdatbase99$et_in
plot(
  sumdatbase99$Runit ~ sumdatbase99$net_precip
    
)

coeffs <- rbind(baselm99$coefficients,
                     cclm99$coefficients,
                     baselm$coefficients,
                     cclm$coefficients)
