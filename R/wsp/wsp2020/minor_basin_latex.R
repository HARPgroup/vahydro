library("reshape2")
library("kableExtra")
library("sqldf")
library("sjmisc")
#library("beepr") #play beep sound when done running
library("assertive.base")
library("tictoc")
#--INITIALIZE GLOBAL VARIABLES------------------------

#totals function which quickly applies sum to each numeric column (skips non-numeric)
totals_func <- function(z) if (is.numeric(z)) sum(z) else ''

#function which allows us to append column sums to table to generate in kable
append_totals <- function(table_x, row_name = "Total"){
   
   #calculate columns sums 
   totals <- as.data.frame(lapply(table_x, totals_func),stringsAsFactors = F)
   #calculate total percentage change
   totals$pct_change <- round(((sum(totals$MGD_2040) - sum(totals$MGD_2020)) / sum(totals$MGD_2020)) * 100,2)
   #set total row name to given name or default to "Total"
   totals[1] <- row_name
   #append totals to table
   #table_z <- rbind(cbind(' '=' ', table_x), cbind(' '='Total', totals)) #adds extra column at front for Totals
   table_z <- rbind(table_x,totals)
   return(table_z)
} 

#----LOAD DATA-------------------------------
basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
#folder <- "C:/Users/maf95834/Documents/vpn_connection_down_folder/" #JM use when vpn can't connect to common drive

data_raw <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))
mp_all <- data_raw

#--------select MPs with no minor basin---------------------------------------
# ## select MPs with no minor basin
# null_minorbasin <- sqldf("SELECT *
#       FROM mp_all
#       WHERE MinorBasin_Name IS NULL")
# write.csv(null_minorbasin, paste(folder,"tables_maps/all_minor_basins/NA_minorbasin_mp.csv", sep=""))

