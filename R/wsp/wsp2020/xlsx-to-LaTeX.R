library("knitr")
library("kableExtra")
library("sqldf")

#---------------------INITIALIZE GLOBAL VARIABLES------------------------#
#"html" for viewing in Rstudio Viewer pane; "latex" when ready to output to Overleaf
#options(knitr.table.format = "latex")
options(knitr.table.format = "html")

#Kable Styling
latexoptions <- c("striped")
width <- T
kable_col_names <- c("",
                     "System Type",
                     "2020 Demand (MGY)",
                     "2030 Demand (MGY)",
                     "2040 Demand (MGY)",
                     "2020 Demand (MGD)",
                     "2030 Demand (MGD)",
                     "2040 Demand (MGD)",
                     "20 Year Percent Change")

#SQL
aggregate_select <- 'sum(mp_2020_mgy) AS MGY_2020,
sum(mp_2030_mgy) AS MGY_2030, 
sum(mp_2040_mgy) AS MGY_2040, 
sum(mp_2020_mgy)/365.25 AS MGD_2020,
sum(mp_2030_mgy)/365.25 AS MGD_2030, 
sum(mp_2040_mgy)/365.25 AS MGD_2040,
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS pct_change'

#totals function which allows us to append column sums to table to generate in kable
totals_func <- function(z) if (is.numeric(z)) sum(z) else ''
#--------------------------------LOAD DATA-------------------------------#

# Location of source data
#source <- "wsp2020.fac.all.MinorBasins_RSegs.csv"
source <- "wsp2020.mp.all.MinorBasins_RSegs.csv"
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"

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
# kable(data,  booktabs = T,
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


########################### CHOOSE A MINOR BASIN ##############################

