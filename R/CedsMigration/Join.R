###################################################
# To join use type, five year average, owner, and permit nubmer, 
# from the foundation data,
# to the VAHydro facilities that don't map directly to a CEDS facility based on exact name and address matches.
###################################################

library('sqldf')
library("hydrotools")

basepath ='/var/www/R'
source(paste0(basepath,'/config.R'))

# load data ###################################################################
A <- read.csv(paste0(github_location,"/vahydro/R/CedsMigration/VAHydro_Phase4_Facility_Mapping.csv"))#starting data migration list
C <- read.csv("C:\\Users\\rnv55934\\Documents\\Docs\\Misc\\Tasks Misc\\VAHydroMigration\\ows_permit_list.csv") #includes permit number and owner (download from https://deq1.bse.vt.edu/d.dh/ows-permit-list)
# # Use the ows permit list for the join instead of the expanded map exports bc using the permit list workflow later anyways
#B <- read.csv("U:\\OWS\\foundation_datasets\\awrr\\2022\\mp_all_mgy_2017-2021.csv") #includes use type, can derive 5yr avg
#Use the foudnation data instead of the mp_all_mgy so power gets included
# D <- read.csv("C:\\Users\\rnv55934\\Documents\\Docs\\Misc\\Tasks Misc\\VAHydroMigration\\ows_annual_report_map_exports-expanded (1).csv") # expanded map exports which includes owner and permit (map exports, 3rd CSV button)