######### SUMMARY TABLE #############################
summary_table_func <- function(minorbasin = "NR", file_extension = ".html"){

   
   #-------- html or latex -----
   #switch between file types to save in common drive folder; html or latex
   if (file_extension == ".html") {
      options(knitr.table.format = "html") #"html" for viewing in Rstudio Viewer pane
      file_ext <- ".html" #view in R or browser
   } else {
      options(knitr.table.format = "latex") #"latex" when ready to output to Overleaf
      file_ext <- ".tex" #for easy upload to Overleaf
   }
   
   #-------- Repeating Kable arguments -----
   #Kable Styling
   latexoptions <- c("scale_down")
   #Kable column names
   kable_col_names <- c("",
                        "System Type",
                        "2020 Demand (MGD)",
                        "2030 Demand (MGD)",
                        "2040 Demand (MGD)",
                        "20 Year Percent Change")
   #SQL
   aggregate_select <- '
round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040,
round((sum(mp_2040_mgy/365.25) - sum(mp_2020_mgy/365.25)) / sum(mp_2020_mgy/365.25), 2) AS pct_change'
   
   #    if (minorbasin == "all") {
   #    #--------All Minor Basins including power -----------------------------------------
   #    #All Minor Basins in a single table for comparison (including power generation)
   #    mb_totals_yes_power <- sqldf(paste('SELECT 
   #                   MinorBasin_Name,',
   #                                       aggregate_select,'
   #                   FROM mp_all
   #                   GROUP BY MinorBasin_Name', sep=""))
   #    
   #    # OUTPUT TABLE IN KABLE FORMAT
   #    kable(mb_totals_yes_power,  booktabs = T,
   #          caption = "All Minor Basins Withdrawal Demand (including Power Generation)",
   #          label = "mb_totals_yes_power",
   #          col.names = c("Minor Basin",kable_col_names[3:6])) %>%
   #       kable_styling(latex_options = latexoptions) %>%
   #       cat(., file = paste(folder,"tables_maps/all_minor_basins/mb_totals_yes_power_table",file_ext,sep=""))
   #    
   #    
   #    
   #    mb_totals_system_yes_power <- sqldf(paste('SELECT  
   #                   MinorBasin_Name,system_type,',
   #                                              aggregate_select,'
   #                   FROM mp_all
   #                   GROUP BY MinorBasin_Name, system_type', sep=""))
   #    
   #    # OUTPUT TABLE IN KABLE FORMAT
   #    kable(mb_totals_system_yes_power,  booktabs = T,
   #          caption = "All Minor Basins Withdrawal Demand by System (including Power Generation)",
   #          label = "mb_totals_system_yes_power",
   #          col.names = c("Minor Basin",kable_col_names[2:6])) %>%
   #       kable_styling(latex_options = latexoptions) %>%
   #       cat(., file = paste(folder,"tables_maps/all_minor_basins/mb_totals_system_yes_power_table",file_ext,sep=""))
   #    
   #    mb_totals_source_yes_power <- sqldf(paste('SELECT 
   #                   MinorBasin_Name, source_type,',
   #                                              aggregate_select,'
   #                   FROM mp_all
   #                   GROUP BY MinorBasin_Name, source_type', sep=""))
   #    
   #    # OUTPUT TABLE IN KABLE FORMAT
   #    kable(mb_totals_source_yes_power,  booktabs = T,
   #          caption = "All Minor Basins Withdrawal Demand by Source (including Power Generation)",
   #          label = "mb_totals_source_yes_power",
   #          col.names = c("Minor Basin","Source Type",kable_col_names[3:6])) %>%
   #       kable_styling(latex_options = latexoptions) %>%
   #       cat(., file = paste(folder,"tables_maps/all_minor_basins/mb_totals_source_yes_power_table",file_ext,sep=""))
   #    
   #    #--------All Minor Basins excluding power ----------------------------------------
   #    #All Minor Basins in a single table for comparison (excluding power generation)
   #    mb_totals_no_power <- sqldf(paste('SELECT 
   #                   MinorBasin_Name,',
   #                                      aggregate_select,'
   #                   FROM mp_all
   #                   WHERE facility_ftype NOT LIKE "%power"
   #                   GROUP BY MinorBasin_Name', sep=""))
   #    
   #    # OUTPUT TABLE IN KABLE FORMAT
   #    kable(mb_totals_no_power,  booktabs = T,
   #          caption = "All Minor Basins Withdrawal Demand (excluding Power Generation)",
   #          label = "mb_totals_no_power",
   #          col.names = c("Minor Basin",kable_col_names[3:6])) %>%
   #       kable_styling(latex_options = latexoptions) %>%
   #       cat(., file = paste(folder,"tables_maps/all_minor_basins/mb_totals_no_power_table",file_ext,sep=""))
   #    
   #    mb_totals_system_no_power <- sqldf(paste('SELECT  
   #                   MinorBasin_Name,system_type,',
   #                                             aggregate_select,'
   #                   FROM mp_all
   #                   WHERE facility_ftype NOT LIKE "%power"
   #                   GROUP BY MinorBasin_Name, system_type', sep=""))
   #    
   #    # OUTPUT TABLE IN KABLE FORMAT
   #    kable(mb_totals_system_no_power,  booktabs = T,
   #          caption = "All Minor Basins Withdrawal Demand by System (excluding Power Generation)",
   #          label = "mb_totals_system_no_power",
   #          col.names = c("Minor Basin",kable_col_names[2:6])) %>%
   #       kable_styling(latex_options = latexoptions) %>%
   #       cat(., file = paste(folder,"tables_maps/all_minor_basins/mb_totals_system_no_power_table",file_ext,sep=""))
   #    
   #    mb_totals_source_no_power <- sqldf(paste('SELECT 
   #                   MinorBasin_Name, source_type,',
   #                                             aggregate_select,'
   #                   FROM mp_all
   #                   WHERE facility_ftype NOT LIKE "%power"
   #                   GROUP BY MinorBasin_Name, source_type', sep=""))
   #    
   #    # OUTPUT TABLE IN KABLE FORMAT
   #    kable(mb_totals_source_no_power,  booktabs = T,
   #          caption = "All Minor Basins Withdrawal Demand by Source (excluding Power Generation)",
   #          label = "mb_totals_source_no_power",
   #          col.names = c("Minor Basin","Source Type",kable_col_names[3:6])) %>%
   #       kable_styling(latex_options = latexoptions) %>%
   #       cat(., file = paste(folder,"tables_maps/all_minor_basins/mb_totals_source_no_power_table",file_ext,sep=""))
   #    
   # } else if (sjmisc::str_contains(unique(mp_all$MinorBasin_Code),minorbasin) == F) {
   #    #print message if a wrong minor basin is typed in
   #    stop("Minor Basin Code incorrectly written. Please choose from:\n", print_and_capture(sqldf('SELECT distinct MinorBasin_Name, MinorBasin_Code FROM mp_all ORDER BY MinorBasin_Code')))
   #    
   # } 

   #------CHOOSE A MINOR BASIN ##############################
   
   #select minor basin code to know folder to save in
   mb_code <- minorbasin
   mb_name <- sqldf(paste('SELECT distinct MinorBasin_Name
                   From mp_all
                   WHERE MinorBasin_Code = ','\"',minorbasin,'\"','
              ',sep=""))
   #Select measuring points within minor basin of interest, Restrict output to columns of interest
   mb_mps <- sqldf(paste('SELECT  MP_hydroid,
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
                      fips_name,
                      corrected_latitude,
                      corrected_longitude
                  FROM mp_all 
                  WHERE MinorBasin_Code = ','\"',minorbasin,'\"','
                  ORDER BY mp_2020_mgy DESC', sep=""))
   
   write.csv(mb_mps, paste(folder,"tables_maps/Xtables/",mb_code,"_mp_all",".csv", sep=""), row.names = F)
   
   #### START SUMMARY TABLE GEN ####
   #--- NO POWER ----
# when no power is detected in facility ftype column, then title of Summary table will not specify (including/excluding power generation) 
if (str_contains(mb_mps$facility_ftype, "power") == FALSE) {
   
   sql_A <- sqldf(paste('SELECT " " AS source_type, system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "intake"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   sql_A[nrow(sql_A) + 1,] <- list(" ","Small Self-Supplied User",0.00,0.00,0.00,0.00)
   A <- append_totals(sql_A,"Total SW")
   sql_B <- sqldf(paste('SELECT " " AS source_type, system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "well"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   B <- append_totals(sql_B,"Total GW")
   sql_C <- sqldf(paste('SELECT " " AS source_type, system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   sql_D <-  sqldf(paste('SELECT "Minor Basin Total" AS source_type, "" AS system_type, ',
                         aggregate_select,'
                     FROM mb_mps',sep=""))
   table_1 <- rbind(A,B,sql_C,sql_D)
#KABLE   
   kable(table_1,align = c('l','l','c','c','c','c'),  booktabs = T,
         caption = paste("Summary of ",mb_name$MinorBasin_Name," Minor Basin Water Demand by Source Type and System Type",sep=""),
         label = paste("summary_no_power_",mb_code,sep=""),
         col.names = c("",
                       "System Type",
                       kable_col_names[3:6])) %>%
      kable_styling(latex_options = "scale_down") %>%
      column_spec(2, width = "12em") %>%
      pack_rows("Surface Water", 1, 5, hline_before = T, hline_after = F) %>%
      pack_rows("Groundwater", 6, 10, hline_before = T, hline_after = F) %>%
      pack_rows("Total (GW + SW)", 11, 14, hline_before = T, hline_after = F,extra_latex_after = ) %>%
      #horizontal solid line depending on html or latex output
      row_spec(14, bold=F, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      row_spec(15, bold=T) %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_summary_no_power_table",file_ext,sep=""))
   
   #-------------- TOP 5 USERS (NO POWER detected) ---------------------
#SURFACE WATER
   top_sw_no <- sqldf('SELECT facility_name, system_type,
                        round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
                        round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
                        round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
                        fips_name 
               FROM mb_mps 
               WHERE MP_bundle = "intake"
                  AND facility_ftype NOT LIKE "%power"
                  AND facility_ftype NOT LIKE "wsp_plan%"
               GROUP BY Facility_hydroid')
   
   top_5_sw_no <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_sw_no
                  ORDER BY MGD_2040 DESC
                  limit 5')
   
#APPEND LETTERED INDEX TO TOP 5 Surface Water Users table   
   index <- list()
   
   for (i in 1:nrow(top_5_sw_no)) {
      
      index <- rbind(index, LETTERS[i])
      #print(index)
   }
   top_5_sw_no <- cbind(index, top_5_sw_no)
   
#APPEND TOTALS to TOP 5 Surface Water Users table   
   
   top_5_sw_no <- append_totals(top_5_sw_no, "Total SW")
   
   top_5_sw_no$pct_total_use <- round((top_5_sw_no$MGD_2040 / A$MGD_2040[5]) * 100,2)
#GROUNDWATER   
   top_gw_no <- sqldf('SELECT facility_name, system_type,
                        round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
                        round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
                        round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
                        fips_name 
               FROM mb_mps 
               WHERE MP_bundle = "well"
                  AND facility_ftype NOT LIKE "%power"
                  AND facility_ftype NOT LIKE "wsp_plan%"
               GROUP BY Facility_hydroid')
   
   top_5_gw_no <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_gw_no
                  ORDER BY MGD_2040 DESC
                  limit 5')
   
#APPEND LETTERED INDEX TO TOP 5 Surface Water Users table   
   index <- list()
   
   for (i in 1:nrow(top_5_gw_no)) {
      
      index <- rbind(index, LETTERS[i])
      #print(index)
   }
   top_5_gw_no <- cbind(index, top_5_gw_no)
   
#APPEND TOTALS to TOP 5 Surface Water Users table   
   top_5_gw_no <- append_totals(top_5_gw_no, "Total GW")
   
   top_5_gw_no$pct_total_use <- round((top_5_gw_no$MGD_2040 / B$MGD_2040[5]) * 100,2)
   
   gw_header <- data.frame("index" = 'Groundwater',
                           "facility_name" = '',
                           "system_type" = '',
                           "fips_name" = '',
                           "MGD_2020" = '',
                           "MGD_2030" ='',
                           "MGD_2040" ='',
                           "pct_change" = '',
                           "pct_total_use" = '% of Total Groundwater')
   
   top_5_no <- rbind(top_5_sw_no, gw_header, top_5_gw_no)

   # OUTPUT TABLE IN KABLE FORMAT
   kable(top_5_no,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
         caption = paste("Top 5 Users by Source Type in ",mb_name$MinorBasin_Name," Minor Basin",sep=""),
         label = paste("top_5_no_power",mb_code,sep=""),
         col.names = c("Map Index",
                       "Facility Name",
                       "System Type",
                       "Locality",
                       kable_col_names[3:6],
                       "% of Total Surface Water")) %>%
      kable_styling(latex_options = latexoptions) %>%
      column_spec(1, width = "10em") %>%
      pack_rows("Surface Water", 1, 6) %>%
      #pack_rows("Surface Water", 7, 13, label_row_css = "border-top: 1px solid", latex_gap_space = "2em", hline_after = F,hline_before = T) %>%
      #horizontal solid line depending on html or latex output
      row_spec(7, bold=T, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_top5_no_power_table",file_ext,sep=""))
   
} else {

   #when 'power' IS detected in facility ftype column, then generate 2 separate summary tables for yes/no power
   
   #YES power (including power generation)
   sql_A <- sqldf(paste('SELECT " " AS source_type, system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "intake"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   sql_A[nrow(sql_A) + 1,] <- list(" ","Small Self-Supplied User",0.00,0.00,0.00,0.00)
   AA <- append_totals(sql_A,"Total SW")
   sql_B <- sqldf(paste('SELECT " " AS source_type, system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "well"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   BB <- append_totals(sql_B,"Total GW")
   sql_C <- sqldf(paste('SELECT " " AS source_type, system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   sql_D <-  sqldf(paste('SELECT "Minor Basin Total" AS source_type, "" AS system_type, ',
                         aggregate_select,'
                     FROM mb_mps',sep=""))
   table_1 <- rbind(AA,BB,sql_C,sql_D)
#KABLE   
   kable(table_1,align = c('l','l','c','c','c','c'),  booktabs = T,
         caption = paste("Summary of ",mb_name$MinorBasin_Name," Minor Basin Water Demand by Source Type and System Type (including Power Generation)",sep=""),
         label = paste("summary_yes_power_",mb_code,sep=""),
         col.names = c("",
                       "System Type",
                       kable_col_names[3:6])) %>%
      kable_styling(latex_options = "scale_down") %>%
      column_spec(2, width = "12em") %>%
      pack_rows("Surface Water", 1, 5, hline_before = T, hline_after = F) %>%
      pack_rows("Groundwater", 6, 10, hline_before = T, hline_after = F) %>%
      pack_rows("Total (GW + SW)", 11, 14, hline_before = T, hline_after = F,extra_latex_after = ) %>%
      #horizontal solid line depending on html or latex output
      row_spec(14, bold=F, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      row_spec(15, bold=T) %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_summary_yes_power_table",file_ext,sep=""))
   
   #------------------------------------------------------------------------
   #NO power (excluding power generation)
   sql_A <- sqldf(paste('SELECT " " AS source_type, system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "intake"
                     AND facility_ftype NOT LIKE "%power"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   sql_A[nrow(sql_A) + 1,] <- list(" ","Small Self-Supplied User",0.00,0.00,0.00,0.00)
   A <- append_totals(sql_A,"Total SW")
   sql_B <- sqldf(paste('SELECT " " AS source_type, system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "well"
                     AND facility_ftype NOT LIKE "%power"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   B <- append_totals(sql_B,"Total GW")
   sql_C <- sqldf(paste('SELECT " " AS source_type, system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   sql_D <-  sqldf(paste('SELECT "Minor Basin Total" AS source_type, "" AS system_type, ',
                         aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"',sep=""))
   table_1 <- rbind(A,B,sql_C,sql_D)
   #KABLE   
   kable(table_1,align = c('l','l','c','c','c','c'),  booktabs = T,
         caption = paste("Summary of ",mb_name$MinorBasin_Name," Minor Basin Water Demand by Source Type and System Type (excluding Power Generation)",sep=""),
         label = paste("summary_no_power_",mb_code,sep=""),
         col.names = c("",
                       "System Type",
                       kable_col_names[3:6])) %>%
      kable_styling(latex_options = "scale_down") %>%
      column_spec(2, width = "12em") %>%
      pack_rows("Surface Water", 1, 5, hline_before = T, hline_after = F) %>%
      pack_rows("Groundwater", 6, 10, hline_before = T, hline_after = F) %>%
      pack_rows("Total (GW + SW)", 11, 14, hline_before = T, hline_after = F,extra_latex_after = ) %>%
      #horizontal solid line depending on html or latex output
      row_spec(14, bold=F, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      row_spec(15, bold=T) %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_summary_no_power_table",file_ext,sep=""))
   
   ######## TOP 5 USERS Table ###############################################################
   #NOTE: these are sums of each source type by facility (aka the #1 groundwater user may have 4 wells that add up to a huge amount, it's not a table showing simply the largest MP withdrawal by source)
   
   #-------------- TOP 5 USERS INCLUDING POWER GENERATION (YES POWER) ---------------------
   top_sw <- sqldf('SELECT facility_name, system_type,
                        round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
                        round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
                        round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
                        fips_name 
               FROM mb_mps 
               WHERE MP_bundle = "intake"
                  AND facility_ftype NOT LIKE "wsp_plan%"
               GROUP BY Facility_hydroid')
   
   top_5_sw <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_sw
                  ORDER BY MGD_2040 DESC
                  limit 5')
   
   #APPEND LETTERED INDEX TO TOP 5 Surface Water Users table   
   index <- list()
   
   for (i in 1:nrow(top_5_sw)) {
      
      index <- rbind(index, LETTERS[i])
      #print(index)
   }
   top_5_sw <- cbind(index, top_5_sw)
   
   #APPEND TOTALS to TOP 5 Surface Water Users table 
   top_5_sw <- append_totals(top_5_sw, "Total SW")
   
   #need to select the AA for the YES power (including)
   top_5_sw$pct_total_use <- round((top_5_sw$MGD_2040 / AA$MGD_2040[5]) * 100,2)
   
   top_gw <- sqldf('SELECT facility_name, system_type,
                        round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
                        round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
                        round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
                        fips_name 
               FROM mb_mps 
               WHERE MP_bundle = "well"
                  AND facility_ftype NOT LIKE "wsp_plan%"
               GROUP BY Facility_hydroid')
   
   top_5_gw <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_gw
                  ORDER BY MGD_2040 DESC
                  limit 5')
   
   #APPEND LETTERED INDEX TO TOP 5 Groundwater Users table   
   index <- list()
   
   for (i in 1:nrow(top_5_gw)) {
      
      index <- rbind(index, LETTERS[i])
      #print(index)
   }
   top_5_gw <- cbind(index, top_5_gw)
   
   #APPEND TOTALS to TOP 5 Groundwater Users table 
   top_5_gw <- append_totals(top_5_gw, "Total GW")
   
   #need to select the BB for the YES power (including)
   top_5_gw$pct_total_use <- round((top_5_gw$MGD_2040 / BB$MGD_2040[5]) * 100,2)
   
   gw_header <- data.frame("index" = 'Groundwater',
                           "facility_name" = '',
                           "system_type" = '',
                           "fips_name" = '',
                           "MGD_2020" = '',
                           "MGD_2030" ='',
                           "MGD_2040" ='',
                           "pct_change" = '',
                           "pct_total_use" = '% of Total Groundwater')
   
   top_5 <- rbind(top_5_sw, gw_header, top_5_gw)

   # OUTPUT TABLE IN KABLE FORMAT
   kable(top_5,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
         caption = paste("Top 5 Users by Source Type in ",mb_name$MinorBasin_Name," Minor Basin (including Power Generation)",sep=""),
         label = paste("top_5_yes_power",mb_code,sep=""),
         col.names = c("Map Index",
                       "Facility Name",
                       "System Type",
                       "Locality",
                       kable_col_names[3:6],
                       "% of Total Surface Water")) %>%
      kable_styling(latex_options = latexoptions) %>%
      column_spec(1, width = "3em") %>%
      column_spec(2, width = "10em") %>%
      pack_rows("Surface Water", 1, 6) %>%
      #pack_rows("Surface Water", 7, 13, label_row_css = "border-top: 1px solid", latex_gap_space = "2em", hline_after = F,hline_before = T) %>%
      #horizontal solid line depending on html or latex output
      row_spec(7, bold=T, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_top5_yes_power_table",file_ext,sep=""))
   
   #-------------- TOP 5 USERS EXCLUDING POWER GENERATION (NO POWER) ---------------------
   top_sw_no <- sqldf('SELECT facility_name, system_type,
                        round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
                        round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
                        round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
                        fips_name 
               FROM mb_mps 
               WHERE MP_bundle = "intake"
                  AND facility_ftype NOT LIKE "%power"
                  AND facility_ftype NOT LIKE "wsp_plan%"
               GROUP BY Facility_hydroid')
   
   top_5_sw_no <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_sw_no
                  ORDER BY MGD_2040 DESC
                  limit 5')
   
   #APPEND LETTERED INDEX TO TOP 5 Surface Water Users table   
   index <- list()
   
   for (i in 1:nrow(top_5_sw_no)) {
      
      index <- rbind(index, LETTERS[i])
      #print(index)
   }
   top_5_sw_no <- cbind(index, top_5_sw_no)
   
   #APPEND TOTALS to TOP 5 Groundwater Users table 
   top_5_sw_no <- append_totals(top_5_sw_no, "Total SW")
   
   top_5_sw_no$pct_total_use <- round((top_5_sw_no$MGD_2040 / A$MGD_2040[5]) * 100,2)
   
   top_gw_no <- sqldf('SELECT facility_name, system_type,
                        round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
                        round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
                        round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
                        fips_name 
               FROM mb_mps 
               WHERE MP_bundle = "well"
                  AND facility_ftype NOT LIKE "%power"
                  AND facility_ftype NOT LIKE "wsp_plan%"
               GROUP BY Facility_hydroid')
   
   top_5_gw_no <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_gw_no
                  ORDER BY MGD_2040 DESC
                  limit 5')
   
   #APPEND LETTERED INDEX TO TOP 5 Groundwater Users table   
   index <- list()
   
   for (i in 1:nrow(top_5_gw_no)) {
      
      index <- rbind(index, LETTERS[i])
      #print(index)
   }
   top_5_gw_no <- cbind(index, top_5_gw_no)
   
   #APPEND TOTALS to TOP 5 Groundwater Users table 
   top_5_gw_no <- append_totals(top_5_gw_no, "Total GW")
   
   top_5_gw_no$pct_total_use <- round((top_5_gw_no$MGD_2040 / B$MGD_2040[5]) * 100,2)
   
   gw_header <- data.frame("index" = 'Groundwater',
                           "facility_name" = '',
                           "system_type" = '',
                           "fips_name" = '',
                           "MGD_2020" = '',
                           "MGD_2030" ='',
                           "MGD_2040" ='',
                           "pct_change" = '',
                           "pct_total_use" = '% of Total Groundwater')
   
   top_5_no <- rbind(top_5_sw_no, gw_header, top_5_gw_no)
   
   # OUTPUT TABLE IN KABLE FORMAT
   kable(top_5_no,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
         caption = paste("Top 5 Users by Source Type in ",mb_name$MinorBasin_Name," Minor Basin (excluding Power Generation)",sep=""),
         label = paste("top_5_no_power",mb_code,sep=""),
         col.names = c("Map Index",
                       "Facility Name",
                       "System Type",
                       "Locality",
                       kable_col_names[3:6],
                       "% of Total Surface Water")) %>%
      kable_styling(latex_options = latexoptions) %>%
      column_spec(1, width = "10em") %>%
      pack_rows("Surface Water", 1, 6) %>%
      #pack_rows("Surface Water", 7, 13, label_row_css = "border-top: 1px solid", latex_gap_space = "2em", hline_after = F,hline_before = T) %>%
      #horizontal solid line depending on html or latex output
      row_spec(7, bold=T, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_top5_no_power_table",file_ext,sep=""))
   
}
   
}

### RUN TABLE GENERATION FUNCTION ########################
summary_table_func(minorbasin = 'PL', file_extension = '.html')

# call summary table function in for loop to iterate through basins
basins <- c('PS', 'NR', 'YP', 'TU', 'RL', 'OR', 'EL', 'ES', 'PU', 'RU', 'YM', 'JA', 'MN', 'PM', 'YL', 'BS', 'PL', 'OD', 'JU', 'JB', 'JL')
ext <- c(".html",".tex")

tic()
for (b in basins) {
   tic(paste(b,"Minor Basin"))
   print(paste("Begin",b,"Table Generation"))
   
   for (e in ext) {
      print(paste("Begin",e,"Table Generation"))
      summary_table_func(b,e) 
      print(paste(e,"Tables Complete"))
   }
  
   print(paste(b,"Minor Basin Tables Complete"))
   toc()
}
toc()



######### GRAPH - Demand by System & Source Type###########################################
system_source <- sqldf(paste('SELECT 
                     source_type,system_type,',
                            aggregate_select,'
                     FROM mb_mps
                     GROUP BY wsp_ftype, MP_bundle
                     ORDER BY source_type,system_type', sep=""))

system_source <- append_totals(system_source)

# OUTPUT TABLE IN KABLE FORMAT
kable(system_source,  booktabs = T,
      caption = paste("Withdrawal Demand by System and Source Type (including Power Generation) in ",mb_name$MinorBasin_Name," Minor Basin",sep=""),
      label = paste("demand_source_type_yes_power_",mb_code,sep=""),
      col.names = c("Source Type","System Type",kable_col_names[3:6])) %>%
   kable_styling(latex_options = latexoptions) %>%
   cat(., file = paste(folder,"tables_maps/",mb_name$MinorBasin_Name,"/demand_system_source_",mb_code,"_kable",file_ext,sep=""))
#---------BAR GRAPH V3 - with percent change line and label-------------------------------
system_source <- melt(system_source, id=c("system_type","source_type", "pct_change"))
system_source[system_source == 0] <- NA
h <- sqldf("SELECT *,
            ( select CASE
            WHEN pct_change IS NOT NULL
            THEN round(pct_change,1) || '%'
            ELSE pct_change IS NULL
            END
            FROM system_source
            WHERE variable LIKE '%2040%'
            AND system_type = a.system_type
            AND source_type = a.source_type
            AND variable = a.variable) as pct_change2
            FROM system_source as a
            ")
h$pct_change2 <-if_else(h$pct_change2 == 1, "0%",h$pct_change2)

v3 <- ggplot(h, aes(x = system_type, y = value, fill = variable, label = pct_change2)) + 
   geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
   theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), legend.position = "bottom", legend.title = element_text(size = 10)) +
   xlab(label = element_blank())  +
   labs(title = paste(mb_name$MinorBasin_Name," Minor Basin",sep=""), subtitle = "Water Withdrawal Demand by System", fill = "Demand: ") +
   facet_grid(~ source_type) +
   scale_fill_discrete(labels = c("2020","2030","2040")) +
   scale_y_continuous(name = "MGD") +
   geom_text(show.legend = F, check_overlap = F, nudge_y = 2, na.rm = T)
   
ggsave(plot = v3, path = paste(folder,"tables_maps/",mb_name$MinorBasin_Name,"/", sep=""),filename = paste("demand_system_source_",mb_code,"_graph.png",sep=""))

 ######## by_locality###########################################

 by_locality <- sqldf(paste('SELECT 
                     fips_code,
                     fips_name,
                     ',aggregate_select,'
                     FROM mb_mps
                     GROUP BY fips_code
                     ORDER BY pct_change DESC', sep=""))
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_locality[1:6],  booktabs = T,
       caption = paste("Withdrawal Demand by Locality in ",mb_name$MinorBasin_Name," Minor Basin",sep=""),
       label = paste("demand_locality_",mb_code,sep=""),
       col.names = c("Fips Code",
                     "Locality",kable_col_names[3:6])) %>%
    kable_styling(latex_options = latexoptions) %>%
    cat(., file = paste(folder,"tables_maps/",mb_name$MinorBasin_Name,"/demand_locality_",mb_code,"_kable",file_ext,sep=""))
#---------PS Powerpoint presentation cleanup #######################################
# ###PS Powerpoint presentation cleanup
#  if (mb_code$MinorBasin_Code == 'PS') {
#     hanover_mps <- sqldf("SELECT *
#                            FROM mb_mps
#                            WHERE fips_name like '%hanover'")
#     hanover_mps$fips_code <- '51171'
#     hanover_mps$fips_name <- 'Shenandoah'
#     no_hanover <- sqldf("SELECT *
#                            FROM mb_mps
#                            WHERE fips_name not like '%hanover'")
#     ps_mb_mps <- sqldf("SELECT *
#                      from hanover_mps 
#                     UNION  Select * from no_hanover
#                     ")
#     by_county_source_sql <- paste('SELECT 
#                      fips_code,
#                      fips_name,
#                      source_type,
#                      ',aggregate_select,'
#                      FROM ps_mb_mps
#                      GROUP BY fips_code, MP_bundle
#                      ORDER BY fips_code, MP_bundle DESC', sep="")
#     by_county_source <- sqldf(by_county_source_sql)
#  } else {
#   by_county_source_sql <- paste('SELECT 
#                      fips_code,
#                      fips_name,
#                      source_type,
#                      ',aggregate_select,'
#                      FROM mb_mps
#                      GROUP BY fips_code, MP_bundle
#                      ORDER BY fips_code, MP_bundle DESC', sep="")
#  by_county_source <- sqldf(by_county_source_sql)   
#     
#  }
# 
#  write.csv(by_county_source, paste(folder,"tables_maps/",mb_name$MinorBasin_Name,"/county_source_type_demand_",mb_code$MinorBasin_Code,".csv", sep=""))
#  
#  kable(by_county_source[1:7],  booktabs = T,
#        caption = paste("GW vs. SW Withdrawal Demand by Locality in ",mb_name$MinorBasin_Name," Minor Basin",sep=""),
#        label = paste("demand_locality_by_source",mb_code$MinorBasin_Code,sep=""),
#        col.names = c("Fips Code",
#                      "Locality",
#                      "Source Type",kable_col_names[3:6])) %>%
#     kable_styling(latex_options = latexoptions) %>%
#     #column_spec(1, width = "5em") %>%
#     #column_spec(2, width = "5em") %>%
#     #column_spec(3, width = "5em") %>%
#     #column_spec(4, width = "4em") %>%
#     cat(., file = paste(folder,"tables_maps/",mb_name$MinorBasin_Name,"/demand_locality_by_source_",mb_code$MinorBasin_Code,"_kable",file_ext,sep=""))
######### system_specific_facility######################################################
#basin schedule email test to select source count for only specific facility demand (excludes county-wide estimate count but demand amount still included in total sums)
#count_with_county_estimates column = (specific + county_wide estimate) ---> shows # of MPs in each category including county-wide estimate MPs
#specific count column = only facilities with specific demand amounts ---> does NOT include county wide estimates
 
 system_specific_facility <- sqldf(paste('SELECT a.system_type,  count(MP_hydroid) as "count_with_county_estimates",
            (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count",',
                       aggregate_select,'
                     FROM mb_mps a
       WHERE facility_ftype NOT LIKE "%power"
       GROUP BY a.wsp_ftype', sep=""))
 
######### system_source_specific_facility ----------------------------------------------
 
 system_source_specific_facility <- sqldf(paste('SELECT a.system_type, a.source_type,  count(MP_hydroid) as "count_with_county_estimates",
            (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND wsp_ftype = a.wsp_ftype
             AND MP_bundle = a.MP_bundle) AS "specific_count",',
                       aggregate_select,'
                     FROM mb_mps a
       WHERE facility_ftype NOT LIKE "%power"
       GROUP BY a.wsp_ftype, a.MP_bundle', sep=""))

system_source_specific_facility <- append_totals(system_source_specific_facility)

#Add footnotes to table
if (file_ext == '.tex') {
   #latex column superscripts (using latex options) 
   names(system_source_specific_facility)[4] <- paste0("Total Source Count",footnote_marker_number(1))
   names(system_source_specific_facility)[5] <- paste0("Specific Source Count",footnote_marker_number(2))
} else {
   #html column superscripts (using html options)
   names(system_source_specific_facility)[4] <- "Total Source Count<sup>[1]<sup>"
   names(system_source_specific_facility)[5] <- "Specific Source Count<sup>[2]<sup>"
}
# OUTPUT TABLE IN KABLE FORMAT
kable(system_source_specific_facility,  booktabs = T, escape = F,
      caption = paste("Withdrawal Demand by System and Source Type in ",mb_name$MinorBasin_Name," Minor Basin",sep=""),
      label = paste("demand_system_source_specific_count",mb_code,sep=""),
      col.names = c("System Type",
                    "Source Type",
                    names(system_source_specific_facility)[4],
                    names(system_source_specific_facility)[5],
                    kable_col_names[3:6])) %>%
   kable_styling(latex_options = latexoptions) %>%
   footnote(
      general = "Each locality has a single diffuse demand estimate for each system and source combination",
      number = c("includes diffuse demand estimates; ", "shows only demand amounts from specific facilities (no diffuse demand estimates) "),
      number_title = "Count Note: ",
      footnote_as_chunk = T) %>%
   cat(., file = paste(folder,"tables_maps/",mb_name$MinorBasin_Name,"/demand_system_source_with_count_",mb_code,"_kable",file_ext,sep=""))

######### Top 5 Users by Source Type ##########################################


#---------PS power point presentation table---------------------------------
#PS power point presentation table
top_5[1] <- c('Merck & Co Elkton Plant','Rockingham Co. Three Springs','Augusta Co. Service Authority','The Lycra Company','Town of Dayton','','','City of Winchester','City of Staunton WTP','City of Harrisonburg WTP','Frederick County Sanitation','Town of Front Royal WTP','')

# OUTPUT TABLE IN KABLE FORMAT
kable(top_5,align = c('l','l','c','c','c','c','c','l'),  booktabs = T,
      caption = "",
      label = paste("top_5_",mb_code,sep=""),
      col.names = c("Organization Name",
                    "System Type",
                    kable_col_names[3:6],
                    "% of Total Groundwater",
                    "Locality")) %>%
   kable_styling(latex_options = latexoptions)%>%
   column_spec(1, width = "10em") %>%
   pack_rows("Groundwater", 1, 6) %>%
   pack_rows("Surface Water", 7, 13, label_row_css = "border-top: 1px solid", latex_gap_space = "2em", hline_after = F,hline_before = T) %>%
   #horizontal solid line depending on html or latex output
   row_spec(7, bold=T, hline_after = F) %>%
   cat(., file = paste(folder,"tables_maps/",mb_name$MinorBasin_Name,"/PPT_Top_5_",mb_code,"_kable",file_ext,sep=""))