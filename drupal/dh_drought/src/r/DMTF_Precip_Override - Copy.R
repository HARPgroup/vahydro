#THIS SCRIPT CALCULATES THE CURRENT 7-DAY RUNNING AVERAGE "Depth to water level, feet below land surface (Maximum) level" FOR ALL USGS DROUGHT GAGES 
#THE CORRESPONDING PERCENTILE IS THEN CALCULATED USING THE HISTORIC "DAILY" "Depth to water level" VALUES FOR THE CURRENT MONTH
#   STORED VIA REST:
#     drought_status_stream (PROPERTY ON GAGE FEATURE THAT IS UPDATED EACH DAY THE SCRIPT IS RUN)
#     q_7day_cfs (TIMESERIES ON GAGE FEATURE THAT IS CREATED EACH DAY THE SCRIPT IS RUN)
#     nonex_pct (PROPERTY ON TIMESERIES ABOVE THAT IS CREATED EACH DAY THE SCRIPT IS RUN)
#
#----------------------------------------------------------------------------------------------------------
rm(list = ls())  #clear variables
#library(waterData)
library(dataRetrieval)
require(data.table)
require(zoo)
library(httr)
library(stringr)
library(sqldf)

push_to_rest <- TRUE

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
# source('/var/www/R/config.R')

#load libraries
source(paste(hydro_tools,"VAHydro-2.0/rest_functions.R", sep = "/"));
source(paste(basepath,"auth.private",sep = '/'))
token <- rest_token (base_url, token, rest_uname = rest_uname, rest_pw = rest_pw) #token needed for REST
site <- base_url



URL <- paste(site,"precipitation-drought-timeseries-export", sep = "/");
precip_df <- read.csv(URL, sep = ",")

region_hydroids <- precip_df$hydroid 
status_pids <- precip_df$pid 

