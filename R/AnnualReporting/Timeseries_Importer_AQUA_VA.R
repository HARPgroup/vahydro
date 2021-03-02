library(httr)

#----------------------------------------------
# USER INPUTS
site <- "http://deq2.bse.vt.edu/d.dh"
datafile <- "C:/Users/jklei/Desktop/aqua_2021/aqua_2020.csv"
reporting_year <- "2020"


basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))

# load libraries
source(paste(hydro_tools,"VAHydro-2.0/rest_functions.R", sep = "/")); 
source(paste(basepath,"auth.private",sep = '/'))
token <- rest_token (site, token, rest_uname = rest_uname, rest_pw = rest_pw) #token needed for REST

options(scipen = 999) #disable scientific notation data format

#---Load file
data <- read.csv(file = datafile, header = TRUE, sep = ",")

#---Summary variables
run_started <- Sys.time()
num_recs <- length(data[, 1])

#i <- 1
#---Begin MP Feature Loop
for (i in 1:num_recs) {
  print(paste("Processing MP ", i, " of ", num_recs, sep = ""))
  
  
  hydroid <- paste(data[i,]$mp_hydroid)
    # IF STATEMENT TO ONLY IMPORT DATA FOR EXISTING VAHYDRO WELLS
    if (hydroid == "NA") {
        print(paste("MP Does Not Exist In VAHydro OR Reports Quarterly - Skipping MP ", i, " of ", num_recs, sep = ""))
        next
    }
    
  print(paste("Processing  MP Feature ", i, " of ", num_recs, sep = ""))
  
  JAN <- as.numeric(as.character(data[i,]$jan_mgm))
  FEB <- as.numeric(as.character(data[i,]$feb_mgm))
  MAR <- as.numeric(as.character(data[i,]$mar_mgm))
  APR <- as.numeric(as.character(data[i,]$apr_mgm))
  MAY <- as.numeric(as.character(data[i,]$may_mgm))
  JUN <- as.numeric(as.character(data[i,]$jun_mgm))
  JUL <- as.numeric(as.character(data[i,]$jul_mgm))
  AUG <- as.numeric(as.character(data[i,]$aug_mgm))
  SEP <- as.numeric(as.character(data[i,]$sep_mgm))
  OCT <- as.numeric(as.character(data[i,]$oct_mgm))
  NOV <- as.numeric(as.character(data[i,]$nov_mgm))
  DEC <- as.numeric(as.character(data[i,]$dec_mgm))
  
  timeseries_values <- c(JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC)
  dates <- c(paste(reporting_year, "-01-01", sep = ""),
             paste(reporting_year, "-02-01", sep = ""),
             paste(reporting_year, "-03-01", sep = ""),
             paste(reporting_year, "-04-01", sep = ""),
             paste(reporting_year, "-05-01", sep = ""),
             paste(reporting_year, "-06-01", sep = ""),
             paste(reporting_year, "-07-01", sep = ""),
             paste(reporting_year, "-08-01", sep = ""),
             paste(reporting_year, "-09-01", sep = ""),
             paste(reporting_year, "-10-01", sep = ""),
             paste(reporting_year, "-11-01", sep = ""),
             paste(reporting_year, "-12-01", sep = ""))
  timeseries_values <- data.frame(timeseries_values, dates)
    
  # j <- 8
  #---Begin MP Timeseries Loop
  num_timeseries_values <- length(timeseries_values$timeseries_values)
  for (j in 1:num_timeseries_values) {
      
    #IMPORT MONTHLY DATA
    varkey <- "wd_mgm" #variable id for wd_mgm
    tsvalue <- as.numeric(timeseries_values$timeseries_values[j])
      
    # FORMAT TIMESERIES DATA
    print(paste("---Formatting Timeseries ", j, " of ", num_timeseries_values, sep = ""))
    print(paste("----- ", dates[j], " -> ", as.numeric(as.character(timeseries_values$timeseries_values[j])), sep = ""))
        
    # convert date to UNIX timestamp
    month <- as.character(timeseries_values$dates[j])
    tstime <- as.numeric(as.POSIXct(month, origin = "1970-01-01"))

    inputs <- data.frame(
      featureid = hydroid,
      varkey = varkey,
      entity_type = "dh_feature",
      tsvalue = as.numeric(format(tsvalue, scientific=F)),
      tstime = tstime
    )
    ts <- postTimeseries(inputs, site)
       
  }  #---END Timeseries Loop
    
  #Set max day
  maxval <- as.numeric(as.character(data[i,]$max_day_mgd))
  
  if (is.na(maxval) == TRUE) {
      print(paste("MP 'Water Use - Max Daily' is NA - Skipping MP ", i, " of ", num_recs, sep = ""))
      next
  }
    
  maxmo <- as.numeric(as.character(data[i, ]$month_max))
  if (maxmo < 10){
      maxmo <- paste0("0",maxmo)
  }
    
  max_day_inputs <- data.frame(
    featureid = hydroid,
    varkey = "max_daily_wd_mgd",
    entity_type = "dh_feature",
    tsvalue = maxval,
    tstime = as.numeric(as.POSIXct(paste(reporting_year, "-", maxmo, "-01", sep = ""), origin = "1970-01-01"))
  )
  max_day_ts <- postTimeseries(max_day_inputs, site)
    
    
}  #---END MP Feature For Loop


################################
################################
