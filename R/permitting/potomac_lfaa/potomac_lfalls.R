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
historic$month <- month(historic$Date)
historic$year <- year(historic$Date)
gage_sum_historic <- om_flow_table(historic, "X_00060_00003")

# Load the IFIM feature and data
# to do: put this on github as json data
source("c:/usr/local/home/git/vahydro/R/permitting/potomac_lfaa/ifim_data_lfalls.R")

# load PoR time series from Gage and ICPRB
# compare PoR gage time series with
icprb_monthly_lf <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/lfalls_nat_monthly_data.csv")
icprb_monthly_prod <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/wma_production.csv")
icprb_monthly_prod$month <- month(as.Date(icprb_monthly_prod$thisdate,format="%m/%d/%Y"))
icprb_monthly_prod$year <- year(as.Date(icprb_monthly_prod$thisdate,format="%m/%d/%Y"))

# monthly mean flows from ICPRB
da_por <- 9651.0 # https://waterdata.usgs.gov/nwis/uv?site_no=01638500
da_lf <- 11586.6 # d.dh/admin/content/dh_features/manage/68363/dh_properties

nat_lf <- historic[c("Date", "X_00060_00003", "year", "month")]
colnames(nat_lf) <- c('Date', 'Flow', "year", "month")
nat_lf$Flow <- (da_lf / da_por) * nat_lf$Flow

QLF_usgs <- historic
QLF_usgs$X_00060_00003 <- QLF_usgs$X_00060_00003 * 1.20056
Qmonth_LF_usgs <- sqldf("select month, year, avg(X_00060_00003) as Flow from QLF_usgs group by year, month")
Qmonth_diff <- sqldf(
  "
    select a.year as year, a.month, (b.lfalls_nat - Flow) as dQ
    from Qmonth_LF_usgs as a
    left outer join icprb_monthly_lf as b
    on (
      a.month = b.month
      and a.year = b.cyear
    )
    order by a.year, a.month
  "
)


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

alt_lf <- sqldf(
  "
   select a.Date, a.year, a.month,
    (b.wssc_pot + b.wa_gf + b.wa_lf
      + b.fw_pot + b.rville) as demand_mgd,
      a.Flow
   from nat_lf as a
   left outer join icprb_prod_max as b
   on (
     a.month = b.month
   )
  "
)

alt_lf <- sqldf(
  "
    select *,
      (Flow * 0.2)/1.547 as avail_p20_mgd,
      (Flow * 0.3)/1.547 as avail_p30_mgd,
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
    from alt_lf
  "
)

# add in the demands, factoring for flowby
alt_lf <- sqldf(
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
        WHEN demand_mgd > avail_p30_mgd THEN avail_p30_mgd
        ELSE demand_mgd
      END as wd_p30_mgd,
      CASE
        WHEN demand_mgd > avail_q500_mgd THEN avail_q500_mgd
        ELSE demand_mgd
      END as wd_q500_mgd
    from alt_lf as a
    order by Date
  "
)

# calculate release needed
alt_lf <- sqldf(
  "
    select a.*,
      demand_mgd - wd_curr_mgd as need_curr_mgd,
      demand_mgd - wd_p20_mgd as need_p20_mgd,
      demand_mgd - wd_p30_mgd as need_p30_mgd,
      demand_mgd - wd_q500_mgd as need_q500_mgd,
      Flow - wd_curr_mgd * 1.547 as Flow_curr,
      Flow - wd_p20_mgd * 1.547 as Flow_p20,
      Flow - wd_p30_mgd * 1.547 as Flow_p30,
      Flow - wd_q500_mgd * 1.547 as Flow_q500
    from alt_lf as a
    order by Date
  "
)

# calculate release needed
need_lf <- sqldf(
  "
    select year, sum(need_curr_mgd) as need_curr_mgd,
      sum(need_p20_mgd) as need_p20_mgd,
      sum(need_p30_mgd) as need_p30_mgd,
      sum(need_q500_mgd) as need_q500_mgd
    from alt_lf
    group by year
  "
)

rbind(
  round(quantile(need_lf$need_curr_mgd, probs=c(0,0.25,0.5,0.75,0.9,0.95,0.99,1.0))),
  round(quantile(need_lf$need_q500_mgd, probs=c(0,0.25,0.5,0.75,0.9,0.95,0.99,1.0))),
  round(quantile(need_lf$need_p20_mgd, probs=c(0,0.25,0.5,0.75,0.9,0.95,0.99,1.0))),
  round(quantile(need_lf$need_p30_mgd, probs=c(0,0.25,0.5,0.75,0.9,0.95,0.99,1.0)))
)


usgs_monthly <- sqldf(
  "
  select year, month, avg(X_00060_00003) as usgs_por
  from historic
  group by year, month
"
)


sqldf(
  "
   select a.month, avg(usgs_por) as usgs_por,
     avg(b.lfalls_nat) as icprb_lfalls,
     avg(b.lfalls_nat)/avg(usgs_por) as da_fact
   from usgs_monthly as a
   left outer join icprb_monthly_lf as b
   on (
     a.year = b.cyear
     and a.month = b.month
   )
   where a.year = 1930
   group by a.month
   order by a.month
  "
)
