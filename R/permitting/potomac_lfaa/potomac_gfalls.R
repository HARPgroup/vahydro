#----------------------------------------------
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
library(hydrotools)
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
source(paste("https://raw.githubusercontent.com/HARPgroup/r-dh-ecohydro",'master/Analysis/habitat','ifim_wua_change_plot.R',sep='/'))
source(paste("https://raw.githubusercontent.com/HARPgroup/r-dh-ecohydro",'master/Analysis/habitat','hab_ts_functions.R',sep='/'))
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/VAHydro-2.0/rest_functions.R") #Used during development
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/VAHydro-2.0/find_name.R") #Used during development
source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/R/fac_utils.R") #Used until fac_utils is packaged

# Load the gage flow record
gageid = '01638500'
historic <- dataRetrieval::readNWISdv(gageid,'00060')
gageid = '01646500'
lf_usgs <- dataRetrieval::readNWISdv(gageid,'00060')
gageid = '01646502'
lf_usgs_adj <- dataRetrieval::readNWISdv(gageid,'00060')
lf_usgs_adj$year <- year(lf_usgs_adj$Date)
lf_usgs_adj$mon <- month(lf_usgs_adj$Date)
lf_usgs$year <- year(lf_usgs$Date)
lf_usgs$mon <- month(lf_usgs$Date)

historic$month <- month(historic$Date)
historic$year <- year(historic$Date)
gage_sum_historic <- om_flow_table(historic, "X_00060_00003")

# Load the IFIM feature and data
# to do: put this on github as json data
source("c:/usr/local/home/git/vahydro/R/permitting/potomac_lfaa/ifim_data_gfalls.R")
# load demand data
source("c:/usr/local/home/git/vahydro/R/permitting/potomac_lfaa/demands.R")

# load PoR time series from Gage and ICPRB
# compare PoR gage time series with
icprb_monthly_lf <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/lfalls_nat_monthly_data.csv")
icprb_monthly_gf <- icprb_monthly_lf
#icprb_monthly_gf$gfalls <-
icprb_monthly_prod <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/wma_production.csv")
icprb_monthly_prod$month <- month(as.Date(icprb_monthly_prod$thisdate,format="%m/%d/%Y"))
icprb_monthly_prod$year <- year(as.Date(icprb_monthly_prod$thisdate,format="%m/%d/%Y"))

# monthly mean flows from ICPRB
da_por <- 9651.0 # https://waterdata.usgs.gov/nwis/uv?site_no=01638500
da_gf <- 11586.6 # d.dh/admin/content/dh_features/manage/68363/dh_properties

nat_gf <- historic[c("Date", "X_00060_00003", "year", "month")]
colnames(nat_gf) <- c('Date', 'Flow', "year", "month")
nat_gf$Flow <- (da_gf / da_por) * nat_gf$Flow



icprb_prod_max <- sqldf(
  "
   select month,
     max(wssc_pot) as wssc_pot,
     max(wa_gf) as  wa_gf,
     max(wa_lf) as wa_lf,
     max(fw_pot) as fw_pot,
     max(rville) as rville,
     max(up_cu) as up_cu
   from icprb_monthly_prod where year >= 2015
   group by month
  "
)

alt_gf <- sqldf(
  "
   select a.Date, a.year, a.month,
    (b.wssc_pot + b.wa_gf 
      + b.fw_pot + b.rville) as demand_mgd,
      a.Flow
   from nat_gf as a
   left outer join icprb_prod_max as b
   on (
     a.month = b.month
   )
  "
)

alt_gf <- sqldf(
  "
    select *,
      (Flow * 0.2)/1.547 as avail_p20_mgd,
      CASE
        WHEN Flow >= (100.0 * 1.547)
          THEN (Flow - (100.0 * 1.547))/1.547
        ELSE 0.0
      END as avail_curr_mgd,
      CASE
        WHEN Flow >= (500.0 * 1.547)
          THEN (Flow - (500.0 * 1.547))/1.547
        ELSE 0.0
      END as avail_q500_mgd
    from alt_gf
  "
)

