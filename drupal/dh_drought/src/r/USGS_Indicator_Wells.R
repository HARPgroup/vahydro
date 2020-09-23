rm(list = ls())  #clear variables
library(dataRetrieval) #https://cran.r-project.org/web/packages/dataRetrieval/dataRetrieval.pdf
library(lubridate) #required for year()
library(sqldf) #required for SQL queries
library(openxlsx) #required  for exporting data to excel file, each well as separate sheet
# library(httr) 

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))

# load libraries
source(paste(hydro_tools,"VAHydro-2.0/rest_functions.R", sep = "/")); 
source(paste(basepath,"auth.private",sep = '/'))
token <- rest_token (base_url, token, rest_uname = rest_uname, rest_pw = rest_pw) #token needed for REST
site <- base_url

#USED TO EXPORT TABLES AS INDIVIDUAL CSVS, AND EXCEL FILE WITH MULTIPLE SHEETS
export_path <- 'C:/Users/jklei/Desktop/Potomac Monitoring Wells/exports/'

#Pull in list of all Potomac Monitoring Well dH Features 
URL <- paste(site,"potomac-monitoring-wells-export", sep = "/");
well_list <- read.table(URL,header = TRUE, sep = ",")
hydrocodes <- well_list$hydrocode
well_names <- well_list$Feature.Name


#==================================================================
#INITIATE LIST OF ALL WELLS DATA
annual_summary_list <- list()

