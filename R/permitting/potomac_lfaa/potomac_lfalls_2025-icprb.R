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

nat_lf <- as.data.frame(icprb_daily_nat_lf)
nat_lf$Date <- as.Date(nat_lf$Date)
nat_lf$month <- month(nat_lf$Date)
nat_lf$year <- year(nat_lf$Date)
nat_lf$Flow <- nat_lf$lfalls_nat * 1.547


