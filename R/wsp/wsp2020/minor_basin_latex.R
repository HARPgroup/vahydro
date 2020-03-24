library("knitr")
library("kableExtra")
library("sqldf")

#---------------------INITIALIZE GLOBAL VARIABLES------------------------#
#switch between file types to save in common drive folder; html or latex

options(knitr.table.format = "html") #"html" for viewing in Rstudio Viewer pane
file_ext <- ".html" #view in R

#options(knitr.table.format = "latex") #"latex" when ready to output to Overleaf
#file_ext <- ".tex" #for easy upload to Overleaf

#Kable Styling
latexoptions <- c("striped","scale_down")
kable_col_names <- c("",
                     "System Type",
                     #"2020 Demand (MGY)",
                     #"2030 Demand (MGY)",
                     #"2040 Demand (MGY)",
                     "2020 Demand (MGD)",
                     "2030 Demand (MGD)",
                     "2040 Demand (MGD)",
                     "20 Year Percent Change")

#SQL
aggregate_select <- '
round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040,
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS pct_change'

#totals function which allows us to append column sums to table to generate in kable
totals_func <- function(z) if (is.numeric(z)) sum(z) else ''
#--------------------------------LOAD DATA-------------------------------#

# Location of source data
source <- "wsp2020.mp.all.MinorBasins_RSegs.csv"
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
#folder <- "C:/Users/maf95834/Documents/vpn_connection_down_folder/" #JM use when vpn can't connect to common drive

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
#   cat(., file = paste(folder,"kable_tables/","Top5_",huc6_name,"_kable",file_ext,sep=""))


########################### CHOOSE A MINOR BASIN ##############################