#Output all Minor Basin options
mb_options <- sqldf('SELECT DISTINCT MinorBasin_Name, MinorBasin_Code
      FROM mp_all
      ')
#change minor basin name
mb_name <- "New River"
#select minor basin code to know folder to save in
sql <- paste('SELECT MinorBasin_Code
                   From mb_options
                   WHERE MinorBasin_Name = ','\"',mb_name,'\"','
              ',sep="")
mb_abbrev <- sqldf(sql)
#Select measuring points  within HUC of interest, Restict output to columns of interest
sql <- paste('SELECT  MP_hydroid,
                      MP_bundle,
                      Facility_hydroid, 
                      facility_name, 
                      facility_ftype,
                      wsp_ftype,
                      mp_2020_mgy,
                      mp_2030_mgy,
                      mp_2040_mgy, 
                      MinorBasin_Name
                  FROM mp_all 
                  WHERE MinorBasin_Name = ','\"',mb_name,'\"','
                  ORDER BY mp_2020_mgy DESC', sep="")

mb_mps <- sqldf(sql)

#---------------------------------------------------------------#

#Transform
#Demand by System Type 
system_sql <- paste('SELECT 
                     wsp_ftype,',
                     aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY wsp_ftype', sep="")

by_system_type <- sqldf(system_sql)
   
#calculate columns sums 
totals <- as.data.frame(lapply(by_system_type[1:7], totals_func),stringsAsFactors = F)
#calculate total percentage change
totals <- sqldf("SELECT *, 
round(((sum(MGY_2040) - sum(MGY_2020)) / sum(MGY_2020)) * 100,2) AS 'pct_change'
      FROM totals")
#append totals to table
by_system_type <- rbind(cbind(' '=' ', by_system_type),
                        cbind(' '='Total', totals))

# OUTPUT TABLE IN KABLE FORMAT
kable(by_system_type,  booktabs = T,
      caption = paste("Withdrawal Demand by System Type (excluding Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demandsystem_type_no_power",mb_abbrev,sep=""),
       col.names = kable_col_names) %>%
    kable_styling(latex_options = latexoptions, full_width = width) %>%
   #column_spec(1, width = "6em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demandsystem_type_no_power_",mb_abbrev,"_kable.tex",sep=""))
 
 #---------------------------------------------------------------#
 
#Transform
#Demand by System Type 
system_sql <- paste('SELECT 
                     wsp_ftype,',
                    aggregate_select,'
                     FROM mb_mps
                     GROUP BY wsp_ftype', sep="")

by_system_type <- sqldf(system_sql)
 
 #calculate columns sums 
 totals <- as.data.frame(lapply(by_system_type[1:7], totals_func),stringsAsFactors = F)
 #calculate total percentage change
 totals <- sqldf("SELECT *, 
round(((sum(MGY_2040) - sum(MGY_2020)) / sum(MGY_2020)) * 100,2) AS 'pct_change'
      FROM totals")
 #append totals to table
 by_system_type <- rbind(cbind(' '=' ', by_system_type),
                         cbind(' '='Total', totals))
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_system_type,  booktabs = T,
       caption = paste("Withdrawal Demand by System Type (including Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demandsystem_type_yes_power",mb_name,sep=""),
       col.names = kable_col_names) %>%
     kable_styling(latex_options = latexoptions, full_width = width) %>%
    #column_spec(1, width = "6em") %>%
    #column_spec(2, width = "5em") %>%
    #column_spec(3, width = "5em") %>%
    #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demandsystem_type_yes_power_",mb_abbrev,"_kable.tex",sep=""))

 ###############################################################

 #Transform
 #Demand by System Type 
 source_sql <- paste('SELECT 
                     MP_bundle,',
                     aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY MP_bundle', sep="")
 
 by_source_type <- sqldf(source_sql)
 
 #calculate columns sums 
 totals <- as.data.frame(lapply(by_source_type[1:7], totals_func),stringsAsFactors = F)
 #calculate total percentage change
 totals <- sqldf("SELECT *, 
round(((sum(MGY_2040) - sum(MGY_2020)) / sum(MGY_2020)) * 100,2) AS 'pct_change'
      FROM totals")
 #append totals to table
 by_source_type <- rbind(cbind(' '=' ', by_source_type),
                         cbind(' '='Total', totals))
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_source_type,  booktabs = T,
       caption = paste("Withdrawal Demand by Source Type (excluding Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demandsource_type_no_power",mb_name,sep=""),
       col.names = kable_col_names) %>%
     kable_styling(latex_options = latexoptions, full_width = width) %>%
   #column_spec(1, width = "5em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demandsource_type_no_power_",mb_abbrev,"_kable.tex",sep=""))
 
#----------------------------------------------------------------#
 
 #Transform
 #Demand by System Type 
 source_sql <- paste('SELECT 
                     MP_bundle,',
                     aggregate_select,'
                     FROM mb_mps
                     GROUP BY MP_bundle', sep="")
 
 by_source_type <- sqldf(source_sql)
 
 #calculate columns sums 
 totals <- as.data.frame(lapply(by_source_type[1:7], totals_func),stringsAsFactors = F)
 #calculate total percentage change
 totals <- sqldf("SELECT *, 
round(((sum(MGY_2040) - sum(MGY_2020)) / sum(MGY_2020)) * 100,2) AS 'pct_change'
      FROM totals")
 #append totals to table
 by_source_type <- rbind(cbind(' '=' ', by_source_type),
                         cbind(' '='Total', totals))
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_source_type,  booktabs = T,
       caption = paste("Withdrawal Demand by Source Type (including Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demandsource_type_yes_power",mb_name,sep=""),
       col.names = kable_col_names) %>%
     kable_styling(latex_options = latexoptions, full_width = width) %>%
   #column_spec(1, width = "5em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demandsource_type_yes_power_",mb_abbrev,"_kable.tex",sep=""))
 
############################################################################
 
############################################################################
 
############################################################################
 
############################################################################
 
############################################################################
 
############################################################################
#Locality Plan Updates 
summary(mp_all) 
summary_total <- sqldf("SELECT 
sum(mp_2020_mgy) as 'Total 2020 MGY', 
sum(mp_2020_mgy)/365.25 as 'Total 2020 MGD', 
sum(mp_2040_mgy) as 'Total 2040 MGY',  
sum(mp_2040_mgy)/365.25 as 'Total 2040 MGD'
                       FROM mp_all")

#----------------------------------------------------------------#

updated_by_user <- sqldf("SELECT *
                         FROM mp_all
                         WHERE fips_code IN (51015, 51033, 51041, 51047, 51069, 51099, 51103, 51113, 51133, 51159, 51165, 51193, 51660, 51760)")
sqldf("SELECT  
sum(mp_2020_mgy) as 'Total 2020 MGY', 
sum(mp_2020_mgy)/365.25 as 'Total 2020 MGD', 
sum(mp_2040_mgy) as 'Total 2040 MGY',  
sum(mp_2040_mgy)/365.25 as 'Total 2040 MGD'
      FROM updated_by_user")

user_type <- sqldf("SELECT 
wsp_ftype, 
sum(mp_2020_mgy) as 'Total 2020 MGY', 
sum(mp_2020_mgy)/365.25 as 'Total 2020 MGD', 
round(sum(mp_2020_mgy)/2504894,2) as '2020 % of Total', 
sum(mp_2040_mgy) as 'Total 2040 MGY',  
sum(mp_2040_mgy)/365.25 as 'Total 2040 MGD', 
round(sum(mp_2040_mgy)/2943110,2) as '2040 % of Total'
      FROM updated_by_user
      group by wsp_ftype")

kable(user_type, booktabs = T,
      caption = "Updated by Locality",
      label = "Updated by Locality",
      col.names = c("System Type",
                    "2020 Demand (MGY)",
                    "2020 Demand (MGD)",
                    "2020 % of Total",
                    "2040 Demand (MGY)",
                    "2040 Demand (MGD)",
                    "2040 % of Total")) %>%
   kable_styling(latex_options = c("striped", "full_width"))

#----------------------------------------------------------------#

updated_by_DEQ_staff <- sqldf("SELECT *
                         FROM mp_all
                         WHERE fips_code IN (51003, 51029, 51036, 51041, 51049, 51061, 51069, 51075, 51085, 51087, 51109, 51113, 51127, 51137, 51145, 51159, 51165, 51171, 51540)")

sqldf("SELECT  
sum(mp_2020_mgy) as 'Total 2020 MGY', 
sum(mp_2020_mgy)/365.25 as 'Total 2020 MGD', 
sum(mp_2040_mgy) as 'Total 2040 MGY',  
sum(mp_2040_mgy)/365.25 as 'Total 2040 MGD'
      FROM updated_by_DEQ_staff")

staff_type <- sqldf("SELECT 
wsp_ftype, sum(mp_2020_mgy) as 'Total 2020 MGY', 
sum(mp_2020_mgy)/365.25 as 'Total 2020 MGD', 
round(sum(mp_2020_mgy)/2504894,2) as '2020 % of Total', 
sum(mp_2040_mgy) as 'Total 2040 MGY',  
sum(mp_2040_mgy)/365.25 as 'Total 2040 MGD', 
round(sum(mp_2040_mgy)/2943110,2) as '2040 % of Total'
      FROM updated_by_DEQ_staff
      group by wsp_ftype")

kable(staff_type,  booktabs = T,
      caption = "Updated by DEQ Staff",
      label = "Updated by DEQ Staff",
      col.names = c("System Type",
                    "2020 Demand (MGY)",
                    "2020 Demand (MGD)",
                    "2020 % of Total",
                    "2040 Demand (MGY)",
                    "2040 Demand (MGD)",
                    "2040 % of Total")) %>%
   kable_styling(latex_options = c("striped", "full_width"))

#----------------------------------------------------------------#

updated_by_both <- sqldf("SELECT *
                         FROM mp_all
                         WHERE fips_code IN (51003,
51015,
51029,
51033,
51036,
51041,
51047,
51049,
51061,
51069,
51075,
51085,
51087,
51099,
51103,
51109,
51113,
51127,
51133,
51137,
51159,
51165,
51171,
51193,
51540,
51660,
51760)")

sqldf("SELECT 
sum(mp_2020_mgy) as 'Total 2020 MGY', 
sum(mp_2020_mgy)/365.25 as 'Total 2020 MGD', 
sum(mp_2040_mgy) as 'Total 2040 MGY',  
sum(mp_2040_mgy)/365.25 as 'Total 2040 MGD'
      FROM updated_by_both")

both <- sqldf("SELECT 
wsp_ftype, 
sum(mp_2020_mgy) as 'Total 2020 MGY', 
sum(mp_2020_mgy)/365.25 as 'Total 2020 MGD', 
round(sum(mp_2020_mgy)/2504894,2) as '2020 % of Total', 
sum(mp_2040_mgy) as 'Total 2040 MGY',  
sum(mp_2040_mgy)/365.25 as 'Total 2040 MGD', 
round(sum(mp_2040_mgy)/2943110,2) as '2040 % of Total'
      FROM updated_by_both
      group by wsp_ftype")

kable(both,  booktabs = T,
      caption = "Updated by Locality & DEQ Staff",
      label = "Updated by Locality & DEQ Staff",
      col.names = c("System Type",
                    "2020 Demand (MGY)",
                    "2020 Demand (MGD)",
                    "2020 % of Total",
                    "2040 Demand (MGY)",
                    "2040 Demand (MGD)",
                    "2040 % of Total")) %>%
   kable_styling(latex_options = c("striped", "full_width"))

#----------------------------------------------------------------#
not_updated_by_both <- sqldf("SELECT *
                         FROM mp_all
                         WHERE fips_code NOT IN (51003,
51015,
51029,
51033,
51036,
51041,
51047,
51049,
51061,
51069,
51075,
51085,
51087,
51099,
51103,
51109,
51113,
51127,
51133,
51137,
51159,
51165,
51171,
51193,
51540,
51660,
51760)")

sqldf("SELECT  
sum(mp_2020_mgy) as 'Total 2020 MGY', 
sum(mp_2020_mgy)/365.25 as 'Total 2020 MGD', 
sum(mp_2040_mgy) as 'Total 2040 MGY',  
sum(mp_2040_mgy)/365.25 as 'Total 2040 MGD'
      FROM not_updated_by_both")

not_updated <- sqldf("SELECT 
wsp_ftype, sum(mp_2020_mgy) as 'Total 2020 MGY', 
sum(mp_2020_mgy)/365.25 as 'Total 2020 MGD', 
round(sum(mp_2020_mgy)/2504894,2) as '2020 % of Total', 
sum(mp_2040_mgy) as 'Total 2040 MGY',  
sum(mp_2040_mgy)/365.25 as 'Total 2040 MGD', 
round(sum(mp_2040_mgy)/2943110,2) as '2040 % of Total'
      FROM not_updated_by_both
      group by wsp_ftype")

kable(not_updated,  booktabs = T,
      caption = "Not Updated",
      label = "Not Updated",
      col.names = c("System Type",
                    "2020 Demand (MGY)",
                    "2020 Demand (MGD)",
                    "2020 % of Total",
                    "2040 Demand (MGY)",
                    "2040 Demand (MGD)",
                    "2040 % of Total")) %>%
   kable_styling(latex_options = c("striped", "full_width"))
