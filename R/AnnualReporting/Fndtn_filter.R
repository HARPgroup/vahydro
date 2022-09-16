#############################################################################
# This script filters the foundation data for various data request purposes
#############################################################################

library('sqldf')

#load foundation datasets
basepath <- "U:/OWS/foundation_datasets/awrr/2022/"
foundation <- read.csv(file=paste0(basepath,"foundation_dataset_mgy_1982-2021.csv"))
fac_all <- read.csv(file=paste0(basepath,"fac_all_1982-2021.csv"))

#set export path
#export_path <- "C:/Users/rnv55934/Documents/"
source(paste("C:/var/www/R/config.local.private", sep = ""))


# REQUEST: All Municipal Facilities that use ONLY GW, without any SW additions ########################

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

################################################################################


# #cross check
# # sw_fac <- sqldf('SELECT Facility_hydroid FROM pws WHERE "Source.Type" == "Surface Water"')
# # pws_gw_check <- sqldf('SELECT * FROM pws WHERE Facility_hydroid NOT IN (SELECT Facility_hydroid FROM sw_fac) ')