#Output all Minor Basin options
mb_options <- sqldf('SELECT DISTINCT MinorBasin_Name, MinorBasin_Code
      FROM mp_all
      ')
#change minor basin name
mb_name <- "Potomac Shenandoah"
#select minor basin code to know folder to save in
sql <- paste('SELECT MinorBasin_Code
                   From mb_options
                   WHERE MinorBasin_Name = ','\"',mb_name,'\"','
              ',sep="")
mb_abbrev <- sqldf(sql)
#Select measuring points within HUC of interest, Restict output to columns of interest
sql <- paste('SELECT  MP_hydroid,
                      MP_bundle,
                      source_type,
                      Facility_hydroid, 
                      facility_name, 
                      facility_ftype,
                      wsp_ftype,
                      system_type,
                      mp_2020_mgy,
                      mp_2030_mgy,
                      mp_2040_mgy, 
                      MinorBasin_Name, 
                      fips_code,
                      fips_name
                  FROM mp_all 
                  WHERE MinorBasin_Name = ','\"',mb_name,'\"','
                  ORDER BY mp_2020_mgy DESC', sep="")

mb_mps <- sqldf(sql)
write.csv(mb_mps, paste(folder,"kable_tables/",mb_name,"/all_mps_",mb_abbrev,".csv", sep=""))
#---------------------------------------------------------------#

#Demand by System Type 
system_sql <- paste('SELECT 
                     system_type,',
                     aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY wsp_ftype', sep="")

by_system_type <- sqldf(system_sql)
   
#calculate columns sums 
totals <- as.data.frame(lapply(by_system_type[1:4], totals_func),stringsAsFactors = F)
#calculate total percentage change
totals <- sqldf("SELECT *, 
round(((sum(MGD_2040) - sum(MGD_2020)) / sum(MGD_2020)) * 100,2) AS 'pct_change'
      FROM totals")
#append totals to table
by_system_type <- rbind(cbind(' '=' ', by_system_type),
                        cbind(' '='Total', totals))

# OUTPUT TABLE IN KABLE FORMAT
kable(by_system_type,  booktabs = T,
      caption = paste("Withdrawal Demand by System Type (excluding Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demand_system_type_no_power_",mb_abbrev,sep=""),
       col.names = kable_col_names) %>%
    kable_styling(latex_options = latexoptions) %>%
   #column_spec(1, width = "6em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demand_system_type_no_power_",mb_abbrev,"_kable",file_ext,sep=""))
 
 #---------------------------------------------------------------#
 
#Demand by System Type 
system_sql <- paste('SELECT 
                     system_type,',
                    aggregate_select,'
                     FROM mb_mps
                     GROUP BY wsp_ftype', sep="")

by_system_type <- sqldf(system_sql)
 
 #calculate columns sums 
 totals <- as.data.frame(lapply(by_system_type[1:4], totals_func),stringsAsFactors = F)
 #calculate total percentage change
 totals <- sqldf("SELECT *, 
round(((sum(MGD_2040) - sum(MGD_2020)) / sum(MGD_2020)) * 100,2) AS 'pct_change'
      FROM totals")
 #append totals to table
 by_system_type <- rbind(cbind(' '=' ', by_system_type),
                         cbind(' '='Total', totals))
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_system_type,  booktabs = T,
       caption = paste("Withdrawal Demand by System Type (including Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demand_system_type_yes_power_",mb_abbrev,sep=""),
       col.names = kable_col_names) %>%
     kable_styling(latex_options = latexoptions) %>%
    #column_spec(1, width = "6em") %>%
    #column_spec(2, width = "5em") %>%
    #column_spec(3, width = "5em") %>%
    #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demand_system_type_yes_power_",mb_abbrev,"_kable",file_ext,sep=""))

 ###############################################################

 #Demand by System Type 
 source_sql <- paste('SELECT 
                     source_type,',
                     aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY MP_bundle', sep="")
 
 by_source_type <- sqldf(source_sql)
 
 #calculate columns sums 
 totals <- as.data.frame(lapply(by_source_type[1:4], totals_func),stringsAsFactors = F)
 #calculate total percentage change
 totals <- sqldf("SELECT *, 
round(((sum(MGD_2040) - sum(MGD_2020)) / sum(MGD_2020)) * 100,2) AS 'pct_change'
      FROM totals")
 #append totals to table
 by_source_type <- rbind(cbind(' '=' ', by_source_type),
                         cbind(' '='Total', totals))
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_source_type,  booktabs = T,
       caption = paste("Withdrawal Demand by Source Type (excluding Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demand_source_type_no_power_",mb_abbrev,sep=""),
       col.names = kable_col_names) %>%
     kable_styling(latex_options = latexoptions) %>%
   #column_spec(1, width = "5em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demand_source_type_no_power_",mb_abbrev,"_kable",file_ext,sep=""))
 
#----------------------------------------------------------------#
 
 #Demand by System Type 
 source_sql <- paste('SELECT 
                     source_type,',
                     aggregate_select,'
                     FROM mb_mps
                     GROUP BY MP_bundle', sep="")
 by_source_type <- sqldf(source_sql)
 
 #calculate columns sums 
 totals <- as.data.frame(lapply(by_source_type[1:4], totals_func),stringsAsFactors = F)
 #calculate total percentage change
 totals <- sqldf("SELECT *, 
round(((sum(MGD_2040) - sum(MGD_2020)) / sum(MGD_2020)) * 100,2) AS 'pct_change'
      FROM totals")
 #append totals to table
 by_source_type <- rbind(cbind(' '=' ', by_source_type),
                         cbind(' '='Total', totals))
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_source_type,  booktabs = T,
       caption = paste("Withdrawal Demand by Source Type (including Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demand_source_type_yes_power_",mb_abbrev,sep=""),
       col.names = kable_col_names) %>%
     kable_styling(latex_options = latexoptions) %>%
   #column_spec(1, width = "5em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demand_source_type_yes_power_",mb_abbrev,"_kable",file_ext,sep=""))
 
############################################################################
 
 #Demand by System & Source Type with count
 system_source_sql <- paste('SELECT 
                     system_type, source_type,',
                            aggregate_select,'
                     FROM mb_mps
                     GROUP BY wsp_ftype, MP_bundle', sep="")
 
 system_source <- sqldf(system_source_sql)
 #calculate columns sums 
 totals <- as.data.frame(lapply(system_source[1:5], totals_func),stringsAsFactors = F)
 #calculate total percentage change
 totals <- sqldf("SELECT *, 
round(((sum(MGD_2040) - sum(MGD_2020)) / sum(MGD_2020)) * 100,2) AS 'pct_change'
      FROM totals")
 #append totals to table
 system_source <- rbind(cbind(' '=' ', system_source),
                        cbind(' '='Total', totals))
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(system_source,  booktabs = T,
       caption = paste("Withdrawal Demand by System and Source Type (including Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demand_source_type_no_power_",mb_abbrev,sep=""),
       col.names = c("",
                     "System Type",
                     "Source Type",
                     "2020 Demand (MGD)",
                     "2030 Demand (MGD)",
                     "2040 Demand (MGD)",
                     "20 Year Percent Change")) %>%
    kable_styling(latex_options = latexoptions) %>%
    #column_spec(1, width = "6em") %>%
    #column_spec(2, width = "5em") %>%
    #column_spec(3, width = "5em") %>%
    #column_spec(4, width = "4em") %>%
    cat(., file = paste(folder,"kable_tables/",mb_name,"/demand_system_source_",mb_abbrev,"_kable",file_ext,sep=""))
 
 ############################################################################
 by_county <- paste('SELECT 
                     fips_code,
                     fips_name,
                     ',aggregate_select,'
                     FROM mb_mps
                     GROUP BY fips_code
                     ORDER BY pct_change DESC', sep="")
 by_county <- sqldf(by_county)
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_county[1:6],  booktabs = T,
       caption = paste("Withdrawal Demand by Locality in ",mb_name," Minor Basin",sep=""),
       label = paste("demand_locality_",mb_abbrev,sep=""),
       col.names = c("Fips Code",
                     "Locality",
                     "2020 Demand (MGD)",
                     "2030 Demand (MGD)",
                     "2040 Demand (MGD)",
                     "20 Year Percent Change")) %>%
    kable_styling(latex_options = latexoptions) %>%
    #column_spec(1, width = "5em") %>%
    #column_spec(2, width = "5em") %>%
    #column_spec(3, width = "5em") %>%
    #column_spec(4, width = "4em") %>%
    cat(., file = paste(folder,"kable_tables/",mb_name,"/demand_locality_",mb_abbrev,"_kable",file_ext,sep=""))
############################################################################
 by_county_source_sql <- paste('SELECT 
                     fips_code,
                     fips_name,
                     source_type,
                     ',aggregate_select,'
                     FROM mb_mps
                     GROUP BY fips_code, MP_bundle
                     ORDER BY fips_code, MP_bundle DESC', sep="")
 by_county_source <- sqldf(by_county_source_sql)

 write.csv(by_county_source, paste(folder,"kable_tables/",mb_name,"/county_source_type_demand_",mb_abbrev,".csv", sep=""))
 
 kable(by_county_source[1:7],  booktabs = T,
       caption = paste("GW vs. SW Withdrawal Demand by Locality in ",mb_name," Minor Basin",sep=""),
       label = paste("demand_locality_by_source",mb_abbrev,sep=""),
       col.names = c("Fips Code",
                     "Locality",
                     "Source Type",
                     "2020 Demand (MGD)",
                     "2030 Demand (MGD)",
                     "2040 Demand (MGD)",
                     "20 Year Percent Change")) %>%
    kable_styling(latex_options = latexoptions) %>%
    #column_spec(1, width = "5em") %>%
    #column_spec(2, width = "5em") %>%
    #column_spec(3, width = "5em") %>%
    #column_spec(4, width = "4em") %>%
    cat(., file = paste(folder,"kable_tables/",mb_name,"/demand_locality_by_source_",mb_abbrev,"_kable",file_ext,sep=""))
############################################################################
#basin schedule email test to select source count for only specific facility demand (excludes county-wide estimate count but demand amount still included in total sums)
#count_with_county_estimates column = (specific + county_wide estimate) ---> shows # of MPs in each category including county-wide estimate MPs
#specific count column = only facilities with specific demand amounts ---> does NOT include county wide estimates
 
 system_specific_sql <- paste('SELECT a.system_type,  count(MP_hydroid) as "count_with_county_estimates",
            (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count",',
                       aggregate_select,'
                     FROM mb_mps a
       WHERE facility_ftype NOT LIKE "%power"
       GROUP BY a.wsp_ftype', sep="")
 
 system_specific_facility <- sqldf(system_specific_sql)
 
 #----------------------------------------------------------------#
 
 system_source_specific_sql <- paste('SELECT a.system_type, a.source_type,  count(MP_hydroid) as "count_with_county_estimates",
            (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND wsp_ftype = a.wsp_ftype
             AND MP_bundle = a.MP_bundle) AS "specific_count",',
                       aggregate_select,'
                     FROM mb_mps a
       WHERE facility_ftype NOT LIKE "%power"
       GROUP BY a.wsp_ftype, a.MP_bundle', sep="")
 
system_source_specific_facility <- sqldf(system_source_specific_sql)

#calculate columns sums 
totals <- as.data.frame(lapply(system_source_specific_facility[1:7], totals_func),stringsAsFactors = F)
#calculate total percentage change
totals <- sqldf("SELECT *, 
round(((sum(MGD_2040) - sum(MGD_2020)) / sum(MGD_2020)) * 100,2) AS 'pct_change'
      FROM totals")
#append totals to table
system_source_specific_facility <- rbind(cbind(' '=' ', system_source_specific_facility), cbind(' '='Total', totals))

# #Add footnotes to table
# #latex column superscripts
# names(system_source_specific_facility)[4] <- paste0("Total Source Count",footnote_marker_number(1))
# names(system_source_specific_facility)[5] <- paste0("Specific Source Count",footnote_marker_number(2))
# 
#html column superscripts
names(system_source_specific_facility)[4] <- "Total Source Count<sup>[1]<sup>"
names(system_source_specific_facility)[5] <- "Specific Source Count<sup>[2]<sup>"
# OUTPUT TABLE IN KABLE FORMAT
kable(system_source_specific_facility,  booktabs = T, escape = F,
      caption = paste("Withdrawal Demand by System and Source Type in ",mb_name," Minor Basin",sep=""),
      label = paste("demand_system_source_specific_count",mb_abbrev,sep=""),
      col.names = c("",
                    "System Type",
                    "Source Type",
                    names(system_source_specific_facility)[4],
                    names(system_source_specific_facility)[5],
                    "2020 Demand (MGD)",
                    "2030 Demand (MGD)",
                    "2040 Demand (MGD)",
                    "20 Year Percent Change")) %>%
   kable_styling(latex_options = latexoptions) %>%
   footnote(
      general = "Each locality has a single diffuse demand estimate for each system and source combination",
      number = c("includes diffuse demand estimates; ", "shows only demand amounts from specific facilities (no diffuse demand estimates) "),
      number_title = "Count Note: ",
      footnote_as_chunk = T) %>%
   #column_spec(1, width = "6em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demand_system_source_with_count_",mb_abbrev,"_kable",file_ext,sep=""))


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