#j <-1
#BEGIN LOOP THROUGH EACH USGS GAGE
for (j in 1:length(hydrocodes)) {
  print(paste("PROCESSING WELL: ",j," OF ",length(hydrocodes),sep=''))
  siteNumber = unlist(strsplit(toString(hydrocodes[j]), split='_', fixed=TRUE))[2]
  well_code <- substr(well_names[j], 22, nchar(well_names[j])) 
  print(paste("USGS siteNumber: ", siteNumber, sep=''))
  
  welldata <- whatNWISdata(siteNumber = siteNumber)
  #Parameter code '72019' = Depth to water level, feet below land surface (ft) https://help.waterdata.usgs.gov/code/parameter_cd_nm_query?parm_nm_cd=%25level%25&fmt=html
  #Data type 'dv' = Daily Values
  #RETRIEVE DATE WELL BEGAN RECORDING DAILY DEPTH TO WATER LEVEL 
  gwl_param <-          paste("SELECT begin_date
                              FROM welldata
                              WHERE parm_cd == 72019 AND data_type_cd == 'dv'
                              ORDER BY begin_date ASC
                              LIMIT 1",sep="")
  begin_date <- sqldf(gwl_param)$begin_date
  print(paste("Historic Record begining ",begin_date,sep=""))
  
  #RETREIEVE DATA FROM NWIS
  url <- paste("https://waterdata.usgs.gov/nwis/dv?cb_72019=on&format=rdb_meas&site_no=",siteNumber,"&referred_module=sw&period=&begin_date=",begin_date,"&end_date=",sep="")
  print(paste("Retrieving Data from NWIS using:",url))
  data <- read.table(url,header = TRUE, sep = "\t")
  
  #REMOVE USGS HEADER
  data <-data[-1,]
  
  #IDENTIFY COLUMN NAMES FOR "Depth to water level" STATISTIC
  max_colname <- colnames(data)[which(grepl('_72019_00001$', colnames(data)))] #COLUMN NAME ENDING WITH _72019_00001 - USGS CODE FOR "Depth to water level, feet below land surface (Maximum)"
  min_colname <- colnames(data)[which(grepl('_72019_00002$', colnames(data)))] #COLUMN NAME ENDING WITH _72019_00001 - USGS CODE FOR "Depth to water level, feet below land surface (Minimum)"

  #ADD COLUMNS FOR max, min, median
  if (length(min_colname) == 0) {
        #SOME WELLS ONLY RECORD DAILY MAX VALUES
          data_cols <-  paste("SELECT *,
                              ",max_colname," AS max,
                              '' AS min,
                              ",max_colname," AS median
                              FROM data ",sep="")
  } else {
          data_cols <-  paste("SELECT *,
                              ",max_colname," AS max,
                              ",min_colname," AS min,
                              CASE WHEN ",max_colname," > 0 AND ",min_colname," > 0 THEN (",max_colname,"+",min_colname,")/2
                		          ELSE ",max_colname,"
                              END AS median
                              FROM data",sep="")
  }
  data <- suppressWarnings(sqldf(data_cols))
  data$year <- year(data[,"datetime"])

  #EXCLUDE EMPTY MEDIANS (DAYS WHEN DATA WAS NOT RECORDED)
  #THIS IS NEEDED PRIOR TO CALCULATING ANNUAL median_depth, min_depth, max_depth STATISTICS
  data_rm_blanks <-     paste("SELECT *
                              FROM data
                              WHERE max != ''",sep="")
  data <- sqldf(data_rm_blanks)
  
  #CREATE DATAFRAME WITH annual median, min, max (CAST TO NUMERIC DATA TYPE, DECIMAL)
  annual_summaries <-   paste("SELECT year,
                              CAST(min(median) AS DEC) AS 'min_depth_ft',
                              CAST(max(median) AS DEC) AS 'max_depth_ft',
                              CAST(median(median) AS DEC) AS 'median_depth_ft'
                              FROM data 
                              GROUP BY year",sep="")
  annual_summaries <- sqldf(annual_summaries)
  
  #ADD COLUMN one_yr_diff
  one_yr_diff_sql <-    paste("SELECT *,
                              median_depth_ft - LAG(median_depth_ft)
                            	OVER (ORDER BY year) AS one_yr_diff
    	                        FROM annual_summaries
                              ORDER BY year",sep="")
  annual_summaries <- sqldf(one_yr_diff_sql)
  
  #ADD COLUMN one_yr_diff_rating
  rating_sql <-         paste("SELECT *,
          		                CASE WHEN one_yr_diff < 0 THEN 'IMPROVE'
          		                WHEN one_yr_diff > 0 THEN 'DECLINE'
          		                ELSE 'NA'
          		                END AS 'one_yr_diff_rating'
          		                FROM annual_summaries
                              ORDER BY year",sep="")
  annual_summaries <- sqldf(rating_sql)
  
  #ADD COLUMN five_yr_avg_diff
  five_yr_diff_sql <-  paste("SELECT *,
                              AVG(one_yr_diff) OVER (ORDER BY year ASC ROWS 4 PRECEDING) AS five_yr_avg_diff
    	                        FROM annual_summaries
                              ORDER BY year",sep="")
  annual_summaries <- sqldf(five_yr_diff_sql)
  
  #ADD COLUMN five_yr_avg_diff_rating
  rating_sql <-         paste("SELECT *,
          		                CASE WHEN five_yr_avg_diff < 0 THEN 'IMPROVE'
          		                WHEN five_yr_avg_diff > 0 THEN 'DECLINE'
          		                ELSE 'NA'
          		                END AS 'five_yr_avg_diff_rating'
          		                FROM annual_summaries",sep="")
  annual_summaries <- sqldf(rating_sql)

  #REMOVE ROWS WITH ALL NAs (years brefore continuous record was avaialble)
  NA_sql <-             paste("SELECT *
          		                FROM annual_summaries
                              WHERE median_depth_ft != 'NA'",sep="")
  annual_summaries <- sqldf(NA_sql)

  #REMOVE ROW FOR CURRENT YEAR (not used for the annual strategic planning measure)
  current.year <- as.character(as.numeric(format(Sys.Date(), "%Y")))
  current_yr_sql <-     paste("SELECT *
  		                        FROM annual_summaries
                              WHERE year != ",current.year,sep="")
  annual_summaries <- sqldf(current_yr_sql)
  
  #==================================================================
  #OUTPUT WELL DATA TO INDIVIDUAL CSV, AND SHEET OF EXCEL FILE CONTAINING ALL WELLS
  #write.csv(format(annual_summaries, digits=4),paste(export_path,well_code,'_annual_summaries.csv',sep=''), row.names=FALSE)
  write.csv(annual_summaries,paste(export_path,well_code,'_annual_summaries.csv',sep=''), row.names=FALSE)
  annual_summary_list[[well_code]] <- annual_summaries
    
  # #################################################################################################
  # # REST (TO BE REVISED)
  # #################################################################################################
  # tscode <- annual_summaries[length(annual_summaries[,1]),]$rating_five_yr_avg_diff
  # hydrocode <- hydrocodes[j]
  # 
  # #Retrieve dH usgsgage feature from vahydro
  # well_inputs <- list(hydrocode=hydrocode)
  # well_feature <- getFeature(well_inputs,token,base_url)
  # hydroid <- as.character(well_feature$hydroid[1])
  # 
  # 
  #     #------CREATE/UPDATE TIMESERIES
  #      tsbody = list(
  #        featureid = hydroid,
  #        varkey = 'indicator_rating',
  #        entity_type = 'dh_feature',
  #        # tstime = as.numeric(as.POSIXct("2020-01-01",origin = "1970-01-01", tz = "GMT")),
  #        # tsendtime = as.numeric(as.POSIXct("2020-12-31",origin = "1970-01-01", tz = "GMT")),
  #        tstime = as.numeric(as.POSIXct(paste(startyear,"-01-02",sep=""),origin = "1970-01-01", tz = "GMT")),
  #        tsendtime = as.numeric(as.POSIXct(paste(format(Sys.Date(), "%Y"),"-12-31",sep=""),origin = "1970-01-01", tz = "GMT")),
  #        tscode = tscode,
  #        limit = 100
  #      );
  # 
  #     post_ts <- postTimeseries(tsbody, base_url)
  # #################################################################################################
  # #################################################################################################

} #end of well feature loop

 write.xlsx(annual_summary_list, file = paste(export_path,'POTOMAC_WELL_SUMMARIES_',as.character(as.numeric(format(Sys.Date(), "%Y"))),'.xlsx',sep=''),
            keepNA=TRUE,
            na.string="NA")
