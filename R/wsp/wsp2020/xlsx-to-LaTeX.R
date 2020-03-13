library("readxl")
library("knitr")
library("kableExtra")
library("sqldf")

# Location of source data
#source <- "wsp2020.fac.all.MinorBasins_RSegs.csv"
source <- "wsp2020.mp.all.MinorBasins_RSegs.csv"
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"

# Location of GIS_functions and gdb
hydro_tools_remote <-"https://raw.githubusercontent.com/HARPgroup/hydro-tools/master"
localpath <-"C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/"
source(paste(hydro_tools_remote,'GIS_LAYERS/GIS_functions.R', sep='/'));

gdb_path <- "hydro-tools/GIS_LAYERS/HUC.gdb" #Location of HUC .gdb
layer_name <- 'WBDHU6' #HUC6 layer withing the HUC .gdb


data_raw <- read.csv(paste(folder,source,sep=""))
mp_all <- data_raw

# ###########################################################################
# # PERFORM SPATIAL CONTAINMENT
# data_sp <- data_sp[-which(data_sp$Latitude > 90),]
# 
# #PERFORM THIS PART IN SQL AS WELL:
# #Set NA, -99, or 99 coordinates to 0.0; This step is required for coordinates() function
# data_sp$Latitude[is.na(data_sp$Latitude)] = 0.0 #-9999 
# data_sp$Longitude[is.na(data_sp$Longitude)] = 0.0
# data_sp$Latitude[data_sp$Latitude == 99] = 0.0
# data_sp$Latitude[data_sp$Latitude == -99] = 0.0
# data_sp$Longitude[data_sp$Longitude == 99] = 0.0
# data_sp$Longitude[data_sp$Longitude == -99] = 0.0
# 
# data_sp$Latitude[is.na(data_sp$Latitude)] = data_sp$fips_code #-9999 
# data_sp$Longitude[is.na(data_sp$Longitude)] = 0.0
# data_sp$Latitude[data_sp$Latitude == 99] = 0.0
# data_sp$Latitude[data_sp$Latitude == -99] = 0.0
# data_sp$Longitude[data_sp$Longitude == 99] = 0.0
# data_sp$Longitude[data_sp$Longitude == -99] = 0.0
# 
# 
# 
# data_sp_sql <- sqldf('SELECT * FROM data_sp WHERE NOT Latitude > 90')
# data_sp_sql <- sqldf('SELECT * FROM data_sp_sql WHERE NOT Latitude = 99')
# data_sp_sql <- sqldf('SELECT * FROM data_sp_sql WHERE NOT Latitude = -99')
# data_sp_sql <- sqldf('SELECT * FROM data_sp_sql WHERE NOT Longitude = 99')
# data_sp_sql <- sqldf('SELECT * FROM data_sp_sql WHERE NOT Longitude = -99')
# data_sp <- data_sp_sql
# 
# coordinates(data_sp) <- c("Longitude", "Latitude") #sp_contain() requires a coordinates column
# data_sp_cont <- sp_contain(paste(localpath,gdb_path,sep="/"),layer_name,'all',data_sp)
# data_sp_cont <- data.frame(data_sp_cont)
# ###########################################################################

#Top users from all watersheds, excluding wsp facilities
# sql <- paste("SELECT facility_name, 
#                       facility_ftype, 
#                       fac_2020_mgy, 
#                       fac_2040_mgy, 
#                       Poly_Name
#                   FROM data_sp_cont 
#                   WHERE facility_ftype NOT LIKE 'wsp%'
#                   ORDER BY fac_2020_mgy DESC
#                   LIMIT 20"
#               ,sep="")
# data <- sqldf(sql)

# 
# # OUTPUT TABLE IN KABLE FORMAT
# kable(data, "latex", booktabs = T,
#       caption = paste("Top 5 Users in ",huc6_name," HUC 6",sep=""), 
#       label = paste("Top5_",huc6_name,sep=""),
#       col.names = c("Facility Name",
#                     "Facility Type",
#                     "2020 (MGY)",
#                     "2040 (MGY)",
#                     "HUC6")) %>%
#   kable_styling(latex_options = c("striped", "scale_down")) %>% 
#   #column_spec(1, width = "5em") %>%
#   #column_spec(2, width = "5em") %>%
#   #column_spec(3, width = "5em") %>%
#   #column_spec(4, width = "4em") %>%
#   cat(., file = paste(folder,"kable_tables/","Top5_",huc6_name,"_kable.tex",sep=""))

###########################################################################