# add in the demands, factoring for flowby
alt_gf <- sqldf(
  "
    select a.*,
      CASE
        WHEN demand_mgd > avail_curr_mgd THEN avail_curr_mgd
        ELSE demand_mgd
      END as wd_curr_mgd,
      CASE
        WHEN demand_mgd > avail_p20_mgd THEN avail_p20_mgd
        ELSE demand_mgd
      END as wd_p20_mgd,
      CASE
        WHEN demand_mgd > avail_q500_mgd THEN avail_q500_mgd
        ELSE demand_mgd
      END as wd_q500_mgd
    from alt_gf as a
    order by Date
  "
)

# calculate release needed
alt_gf <- sqldf(
  "
    select a.*,
      demand_mgd - wd_curr_mgd as need_curr_mgd,
      demand_mgd - wd_p20_mgd as need_p20_mgd,
      demand_mgd - wd_q500_mgd as need_q500_mgd,
      Flow - wd_curr_mgd * 1.547 as Flow_curr,
      Flow - wd_p20_mgd * 1.547 as Flow_p20,
      Flow - wd_q500_mgd * 1.547 as Flow_q500
    from alt_gf as a
    order by Date
  "
)

quantile(alt_gf$need_curr_mgd, probs=c(0.5,0.75,0.8,0.9,0.95,0.99,1.0))
quantile(alt_gf$need_q500_mgd, probs=c(0.5,0.75,0.8,0.9,0.95,0.99,1.0))
quantile(alt_gf$need_p20_mgd, probs=c(0.5,0.75,0.8,0.9,0.95,0.99,1.0))




agf_1997 <- sqldf("select * from alt_gf where year >= 1997")
gfz = zoo(agf_1997$Flow/1.547, order.by = as.Date(agf_1997$Date))
gf_gf = group2(gfz, "calendar")

yr <- year(index(gfz))
rollx <- runmean.iha(gfz, year = yr, mimic.tnc = TRUE)
q30s <- rollx$w30

gfaz = zoo(agf_1997$Flow_curr/1.547, order.by = as.Date(agf_1997$Date))
gfa_gf = group2(gfaz, "calendar")

gfb = as.data.frame(cbind(gfa_gf$year, gfa_gf$`30 Day Min`, gf_gf$`30 Day Min`))
colnames(gfb) <- c('Year', 'PostWD', 'Baseline')

gfb$pct_chg <- (gfb$PostWD - gfb$Baseline) / gfb$Baseline

bp <- barplot(
  cbind(Baseline, PostWD) ~ Year, data=gfb,
  col=c("blue", "black"),
  main="Pre-Withdrawal vs. Post-Withdrawal 30 Day Low Flow, 1997-2010",
  beside=TRUE,
  ylim=c(0,4000)
)
#text(bp, 4500, round(100*gfb$pct_chg),cex=1,pos=3) 
#text(bp, 4500, round(100*gfb$pct_chg)) 

bp
quantile(gfb$pct_chg)

alt_gf_aso <- sqldf("select * from agf_1997 where month in (8, 9, 10)")
quantile(alt_gf_aso$cu_pct_curr)
alt_gf_aso$pct_chg <- (alt_gf_aso$Flow_curr - alt_gf_aso$Flow) / alt_gf_aso$Flow
quantile(alt_gf_aso$pct_chg)

bxp <- boxplot(-100.0 * as.numeric(alt_gf_aso$pct_chg) ~ alt_gf_aso$year, ylab="Percent of Flow in Aug-Oct Withdrawn", main="Demand as Percent of Flow at Little Falls, 1997-2010")


# all flows
agfz = zoo(alt_gf$Flow/1.547, order.by = as.Date(alt_gf$Date))
agf_gf = group2(gfz, "calendar")

agfaz = zoo(alt_gf$Flow_curr/1.547, order.by = as.Date(alt_gf$Date))
agfa_agf = group2(agfaz, "calendar")