# j = 1
for (j in 1:length(status_pids)) {
  print(paste("-----PROCESSING REGION ",j," OF ",length(status_pids), sep=''))
  region_hydroid <- region_hydroids[j]
  status_pid <- status_pids[j]
  print(paste("-------region_pid ", region_pid, sep=''))

  


if (push_to_rest == TRUE) {

    
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
  
  #------CREATE TIMESERIES IF ONE DOES NOT EXIST     
  # pbody = list(
  #   featureid = pf$featureid,
  #   varid = pf$varid,
  #   entity_type = 'dh_feature',
  #   tsvalue = pf$tsvalue,
  #   tstime = pf$tstime,
  #   tsendtime = pf$tsendtime,
  #   tscode = NULL
  # );
  
  #Update TIMESERIES if it exists    
  # if (length(timeseries_gwl$list)) {
    # timeseries_gwl <- timeseries_gwl$list[[1]];
    # tid <-  timeseries_gwl$list[[1]]$tid
    # print(paste("tid: ", tid, "tsvalue", pbody$tsvalue));
    #** PUT - Update
    print ("Property exists - PUT drought_status_precip");
    sub <- PUT(paste(site,"/dh_properties/",status_pid,sep=''), 
               add_headers(HTTP_X_CSRF_TOKEN = token),
               body = list(
                 featureid = region_hydroid,
                 varid = varid,
                 entity_type = 'dh_feature',
                 propcode = 1#,
                 #propvalue = 0,
                 #propname = 'drought_status_precip',
                 #startdate = as.numeric(as.POSIXct("2022-10-01 00:00",origin = "1970-01-01", tz = "GMT")),
                 #enddate = as.numeric(as.POSIXct(Sys.Date(),origin = "1970-01-01", tz = "GMT"))
               ), 
               encode = "json"
    );
    
    #content(sub)
    
  #   #Create Timeseries if it does not exist        
  # } else {
  #   print ("Timeseries does not exist - POST q_7day_cfs");
  #   #** POST - Insert
  #   x <- POST(paste(site,"/dh_timeseries/",sep=""), 
  #             add_headers(HTTP_X_CSRF_TOKEN = token),
  #             body = pbody,
  #             encode = "json"
  #   );
  # }
  # 
  #########################################################################
  #########################################################################
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
    #Retrieve dH usgsgage feature 
    gage_feature <- GET(paste(site,"/dh_feature.json",sep=""), 
                        add_headers(HTTP_X_CSRF_TOKEN = token),
                        query = list(bundle = 'usgsgage',
                                     hydrocode = hydrocode
                        ), 
                        encode = "json"
    );
    gage <- content(gage_feature);
    gage <- gage$list[[1]];
    hydroid = gage$hydroid[[1]]
    
    #Convert start and endate to UNIX timestamp (to be used with timeseries)
    startdate <- as.numeric(as.POSIXct(Sys.Date()-6,origin = "1970-01-01", tz = "GMT"))
    enddate <- as.numeric(as.POSIXct(Sys.Date(),origin = "1970-01-01", tz = "GMT"))
    
    #Set dH Variables 
    propvars <- c(
      'q_7day_cfs',
      'drought_status_stream'
    );
    
    proplist <- list(
      q_7day_cfs = FALSE,
      drought_status_stream = FALSE
    );
    
    #i<-2
    #Begin Loop to REST properties one at a time 
    for (i in 1:length(propvars)) {
      
      propdef_url<- paste(site,"/?q=vardefs.tsv/all/drought",sep="");
      propdef_table <- read.table(propdef_url,header = TRUE, sep = "\t")    
      
      varkey <- propvars[i];
      print(varkey); 
      
      # retrieve varid
      varid <- propdef_table[1][which(propdef_table$varkey == varkey),];
      print(paste("Found varid ", varid));
      
      if ((varkey == 'q_7day_cfs')) {
        tsvalue = q_7day_cfs;
        tstime <- startdate 
        tsendtime <- enddate 
        
        #Format timeseries 
        pf <- list(
          varid = varid,
          tsvalue = tsvalue,
          tstime = tstime,
          tsendtime = tsendtime,
          tscode = '',
          featureid = hydroid,
          entity_type = 'dh_feature'
        );  
        
        
        #-----RETRIEVE TIMESERIES   
        timeseries_gwl <- GET(paste(site,"/dh_timeseries.json",sep=""), 
                              add_headers(HTTP_X_CSRF_TOKEN = token),
                              query = list(
                                featureid = pf$featureid,
                                varid = varid,
                                tstime = pf$tstime,
                                tsendtime = pf$tsendtime,
                                entity_type = 'dh_feature'
                              ), 
                              encode = "json"
        );
        timeseries_gwl <- content(timeseries_gwl);
        
        #------CREATE TIMESERIES IF ONE DOES NOT EXIST     
        pbody = list(
          featureid = pf$featureid,
          varid = pf$varid,
          entity_type = 'dh_feature',
          tsvalue = pf$tsvalue,
          tstime = pf$tstime,
          tsendtime = pf$tsendtime,
          tscode = NULL
        );
        
        #Update TIMESERIES if it exists    
        if (length(timeseries_gwl$list)) {
          timeseries_gwl <- timeseries_gwl$list[[1]];
          tid <-  timeseries_gwl$list[[1]]$tid
          print(paste("tid: ", tid, "tsvalue", pbody$tsvalue));
          #** PUT - Update
          print ("Timeseries exists - PUT q_7day_cfs");
          sub <- PUT(paste(site,"/dh_timeseries/",tid,sep=''), 
                     add_headers(HTTP_X_CSRF_TOKEN = token),
                     body = pbody, 
                     encode = "json"
          );
          
          #content(sub)
          
          #Create Timeseries if it does not exist        
        } else {
          print ("Timeseries does not exist - POST q_7day_cfs");
          #** POST - Insert
          x <- POST(paste(site,"/dh_timeseries/",sep=""), 
                    add_headers(HTTP_X_CSRF_TOKEN = token),
                    body = pbody,
                    encode = "json"
          );
        }
        
        
        #------ATTATCH PROPERTY 'nonex_pct' TO TIMESERIES   
        
        #-----RETRIEVE TIMESERIES   
        timeseries_gwl <- GET(paste(site,"/dh_timeseries.json",sep=""), 
                              add_headers(HTTP_X_CSRF_TOKEN = token),
                              query = list(
                                featureid = pf$featureid,
                                varid = varid,
                                tstime = pf$tstime,
                                tsendtime = pf$tsendtime,
                                entity_type = 'dh_feature'
                              ), 
                              encode = "json"
        );
        timeseries_gwl <- content(timeseries_gwl)
        tid <- timeseries_gwl$list[[1]]$tid
        
        
        #---------------------------------------------------------
        # retrieve varid
        nonex_pct_varid <- propdef_table[1][which(propdef_table$varkey == 'nonex_pct'),];
        print(paste("Found nonex_pct varid ", nonex_pct_varid));
        
        #Format property  
        pf <- list(
          varid =  nonex_pct_varid,
          propname = 'nonex_pct',
          propvalue = nonex_propvaue,
          propcode = nonex_propcode,
          tid = tid,
          bundle = 'dh_properties',
          entity_type = 'dh_timeseries'
        );  
        
        #Retrieve property if it exists   
        sp <- GET(
          paste(site,"/dh_properties.json",sep=""), 
          add_headers(HTTP_X_CSRF_TOKEN = token),
          query = list(
            bundle = 'dh_properties',
            #tid = pf$tid,
            featureid = pf$tid,
            varid = pf$varid,
            entity_type = 'dh_timeseries'
            
          ), 
          encode = "json"
        );
        spc <- content(sp);  
        
        pbody = list(
          bundle = 'dh_properties',
          # tid = pf$tid,
          featureid = pf$tid,
          varid = pf$varid,
          entity_type = 'dh_timeseries',
          propname = pf$propname,
          propvalue = pf$propvalue,
          propcode = pf$propcode
        );
        
        #Update property if it exists    
        if (length(spc$list)) {
          spe <- spc$list[[1]];
          print ("Property exists - PUT nonex_pct");
          pid <- spe$pid[[1]];
          print(paste("pid: ", pid, "propcode", pbody$propcode));
          #** PUT - Update
          sub <- PUT(paste(site,"/dh_properties/",pid,sep=''), 
                     add_headers(HTTP_X_CSRF_TOKEN = token),
                     body = pbody, 
                     encode = "json"
          );
          #Create property if it does not exist        
        } else {
          print ("Property does not exist - POST nonex_pct");
          #** POST - Insert
          x <- POST(paste(site,"/dh_properties/",sep=""), 
                    add_headers(HTTP_X_CSRF_TOKEN = token),
                    body = pbody,
                    encode = "json"
          );
        } 
        
        
        #------SET drought_status_stream PROPERTY    
        #----------------------------------------------------------------------------   
      } else { ((varkey == 'drought_status_stream')) 
        propval = nonex_propvaue;
        
        
        #Format property  
        pf <- list(
          varid = varid,
          propname = varkey,
          propvalue = propval,
          propcode = '',
          featureid = hydroid,
          bundle = 'dh_properties',
          entity_type = 'dh_feature'
        );  
        
        #Retrieve property if it exists   
        sp <- GET(
          paste(site,"/dh_properties.json",sep=""), 
          add_headers(HTTP_X_CSRF_TOKEN = token),
          query = list(
            bundle = 'dh_properties',
            featureid = pf$featureid,
            varid = varid,
            entity_type = 'dh_feature'
            
          ), 
          encode = "json"
        );
        spc <- content(sp);  
        
        pbody = list(
          bundle = 'dh_properties',
          featureid = pf$featureid,
          varid = pf$varid,
          entity_type = 'dh_feature',
          propname = pf$propname,
          propvalue = pf$propvalue,
          propcode = NULL
        );
        
        if ((varkey == 'q_7day_cfs')) {
          pbody$propcode = NULL;
          pbody$propvalue = q_7day_cfs;
        } else { ((varkey == 'drought_status_stream')) 
          pbody$propcode = nonex_propcode;
          pbody$propvalue = nonex_propvaue;
        }
        
        
        #Update property if it exists    
        if (length(spc$list)) {
          spe <- spc$list[[1]];
          print ("Property exists - PUT drought_status_stream");
          pid <- spe$pid[[1]];
          print(paste("pid: ", pid, "propcode", pbody$propcode));
          #** PUT - Update
          sub <- PUT(paste(site,"/dh_properties/",pid,sep=''), 
                     add_headers(HTTP_X_CSRF_TOKEN = token),
                     body = pbody, 
                     encode = "json"
          );
          #Create property if it does not exist        
        } else {
          print ("Property does not exist - POST drought_status_stream");
          #** POST - Insert
          x <- POST(paste(site,"/dh_properties/",sep=""), 
                    add_headers(HTTP_X_CSRF_TOKEN = token),
                    body = pbody,
                    encode = "json"
          );
        }
        
      } #end of drought_status_stream property loop  
      
    } #end of REST LOOP
  } #end push_to_rest IF block   


} #end of gage feature loop
