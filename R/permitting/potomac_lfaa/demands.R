icprb_daily_2025_prod <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/PRRISM_2025_nocc_for_vadeq.csv")
icprb_daily_2025_prod$Date <- as.Date(icprb_daily_2025_prod$Date,format="%Y/%m/%d")

icprb_monthly_prod <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/wma_production.csv")
icprb_monthly_prod$month <- month(as.Date(icprb_monthly_prod$thisdate,format="%m/%d/%Y"))
icprb_monthly_prod$year <- year(as.Date(icprb_monthly_prod$thisdate,format="%m/%d/%Y"))
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

icprb_prod_mon_mean <- sqldf(
  "
   select month,
     avg(wssc_pot) as wssc_pot,
     avg(wa_gf) as  wa_gf,
     avg(wa_lf) as wa_lf,
     avg(fw_pot) as fw_pot,
     avg(rville) as rville,
     avg(up_cu) as up_cu,
     avg(wssc_pot + wa_gf + fw_pot + rville + up_cu) as gf_mgd
   from icprb_monthly_prod where year >= 2015
   group by month
  "
)

demand_lf <- sqldf(
  "
   select a.Date, a.year, a.month,
    (b.wssc_pot + b.wa_gf + b.wa_lf
      + b.fw_pot + b.rville) as demand_max_mgd,
      c.wd_pot_mgd as demand_2025_old_mgd,
      d.lfalls_wd_mgd as demand_mgd,
      a.Flow
   from nat_lf as a
   left outer join icprb_prod_max as b
   on (
     a.month = b.month
   )
   left outer join icprb_daily_2025_prod as c
   on (
     c.Date = a.Date
   )
   left outer join icprb_daily_nat_lf as d
   on (
     d.Date = a.Date
   )
  "
)

demand_lf <- sqldf("select * from demand_lf where demand_mgd is not null")

rbind(
  quantile(demand_lf$demand_mgd),
  quantile(demand_lf$demand_2025_old_mgd),
  quantile(demand_lf$demand_max_mgd)
)
