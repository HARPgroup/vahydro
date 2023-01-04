# load the Weighted Usable Area Table
wua_gf <- read.table(
  "https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/wua_gf.csv"
  , header=TRUE, sep=","
)
ifim_da_sqmi = 11010
ifim_site_name = "Great Falls"

curr_plot_gf100 <- pothab_plot(
  wua_gf, lf_alt_usgs, "flow_baseline", "flow_obs",
  1.0, ifim_da_sqmi,
  "Great Falls", "Current"
)
plotdata <- curr_plot_gf100$all_pctile_data
plotdata$year <- year(plotdata$Date)

plot(plotdata$smb_adult ~ plotdata$year)
boxplot(
  plotdata$smb_adult ~ plotdata$year,
  main="Change in Habitat Due to Withdrawal for SMB(adult) 1930-2022",
  ylab="% Change in Habitat",
  xlab="Year"
)
abline(h = -10, col="blue")
abline(h = -20, col="red")
legend(
  "topright", 
  c('Range of Modeled Habitat Change', '-10% line', '-20% line'), 
  fill=c('black', 'blue','red')
)


