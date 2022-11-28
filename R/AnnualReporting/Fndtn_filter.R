#############################################################################
# This script filters the foundation data for various data request purposes
#############################################################################

library('sqldf')

#load foundation datasets
basepath <- "U:/OWS/foundation_datasets/awrr/2022/"
foundation <- read.csv(file=paste0(basepath,"foundation_dataset_mgy_1982-2021.csv"))
fac_all <- read.csv(file=paste0(basepath,"fac_all_1982-2021.csv"))
ows_permit_list <- read.csv(file=paste0(basepath,"ows_permit_list.csv"))

#set export path
#export_path <- "C:/Users/rnv55934/Documents/"
source(paste("C:/var/www/R/config.local.private", sep = ""))

################################################################################
# REQUEST: All Municipal Facilities that use ONLY GW, without any SW additions ################################################################################

#filter for use type
pws <- sqldf('SELECT * FROM foundation WHERE "Use.Type" == "municipal" ')

#select GW facilities, and remove any facility that contains a SW intake
pws_gw <- sqldf('SELECT * FROM pws WHERE "Source.Type" == "Groundwater"
                AND Facility_hydroid NOT IN 
                (SELECT Facility_hydroid FROM pws WHERE "Source.Type" == "Surface Water" GROUP BY Facility_hydroid) ')


#filter facility foundation table for the selected facility hydroids
export <- sqldf('SELECT * FROM fac_all WHERE Facility_hydroid IN (SELECT Facility_hydroid FROM pws_gw) ')

write.csv(export, file=paste0(export_path,"fac_pws_gw.csv"), row.names=FALSE)


## generic version for other usetypes #####

#filter for use type
u <- "manufacturing"
use <- sqldf(paste('SELECT * FROM foundation WHERE "Use.Type" == ',paste('"',u,'"', sep = ''),sep=''))

#select GW facilities, and remove any facility that contains a SW intake
use_gw <- sqldf('SELECT * FROM use WHERE "Source.Type" == "Groundwater"
                AND Facility_hydroid NOT IN 
                (SELECT Facility_hydroid FROM use WHERE "Source.Type" == "Surface Water" GROUP BY Facility_hydroid) ')

#filter facility foundation table for the selected facility hydroids
export <- sqldf('SELECT * FROM fac_all WHERE Facility_hydroid IN (SELECT Facility_hydroid FROM use_gw) ')

write.csv(export, file=paste0(export_path,"fac_",u,"_gw.csv"), row.names=FALSE)

# saved 09/16/22

################################################################################
# REQUEST: "The Database" = Provide facility level foundation data with 1982-2021 reported use and OWS permit limits #####
# Date: 11-28-2022
################################################################################

#group foundation MP data by facility
fndtn_fac <- sqldf('SELECT "Source.Type","Facility_hydroid","Facility","Use.Type","Latitude","Longitude","FIPS.Code", 
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

#overwrite with latest OWS permit list downloaded from https://deq1.bse.vt.edu/d.dh/ows-permit-list
ows_permit_list <- read.csv("C:\\Users\\rnv55934\\Documents\\Docs\\Misc\\Tasks Misc\\VAHydroMigration\\ows_permit_list.csv") 
#rename hydroid column for the join
ows_prmt <- sqldf('SELECT "VA.Hydro.Facility.ID" as Facility_hydroid, "GWP.Annual.Limit" as GWP_Annual_Limit,"GWP.Monthly.Limit" as GWP_Monthly_Limit,"VWP.Annual.Limit" as VWP_Annual_Limit, "VWP.Monthly.Limit" as VWP_Monthly_Limit,"VWP.Daily.Limit" as VWP_Daily_Limit, Status
                  FROM ows_permit_list
                  WHERE Status = "active" OR Status = "expired"')

#join facility foundation data to permit limits
fac_prmt <- sqldf('SELECT a.*, b.GWP_Annual_Limit, b.GWP_Monthly_Limit, b.VWP_Annual_Limit, b.VWP_Monthly_Limit, b.VWP_Daily_Limit, b.Status as Permit_Status
            FROM fndtn_fac a
            LEFT JOIN ows_prmt b
            ON a.Facility_hydroid = b.Facility_hydroid')

#check for duplicates
check <- sqldf('select * from fac_prmt group by Facility_hydroid having count(*)>1')
rm(check)
#note Lake Kilby Water Treatment Facility 67337 has active GW and expired SW in application so leaving the duplicated hydroid
#note Birchwood Power Facility 67174 has active GW and SW in two rows so leaving the duplicated hydroid

#identify the facilities with multiple source types
swfac <- sqldf('SELECT "Facility_hydroid","Source.Type" as Source_Type FROM foundation
               WHERE "Source.Type" = "Surface Water" GROUP BY Facility_hydroid ')
gwfac <- sqldf('SELECT "Facility_hydroid","Source.Type" as Source_Type FROM foundation
               WHERE "Source.Type" = "Groundwater"  GROUP BY Facility_hydroid ')
gwsw <- sqldf('SELECT Facility_hydroid FROM swfac WHERE Facility_hydroid IN (SELECT Facility_hydroid FROM gwfac)')
swgw <- sqldf('SELECT a.*,
              CASE WHEN Facility_hydroid IS NOT NULL THEN "GW_and_SW" END AS "Source_Types"
              FROM gwsw AS a')
fac_prmt2 <- sqldf('SELECT a.*, b.Source_Types
            FROM fac_prmt a
            LEFT JOIN swgw b
            ON a.Facility_hydroid = b.Facility_hydroid')

#write csv
write.csv(fac_prmt2, paste0(export_path,"fac_prmt2.csv"), row.names=F)

################################################################################
# REQUEST: 
# Date: 
################################################################################