agfb = as.data.frame(cbind(agfa_agf$year, agf_gf$`30 Day Min`, agfa_agf$`30 Day Min`))
colnames(agfb) <- c('Year', 'PostWD', 'Baseline')

agfb$pct_chg <- (agfb$PostWD - agfb$Baseline) / agfb$Baseline

bp <- barplot(
  cbind(Baseline, PostWD) ~ Year, data=agfb,
  col=c("blue", "black"),
  main="Pre-Withdrawal vs. Post-Withdrawal 30 Day Low Flow, 1997-2010",
  beside=TRUE,
  ylim=c(0,4000)
)
#text(bp, 4500, round(100*gfb$pct_chg),cex=1,pos=3) 
#text(bp, 4500, round(100*gfb$pct_chg)) 


bp
quantile(gfb$pct_chg)

alt_agf_aso <- sqldf("select * from alt_gf where month in (8, 9, 10)")
quantile(alt_agf_aso$cu_pct_curr)
alt_agf_aso$pct_chg <- (alt_agf_aso$Flow_curr - alt_agf_aso$Flow) / alt_agf_aso$Flow
quantile(alt_agf_aso$pct_chg)

bxp <- boxplot(-100.0 * as.numeric(alt_agf_aso$pct_chg) ~ alt_agf_aso$year, ylab="Percent of Flow in Aug-Oct Withdrawn", main="Demand as Percent of Flow at Little Falls, 1997-2010")
bxp


gf_alt_usgs <- sqldf(
  "
    select a.Date, a.X_00060_00003 as flow_obs, b.gf_mgd, 
      (a.X_00060_00003 + b.gf_mgd * 1.547) as flow_baseline
    from historic as a
    left outer join icprb_prod_mon_mean as b 
    on (
      a.month = b.month
    )
    order by a.Date
  "
)




gf_alt_usgs$year <- year(gf_alt_usgs$Date)
gf_alt_usgs$mon <- month(gf_alt_usgs$Date)

gf_aso_alt_usgs <- sqldf(
  "
    select year, avg(flow_obs) as flow_obs,
      avg(flow_baseline) as flow_baseline
      from gf_alt_usgs
      where mon in (8, 9, 10)
      group by year
      order by year
  "
)

# pre vs post-WD
barplot(
  cbind(flow_baseline, flow_obs) ~ year, data=gf_aso_alt_usgs,
  col=c("blue", "black"),
  main="Pre-Withdrawal vs. Post-Withdrawal Aug-Sep Flow, 1895-2010",
  beside=TRUE,
  ylim=c(0,25000)
)

lm_aso_all <- lm(gf_aso_alt_usgs$flow_obs ~ index(gf_aso_alt_usgs))
barplot(
  flow_obs ~ year, data=gf_aso_alt_usgs,
  col=c("blue"),
  main="Aug-Sep Flow, 1895-2022",
  beside=TRUE,
  ylim=c(0,25000)
)
abline(lm_aso_all)

# 1997 forward
gf_aso_1997 <- sqldf("select * from gf_aso_alt_usgs where year >= 1997")

lm_aso <- lm(gf_aso_1997$flow_obs ~ index(gf_aso_1997))

barplot(
  flow_obs ~ year, data=gf_aso_1997,
  col=c("blue"),
  main="Aug-Sep Flow, 1997-2022",
  beside=TRUE,
  ylim=c(0,25000)
)
abline(lm_aso)



# little falls based on usgs 
lf_alt_usgs <- sqldf(
  "
    select a.year, a.mon, a.Date, a.X_00060_00003 as flow_obs, 
    b.X_00060_00003 as flow_baseline
    from lf_usgs as a
    left outer join lf_usgs_adj as b 
    on (
      a.Date = b.Date
    )
    order by a.Date
  "
)
lf_aso_alt_usgs <- sqldf(
  "
    select year, avg(flow_obs) as flow_obs,
      avg(flow_baseline) as flow_baseline
      from lf_alt_usgs
      where mon in (8, 9, 10)
      group by year
      order by year
  "
)

