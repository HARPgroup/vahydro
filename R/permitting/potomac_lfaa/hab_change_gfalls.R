# load the Weighted Usable Area Table
wua_gf <- read.table(
  "https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/wua_gf.csv"
  , header=TRUE, sep=","
)
ifim_da_sqmi = 11010
ifim_site_name = "Great Falls"
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
# setting values in dataframe alt_gf
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/alt_gf.R")

# Load plotting helper functions
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/hab_plot.R")


curr_plot_gf100 <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_curr",
  1.0, ifim_da_sqmi,
  "Great Falls", "Current"
)

curr_plot_gf <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_curr",
  0.1, ifim_da_sqmi,
  "Great Falls", "Current"
)
q500_plot_gf <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_q500",
  0.1, ifim_da_sqmi,
  "Great Falls", "Current"
)
p20_plot_gf <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_p20",
  0.1, ifim_da_sqmi,
  "Great Falls", "Current"
)
p30_plot_gf <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_p30",
  0.1, ifim_da_sqmi,
  "Great Falls", "Current"
)

p20_plot_gf100 <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_p20",
  1.0, ifim_da_sqmi,
  "Great Falls", "Current"
)
p30_plot_gf100 <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_p30",
  1.0, ifim_da_sqmi,
  "Great Falls", "Current"
)
q500_plot_gf100 <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_q500",
  1.0, ifim_da_sqmi,
  "Great Falls", "Current"
)
curr_plot_gf100 + ylim(c(-75,75)) + labs(title = paste("Habitat Change, Great Falls, 300mgd flowby (all)") )
q500_plot_gf100 + ylim(c(-75,75)) + labs(title = paste("Habitat Change, Great Falls, 500mgd flowby (all)") )
p30_plot_gf100 + ylim(c(-75,75)) + labs(title = paste("Habitat Change, Great Falls, 70% flowby (all)") )
p20_plot_gf100 + ylim(c(-75,75)) + labs(title = paste("Habitat Change, Great Falls, 80% flowby (all)") )


curr_plot_gf + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 300mgd flowby (drought)") )
q500_plot_gf + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 500mgd flowby (drought)") )
p30_plot_gf + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 70% flowby (drought)") )
p20_plot_gf + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 80% flowby (drought)") )

# export all data for review
write.table(
  curr_plot_gf$all_pctile_data,
  file = paste(github_location,"/vahydro/R/permitting/potomac_lfaa/",'ifim_wua_all_current_great_falls','.csv',sep=""),
  sep = ","
)
# export flow alteration summary data for review
write.table(
  gf_flow_alt_table,
  file = paste(github_location,"/vahydro/R/permitting/potomac_lfaa/",'gf_flow_alt_table','.csv',sep=""),
  sep = ","
)
# export habitat alteration summary data for review
write.table(
  hab_alt_tbl(curr_plot_gf),
  file = paste(github_location,"/vahydro/R/permitting/potomac_lfaa/",'ifim_wua_chg_current_great_falls','.csv',sep=""),
  sep = ","
)

curr_plot_gf_alt_tbl <- hab_alt_tbl(curr_plot_gf)
q500_plot_gf_alt_tbl <- hab_alt_tbl(q500_plot_gf)
p20_plot_gf_alt_tbl <- hab_alt_tbl(p20_plot_gf)
p30_plot_gf_alt_tbl <- hab_alt_tbl(p30_plot_gf)

alt_gf_2019 <- sqldf("select * from alt_gf where year = 2019")
curr_plot_gf2019 <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_curr",
  1.0, ifim_da_sqmi,
  "Great Falls", "Current 2019"
)
curr_plot_gf2019 + ylim(c(-75,75)) + labs(title = paste("Habitat Change, Great Falls, 300mgd flowby (all)") )
