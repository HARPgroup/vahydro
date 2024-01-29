library(ggplot2)
# load the Weighted Usable Area Table
wua_gf <- read.table(
  "https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac/potomac_lfaa/wua_gf.csv"
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
summer_plotdata <- sqldf(
  "
    select * from plotdata 
    where month in ('Aug', 'Sep', 'Oct')
  "
)

plot(summer_plotdata$smb_adult ~ summer_plotdata$year)
# SMB Adult
boxplot(
  summer_plotdata$smb_adult ~ summer_plotdata$year,
  main=paste("Change in Habitat Due to Withdrawal for SMB(adult)", "\n", min(summer_plotdata$Date), "to", max(summer_plotdata$Date)),
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

# Greenside Darter adult
boxplot(
  summer_plotdata$gd_adult ~ summer_plotdata$year,
  main="Change in Habitat Due to Withdrawal for GS(adult) 1930-2022",
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

fish_sls <- names(summer_plotdata)
fish_names <- list(
  bg_fry = "Bluegill (fry)",
  bg_juv = "Bluegill (juvenile)",
  bg_spawn = "Bluegill (spawn)",
  bg_adult = "Bluegill (adult)",
  cc_fry = "Channel cat (fry)",
  cc_adult = "Channel cat (adult)",
  cc_spawn = "Channel cat (spawn)",
  gd_spawn = "Greenside Darter(spawn)",
  gd_juv = "Greenside Darter (juvenile)",
  gd_adult = "Greenside Darter (adult)",
  gs_fry = "Gizzard Shad (fry)",
  gs_juv = "Gizzard Shad (juvenile)",
  gs_adult = "Gizzard Shad (adult)",
  gs_spawn = "Gizzard Shad (spawn)",
  smb_fry = "Smallmouth Bass (fry)",
  smb_juv = "Smallmouth Bass (juvenile)",
  smb_spawn = "Smallmouth Bass (spawn)",
  smb_inc = "Smallmouth Bass (incubation)",
  smb_adult = "Smallmouth Bass (adult)",
  ws_fry = "White Sucker (fry)",
  ws_spawn = "White Sucker (spawn)"
)

fish_sls <- fish_sls[!(fish_sls %in% c('month', 'year', 'Date', 'Flow', 'Flow2'))]
for (f in fish_sls) {
  print(f)
  boxplot(
    summer_plotdata[,f] ~ summer_plotdata$year,
    main=paste("Aug-Oct Habitat and Withdrawal for", fish_names[f],"1930-2022"),
    ylab="% Change in Habitat",
    xlab="Year"
  )
  abline(h = -10, col="blue")
  abline(h = -20, col="red")
  legend(
    "topleft", 
    c('Habitat Change', '-10% line', '-20% line'), 
    fill=c('black', 'blue','red')
  )
}