lm_uaso_all <- lm(lf_aso_alt_usgs$flow_obs ~ index(lf_aso_alt_usgs))
barplot(
  flow_obs ~ year, data=lf_aso_alt_usgs,
  col=c("blue"),
  main="Aug-Sep Flow, 1895-2022",
  beside=TRUE,
  ylim=c(0,25000)
)
abline(lm_uaso_all)
lf_aso_alt_usgs_1997 <- sqldf(
  "
   select * from lf_aso_alt_usgs where year >= 1997"
)
lm_uaso_1997 <- lm(lf_aso_alt_usgs_1997$flow_obs ~ index(lf_aso_alt_usgs_1997))
barplot(
  flow_obs ~ year, data=lf_aso_alt_usgs_1997,
  col=c("blue"),
  main="Aug-Sep Flow, 1997-2022",
  beside=TRUE,
  ylim=c(0,25000)
)
abline(lm_uaso_1997)

# percent change in l30
lfaz = zoo(lf_alt_usgs$flow_obs/1.547, order.by = as.Date(lf_alt_usgs$Date))
lfbz = zoo(lf_alt_usgs$flow_baseline/1.547, order.by = as.Date(lf_alt_usgs$Date))

lfa_lf = group2(lfaz, "calendar")[,c('year', '30 Day Min')]
names(lfa_lf) <- c('year', 'lf30')
lfb_lf = group2(lfbz, "calendar")[,c('year', '30 Day Min')]
names(lfb_lf) <- c('year', 'lf30')

lfb <- sqldf(
  "select a.year, a.lf30, b.lf30
   from lfa_lf as a
   left outer join lfb_lf as b
   on (a.year = b.year)
   where b.year is not null
   and b.lf30 is not null
   and a.lf30 is not null
   order by a.year
  "
)
colnames(lfb) <- c('Year', 'PostWD', 'Baseline')

lfb$pct_chg <- (lfb$PostWD - lfb$Baseline) / lfb$Baseline
lfb$pct_decrease <- -1.0 * (lfb$PostWD - lfb$Baseline) / lfb$Baseline
lm_lfb <- lm(lfb$pct_decrease ~ index(lfb))
summary(lm_lfb)
barplot( 
  lfb$pct_decrease ~ lfb$Year,
  col=c("tan"),
  main="% Reduction in 30 Day Low Flow due to Demand",
  beside=TRUE
)
abline(lm_lfb)

lfb_1997 <- sqldf(
  "select a.year, a.lf30, b.lf30
   from lfa_lf as a
   left outer join lfb_lf as b
   on (a.year = b.year)
   where b.year is not null
   and b.lf30 is not null
   and a.lf30 is not null
   and a.year >= 1984
   order by a.year
  "
)
colnames(lfb_1997) <- c('Year', 'PostWD', 'Baseline')

lfb_1997$pct_chg <- (lfb_1997$PostWD - lfb_1997$Baseline) / lfb_1997$Baseline
lfb_1997$pct_decrease <- -1.0 * (lfb_1997$PostWD - lfb_1997$Baseline) / lfb_1997$Baseline
lm_lfb_1997 <- lm(lfb_1997$pct_decrease ~ index(lfb_1997))
summary(lm_lfb_1997)
barplot( 
  lfb_1997$pct_decrease ~ lfb_1997$Year,
  col=c("tan"),
  main="% Reduction in 30 Day Low Flow due to Demand",
  beside=TRUE
)
abline(lm_lfb_1997)




bp <- barplot(
  cbind(Baseline, PostWD) ~ Year, data=lfb,
  col=c("blue", "black"),
  main="Pre-Withdrawal vs. Post-Withdrawal 30 Day Low Flow, 1997-2010",
  beside=TRUE,
  ylim=c(0,4000)
)
#text(bp, 4500, round(100*lfb$pct_chg),cex=1,pos=3) 
#text(bp, 4500, round(100*lfb$pct_chg)) 

bp
quantile(lfb$pct_chg)
