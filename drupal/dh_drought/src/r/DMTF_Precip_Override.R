# rm(list = ls())  #clear variables
#library(waterData)
# library(dataRetrieval)
# require(data.table)
# require(zoo)
library(httr)
# library(stringr)
library(sqldf)



basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
 source('/var/www/R/config.R')

#load libraries
source(paste(hydro_tools,"VAHydro-2.0/rest_functions.R", sep = "/"));
source(paste(basepath,"auth.private",sep = '/'))
token <- rest_token (base_url, token, rest_uname = rest_uname, rest_pw = rest_pw) #token needed for REST
site <- base_url



URL <- paste(site,"precipitation-drought-timeseries-export", sep = "/");
precip_df <- read.csv(URL, sep = ",")

##################################################################
# GENERATE OVERRIDE VALUES USING SQL
precip_df <- sqldf(paste('
SELECT *, 
CASE
  WHEN drought_region == "Eastern Shore" THEN 1
  ELSE 0
END AS status_override
FROM precip_df',sep="")) 
##################################################################

region_hydroids <- precip_df$hydroid 
status_pids <- precip_df$pid
status_override <- precip_df$status_override 

# j = 1
for (j in 1:length(status_pids)) {
  print(paste("-----PROCESSING REGION ",j," OF ",length(status_pids), sep=''))
  region_hydroid <- region_hydroids[j]
  status_pid <- status_pids[j]
  status_override_j <- as.character(status_override[j])
  print(paste("-------region_pid ", region_hydroid, sep=''))

  
  #--UPDATE WITH REST 'drought_status_precip'
  #########################################################################
  #########################################################################  
  
  #-----Retrieve Varid
  propdef_url<- paste(site,"/?q=vardefs.tsv/all/drought",sep="");
  propdef_table <- read.table(propdef_url,header = TRUE, sep = "\t")    
  varid <- propdef_table[1][which(propdef_table$varkey == "drought_status_precip"),];
  print(paste("Found varid ", varid));
  
  #-----RETRIEVE PROPERTY   
  prop <- GET(paste(site,"/dh_properties.json",sep=""), 
                        add_headers(HTTP_X_CSRF_TOKEN = token),
                        query = list(
                          featureid = region_hydroid,
                          varid = varid,
                          pid = status_pid,
                          entity_type = 'dh_feature'
                        ), 
                        encode = "json"
  );
  prop <- content(prop);
  
  #------UPDATE EXISTING PROPERTY   
  print ("Property exists - PUT drought_status_precip");
  sub <- PUT(paste(site,"/dh_properties/",status_pid,sep=''), 
             add_headers(HTTP_X_CSRF_TOKEN = token),
             body = list(
               featureid = region_hydroid,
               varid = varid,
               entity_type = 'dh_feature',
               propcode = status_override_j#,
               #propvalue = 0,
               #propname = 'drought_status_precip',
               #startdate = as.numeric(as.POSIXct("2022-10-01 00:00",origin = "1970-01-01", tz = "GMT")),
               #enddate = as.numeric(as.POSIXct(Sys.Date(),origin = "1970-01-01", tz = "GMT"))
             ), 
             encode = "json"
  );
    
    #content(sub)
  #########################################################################
  #########################################################################

} #end of region feature loop
