# Load the baseline flow time series
# into dataframe nat_lf
# usgs based
source("c:/usr/local/home/git/vahydro/R/permitting/potomac_lfaa/potomac_lfalls.R")
# icprb Monthly
#source("c:/usr/local/home/git/vahydro/R/permitting/potomac_lfaa/potomac_lfalls_icprb.R")
# icprb Daily, 2025

# now do the flowby and CU calcs
# setting values in dataframe alt_lf
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/alt_lf.R")

# Load plotting helper functions
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/hab_plot.R")


curr_plot100 <- pothab_plot(
  wua_lf, alt_lf, "Flow", "Flow_curr",
  1.0, ifim_da_sqmi,
  "Little Falls", "Current"
)


curr_plot <- pothab_plot(
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
p30_plot <- pothab_plot(
  wua_lf, alt_lf, "Flow", "Flow_p30",
  0.1, ifim_da_sqmi,
  "Little Falls", "Current"
)

p20_plot100 <- pothab_plot(
  wua_lf, alt_lf, "Flow", "Flow_p20",
  1.0, ifim_da_sqmi,
  "Little Falls", "Current"
)
p30_plot100 <- pothab_plot(
  wua_lf, alt_lf, "Flow", "Flow_p30",
  1.0, ifim_da_sqmi,
  "Little Falls", "Current"
)
q500_plot100 <- pothab_plot(
  wua_lf, alt_lf, "Flow", "Flow_q500",
  1.0, ifim_da_sqmi,
  "Little Falls", "Current"
)
curr_plot100 + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 100mgd flowby (10%)") )
q500_plot100 + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 500mgd flowby (10%)") )
p20_plot100 + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 80% flowby (10%)") )
p30_plot100 + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 70% flowby (10%)") )


curr_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 100mgd flowby (all)") )
q500_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 500mgd flowby (all)") )
p20_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 80% flowby (all)") )
p30_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 70% flowby (all)") )

# export all data for review
write.table(
  curr_plot$all_pctile_data,
  file = paste(github_location,"/vahydro/R/permitting/potomac_lfaa/",'ifim_wua_chg_current_',elid,'.csv',sep=""),
  sep = ","
)

curr_plot_alt_tbl <- hab_alt_tbl(curr_plot)
curr_plot_alt_tbl <- hab_alt_tbl(curr_plot)
curr_plot_alt_tbl <- hab_alt_tbl(curr_plot)

# need change
need_lf <- sqldf(
  "
    select year,
      sum(need_curr_mgd) as need_curr_mgd,
      sum(need_q500_mgd) as need_q500_mgd,
      sum(need_p20_mgd) as need_p20_mgd
    from alt_lf
    group by year
    order by year
  "
)

yrs = c(1930, 2002, 2007, 2008, 2015, 2016,2019)
yrs = c(1930)

for (yr in yrs) {
  # Box Plot for 1931
  alt_lf_yr <- sqldf(paste("select * from alt_lf where year = ", yr))

  # just look at the box plot
  yrplot <- pothab_plot(
    wua_lf, alt_lf_yr, "Flow", "Flow_curr",
    1.0, ifim_da_sqmi,
    "Little Falls", "Current"
  )
  yrplot +
    labs(title = paste("Habitat Change, ICPRB Max Demand Little Falls,", yr, "only.") )
  + ylim(c(-100,100))

  plot(alt_lf_yr$Flow ~ nat_lf_yr$Date, col='blue', ylim=c(0,5000))
  points(alt_lf_yr$Flow_curr ~ alt_lf_yr$Date, col='red')

  pd_nat_flow_table <- om_flow_table(nat_lf_yr, "Flow")
  pd_alt_flow_table <- om_flow_table(alt_lf_yr, "Flow")


  yrplot$data$pctchg <- round(yrplot$data$pctchg, 2)
  yrplot$data[is.na(yrplot$data$pctchg),]$pctchg <- 0.0
  ifim_sumdata_yr <- xtabs(pctchg ~ metric + flow, data = yrplot$data)
  ifim_mat <- as.data.frame.matrix(ifim_sumdata_yr)
  ifim_mat <- cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
  yrplot$data.formatted <-  cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
  tbls5pct <- as.data.frame(yrplot$data.formatted)
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