#Load in foundation data and make into a wide format by facility
foundation <- read.csv("U:/OWS/foundation_datasets/awrr/2022/foundation_dataset_mgy_1982-2021.csv")
fndtn_fac <- sqldf('SELECT "Facility_hydroid","Facility","Use.Type" as Use_Type,"Latitude","Longitude","FIPS.Code" as FIPS_Code, 
sum("X1982") as X1982,
sum("X1983") as X1983,
sum("X1984") as X1984,
sum("X1985") as X1985,
sum("X1986") as X1986,
sum("X1987") as X1987,
sum("X1988") as X1988,
sum("X1989") as X1989,
sum("X1990") as X1990,
sum("X1991") as X1991,
sum("X1992") as X1992,
sum("X1993") as X1993,
sum("X1994") as X1994,
sum("X1995") as X1995,
sum("X1996") as X1996,
sum("X1997") as X1997,
sum("X1998") as X1998,
sum("X1999") as X1999,
sum("X2000") as X2000,
sum("X2001") as X2001,
sum("X2002") as X2002,
sum("X2003") as X2003,
sum("X2004") as X2004,
sum("X2005") as X2005,
sum("X2006") as X2006,
sum("X2007") as X2007,
sum("X2008") as X2008,
sum("X2009") as X2009,
sum("X2010") as X2010,
sum("X2011") as X2011,
sum("X2012") as X2012,
sum("X2013") as X2013,
sum("X2014") as X2014,
sum("X2015") as X2015,
sum("X2016") as X2016,
sum("X2017") as X2017,
sum("X2018") as X2018,
sum("X2019") as X2019,
sum("X2020") as X2020,
sum("X2021") as X2021
                   FROM foundation GROUP BY Facility_hydroid')
#write.csv(fndtn_fac,U:/OWS/foundation_datasets/awrr/2022/fac_all_wide_1982-2021.csv",row.names = F)


# Method using CSV downloads from VAHydro ####################################

## GROUP BY FACILITY #########################################################
CC <- sqldf('SELECT "VA.Hydro.Facility.ID" as Facility_hydroid, Owner, "Permit.ID" as PermitID, Status
            FROM C
            Group By "VA.Hydro.Facility.ID" ') #status may not be accurate if group by hydroid
# BB <- sqldf('SELECT Facility_hydroid, "Use.Type" as Use_Type, sum(X2017) as X2017, sum(X2018) as X2018, sum(X2019) as X2019, sum(X2020) as X2020, sum(X2021) as X2021
#             FROM B
#             Group By Facility_hydroid')
# DD <- sqldf('SELECT "Facility.ID" as Facility_hydroid, "Permit.ID" as PermitID, Owner
#             FROM D
#             Group By "Facility.ID" ')


## CALCULATE FIVE YEAR AVERAGE on foundation data ########################
five_yr_avg <- round((rowMeans(fndtn_fac[(length(fndtn_fac)-4):length(fndtn_fac)], na.rm = TRUE, dims = 1)),2)
ut_5ya <- cbind(fndtn_fac, five_yr_avg)

# #calculate Five Year Avg on mp_all_mgy - no longer needed
# five_yr_avg <- round((rowMeans(BB[3:7], na.rm = TRUE, dims = 1)),2)
# ut_5ya <- cbind(BB, five_yr_avg)


## PERFORM JOIN ############################################################

#join A to Use Type and Five Year Avg
A_ut_5ya <- sqldf('SELECT a.*, b.Use_Type, b.five_yr_avg
            FROM A a
            LEFT JOIN ut_5ya b
            ON a.VAHYDRO_HYDROID = b.Facility_hydroid')


#join A to Permit and Owner using ows permit list
A_Prmt_Ownr3 <- sqldf('SELECT a.*, b.Owner, b.PermitID
            FROM A_ut_5ya a
            LEFT JOIN CC b
            ON a.VAHYDRO_HYDROID = b.Facility_hydroid')

# #join A to Permit and Owner using ows permit list
# A_Prmt_Ownr1 <- sqldf('SELECT a.*, b.Owner, b.PermitID
#             FROM A_ut_5ya a
#             LEFT JOIN CC b
#             ON a.VAHYDRO_HYDROID = b.Facility_hydroid')
# #join A to Permit and Owner using expanded map exports
# A_Prmt_Ownr2 <- sqldf('SELECT a.*, b.PermitID, b.Owner
#             FROM A_ut_5ya a
#             LEFT JOIN DD b
#             ON a.VAHYDRO_HYDROID = b.Facility_hydroid')


## UNMATCHED HYDROIDS #########################################################

#check whether any hydroids were unmatched
A3_not_fndtn <- sqldf('select * from A_Prmt_Ownr3 where VAHYDRO_HYDROID NOT IN 
                 (select Facility_hydroid from fndtn_fac)') # use this
A3_not_CC <- sqldf('select * from A_Prmt_Ownr3 where VAHYDRO_HYDROID NOT IN 
                 (select Facility_hydroid from CC)') # use this
A3_not_fnCC <- sqldf('select * from A_Prmt_Ownr3 where VAHYDRO_HYDROID NOT IN 
                 (select Facility_hydroid from fndtn_fac) AND VAHYDRO_HYDROID NOT IN
                 (select Facility_hydroid from CC)') # use this

#check that using foundation data instead of mp_all_mgy doesnt add unmatched facilites - it doesn't
# check_A3notA <- sqldf('select * from A3_not_fndtn where VAHYDRO_HYDROID NOT IN 
#                  (select VAHYDRO_HYDROID from A_not_BB)')
# check_A3notA <- sqldf('select * from A3_not_CC where VAHYDRO_HYDROID NOT IN 
#                  (select VAHYDRO_HYDROID from A_not_CC)')
# check_A3notA <- sqldf('select * from A3_not_fnCC where VAHYDRO_HYDROID NOT IN 
#                  (select VAHYDRO_HYDROID from A_not_BBCC)')


## WRITE CSV ##################################################################
#export_path <- "C:\\Users\\rnv55934\\Documents\\Docs\\Misc\\Tasks Misc\\VAHydroMigration\\"
#write.csv(A_Prmt_Ownr3,paste0(export_path,"A_Prmt_Ownr3.csv"),row.names = F)
write.csv(A_Prmt_Ownr3,paste0(github_location,"/vahydro/R/CedsMigration/A_Prmt_Ownr3.csv"),row.names = F)

## ADDITIONAL CHECKS and QUESTIONS #############################################

# #check whether any hydroids were unmatched
# A_not_BB <- sqldf('select * from A_Prmt_Ownr1 where VAHYDRO_HYDROID NOT IN 
#                  (select Facility_hydroid from BB)') # old version
# A_not_CC <- sqldf('select * from A_Prmt_Ownr1 where VAHYDRO_HYDROID NOT IN 
#                  (select Facility_hydroid from CC)') # old version
# A_not_BBCC <- sqldf('select * from A_Prmt_Ownr1 where VAHYDRO_HYDROID NOT IN 
#                  (select Facility_hydroid from BB) AND VAHYDRO_HYDROID NOT IN 
#                  (select Facility_hydroid from CC)') # old version
# C_not_B <- sqldf('select * from CC where Facility_hydroid NOT IN 
#                  (select Facility_hydroid from BB)')
# # whichmatter <- sqldf('select * from A_Prmt_Ownr1 where VAHYDRO_HYDROID IN 
# #                  (select Facility_hydroid from C_not_B)')
# # A_not_DD <- sqldf('select * from A_Prmt_Ownr2 where VAHYDRO_HYDROID NOT IN 
# #                  (select Facility_hydroid from DD)')
# # A_not_BD <- sqldf('select * from A_Prmt_Ownr2 where VAHYDRO_HYDROID NOT IN 
# #                  (select Facility_hydroid from DD) AND VAHYDRO_HYDROID NOT IN
# #                  (select Facility_hydroid from DD) ')
# # B_not_D <- sqldf('select * from BB where Facility_hydroid NOT IN 
# #                  (select Facility_hydroid from DD)')
# # D_not_B <- sqldf('select * from DD where Facility_hydroid NOT IN 
# #                  (select Facility_hydroid from BB)')

#QUESTIONS
#why isn't hydro pull below working? - even if change expanded view not to be a batch export. permit view would pull faster as long as it contains owner. download csv provides the same data as the view so either method is fine.

#CHECKS
# are all the hydroids in the migration data sheet A receiving hydroid matches? which are not and why

#ANSWERS TO CHECKS 

# 217 hydroids in A not in foundation mp_all data - most of these are permit stati other than active. Of the active GWP/VWP, some make sense, ex. 2022 started reporting and power [fix this though] some don't ex 419188 linkmt permit writer 
# 192 hydroids in A not in foundation fac data, same as mp_all but includes power

# There are 34 in A not in the permit list, looks like reporting facilitates that just dont have permits, which could make sense since facilities in A foundation had 5ya values. the 'no vwuds measuring points' disconnect which is correct for GW and the 'no mp reported this year' is also ok when they have reporting prior years but haven't submitted 2022.

# 6 hydroids in A not in either foundation data or permit list, fully 'unmatched', bc no reporting or permits: 480090 never reported in 2021 and not a duplicate, 410580 never reported since 2018, 472077 never reported since 2020, 410119 never reported since 2018, 72715 is hydropower, 476991 never reported in 2021 



#---------------------------------------------------------
# METHOD TWO - using data pulled directly from VAHydro - not working yet #####

#https://deq1.bse.vt.edu/d.dh/ows-awrr-map-export-expanded/wd_mgy?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=1982-01-01&tstime%5Bmax%5D=2022-11-21&bundle%5B0%5D=well&bundle%5B1%5D=intake&hydroid=
  
basepath ='/var/www/R'
source(paste0(basepath,'/auth.private'))
source(paste0(basepath,'/config.R'))
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
ds$get_token(rest_pw)

startdate <-"1982-01-01"
enddate <-"2022-11-21"

#load in foundation data from Annual Map Exports EXPANDED view which includes organizations and permits, doesn't work yet
exp_url <- paste0(site,"ows-awrr-map-export-expanded/wd_mgy?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",startdate,"&tstime%5Bmax%5D=",enddate,"&bundle%5B0%5D=well&bundle%5B1%5D=intake&hydroid=")
Exp <- ds$auth_read(exp_url, content_type = "text/csv", delim = ",")


#load in OWS Permit List, also doesn't work
permit_url <-#"https://deq1.bse.vt.edu/d.dh/ows-permit-list?fstatus=All&modified=&startdate_op=%3D&startdate%5Bvalue%5D=&startdate%5Bmin%5D=&startdate%5Bmax%5D=&permit_id_value_op=%3D&permit_id_value=&dh_link_admin_reg_issuer_target_id_op=in&dh_link_admin_reg_issuer_target_id%5B%5D=65668&dh_link_admin_reg_issuer_target_id%5B%5D=91200&sort_by=enddate&sort_order=ASC"
PermitList <- ds$auth_read(permit_url, content_type = "text/csv", delim = ",")

##################### EXAMPLE ###################
#from AWRR
eyear<-2021
#load in MGY from Annual Map Exports view
tsdef_url <- paste0(site,"ows-awrr-map-export/wd_mgy?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=1982-01-01&tstime%5Bmax%5D=",eyear,"-12-31&bundle%5B0%5D=well&bundle%5B1%5D=intake")
#NOTE: this takes 5-8 minutes (grab a snack; stay hydrated)
multi_yr_data <- ds$auth_read(tsdef_url, content_type = "text/csv", delim = ",")
