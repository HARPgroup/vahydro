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

# Load the gage flow record
gageid = '01638500'
historic <- dataRetrieval::readNWISdv(gageid,'00060')
historic$month <- month(historic$Date)
historic$year <- year(historic$Date)
gage_sum_historic <- om_flow_table(historic, "X_00060_00003")

# Load the IFIM feature and data
# to do: put this on github as json data
source("c:/usr/local/home/git/vahydro/R/permitting/potomac_lfaa/ifim_data_lfalls.R")

# load PoR time series from Gage and ICPRB
# compare PoR gage time series with
icprb_monthly_lf <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/lfalls_nat_monthly_data.csv")
icprb_monthly_prod <- read.csv("https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/wma_production.csv")
icprb_monthly_prod$month <- month(as.Date(icprb_monthly_prod$thisdate,format="%m/%d/%Y"))
icprb_monthly_prod$year <- year(as.Date(icprb_monthly_prod$thisdate,format="%m/%d/%Y"))

# area
# monthly mean flows from ICPRB
da_por <- 9651.0 # https://waterdata.usgs.gov/nwis/uv?site_no=01638500
da_lf <- 11586.6 # d.dh/admin/content/dh_features/manage/68363/dh_properties

nat_lf <- historic[c("Date", "X_00060_00003", "year", "month")]
colnames(nat_lf) <- c('Date', 'Flow', "year", "month")
nat_lf$Flow <- (da_lf / da_por) * nat_lf$Flow

# now do the flowby and CU calcs
source("https://raw.githubusercontent.com/HARPgroup/vahydro/master/R/permitting/potomac_lfaa/alt_lf.R")
