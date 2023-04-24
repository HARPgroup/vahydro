# 1) Use this script to generate a list of Drought Contacts for "public waterworks, and self-supplied water users"
# 2) WSP Staff will then need to append this list with contacts for "local governments" of affected Drought Regions and/or localities prior to sending out the notification email
#LOAD CONFIG FILE
library(sqldf)
library(httr)
library(devtools)
library(hydrotools)
source(paste("/var/www/R/config.local.private", sep = ""))

#Drought Regions and localities dataset
drought_regions <- read.csv(paste0(github_location,"/HARParchive/GIS_layers/Drought_Regions_FIPS_Localities.csv"), stringsAsFactors = F)

#Pull list of all contacts associated with a facility
all_contacts <- read.csv(file = "https://deq1.bse.vt.edu/d.dh/ows-permit-contacts-data-export?dh_link_admin_reg_issuer_target_id%5B0%5D=65668&dh_link_admin_reg_issuer_target_id%5B1%5D=91200&dh_link_admin_reg_issuer_target_id%5B2%5D=77498&email_op=not&email=null.email&fstatus=", stringsAsFactors = F)

#### Manual Pull --------------------------------------------------------------
#drought regions that will be affected under the Drought Watch announcement
# drought_area <- sqldf('SELECT *
#                       FROM drought_regions
#                       WHERE Drought_Region IN ("Big Sandy", "New River", "Upper James", "Shenandoah")
#                       OR fips_name IN ("Loudoun", "Amherst", "Nelson", "Albemarle", "Charlottesville", "Lynchburg", "Bedford County", "Bedford City", "Roanoke City", "Roanoke County", "Salem", "Franklin County", "Patrick")')


drought_area <- sqldf('SELECT *
                      FROM drought_regions
                      WHERE Drought_Region IN ("Chowan", "Eastern Shore", "Northern Coastal Plain", "Southeast Virginia", "York James")')

#only select contacts from the list that are in the drought_area
drought_contacts <- sqldf('SELECT DISTINCT LOWER(a.Email), a.Facility,  b.*
                          FROM all_contacts AS a
                          LEFT OUTER JOIN drought_area AS b
                          ON a."FIPS.Code" = b.FIPS
                          WHERE b.FIPS IS NOT NULL')

#Save Drought Contact List 
#(no multiples of the same email even if that same email is the contact for several facilities)
drought_contacts <- sqldf('SELECT DISTINCT LOWER(a.Email),  b.*
                          FROM all_contacts AS a
                          LEFT OUTER JOIN drought_area AS b
                          ON a."FIPS.Code" = b.FIPS
                          WHERE b.FIPS IS NOT NULL')

write.csv(drought_contacts, paste0("U:/OWS/Drought/6 - Drought Event Contact Lists/2023/Drought_Watch_Contact_List_4-24-2023.csv"), row.names = F)
