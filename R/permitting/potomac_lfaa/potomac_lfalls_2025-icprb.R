library("sqldf")
# Load the IFIM feature and data
# to do: put this on github as json data
source("c:/usr/local/home/git/vahydro/R/permitting/potomac_lfaa/ifim_data_lfalls.R")

# load PoR time series from Gage and ICPRB
# compare PoR gage time series with
# icprb_daily_2025_lf <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/PRRISM_2025_nocc_for_vadeq.csv")
# before revision, had data thru 2018 which was nice
#icprb_daily_nat_lf <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/PRRISM_2025_nocc_for_vadeq.csv")
# revised is C.Schultz best timeseries, only goes thru 2009
icprb_daily_nat_lf <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/PRRISM_2025_nocc_for_vadeq-revised.csv")

icprb_daily_nat_lf <- as.data.frame(icprb_daily_nat_lf)
# may change to need format="%m/%d/%Y"
icprb_daily_nat_lf$Date <- as.Date(icprb_daily_nat_lf$Date, format="%Y/%m/%d")
nat_lf <- icprb_daily_nat_lf
nat_lf$month <- month(nat_lf$Date)
nat_lf$year <- year(nat_lf$Date)
nat_lf$Flow <- nat_lf$lfalls_nat * 1.547
# clean up in case csv is hinky
nat_lf <- sqldf("select * from nat_lf where Flow is not null")

# from IFIM survey:
# - DA at Great Falls IFIM site is 11515.76 square miles
# - DA at Little Falls site is 11562.79
nat_gf <- nat_lf
nat_gf$Flow <- nat_gf$lfalls_nat * 1.547 * (11515.76 / 11562.79)
