#----------------------------------------------------------------------------------------------------------
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

#INITIATE LIST OF WELL DATA
annual_summary_list <- list()

#j <-1
#Begin loop to run through each USGS gage 
for (j in 1:length(hydrocodes)) {
  print(paste("PROCESSING WELL: ",j," OF ",length(hydrocodes),sep=''))
  siteNumber <- hydrocodes[j]
  siteNumber <- toString(siteNumber)
  siteNumber = unlist(strsplit(siteNumber, split='_', fixed=TRUE))[2]
  well_name <- well_names[j]
  well_code <- substr(well_name, 22, nchar(well_name)) 
  print(paste("USGS siteNumber: ", siteNumber, sep='')); 
  

  welldata <- whatNWISdata(siteNumber = siteNumber)
  
  #Parameter code '72019' = Depth to water level, feet below land surface (ft) https://help.waterdata.usgs.gov/code/parameter_cd_nm_query?parm_nm_cd=%25level%25&fmt=html
  gwl_row <- which(welldata$parm_cd == 72019)
  gwl_rows <- welldata[gwl_row,]
  
  dv_rows <- which(gwl_rows$data_type_cd == "dv") #retreive date well began recording dv "daily values"
  dv_rows <- gwl_rows[dv_rows,]
  dv_rows <- gwl_rows[order(dv_rows$begin_date , decreasing = TRUE ),]
  begin_date_row <- dv_rows[length(dv_rows$begin_date),]
  begin_date <- begin_date_row$begin_date
  print(paste("Historic Record begining ",begin_date,sep=""))
  
  url <- paste("https://waterdata.usgs.gov/nwis/dv?cb_72019=on&format=rdb_meas&site_no=",siteNumber,"&referred_module=sw&period=&begin_date=",begin_date,"&end_date=",sep="")
  print(paste("Retrieving Data from NWIS using:",url))
  data <- read.table(url,header = TRUE, sep = "\t")
  
  #REMOVE USGS HEADER
  data <-data[-1,]
  
  data$max <- as.numeric(as.character(data[,5])) #COPY MAX (Depth to water level) COLUMN AND FORCE 'NA's WHERE THERE IS MISSING DATA
  data$min <- as.numeric(as.character(data[,7])) 
  data$median <- ((data$max + data$min) / 2)
  # data$periodic <- as.numeric(as.character(data[,9])) #CREATE COLUMN OF PERIODIC MEASUREMENTS
  
  #THIS WELL ONLY RECORDS SINGLE DAILY VALUES
  if (siteNumber == "381110076550501"){data$median <- data$max}
  
  data$year <- year(data[,"datetime"])
  
  #ADD COLUMNS FOR median, min, max
  #=============================================================
  annual_summaries <-   paste("SELECT year,
                              median(median) AS 'median_depth',
                              min(median) AS 'min_depth',
                              max(median) AS 'max_depth'
                              FROM data 
                              GROUP BY year
                              ",sep="")
  annual_summaries <- sqldf(annual_summaries)

  #ADD COLUMN one_yr_diff
  one_yr_diff_sql <-    paste("SELECT *,
                              median_depth - LAG(median_depth)
                            	OVER (ORDER BY year) AS one_yr_diff
    	                        FROM annual_summaries
                              ORDER BY year",sep="")
  annual_summaries <- sqldf(one_yr_diff_sql)
  
  #ADD COLUMN one_yr_diff_rating
  rating_sql <-  paste("SELECT *,
  		                CASE WHEN one_yr_diff < 0 THEN 'IMPROVE'
  		                WHEN one_yr_diff > 0 THEN 'DECLINE'
  		                ELSE 'NA'
  		                END AS 'one_yr_diff_rating'
  		                FROM annual_summaries
                      ORDER BY year",sep="")
  annual_summaries <- sqldf(rating_sql)
  
  # five_yr_diff_sql <-  paste("SELECT *,
  #                           one_yr_diff + LAG(one_yr_diff,1) + LAG(one_yr_diff,2) + LAG(one_yr_diff,3) + LAG(one_yr_diff,4)
  #                         	OVER (ORDER BY year) AS five_yr_avg_diff
  # 	                        FROM annual_summaries",sep="")
  # annual_summaries <- sqldf(five_yr_diff_sql)
  
  five_yr_diff_sql <-  paste("SELECT *,
                            AVG(one_yr_diff) OVER (ORDER BY year ASC ROWS 4 PRECEDING) AS five_yr_avg_diff
  	                        FROM annual_summaries
                            ORDER BY year",sep="")
  annual_summaries <- sqldf(five_yr_diff_sql)
  
  rating_sql <-  paste("SELECT *,
  		                
  		                CASE WHEN five_yr_avg_diff < 0 THEN 'IMPROVE'
  		                WHEN five_yr_avg_diff > 0 THEN 'DECLINE'
  		                ELSE 'NA'
  		                END AS 'five_yr_avg_diff_rating'
  		                
  		                FROM annual_summaries",sep="")
  annual_summaries <- sqldf(rating_sql)
  #==================================================================
  #==================================================================
  
  
  # #ADD COLUMNS one_yr_diff, five_yr_avg_diff, five_yr_diff
  # #==================================================================
  #   annual_summaries$one_yr_diff <- c(rep(NA, 1), tail(annual_summaries$median_depth, -1) - head(annual_summaries$median_depth, -1))
  #     if (length(annual_summaries[,1]) > 4) {
  #       annual_summaries$five_yr_avg_diff <- (c(rep(NA, 5), tail(annual_summaries$median_depth, -5) - head(annual_summaries$median_depth, -5))/5)
  #           #IF STATEMENT NEEDED IN CASE GAGE RECORD HAS NA 5 YEARS AGO
  #           if (is.na(annual_summaries[length(annual_summaries$median_depth)-4,]$median_depth) == TRUE) {
  #             startyear <- as.character(annual_summaries[length(annual_summaries$median_depth)-3,]$year)
  #           } else {
  #             startyear <- as.character(as.numeric(format(Sys.Date(), "%Y"))-4)
  #           }
  #     } else {
  #       annual_summaries$five_yr_avg_diff <- NA
  #       startyear <- as.character(annual_summaries[1,1])
  #     }
  #   #annual_summaries$five_yr_diff <- (c(rep(NA, 4), tail(annual_summaries$median_depth, -4) - head(annual_summaries$median_depth, -4))/5)
  #   #==================================================================
  # 
  # 
  #   #ADD COLUMN rating_five_yr_avg_diff
  #   #==================================================================
  #     rating_sql <-  paste("SELECT *,
  # 		                CASE WHEN one_yr_diff < 0 THEN 'IMPROVE'
  # 		                WHEN one_yr_diff > 0 THEN 'DECLINE'
  # 		                ELSE 'X'
  # 		                END AS 'one_yr_diff_rating',
  # 		                
  # 		                CASE WHEN five_yr_avg_diff < 0 THEN 'IMPROVE'
  # 		                WHEN five_yr_avg_diff > 0 THEN 'DECLINE'
  # 		                ELSE 'X'
  # 		                END AS 'five_yr_avg_diff_rating'
  # 		                
  # 		                FROM annual_summaries",sep="")
  #     annual_summaries <- sqldf(rating_sql)
  
    #==================================================================
    #REMOVE ROWS WITH ALL NAs (years brefore continuous record was avaialble)
    NA_sql <-  paste("SELECT *
  		                FROM annual_summaries
                      WHERE median_depth != 'NA'",sep="")
    annual_summaries <- sqldf(NA_sql)
    #==================================================================  

    #==================================================================
    #REMOVE ROW FOR CURRENT YEAR
    current.year <- as.character(as.numeric(format(Sys.Date(), "%Y")))
    
    current_yr_sql <-  paste("SELECT *
  		                        FROM annual_summaries
                              WHERE year != ",current.year,sep="")
    annual_summaries <- sqldf(current_yr_sql)
    #==================================================================
    #OUTPUT WELL DATA TO INDIVIDUAL CSV, AND SHEET OF EXCEL FILE CONTAINING ALL WELLS
    #write.csv(format(annual_summaries, digits=4),paste(export_path,well_code,'_annual_summaries.csv',sep=''), row.names=FALSE)
    write.csv(annual_summaries,paste(export_path,well_code,'_annual_summaries.csv',sep=''), row.names=FALSE)
    annual_summary_list[[well_code]] <- annual_summaries
    
  # #################################################################################################
  # # REST
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
