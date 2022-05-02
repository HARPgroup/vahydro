# load the Weighted Usable Area Table
wua_gf <- read.table(
  "https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/wua_gf.csv"
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
# setting values in dataframe alt_gf
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/alt_gf.R")

# Load plotting helper functions
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/hab_plot.R")


curr_plot100 <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_curr",
  1.0, ifim_da_sqmi,
  "Great Falls", "Current"
)


curr_plot <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_curr",
  0.1, ifim_da_sqmi,
  "Great Falls", "Current"
)
q500_plot <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_q500",
  0.1, ifim_da_sqmi,
  "Great Falls", "Current"
)
p20_plot <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_p20",
  0.1, ifim_da_sqmi,
  "Great Falls", "Current"
)
p30_plot <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_p30",
  0.1, ifim_da_sqmi,
  "Great Falls", "Current"
)

p20_plot100 <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_p20",
  1.0, ifim_da_sqmi,
  "Great Falls", "Current"
)
p30_plot100 <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_p30",
  1.0, ifim_da_sqmi,
  "Great Falls", "Current"
)
q500_plot100 <- pothab_plot(
  wua_gf, alt_gf, "Flow", "Flow_q500",
  1.0, ifim_da_sqmi,
  "Great Falls", "Current"
)
curr_plot100 + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 300mgd flowby (10%)") )
q500_plot100 + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 500mgd flowby (10%)") )
p30_plot100 + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 70% flowby (10%)") )
p20_plot100 + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 80% flowby (10%)") )


curr_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 300mgd flowby (all)") )
q500_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 500mgd flowby (all)") )
p30_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 70% flowby (all)") )
p20_plot + ylim(c(-100,100)) + labs(title = paste("Habitat Change, Great Falls, 80% flowby (all)") )

# export all data for review
write.table(
  curr_plot$all_pctile_data,
  file = paste(github_location,"/vahydro/R/permitting/potomac_lfaa/",'ifim_wua_chg_current_',elid,'.csv',sep=""),
  sep = ","
)

curr_plot_alt_tbl <- hab_alt_tbl(curr_plot)
q500_plot_alt_tbl <- hab_alt_tbl(q500_plot)
p20_plot_alt_tbl <- hab_alt_tbl(p20_plot)
p30_plot_alt_tbl <- hab_alt_tbl(p30_plot)
