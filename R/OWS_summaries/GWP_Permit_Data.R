library('sqldf')

savepath <- "C:/Users/nrf46657/Desktop/"
years <- c(2018:2014)


#-----------------------------------------------------------------------------------
# VIEWS USED 
# https://deq1.bse.vt.edu/d.dh/ows-permit-list
# https://deq1.bse.vt.edu/d.dh/ows-annual-report-map-exports
gwp_permits <- read.csv('https://deq1.bse.vt.edu/d.dh/ows-list-permits-export-gwp') #note permit writer field not getting pulled into R
facility_mp_fracs <- read.csv('https://deq1.bse.vt.edu/d.dh/facility_mp_frac_value_export?bundle%5B0%5D=well&hydroid=&propcode_op=%3D&propcode=&fstatus=All&propname_op=%3D&propname=wd_current_mgy')

#-----------------------------------------------------------------------------------
# JOIN FACILITY USE FRACTIONS
### SUM facility_use_fraction BY FACILITY
facility_mp_fracs_sum <- aggregate(facility_mp_fracs$facility_use_fraction,by=list(facility_mp_fracs$Facility_hydroid),FUN=sum, na.rm=TRUE)
  names(facility_mp_fracs_sum)[1] <- paste('Facility_hydroid',sep='')
  names(facility_mp_fracs_sum)[2] <- paste('facility_use_fraction_sum',sep='')

### JOIN FACILITY SUMMED facility_use_fractions TO GWPS DATAFRAME
gwp_permits <-sqldf("SELECT *
                     FROM gwp_permits AS a
                     LEFT OUTER JOIN facility_mp_fracs_sum AS b
                     ON (a.Facility_hydroid = b.Facility_hydroid )")    
#-----------------------------------------------------------------------------------
# LOOP THROUGH EACH YEAR ADDING ANNUAL REPORTED USE TO GWP DATAFRAME
#i <- 1
for (i in 1:length(years)){
  year <- years[i]
  print(paste("PROCESSING YEAR", year))
  print(paste("RETRIEVING DATA"))
  
  # RETRIEVE DATA FOR ALL ISSUING AUTHORITIES
  # map_exports <- read.csv(paste('https://deq1.bse.vt.edu/d.dh/ows-awrr-map-export/wd_mgy?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=',year,'-01-01&tstime%5Bmax%5D=',year,'-12-31&bundle%5B0%5D=well&dh_link_admin_reg_issuer_target_id%5B0%5D=448933&dh_link_admin_reg_issuer_target_id%5B1%5D=379560&dh_link_admin_reg_issuer_target_id%5B2%5D=65668&dh_link_admin_reg_issuer_target_id%5B3%5D=90549&dh_link_admin_reg_issuer_target_id%5B4%5D=90550&dh_link_admin_reg_issuer_target_id%5B5%5D=92517&dh_link_admin_reg_issuer_target_id%5B6%5D=91200&dh_link_admin_reg_issuer_target_id%5B7%5D=77498&dh_link_admin_reg_issuer_target_id%5B8%5D=170026',sep=''))
                                 
  #RETRIEVE DATA FOR gwp ISSUING AUTHORITY ONLY
  map_exports <- read.csv(paste('https://deq1.bse.vt.edu/d.dh/ows-awrr-map-export/wd_mgy?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=',year,'-01-01&tstime%5Bmax%5D=',year,'-12-31&bundle%5B0%5D=well&dh_link_admin_reg_issuer_target_id%5B0%5D=65668',sep=''))

  
  # AGGREGATE MP REPORTING DATA BY FACILITY
  print(paste("AGGREGATING MP DATA BY FACILITY"))
    map_exports_trim <- data.frame('Facility_hydroid' = map_exports$Facility_hydroid,
                                        'mp_count' = 1,
                                        'mgy' = map_exports$Water.Use.MGY,
                                        'year' = map_exports$Year)
    fac_mp_sum <- aggregate(map_exports_trim[,2:3],by=list(map_exports_trim$Facility_hydroid),FUN=sum, na.rm=TRUE)
    names(fac_mp_sum)[1] <- paste('Facility_hydroid',sep='')
    names(fac_mp_sum)[2] <- paste('mp_count_',year,sep='')
    names(fac_mp_sum)[3] <- paste('mgy_',year,sep='')
  
  # JOIN FACILITY YEAR REPORTING DATA TO PERMIT DATAFRAME
    print(paste("JOINING YEAR DATA TO PERMIT"))
    gwp_permits <-sqldf("SELECT *
                            FROM gwp_permits AS a
                            LEFT OUTER JOIN fac_mp_sum AS b
                            ON (a.Facility_hydroid = b.Facility_hydroid)")
}


write.csv(gwp_permits,paste(savepath,"gwp_permit_data_","2014-2018_",gsub(":", "", gsub(" ", "-", Sys.time())),".csv",sep=''), row.names = FALSE)


