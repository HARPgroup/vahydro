########################################################################################
# Aquaveo Export
# This script is for the annual data exports provided to Aquaveo 
# It joins the VAHydro map exports withdrawal data to MPID and DEQ Well Number identifiers used in the Aquaveo Coastal Plain Reported Use model for 2021.

# Data Source Note
# Aquaveo emailed the following files: 2021 Annual Updates IDs from CP and ES RU and TP mnws.xlsx, 2017-2021 Average MNW file Original and Expanded Combined.xlsx
# These files contain a list of measuring point identifiers used for the Coastal Plain and Eastern Shore Reported Use and Total Permitted models. They are not on the common drive as target storage folder has been cleaned up for file migration. Aquaveo maintains these data.
########################################################################################

#library('tidyverse') #loads in tidyr, dplyr, ggplot2, etc
library('tidyr')
library('sqldf')
library("hydrotools")

options(scipen = 999)

#NOTE: The end year needs to be updated every year
syear = 1982
eyear = 2021

#Generate REST token for authentication --------------------------------------------
rest_uname = FALSE
rest_pw = FALSE
basepath ='/var/www/R'
source(paste0(basepath,'/auth.private'))
source(paste0(basepath,'/config.R'))
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
ds$get_token(rest_pw)

#import data ################################
import_path <- export_path
CPRUIDlist <- read.csv(file=paste0(import_path,"/IDlist_CP_RU_workingcopy3.csv"), header = TRUE) #Data Source Note cont.: csv version of coastal plain reported use identifiers tab
ESRUIDlist <- read.csv(file=paste0(import_path,"/IDlist_ES_RU_workingcopy.csv"), header = TRUE) #Data Source Note cont.: csv version of eastern shore reported use identifiers tab
MNW_QA <- read.csv(file=paste0(import_path,"/MNW_QA.csv")) #source: csv version of "Historic" tab of MNW original file
TP <- read.csv(file=paste0(import_path,"/trimmed_aquaveo_total_permitted_query_scinot.csv")) #source: (http://deq1.bse.vt.edu/d.dh/aquaveo-total-permitted-query),filtered to better match modeled wells by removing well types (monitoring/observation, etc) permit statuses (application, inactive, etc) and some duplicates.



### DOWNLOAD VAHYDRO MAP EXPORT FOR ALL YEARS AND READ IT IN ############################
# Information: map export was used last year. It has same useful columns as foundation data, a few more rows, even though it has 2 duplicate well rows even if you group by hydroid mpid and well#"
multi_yr_data <- read.csv(file=paste0(import_path,"/ows_annual_report_map_exports.csv"), header=TRUE)

#exclude dalecarlia
multi_yr_data <- multi_yr_data[-which(multi_yr_data$facility_name=='DALECARLIA WTP'),]
backup2 <- multi_yr_data
multi_yr_data<-backup2

