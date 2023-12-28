# load the Weighted Usable Area Table
wua_lf <- read.table(
  "https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/wua_lf.csv"
  , header=TRUE, sep=","
)

# Load the baseline flow time series
# into dataframe nat_lf
# usgs based
#source("c:/usr/local/home/git/vahydro/R/permitting/potomac_lfaa/potomac_lfalls.R")
# icprb Monthly
#source("c:/usr/local/home/git/vahydro/R/permitting/potomac_lfaa/potomac_lfalls_monthly-icprb.R")
# icprb Daily, 2025
source("c:/usr/local/home/git/vahydro/R/permitting/potomac_lfaa/potomac_lfalls_2025-icprb.R")

# load the demand time series
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/demands.R")


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
curr_plot100 + ylim(c(-75,75)) + labs(title = paste("Habitat Change, Little Falls, 100mgd flowby (all)") )
q500_plot100 + ylim(c(-75,75)) + labs(title = paste("Habitat Change, Little Falls, 500mgd flowby (all") )
p30_plot100 + ylim(c(-75,75)) + labs(title = paste("Habitat Change, Little Falls, 70% flowby (all)") )
p20_plot100 + ylim(c(-75,75)) + labs(title = paste("Habitat Change, Little Falls, 80% flowby (all)") )


curr_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 100mgd flowby") )
q500_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 500mgd flowby") )
p30_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 70% flowby") )
p20_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Little Falls, 80% flowby") )

# export all data for review
write.table(
  curr_plot$all_pctile_data,
  file = paste(github_location,"/vahydro/R/permitting/potomac_lfaa/",'ifim_wua_all_current_little_falls','.csv',sep=""),
  sep = ","
)
# export flow table for review
write.table(
  lf_flow_table,
  file = paste(github_location,"/vahydro/R/permitting/potomac_lfaa/",'lf_flow_table','.csv',sep=""),
  sep = ","
)
# export flow alteration summary data for review
write.table(
  lf_flow_alt_table,
  file = paste(github_location,"/vahydro/R/permitting/potomac_lfaa/",'lf_flow_alt_table','.csv',sep=""),
  sep = ","
)
# export habitat alteration summary data for review
write.table(
  hab_alt_tbl(curr_plot),
  file = paste(github_location,"/vahydro/R/permitting/potomac_lfaa/",'ifim_wua_chg_current_little_falls','.csv',sep=""),
  sep = ","
)

curr_plot_alt_tbl <- hab_alt_tbl(curr_plot)
q500_plot_alt_tbl <- hab_alt_tbl(q500_plot)
p20_plot_alt_tbl <- hab_alt_tbl(p20_plot)
p30_plot_alt_tbl <- hab_alt_tbl(p30_plot)

alt_lf_2019 <- sqldf("select * from alt_lf where year = 2019")
curr_plot_lf2019 <- pothab_plot(
  wua_lf, alt_lf_2019, "Flow", "Flow_curr",
  1.0, ifim_da_sqmi,
  "Little Falls", "Current 2019"
)
curr_plot_lf2019 + ylim(c(-75,75)) + labs(title = paste("Habitat Change, Little Falls, 100mgd flowby (2019)") )
