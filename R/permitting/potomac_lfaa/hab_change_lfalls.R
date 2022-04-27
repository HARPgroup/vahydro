source("c:/usr/local/home/git/vahydro/R/permitting/potomac_lfaa/potomac_lfalls.R")


# now calc wua separately so we can look at a single species
wua_nat_lf <- wua.at.q_fxn(nat_lf[c("Date", "Flow")],wua_lf)
wua_nat_lf$Date <- nat_lf$Date
wua_nat_lf$Flow <- nat_lf$Flow
wua_alt_lf <- wua.at.q_fxn(alt_lf[c("Date", "Flow")],wua_lf)
wua_alt_lf$Date <- alt_lf$Date
wua_alt_lf$Flow <- alt_lf$Flow

pothab_plot <- function (
  wua_dat, all_dat, nat_col, alt_col,
  flow_pct, ifim_da_sqmi,
  site_name, scenario
  ) {
  # format the input data
  udat <- all_dat[c('Date', nat_col)]
  names(udat) <- c('Date', 'Flow')
  adat <- all_dat[c('Date', alt_col)]
  names(adat) <- c('Date', 'Flow')
  # just look at the box plot
  ifim_icprb_maxwd_lf <- ifim_wua_change_plot(
    udat,
    adat,
    wua_dat, flow_pct,
    "ifim_da_sqmi" = ifim_da_sqmi,
    runid_a = "6",
    metric_a = "Qbaseline",
    runid_b = "6",metric_b = "Qout"
  )
  ifim_icprb_maxwd_lf +
    labs(
      title = paste("Habitat Change,", site_name,",",flow_pct,"%ile")
      ) + ylim(c(-50,50))
  return(ifim_icprb_maxwd_lf)
}

allplot <- pothab_plot(
  wua_lf, alt_lf, "Flow", "Flow_curr",
  0.1, ifim_da_sqmi,
  "Little Falls", "Current"
)
q500_plot <- pothab_plot(
  wua_lf, alt_lf, "Flow", "Flow_q500",
  0.1, ifim_da_sqmi,
  "Little Falls", "Current"
)
p20_plot <- pothab_plot(
  wua_lf, alt_lf, "Flow", "Flow_p20",
  0.1, ifim_da_sqmi,
  "Little Falls", "Current"
)
allplot + ylim(c(-50,50))
p20_plot + ylim(c(-50,50))
q500_plot + ylim(c(-50,50))

yrs = c(1930, 2002, 2007, 2008, 2015, 2016,2019)
for (yr in yrs) {
  # Box Plot for 1931
  nat_lf_yr <- sqldf(paste("select * from nat_lf where year = ", yr))
  alt_lf_yr <- sqldf(paste("select * from alt_lf where year = ", yr))
  plot(nat_lf_yr$Flow ~ nat_lf_yr$Date, col='blue', ylim=c(0,5000))
  points(alt_lf_yr$Flow ~ nat_lf_yr$Date, col='red')

  # just look at the box plot
  ifim_icprb_maxwd_lf_yr <- ifim_wua_change_plot(
    nat_lf_yr[c('Date', 'Flow')],
    alt_lf_yr[c('Date', 'Flow')],
    wua_lf, 1.0,
    "ifim_da_sqmi" = ifim_da_sqmi,
    runid_a = "6",
    metric_a = "Qbaseline",
    runid_b = "6",metric_b = "Qout"
  )
  ifim_icprb_maxwd_lf_yr +
    labs(title = paste("Habitat Change, ICPRB Max Demand Little Falls,", yr, "only.") )
  + ylim(c(-50,50))

  pd_nat_flow_table <- om_flow_table(nat_lf_yr, "Flow")
  pd_alt_flow_table <- om_flow_table(alt_lf_yr, "Flow")


  ifim_icprb_maxwd_lf_yr$data$pctchg <- round(ifim_plot6_20$data$pctchg, 2)
  ifim_icprb_maxwd_lf_yr$data[is.na(ifim_icprb_maxwd_lf_yr$data$pctchg),]$pctchg <- 0.0
  ifim_sumdata_yr <- xtabs(pctchg ~ metric + flow, data = ifim_icprb_maxwd_lf_yr$data)
  ifim_mat <- as.data.frame.matrix(ifim_sumdata_yr)
  ifim_mat <- cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
  ifim_icprb_maxwd_lf_yr$data.formatted <-  cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
  tbls5pct <- as.data.frame(ifim_icprb_maxwd_lf_yr$data.formatted)
  write.table(
    tbls5pct$data.formatted,
    file = paste(export_path,'ifim_wua_chg',yr,elid,'.csv',sep=""),
    sep = ","
  )
}
ggsave(paste(export_path,'ifim_wua_chg',yr,elid,'.png',sep=""), width = 7, height = 4)




# WUA time series - flow ts should be 2 columns: Date, Flow
wua_ts1 <- wua.at.q_fxn(ts3,wua_lf)
#wua_ts1 <- wua.at.q_fxn(ts3)
wua_ts1 <- data.frame(ts3,wua_ts1)
wua_ts1$month <- month(wua_ts1$Date)
wua_ts1$year <- year(wua_ts1$Date)
wua_ts1$month <- month(wua_ts1$Date)

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