#remove duplicates
multi_yr_data <- sqldf('SELECT "MP_hydroid", "Hydrocode","MP_Name", "MPID", "DEQ.Well.Number" AS "DEQ_Well_Number", "Source.Type" AS "Source_Type", "facility_hydroid", "facility_name", "facility_status",
   CASE
   WHEN LOWER("facility_use_type") LIKE "%agriculture%" THEN "agriculture"
   WHEN LOWER("facility_use_type") LIKE "%industrial%" THEN "manufacturing"
   ELSE LOWER("facility_use_type")
   END AS "facility_use_type", 
   "MP_latitude", "MP_longitude", "FIPS_Code", "locality", MAX("Year") AS Year, MAX("Water.Use.MGY") AS "Water_Use_MGY"
      FROM multi_yr_data
      WHERE "facility_use_type" NOT LIKE "gw2_%"
      GROUP BY "MP_hydroid", "Hydrocode", "MP_Name", "MPID", "DEQ.Well.Number", "Source.Type", "MP_latitude", "MP_longitude", "FIPS_Code","Year"
      ')
#duplicate_check3 <- sqldf('SELECT * FROM backup2 GROUP BY MP_hydroid,Year HAVING count(MP_hydroid)>1')
duplicate_check2 <- sqldf('SELECT * FROM multi_yr_data GROUP BY MP_hydroid,Year HAVING count(MP_hydroid)>1')
#write.csv(duplicate_check2,file=paste0(export_path,"/writecsv/duplicate_check2.csv"))

#########################################################################x
# Aquaveo's list of Coastal Plain IDs ######################
#########################################################################x

#add column so the individual ID matched rows can be reordered back to their excel sheet order 
nums <- array(1:nrow(CPRUIDlist))
IDlist <- cbind(nums,CPRUIDlist)
names(IDlist) <- c("Ord","CPRUIDs")
summary(IDlist)

#select recent years of interest from multi_yr_data, because their spreadsheet includes since 2003
multiyr_sel <- sqldf('SELECT * FROM multi_yr_data WHERE Year >= 2003')
multiyr_wid <- pivot_wider(multiyr_sel,names_from = "Year", values_from = "Water_Use_MGY")

#join MPIDs to the map export data #####
join_on_mpid <- sqldf('SELECT a.*, b.*
                  FROM IDlist a
                  LEFT JOIN multiyr_wid b
                  ON a.CPRUIDs = b.MPID')
joined_mpid <- sqldf('SELECT * FROM join_on_mpid WHERE MPID IS NOT NULL')
remainder <- sqldf('SELECT Ord, CPRUIDs FROM join_on_mpid WHERE MPID IS NULL')
nrow(remainder)

#checks
nrow(joined_mpid)+nrow(remainder) == nrow(IDlist) # False because there's 8 extra rows, IDList is 1091 rows
# remainder2 <- sqldf('SELECT * FROM join_on_mpid WHERE MPID IS NULL')
# join_check3 <- sqldf('SELECT * FROM remainder2 GROUP BY MPID HAVING count(*)>1')#this returns 1 for all the blank MPIDs so not useful
# join_check2 <- sqldf('SELECT * FROM multiyr_wid GROUP BY mpid HAVING count(*)>1') #includes more than the duplicates created by the join
# join_check <- sqldf('SELECT * FROM join_on_mpid GROUP BY MPID HAVING count(*)>1') #includes 1 row for all the blank MPIDs
#Information: the join is taking the single MPID from the IDlist, and returning both matching rows from the hydroid list. Not all 16 duplicate MPIDs from multiyr_wid will create rows in join_on_mpid because those rows may be in the IDlist as a hydroid instead of as an mpid, so there's nothing to join on in this section.
join_check <- sqldf('SELECT * FROM joined_mpid GROUP BY MPID HAVING count(*)>1') #includes just duplicates created by the join on mpid

#remove the extra rows we don't think are correct from joined_mpid, based on MPIDs that showed up in join_check
choose_mpid <- sqldf('SELECT * FROM joined_mpid WHERE Ord IN (
              SELECT Ord FROM joined_mpid GROUP BY MPID HAVING count(*)>1
              )')
write.csv(choose_mpid, file=paste0(export_path,"/writecsv/choose_mpid.csv")) #see notes in excel on why hydroids were chosen
#Information: chose the hydroid with reporting data, wells not surface water, or the hydroid Aquaveo used

#remove duplicate mpid matches
joined_mpid <- sqldf('SELECT * FROM joined_mpid WHERE MP_Hydroid NOT IN (1406,60779,61053,61000,63072,68418,63030,193515)')
join_check <- sqldf('SELECT * FROM joined_mpid GROUP BY MPID HAVING count(*)>1')
nrow(joined_mpid)+nrow(remainder) == nrow(IDlist) # Now should be True


#join on DEQ WELL NUMBER ######
join_on_well <-  sqldf('SELECT a.*, b.*
                  FROM remainder a
                  LEFT JOIN multiyr_wid b
                  ON a.CPRUIDs = b.DEQ_Well_Number')
joined_well <- sqldf('SELECT * FROM join_on_well WHERE DEQ_Well_Number IS NOT NULL')
remainder <- sqldf('SELECT Ord, CPRUIDs FROM join_on_well WHERE DEQ_Well_Number IS NULL')
nrow(remainder)
#nrow(joined_well)+nrow(remainder) #no extra rows because this matches prior remainder count of 308
join_check4 <- sqldf('SELECT * FROM joined_well GROUP BY DEQ_Well_Number HAVING count(*)>1')

#join on HYDROID ######
hydroid_char <- sqldf('SELECT * FROM remainder WHERE CPRUIDs LIKE "VAHydroid_%"')
hydroid_nums <- separate(data = hydroid_char, col = CPRUIDs, into = c("vahydro", "hydroid"), sep = "_")
hydroid_charnums <- cbind(hydroid_char, hydroid_nums["hydroid"])

join_on_hydroid <-sqldf('SELECT a.Ord,a.CPRUIDs, b.*
                  FROM hydroid_charnums a
                  LEFT JOIN multiyr_wid b
                  ON a.hydroid = b.MP_hydroid')
joined_hydroid <- sqldf('SELECT * FROM join_on_hydroid WHERE MP_hydroid IS NOT NULL')
remainder <- sqldf('SELECT Ord, CPRUIDs FROM join_on_hydroid WHERE MP_hydroid IS NULL')
nrow(remainder)
#nrow(joined_hydroid)+nrow(remainder) == nrow(hydroid_char) #no extra rows because this returns as TRUE 
#join_check5 <- sqldf('SELECT * FROM joined_hydroid GROUP BY MP_hydroid HAVING count(*)>1') #no duplicates

#remainder #####
#combine the individual join types and merge with original IDlist
joined_bind <- rbind(joined_mpid, joined_well, joined_hydroid) 
joined_sum3 <- sqldf('SELECT a.Ord as Ord_1, a.CPRUIDs as CPRUIDs_1, b.*
                    FROM IDlist a
                    LEFT JOIN joined_bind b
                    on a.CPRUIDs = b.CPRUIDs')
remainder4 <- sqldf('SELECT Ord_1, CPRUIDs_1 FROM joined_sum3 WHERE CPRUIDs IS NULL')
join_byhand <- sqldf('SELECT Ord_1, CPRUIDs_1
                     FROM remainder4 
                     WHERE CPRUIDs_1 NOT LIKE "MD%"
                     AND CPRUIDs_1 NOT LIKE "NC%"')
write.csv(join_byhand,file=paste0(export_path,"/writecsv/join_byhand.csv"))
#write.csv(joined_sum3, file=paste0(export_path, "/writecsv/CPRUID_MapExportData.csv")) 

### MANUALLY JOIN THE REMAINDER ROWS ######

#Information: Determine and correct unmatched hydroids based on hydrocodes that contain hydroids, Aquaveo's mastersheet containing potential hydroid matches, and investigating hydro for duplicates. See notes in join_byhand.xlsx on which were chosen. Hydroids of zero denote rows that are already have a hydoid represented in the CPRUIDs list, and should be removed from the model.

#Add hydroids to unmatched CPRUIDs
manual <- sqldf('SELECT Ord_1 as Ord, CPRUIDs_1 as CPRUIDs,
               CASE
                WHEN CPRUIDs_1 = 374338077011801 THEN 59375
                WHEN CPRUIDs_1 = 381429076583502 THEN 224388
                WHEN CPRUIDs_1 = 381435076582201 THEN 224386
                WHEN CPRUIDs_1 = "196-00222" THEN 64625
                WHEN CPRUIDs_1 = "196-00232" THEN 64603
                WHEN CPRUIDs_1 = "mp8966" THEN 224055
                WHEN CPRUIDs_1 = "pmp1115" THEN 230400
                WHEN CPRUIDs_1 = "pmp1125" THEN 230405
                WHEN CPRUIDs_1 = "pmp1126" THEN 230404
                WHEN CPRUIDs_1 = "PMP1127" THEN 230403
                WHEN CPRUIDs_1 = "PMP1128" THEN 230406
                WHEN CPRUIDs_1 = "pmp510" THEN 0
                WHEN CPRUIDs_1 = "pmp511" THEN 0
                WHEN CPRUIDs_1 = "pmp512" THEN 90518
                WHEN CPRUIDs_1 = "pmp733" THEN 234404
                WHEN CPRUIDs_1 = "pmp760" THEN 64606
                WHEN CPRUIDs_1 = "pmp884" THEN 191464
                WHEN CPRUIDs_1 = "VAHydroID_90546" THEN 64578
                WHEN CPRUIDs_1 = "VAHydroID_437035" THEN 0
                WHEN CPRUIDs_1 = "VAHydroID_450316" THEN 0
                WHEN CPRUIDs_1 = "VAHydroID_450325" THEN 0
                WHEN CPRUIDs_1 = "VAHydroID_450324" THEN 0
                END AS MP_hydroid_manual
                FROM remainder4')

#join manually identified hydroids with withdrawal data
joined_manual <- sqldf('SELECT a.Ord, a.CPRUIDs, b.*
                        FROM manual a 
                        LEFT JOIN multiyr_wid b
                       ON a.MP_hydroid_manual = b.MP_Hydroid')

#Row bind all the joins
joined_all <- sqldf('SELECT * from joined_mpid
                     UNION ALL SELECT * from joined_well
                     UNION ALL SELECT * from joined_hydroid
                     UNION ALL SELECT * from joined_manual
                     ORDER BY Ord ASC')
#last checks
remainder <- sqldf('SELECT Ord, CPRUIDs FROM joined_all WHERE MP_hydroid IS NULL 
                    AND CPRUIDs NOT LIKE "MD%"AND CPRUIDs NOT LIKE "NC%"') #should just be the 6 that were manually marked as duplicates
join_check6 <- sqldf('SELECT * FROM joined_all GROUP BY CPRUIDs HAVING count(*)>1') #should be 0
duplicate_check <- sqldf('SELECT * from joined_all group by MP_Hydroid Having count(*)>1') # should be 1 to represent rows that weren't joined
duplicate_check <- sqldf('SELECT * from joined_all group by Ord having count(*)>1') #should be 0 if the Union worked properly


#export data for Aquaveo
joined_export <- joined_all
colnames(joined_export)[colnames(joined_export)=="CPRUIDs"] <- "List of CP 2020 RU IDs"
write.csv(joined_export, file=paste0(export_path, "/writecsv/CPRUID_MatchedExport.csv")) 

# #Alternate ending #####################
# #Or can use use rbind instead of Union All
# joined_bind <- rbind(joined_mpid, joined_well, joined_hydroid, joined_manual) 
# joined_all <- sqldf('SELECT a.Ord as Ord_1, a.CPRUIDs as CPRUIDs_1, b.*
#                     FROM IDlist a
#                     LEFT JOIN joined_bind b
#                     on a.CPRUIDs = b.CPRUIDs')
# remainder <- sqldf('SELECT Ord_1, CPRUIDs_1 FROM joined_all WHERE CPRUIDs IS NULL
#                    AND CPRUIDs_1 NOT LIKE "MD%"AND CPRUIDs_1 NOT LIKE "NC%"')
# joined_export <-subset(joined_all, select = -c(Ord_1,Ord,CPRUIDs))
# colnames(joined_export)[colnames(joined_export)=="CPRUIDs_1"] <- "List of CP 2020 RU IDs"

# #write joined data table without columns added during processing
# export <- sqldf('SELECT Ord_1 AS Ord, CPRUIDs_1 as CPRUID, MP_hydroid, Hydrocode, MP_name, MPID, DEQ_Well_Number, Source_Type, facility_hydroid, facility_name, facility_status, facility_use_type, MP_latitude, MP_longitude, FIPS_code, locality, 2016, 2017, 2018, 2019, 2020, 2021
#                    FROM joined_all')
# write.csv(export, file=paste0(export_path, "/writecsv/CPRUID_MapExportData.csv")

#check
#join_check6 <- sqldf('SELECT * FROM joined_all GROUP BY CPRUIDs_1 HAVING count(*)>1') 
# join on DEQ WEll Number and join on hydriod didn't duplicate any CPRUID rows, and the join on MPID that did duplicate CPRUID rows are the same ones that show up here if not removed earlier, so there should be no observations anymore





# Extra Checks #################

#"Done, have asked whether our starting file has duplicates and checked those are not an issue, then checked whether their list matches to multiple hydroids and addressed those, then consider their starting list as appropriate because if they were using a duplicate instead of a primary then it wouldn't match to map export bc duplicates aren't included (and we would find it in the join_by_hand section)"
# Earlier "Join_checks are to convince myself that the joins were correct, that the mpids join took the correct hydroid if there were multiple hydroids per mpid"

##check joins and duplicates 
# check that the right row of map export got joined to the CPRUIDs
dup_mpid <- sqldf('SELECT * FROM multiyr_wid GROUP BY MPID HAVING count(*)>1') #same as join_check2, resolved 
dup_well <- sqldf('SELECT * FROM multiyr_wid GROUP BY DEQ_Well_Number HAVING count(*)>1') #these don't matter because they aren't in the CPRUIDs list as shown by choose_well
   choose_well <- sqldf('SELECT * FROM IDlist WHERE CPRUIDs IN (
                 SELECT DEQ_Well_Number FROM dup_well
                 )')
dup_hydroid <- sqldf('SELECT * FROM multiyr_wid GROUP BY MP_hydroid HAVING count(*)>1') #these 2 don't matter because they aren't in the CPRUIDs list as shown by choose_hydroid
   choose_hydroid <- sqldf('SELECT * FROM IDlist WHERE CPRUIDs IN (
                 SELECT MP_hydroid FROM dup_hydroid
                 )') #shows 0 if CPRUIDs don't contain the hydroid corresponding to the two duplicate hydroids, but CPRUID would be in the format of VAHydro_##### so the choose_hydroid on the joined_sum3 should address that
   choose_hydroid <- sqldf('SELECT * FROM IDlist WHERE CPRUIDs IN (
                 SELECT DEQ_Well_Number FROM dup_hydroid
                 )') #shows 0 if CPRUIDs don't contain the well number corresponding to the two duplicate hydroids
   choose_hydroid <- sqldf('SELECT * FROM IDlist WHERE CPRUIDs IN (
                 SELECT MPID FROM dup_hydroid
                 )') #shows 0 if CPRUIDs don't contain the MPID corresponding to the two duplicate hydroids
   choose_hydroid <- sqldf('SELECT * FROM joined_sum3 WHERE MP_hydroid IN (
                 SELECT MP_hydroid FROM dup_hydroid
                 )') #shows 0 if final join doesn't contain the hydroid corresponding to the two duplicate hydroids

##Union All   
#for first time development, check that UNION ALL worked the same as an rbind followed by a join
   unioncheck <- sqldf('SELECT a.Ord as Ord_1, a.CPRUIDs as CPRUIDs_1, b.*
                   FROM IDlist a
                   LEFT JOIN joined_all b
                   ON a.CPRUIDs = b.CPRUIDs') 
   unioncheck <- sqldf('SELECT *, CASE WHEN Ord_1 = Ord THEN 0 ELSE 1 END AS OrdCheck,
                     CASE WHEN CPRUIDs_1 = CPRUIDs THEN 0 ELSE 1 END AS IDCheck
                     FROM unioncheck')
   unioncheck <- sqldf('SELECT * from unioncheck where OrdCheck = 1') #should be 0
   unioncheck <- sqldf('SELECT * from unioncheck where IDCheck = 1') #should be 0
   
## Aquaveo hydroid to VAhydroID      
#does Aquaveo's hydroid to MNW ID vlookup match our hydroid to CPRUID joins?
MNW_QA <- sqldf('SELECT HydroID,"MPID.MNW.IDENTIFIER" as mnwID FROM MNW_QA')
join_MNW <- sqldf("SELECT a.CPRUIDs, a.MP_Hydroid, b.*
                  FROM joined_sum3 a
                  INNER JOIN MNW_QA b
                  ON a.CPRUIDs = b.mnwID ") #1092-201NAs=891obs, correct 
join_MNW <- sqldf('SELECT *, 
                  CASE WHEN MP_hydroid = Hydroid
                  THEN 0 ELSE 1 END AS Match 
                  FROM join_MNW')
misidentified <- sqldf('SELECT * FROM join_MNW WHERE Match = 1') 
write.csv(mismatch, file=paste0(export_path,"/writecsv/misidentified_hydroids.csv"))
#flag the mismatches for Aquaveo 
# 63202 is an active vs they noted the duplicate hydroid
# 170251 and 170253 appear to be swapped potentially

#########################################################################
# TP QUERY ###############################
#########################################################################

#remove remaining duplicates from map export data, 
#because 449343 associated with 100-1440 and 100-01440, and 449370 associated with 100-1446 and 100-01446
multiyr_widb <- sqldf('SELECT * FROM multiyr_wid WHERE DEQ_Well_Number NOT IN ("100-1440","100-1446")')


#names(TP)
TP <- sqldf('SELECT "VA.HydroID" as VAHydroID, "MPID" as MPID_2, "DEQ.Well.Number" as DEQ_Well_Number_2, "Well.Status" as Well_Status, "Well.Type" as Well_Type, "Permit.Status" as "Permit_Status", "Permit.ID" as "Permit_ID","Assigned.Model.Layer.Cell" as Assigned_Model_Layer_Cell, "Annual.Permit.Limit..gpy." as Annual_Permit_Limit_gpy, X as Notes
            FROM TP')

joinTP <- sqldf('SELECT a.*, b.*
                  FROM TP a
                  LEFT JOIN multiyr_widb b
                  ON a.VAHydroID = b.MP_Hydroid')
#check duplicates
duplicate_check <- sqldf('SELECT VAHydroID FROM joinTP GROUP BY VAHydroID HAVING count(*)>1')
duplicate_check <- sqldf('SELECT MP_Hydroid FROM joinTP GROUP BY MP_Hydroid HAVING count(*)>1')

nomatch1 <- sqldf('SELECT * FROM joinTP WHERE MP_Hydroid is null ')
#write.csv(nomatch, file=paste0(export_path,"/writecsv/nomatch_TPhydroid_MPhydroid.csv"))
#28 hydroids not match because they began in 2022, and are not in 2021 map export data
#why not join RU to TP? becase hydroids in the TP that are not in joined_all ex. drummondton are bc joined_all is just CP not ES
joinedTP <- sqldf('SELECT * FROM joinTP WHERE VAHydroID NOT IN 
                (SELECT VAHydroID FROM nomatch1)')

#checks
#does MPID_2 match MPID
match_mpid <- sqldf('SELECT VAHydroID, MPID_2, MPID, CASE WHEN MPID_2 = MPID THEN 0 ELSE 1 END AS mpidmatch FROM joinedTP')
match_check <- sqldf('SELECT * from match_mpid where mpidmatch = 1')
#does DEQ_Well_Number_2 match DEQ_Well_Number
match_well <- sqldf('SELECT VAHydroID, DEQ_Well_Number_2, DEQ_Well_Number, CASE WHEN DEQ_Well_Number_2 = DEQ_Well_Number THEN 0 ELSE 1 END AS wellmatch FROM joinedTP')
match_check <- sqldf('SELECT * from match_well where wellmatch = 1') #bc of well# corrections in the notes column, so choose DEQ_Well_Number_2

#export for Aquaveo
joined_export2 <- subset(joinedTP, select = -c(MP_hydroid, MPID,DEQ_Well_Number))
colnames(joined_export2)[colnames(joined_export2)=="VAHydroID"] <- "MP_hydroid"
colnames(joined_export2)[colnames(joined_export2)=="MPID_2"] <- "MPID"
colnames(joined_export2)[colnames(joined_export2)=="DEQ_Well_Number_2"] <- "DEQ_Well_Number"
write.csv(joined_export2, file=paste0(export_path,"/writecsv/TotalPermitted_MatchedExport.csv"))


# #check if nomatch are in foundation data 
# foundation <- read.csv(file="U:/OWS/foundation_datasets/awrr/2022/foundation_dataset_mgy_1982-2021.csv")
# nomatch_f <- sqldf('SELECT a.VAHydroID, b.*
#       FROM nomatch1 a LEFT JOIN foundation b
#       ON a.VAHydroID = b.MP_hydroid')
# nrow(sqldf('SELECT * from nomatch_f where MP_hydroid is not null'))# so only 1 of the nomatch is in foundation data

#The only difference between the foundation pull and the map export pull is the "awrr" vs "annual-report" in the following URLs. Foundation: https://deq1.bse.vt.edu/d.dh/ows-awrr-map-export/wd_mgy?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=1982-01-01&tstime%5Bmax%5D=2021-12-31&bundle%5B0%5D=well&bundle%5B1%5D=intake  vs. Map Export: https://deq1.bse.vt.edu/d.dh/ows-annual-report-map-exports?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=1982-01-01&tstime%5Bmax%5D=2021-12-31&bundle%5B%5D=well&bundle%5B%5D=intake&hydroid= There aren't other filters apparent in the URL other than date, and selection of the wells/intakes bundle type. I don't see behind the scenes of the view if there are other filters. 


#########################################################################
# Aquaveo's list of Eastern Shore IDs ######################
#########################################################################

#add column so the individual ID matched rows can be reordered back to their excel sheet order 
nums <- array(1:nrow(ESRUIDlist))
IDlist <- cbind(nums,ESRUIDlist)
names(IDlist) <- c("Ord","ESRUIDs")
summary(IDlist)

#select recent years of interest from multi_yr_data, because their spreadsheet includes since 2003
multiyr_sel <- sqldf('SELECT * FROM multi_yr_data WHERE Year >= 2003')
multiyr_wid <- pivot_wider(multiyr_sel,names_from = "Year", values_from = "Water_Use_MGY")

#join MPIDs to the map export data #####
join_on_mpid <- sqldf('SELECT a.*, b.*
                  FROM IDlist a
                  LEFT JOIN multiyr_wid b
                  ON a.ESRUIDs = b.MPID')
joined_mpid <- sqldf('SELECT * FROM join_on_mpid WHERE MPID IS NOT NULL')
remainder <- sqldf('SELECT Ord, ESRUIDs FROM join_on_mpid WHERE MPID IS NULL')
nrow(remainder)

#checks
nrow(joined_mpid)+nrow(remainder) == nrow(IDlist) # False because there's 2 extra rows, IDList is 612 rows
join_check <- sqldf('SELECT * FROM joined_mpid GROUP BY MPID HAVING count(*)>1') #includes just duplicates created by the join on mpid

#remove the extra rows we don't think are correct from joined_mpid, based on MPIDs that showed up in join_check
choose_mpid <- sqldf('SELECT * FROM joined_mpid WHERE Ord IN (
              SELECT Ord FROM joined_mpid GROUP BY MPID HAVING count(*)>1
              )')
#rows were identical other than DEQ Well#, Aquaveo used neither, so keeping the instance where the DEQ Well # matches the Well # in the hydrocode

#remove duplicate mpid matches
joined_mpid <- sqldf('SELECT * FROM joined_mpid WHERE DEQ_Well_Number NOT IN ("100-01440","100-01446")')
join_check <- sqldf('SELECT * FROM joined_mpid GROUP BY MPID HAVING count(*)>1')
nrow(joined_mpid)+nrow(remainder) == nrow(IDlist) # Now should be True


#join on DEQ WELL NUMBER ######
join_on_well <-  sqldf('SELECT a.*, b.*
                  FROM remainder a
                  LEFT JOIN multiyr_wid b
                  ON a.ESRUIDs = b.DEQ_Well_Number')
joined_well <- sqldf('SELECT * FROM join_on_well WHERE DEQ_Well_Number IS NOT NULL')
remainder <- sqldf('SELECT Ord, ESRUIDs FROM join_on_well WHERE DEQ_Well_Number IS NULL')
nrow(remainder)
#nrow(joined_well)+nrow(remainder) #no extra rows because this matches prior remainder count of 19
join_check4 <- sqldf('SELECT * FROM joined_well GROUP BY DEQ_Well_Number HAVING count(*)>1')

#join on HYDROID ######
#N/A

#remainder #####
#combine the individual join types and merge with original IDlist
joined_bind <- rbind(joined_mpid, joined_well) 
joined_sum3 <- sqldf('SELECT a.Ord as Ord_1, a.ESRUIDs as ESRUIDs_1, b.*
                    FROM IDlist a
                    LEFT JOIN joined_bind b
                    on a.ESRUIDs = b.ESRUIDs')
remainder4 <- sqldf('SELECT Ord_1, ESRUIDs_1 FROM joined_sum3 WHERE ESRUIDs IS NULL')
join_byhand <- sqldf('SELECT Ord_1, ESRUIDs_1
                     FROM remainder4 
                     WHERE ESRUIDs_1 NOT LIKE "MD%"
                     AND ESRUIDs_1 NOT LIKE "NC%"')
#write.csv(join_byhand,file=paste0(export_path,"/writecsv/join_byhand_es.csv"))
#write.csv(joined_sum3, file=paste0(export_path, "/writecsv/ESRUID_MapExportData.csv")) 


### MANUALLY JOIN THE REMAINDER ROWS ######

#Information: Determine and correct unmatched hydroids based on hydrocodes that contain hydroids, Aquaveo's mastersheet containing potential hydroid matches, and investigating hydro for duplicates. See notes in join_byhand.xlsx on which were chosen. Hydroids of zero denote rows that are already have a hydroid represented in the ESRUIDs list, and should be removed from the model.Hydroids of 1 mean there was no matching hydroid and these need outside investigation before using in this script.

#Add hydroids to unmatched ESRUIDs
manual <- sqldf('SELECT Ord_1 as Ord, ESRUIDs_1 as ESRUIDs,
               CASE
                WHEN ESRUIDs_1 = 371323075585201 THEN 1
                WHEN ESRUIDs_1 = 374817075382402 THEN 1
                WHEN ESRUIDs_1 = 373749075415602 THEN 449343
                WHEN ESRUIDs_1 = 373748075415603 THEN 1
                WHEN ESRUIDs_1 = 373743075415808 THEN 449370
                WHEN ESRUIDs_1 = 373721075472802 THEN 440150
                WHEN ESRUIDs_1 = 373916075455808 THEN 441017
                WHEN ESRUIDs_1 = 374945075350901 THEN 1
                WHEN ESRUIDs_1 = 380013075375701 THEN 1
                WHEN ESRUIDs_1 = 380043075385901 THEN 1
                WHEN ESRUIDs_1 = 380103075393601 THEN 1
                WHEN ESRUIDs_1 = 380148075324301 THEN 1
                WHEN ESRUIDs_1 = 380257075324201 THEN 1
                WHEN ESRUIDs_1 = 380417075334301 THEN 1
                WHEN ESRUIDs_1 = 380758075254301 THEN 1
                WHEN ESRUIDs_1 = 380929075414501 THEN 1
                WHEN ESRUIDs_1 = 381018075411901 THEN 1
                WHEN ESRUIDs_1 = 381148075414201 THEN 1
                WHEN ESRUIDs_1 = 381305075391001 THEN 1
                END AS MP_hydroid_manual
                FROM remainder4')

#join manually identified hydroids with withdrawal data
joined_manual <- sqldf('SELECT a.Ord, a.ESRUIDs, b.*
                        FROM manual a 
                        LEFT JOIN multiyr_wid b
                       ON a.MP_hydroid_manual = b.MP_Hydroid')

#Row bind all the joins
joined_all <- sqldf('SELECT * from joined_mpid
                     UNION ALL SELECT * from joined_well
                     UNION ALL SELECT * from joined_manual
                     ORDER BY Ord ASC')
#last checks
remainder <- sqldf('SELECT Ord, ESRUIDs FROM joined_all WHERE MP_hydroid IS NULL 
                    AND ESRUIDs NOT LIKE "MD%"AND ESRUIDs NOT LIKE "NC%"') #should just be the 15 that were unmatched
join_check6 <- sqldf('SELECT * FROM joined_all GROUP BY ESRUIDs HAVING count(*)>1') #should be 0
duplicate_check <- sqldf('SELECT * from joined_all group by MP_Hydroid Having count(*)>1') # should be 1 to represent rows that weren't joined
duplicate_check <- sqldf('SELECT * from joined_all group by Ord having count(*)>1') #should be 0 if the Union worked properly


#export data for Aquaveo
joined_export <- joined_all
colnames(joined_export)[colnames(joined_export)=="ESRUIDs"] <- "List of ES 2020 RU IDs"
write.csv(joined_export, file=paste0(export_path, "/writecsv/ESRUID_MatchedExport.csv")) 



# Extra Checks #################
##check joins and duplicates 
# check that the right row of map export got joined to the ESRUIDs
dup_mpid <- sqldf('SELECT * FROM multiyr_wid GROUP BY MPID HAVING count(*)>1') #same as join_check2, resolved 
dup_well <- sqldf('SELECT * FROM multiyr_wid GROUP BY DEQ_Well_Number HAVING count(*)>1') #these don't matter because they aren't in the ESRUIDs list as shown by choose_well
choose_well <- sqldf('SELECT * FROM IDlist WHERE ESRUIDs IN (
                 SELECT DEQ_Well_Number FROM dup_well
                 )')



## Aquaveo hydroid to VAhydroID      
#does Aquaveo's hydroid to MNW ID vlookup match our hydroid to CPRUID joins?
MNW_QA <- sqldf('SELECT HydroID,"MPID.MNW.IDENTIFIER" as mnwID FROM MNW_QA')
join_MNW <- sqldf("SELECT a.ESRUIDs, a.MP_Hydroid, b.*
                  FROM joined_sum3 a
                  INNER JOIN MNW_QA b
                  ON a.ESRUIDs = b.mnwID ") #no matches, their MNW list probably isn't for Eastern Shore then
# join_MNW <- sqldf('SELECT *, 
#                   CASE WHEN MP_hydroid = Hydroid
#                   THEN 0 ELSE 1 END AS Match 
#                   FROM join_MNW')
# misidentified <- sqldf('SELECT * FROM join_MNW WHERE Match = 1') 
# write.csv(mismatch, file=paste0(export_path,"/writecsv/misidentified_hydroids.csv"))
# #flag the mismatches for Aquaveo 

