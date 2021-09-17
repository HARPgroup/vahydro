#Use this script to generate a list of Drought Contacts
# 1) WSP Staff need to provide list of affected Drought Regions and/or localities
#LOAD CONFIG FILE
library(sqldf)
library(httr)
library(devtools)
install_github("HARPgroup/hydro-tools")
source(paste("/var/www/R/config.local.private", sep = ""))

#Pull list of all contacts associated with a facility
all_contacts <- read.csv(file = "https://deq1.bse.vt.edu/d.dh/ows-permit-contacts-data-export?dh_link_admin_reg_issuer_target_id%5B0%5D=65668&dh_link_admin_reg_issuer_target_id%5B1%5D=91200&dh_link_admin_reg_issuer_target_id%5B2%5D=77498&email_op=not&email=null.email&fstatus=", stringsAsFactors = F)

#Drought Regions and localities dataset
drought_regions <- read.csv(paste0(github_location,"/HARParchive/GIS_layers/Drought_Regions_FIPS_Localities.csv"), stringsAsFactors = F)

#drought regions that will be affected under the Drought Watch announcement
drought_area <- sqldf('SELECT *
                      FROM drought_regions
                      WHERE Drought_Region IN ("Big Sandy", "New River", "Upper James", "Shenandoah")
                      OR fips_name IN ("Loudoun", "Amherst", "Nelson", "Albemarle", "Charlottesville", "Lynchburg", "Bedford County", "Bedford City", "Roanoke City", "Roanoke County", "Salem", "Franklin County", "Patrick")')

#only select contacts from the list that are in the drought_area
drought_contacts <- sqldf('SELECT DISTINCT a.Email, a.Facility,  b.*
                          FROM all_contacts AS a
                          LEFT OUTER JOIN drought_area AS b
                          ON a."FIPS.Code" = b.FIPS
                          WHERE b.FIPS IS NOT NULL')

#Save Drought Contact List 
#(no multiples of the same email even if that same email is the contact for several facilities)
drought_contacts <- sqldf('SELECT DISTINCT a.Email,  b.*
                          FROM all_contacts AS a
                          LEFT OUTER JOIN drought_area AS b
                          ON a."FIPS.Code" = b.FIPS
                          WHERE b.FIPS IS NOT NULL')

write.csv(drought_contacts, paste0(export_path,"Drought_Watch_Contact_List_",Sys.Date(),".csv"), row.names = F)