#Output all Minor Basin options
sqldf('SELECT DISTINCT MinorBasin_Name, MinorBasin_Code
      FROM mp_all
      ')
#change minor basin name
mb_name <- "New River"

#Select measuring points  within HUC of interest, Restict output to columns of interest
sql <- paste('SELECT  MP_hydroid,
                      MP_bundle,
                      facility_name, 
                      facility_ftype,
                      wsp_ftype,
                      mp_2020_mgy, 
                      mp_2040_mgy, 
                      MinorBasin_Name
                  FROM mp_all 
                  WHERE MinorBasin_Name = ','\"',mb_name,'\"','
                  ORDER BY mp_2020_mgy DESC
              ',sep="")

mb_mps <- sqldf(sql)

#---------------------------------------------------------------#

#Transform
#Demand by System Type 
by_system_type <- sqldf("SELECT wsp_ftype, sum(mp_2020_mgy) AS '2020 Demand (MGY)', sum(mp_2040_mgy) AS '2040 Demand (MGY)'
                        FROM mb_mps
                        WHERE facility_ftype NOT LIKE '%power'
                        GROUP BY wsp_ftype")

# OUTPUT TABLE IN KABLE FORMAT
 kable(by_system_type, "latex", booktabs = T,
      caption = paste("Withdrawal Demand by System Type (excluding Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demandsystem_type_no_power",mb_name,sep=""),
       col.names = c("System Type",
                     "2020 Demand (MGY)",
                     "2040 Demand (MGY)")) %>%
   kable_styling(latex_options = c("striped", "full_width")) %>%
   #column_spec(1, width = "5em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demandsystem_type_no_power_",mb_name,"_kable.tex",sep=""))
 
 #---------------------------------------------------------------#
 
 by_system_type <- sqldf("SELECT wsp_ftype, sum(mp_2020_mgy) AS '2020 Demand (MGY)', sum(mp_2040_mgy) AS '2040 Demand (MGY)'
                        FROM mb_mps
                        GROUP BY wsp_ftype")
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_system_type, "latex", booktabs = T,
       caption = paste("Withdrawal Demand by System Type (including Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demandsystem_type_yes_power",mb_name,sep=""),
       col.names = c("System Type",
                     "2020 Demand (MGY)",
                     "2040 Demand (MGY)")) %>%
   kable_styling(latex_options = c("striped", "full_width")) %>%
   #column_spec(1, width = "5em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demandsystem_type_yes_power_",mb_name,"_kable.tex",sep=""))

 ###############################################################

 #Transform
 #Demand by Source Type 
 by_source_type <- sqldf("SELECT MP_bundle, sum(mp_2020_mgy) AS '2020 Demand (MGY)', sum(mp_2040_mgy) AS '2040 Demand (MGY)'
                        FROM mb_mps
                        WHERE facility_ftype NOT LIKE '%power'
                        GROUP BY MP_bundle")
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_source_type, "latex", booktabs = T,
       caption = paste("Withdrawal Demand by Source Type (excluding Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demandsource_type_no_power",mb_name,sep=""),
       col.names = c("Source Type",
                     "2020 Demand (MGY)",
                     "2040 Demand (MGY)")) %>%
   kable_styling(latex_options = c("striped", "full_width")) %>%
   #column_spec(1, width = "5em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demandsource_type_no_power_",mb_name,"_kable.tex",sep=""))
 
#----------------------------------------------------------------#
 
 by_source_type <- sqldf("SELECT MP_bundle, sum(mp_2020_mgy) AS '2020 Demand (MGY)', sum(mp_2040_mgy) AS '2040 Demand (MGY)'
                        FROM mb_mps
                        GROUP BY MP_bundle")
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_source_type, "latex", booktabs = T,
       caption = paste("Withdrawal Demand by Source Type (including Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demandsource_type_yes_power",mb_name,sep=""),
       col.names = c("Source Type",
                     "2020 Demand (MGY)",
                     "2040 Demand (MGY)")) %>%
   kable_styling(latex_options = c("striped", "full_width")) %>%
   #column_spec(1, width = "5em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demandsource_type_yes_power_",mb_name,"_kable.tex",sep=""))
 
###################################################################
 
############################################################################################
 
#Locality Plan Updates 
summary(mp_all) 
updated_by_user <- sqldf("SELECT *
                         FROM mp_all
                         WHERE fips_code IN (51015, 51033, 51041, 51047, 51069, 51099, 51103, 51113, 51133, 51159, 51165, 51193, 51660, 51760)")
sqldf("SELECT wsp_ftype, sum(mp_2020_mgy), sum(mp_2040_mgy)
      FROM updated_by_user
      group by wsp_ftype")
 
updated_by_DEQ_staff <- sqldf("SELECT *
                         FROM mp_all
                         WHERE fips_code IN (51003, 51029, 51036, 51041, 51049, 51061, 51069, 51075, 51085, 51087, 51109, 51113, 51127, 51137, 51145, 51159, 51165, 51171, 51540)")
sqldf("SELECT wsp_ftype, sum(mp_2020_mgy), sum(mp_2040_mgy)
      FROM updated_by_DEQ_staff
      group by wsp_ftype")