library("reshape2")
library("kableExtra")
library("sqldf")
library("sjmisc")
#library("beepr") #play beep sound when done running
library("assertive.base")
library("tictoc")
library("dplyr")
library("tidyr")
library("ggplot2")
library("cowplot")
library("stringr")
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
#folder <- "C:\\Users\\maf95834\\Documents\\wsp2020\\" #JM use when vpn can't connect to common drive

data_raw <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))
mp_all <- data_raw

unmet30_raw <- read.csv(paste(folder,"metrics_facility_unmet30_mgd.csv",sep=""))

#--------select MPs with no minor basin---------------------------------------
# ## select MPs with no minor basin
# null_minorbasin <- sqldf("SELECT *
#       FROM mp_all
#       WHERE MinorBasin_Name IS NULL")
# write.csv(null_minorbasin, paste(folder,"tables_maps/Xtables/NA_minorbasin_mp.csv", sep=""))

######### TABLE GENERATION FUNCTION #############################
TABLE_GEN_func <- function(minorbasin = "PU", file_extension = ".tex"){

   
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
round(((sum(mp_2040_mgy/365.25) - sum(mp_2020_mgy/365.25)) / sum(mp_2020_mgy/365.25))*100, 2) AS pct_change'
   
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
   #       cat(., file = paste(folder,"tables_maps/Xtables/mb_totals_yes_power_table",file_ext,sep=""))
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
   #       cat(., file = paste(folder,"tables_maps/Xtables/mb_totals_system_yes_power_table",file_ext,sep=""))
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
   #       cat(., file = paste(folder,"tables_maps/Xtables/mb_totals_source_yes_power_table",file_ext,sep=""))
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
   #       cat(., file = paste(folder,"tables_maps/Xtables/mb_totals_no_power_table",file_ext,sep=""))
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
   #       cat(., file = paste(folder,"tables_maps/Xtables/mb_totals_system_no_power_table",file_ext,sep=""))
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
   #       cat(., file = paste(folder,"tables_maps/Xtables/mb_totals_source_no_power_table",file_ext,sep=""))
   #    
   # } else if (sjmisc::str_contains(unique(mp_all$MinorBasin_Code),minorbasin) == F) {
   #    #print message if a wrong minor basin is typed in
   #    stop("Minor Basin Code incorrectly written. Please choose from:\n", print_and_capture(sqldf('SELECT distinct MinorBasin_Name, MinorBasin_Code FROM mp_all ORDER BY MinorBasin_Code')))
   #    
   # } 

   #------CHOOSE A MINOR BASIN ##############################
   
   
   #select minor basin code to know folder to save in
   mb_code <- minorbasin
   
   # change all EL minorbasin_code values to ES
   if (minorbasin == 'ES') {
      mp_all$MinorBasin_Code <- recode(mp_all$MinorBasin_Code, EL = "ES")
      mb_name <- "Eastern Shore"
      
   } else {
      mb_name <- sqldf(paste('SELECT distinct MinorBasin_Name
                   From mp_all
                   WHERE MinorBasin_Code = ','\"',minorbasin,'\"','
              ',sep=""))
      mb_name <- as.character(levels(mb_name$MinorBasin_Name)[mb_name$MinorBasin_Name])
      
   }
  
   #switch around the minor basin names to more human readable labels
   mb_name <- case_when(
      mb_name == "James Bay" ~ "Lower James",
      mb_name == "James Lower" ~ "Middle James",
      mb_name == "James Upper" ~ "Upper James",
      mb_name == "Potomac Lower" ~ "Lower Potomac",
      mb_name == "Potomac Middle" ~ "Middle Potomac",
      mb_name == "Potomac Upper" ~ "Upper Potomac",
      mb_name == "Rappahannock Lower" ~ "Lower Rappahannock",
      mb_name == "Rappahannock Upper" ~ "Upper Rappahannock",
      mb_name == "Tennessee Upper" ~ "Upper Tennessee",
      mb_name == "York Lower" ~ "Lower York",
      mb_name == "Eastern Shore Atlantic" ~ "Eastern Shore",
      mb_name == mb_name ~ mb_name) #this last line is the else clause to keep all other names supplied that don't need to be changed
   
   #Select measuring points within minor basin of interest, Restrict output to columns of interest
   mb_mps <- sqldf(paste('SELECT  MP_hydroid,
                      mp_name,
                      MP_bundle,
                      source_type,
                      Facility_hydroid, 
                      facility_name, 
                      facility_ftype,
                      wsp_ftype,
                      CASE
                     WHEN system_type LIKE "Large Self-Supplied User"
                     THEN "Large SSU"
                     WHEN system_type LIKE "Small Self-Supplied User"
                     THEN "Small SSU"
                     WHEN system_type LIKE "Municipal"
                     THEN "CWS"
                     ELSE system_type
                     END AS system_type,
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
   
   sql_A <- sqldf(paste('SELECT a.system_type, 
                        (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND MP_bundle = "intake"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count", ',
                        aggregate_select,'
                     FROM mb_mps a
                     WHERE a.MP_bundle = "intake"
                     GROUP BY a.system_type
                     ORDER BY a.system_type',sep=""))
   sql_A[nrow(sql_A) + 1,] <- list("Small SSU",0,0.00,0.00,0.00,0.00)
   A <- append_totals(sql_A,"Total SW")
   
   sql_B <- sqldf(paste('SELECT a.system_type,
                        (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND MP_bundle = "well"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count", ',
                        aggregate_select,'
                     FROM mb_mps a
                     WHERE a.MP_bundle = "well"
                     GROUP BY a.system_type
                     ORDER BY a.system_type',sep=""))
   B <- append_totals(sql_B,"Total GW")
   
   sql_C <- sqldf(paste('SELECT a.system_type, (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count", ',
                        aggregate_select,'
                     FROM mb_mps a
                     GROUP BY a.system_type
                     ORDER BY a.system_type',sep=""))
   
   sql_D <- append_totals(sql_C,"Minor Basin Total")
   
   # sql_D <-  sqldf(paste('SELECT "Minor Basin Total" AS system_type, ',
   #                       aggregate_select,'
   #                   FROM mb_mps a',sep=""))
   
   table_1 <- rbind(A,B,sql_D)
   table_1[is.na(table_1)] <- 0
#KABLE   
   table1_tex <- kable(table_1,align = c('l','c','c','c','c','c'),  booktabs = T,
         caption = paste("Summary of ",mb_name," Minor Basin Water Demand by Source Type and System Type",sep=""),
         label = paste("summary_no_power_",mb_code,sep=""),
         col.names = c(
                       "System Type",
                       "Source Count",
                       kable_col_names[3:6])) %>%
      kable_styling(font_size = 10) %>%
      column_spec(1, width = "11em") %>%
      column_spec(2, width = "6em") %>%
      column_spec(3, width = "6em") %>%
      column_spec(4, width = "6em") %>%
      column_spec(5, width = "6em") %>%
      column_spec(6, width = "6em") %>%
      pack_rows("Surface Water", 1, 5, hline_before = T, hline_after = F) %>%
      pack_rows("Groundwater", 6, 10, hline_before = T, hline_after = F) %>%
      pack_rows("Total (SW + GW)", 11, 14, hline_before = T, hline_after = F) %>%
      #Header row is row 0
      row_spec(0, bold=T, font_size = 11) %>%
      row_spec(5, bold=T, extra_latex_after = ) %>%
      row_spec(10, bold=T) %>%
      row_spec(14, bold=F, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      row_spec(15, bold=T) %>%
      footnote(general_title = "Note: ",
               general = "Explain", 
               symbol = "CC")
      
   #CUSTOM LATEX CHANGES
   #insert hold position header
   table1_tex <- gsub(pattern = "{table}[t]", 
                    repl    = "{table}[H]", 
                    x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\midrule", 
                      repl    = "", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\hline", 
                      repl    = "\\hline \\addlinespace[0.4em]", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\vphantom{1}", 
                      repl    = "", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\hspace{1em}T", 
                      repl    = "T", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\textbf{System Type}", 
                      repl    = "\\vspace{0.3em}\\textbf{System Type}", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "Small SSU & 0", 
                      repl    = "Small SSU & N/A", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\multicolumn{6}{l}{\\textit{Note: }}\\\\
\\multicolumn{6}{l}{Explain}\\\\
\\multicolumn{6}{l}{\\textsuperscript{*} CC}\\\\",
                      repl    = "\\addlinespace
\\multicolumn{6}{l}{ \\multirow{}{}{\\parbox{14cm}{\\textsuperscript{*} Small SSU demands are county-wide estimates of private well usage below 300,000 gallons a month. The number of private wells is not known.}}}\\\\",
                      x       = table1_tex, fixed = T )
   table1_tex %>%
   cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_summary_no_power_table",file_ext,sep=""))
   
   
#    #-------------- TOP 5 USERS (NO POWER detected) ---------------------
# #SURFACE WATER
#    top_sw_no <- sqldf('SELECT facility_name, system_type,
#                         round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
#                         round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
#                         round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
#                         fips_name 
#                FROM mb_mps 
#                WHERE MP_bundle = "intake"
#                   AND facility_ftype NOT LIKE "%power"
#                   AND facility_ftype NOT LIKE "wsp_plan%"
#                GROUP BY Facility_hydroid')
#    
#    top_5_sw_no <- sqldf('SELECT facility_name, 
#                            system_type,
#                            fips_name,
#                            MGD_2020,
#                            MGD_2030,
#                            MGD_2040,
#                            round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
#                   FROM top_sw_no
#                   ORDER BY MGD_2040 DESC
#                   limit 5')
#    
#    top_5_sw_no <- append_totals(top_5_sw_no, "Total SW")
#    
#    top_5_sw_no$pct_total_use <- round((top_5_sw_no$MGD_2040 / A$MGD_2040[5]) * 100,2)
# #GROUNDWATER   
#    top_gw_no <- sqldf('SELECT facility_name, system_type,
#                         round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
#                         round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
#                         round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
#                         fips_name 
#                FROM mb_mps 
#                WHERE MP_bundle = "well"
#                   AND facility_ftype NOT LIKE "%power"
#                   AND facility_ftype NOT LIKE "wsp_plan%"
#                GROUP BY Facility_hydroid')
#    
#    top_5_gw_no <- sqldf('SELECT facility_name, 
#                            system_type,
#                            fips_name,
#                            MGD_2020,
#                            MGD_2030,
#                            MGD_2040,
#                            round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
#                   FROM top_gw_no
#                   ORDER BY MGD_2040 DESC
#                   limit 5')
# 
# #APPEND TOTALS to TOP 5 Surface Water Users table   
#    top_5_gw_no <- append_totals(top_5_gw_no, "Total GW")
#    
#    top_5_gw_no$pct_total_use <- round((top_5_gw_no$MGD_2040 / B$MGD_2040[5]) * 100,2)
#    
#    gw_header <- data.frame("facility_name" = 'Groundwater',
#                            "system_type" = '',
#                            "fips_name" = '',
#                            "MGD_2020" = '',
#                            "MGD_2030" ='',
#                            "MGD_2040" ='',
#                            "pct_change" = '',
#                            "pct_total_use" = '% of Total Groundwater')
#    
#    top_5_no <- rbind(top_5_sw_no, gw_header, top_5_gw_no)
#    
#    top_5_no$facility_name <- str_to_title(top_5_no$facility_name)
#    top_5_no$facility_name <- gsub(x = top_5_no$facility_name, pattern = "wtp", replacement = "WTP", ignore.case = T)
#    top_5_no$facility_name <- gsub(x = top_5_no$facility_name, pattern = "Water Treatment Plant", replacement = "WTP", ignore.case = T)
#    top_5_no$facility_name <- gsub(x = top_5_no$facility_name, pattern = "Total sw", replacement = "Total SW", ignore.case = T)
#    top_5_no$facility_name <- gsub(x = top_5_no$facility_name, pattern = "Total gw", replacement = "Total GW", ignore.case = T)
#    
#    top_5_no[is.na(top_5_no)] <- "0.00"
#    top_5_no[top_5_no == 0] <- "0.00"
#    top_5_no[top_5_no == "Agriculture"] <- "AG"
#    
#    # if (nrow(top_5_sw_no) < 6) {
#    #    a <- "yes"
#    # } else {
#    #    
#    # }
#    # OUTPUT TABLE IN KABLE FORMAT
#    table5_tex <- kable(top_5_no,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
#          caption = paste("Top 5 Users in 2040 by Source Type in the ",mb_name," Minor Basin",sep=""),
#          label = paste("top_5_no_power_",mb_code,sep=""),
#          col.names = c("Facility Name",
#                        "System Type",
#                        "Locality",
#                        kable_col_names[3:6],
#                        "% of Total Surface Water")) %>%
#       kable_styling(latex_options = latexoptions) %>%
#       column_spec(1, width = "9em") %>%
#       column_spec(2, width = "3em") %>%
#       column_spec(3, width = "4em") %>%
#       column_spec(4, width = "4em") %>%
#       column_spec(5, width = "4em") %>%
#       column_spec(6, width = "4em") %>%
#       column_spec(7, width = "4em") %>%
#       column_spec(8, width = "7em") %>%
#       row_spec(0, bold=T, font_size = 9) %>%
#       pack_rows("Surface Water", 1, nrow(top_5_sw_no)) %>%
#       row_spec(nrow(top_5_sw_no), extra_latex_after = "\\hline") %>%
#       row_spec(nrow(top_5_sw_no)+1, bold=T, hline_after = F, extra_css = "border-top: 1px solid") 
#       
#    #CUSTOM LATEX CHANGES
#    #insert hold position header
#    table5_tex <- gsub(pattern = "{table}[t]", 
#                       repl    = "{table}[H]", 
#                       x       = table5_tex, fixed = T )
#    table5_tex <- gsub(pattern = "\\hspace{1em}", 
#                       repl    = "", 
#                       x       = table5_tex, fixed = T )
#    table5_tex <- gsub(pattern = "\\hline", 
#                       repl    = "\\addlinespace[0.3em] \\hline \\addlinespace[0.4em]", 
#                       x       = table5_tex, fixed = T )
#    table5_tex <- gsub(pattern = "\\textbf{Facility Name}", 
#                       repl    = "\\vspace{0.3em}\\textbf{Facility Name}", 
#                       x       = table5_tex, fixed = T )
#    table5_tex <- gsub(pattern = "\\textbf{Locality}", 
#                       repl    = "\\vspace{0.3em}\\textbf{Locality}", 
#                       x       = table5_tex, fixed = T )
#    table5_tex %>%
#       cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_top5_no_power_table",file_ext,sep=""))
#    
} else {

   ### when 'power' IS detected in facility ftype column, then generate 2 separate summary tables for yes/no power
   
   #YES power (including power generation)
   sql_A <- sqldf(paste('SELECT a.system_type,
                        (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND MP_bundle = "intake"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count",',
                        aggregate_select,'
                     FROM mb_mps a
                     WHERE a.MP_bundle = "intake"
                     GROUP BY a.system_type
                     ORDER BY a.system_type',sep=""))
   sql_A[nrow(sql_A) + 1,] <- list("Small SSU",0,0.00,0.00,0.00,0.00)
   AA <- append_totals(sql_A,"Total SW")
   
   sql_B <- sqldf(paste('SELECT a.system_type, 
                        (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND MP_bundle = "well"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count",',
                        aggregate_select,'
                     FROM mb_mps a
                     WHERE a.MP_bundle = "well"
                     GROUP BY a.system_type
                     ORDER BY a.system_type',sep=""))
   BB <- append_totals(sql_B,"Total GW")
   
   sql_C <- sqldf(paste('SELECT a.system_type, 
                        (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count",',
                        aggregate_select,'
                     FROM mb_mps a
                     GROUP BY a.system_type
                     ORDER BY a.system_type',sep=""))
   
   
   sql_D <- append_totals(sql_C,"Minor Basin Total")
   
   # sql_D <-  sqldf(paste('SELECT "Minor Basin Total" AS system_type, ',
   #                       aggregate_select,'
   #                   FROM mb_mps a',sep=""))
   
   table_1 <- rbind(AA,BB,sql_D)
   table_1[is.na(table_1)] <- 0
   
#KABLE   
   table1_tex <- kable(table_1,align = c('l','c','c','c','c','c'),  booktabs = T,
         caption = paste("Summary of ",mb_name," Minor Basin Water Demand by Source Type and System Type (including Power Generation)",sep=""),
         label = paste("summary_yes_power_",mb_code,sep=""),
         col.names = c("System Type",
                       "Source Count",
                       kable_col_names[3:6]))%>%
      kable_styling(font_size = 10) %>%
      column_spec(1, width = "11em") %>%
      column_spec(2, width = "6em") %>%
      column_spec(3, width = "6em") %>%
      column_spec(4, width = "6em") %>%
      column_spec(5, width = "6em") %>%
      column_spec(6, width = "6em") %>%
      pack_rows("Surface Water", 1, 5, hline_before = T, hline_after = F) %>%
      pack_rows("Groundwater", 6, 10, hline_before = T, hline_after = F) %>%
      pack_rows("Total (SW + GW)", 11, 14, hline_before = T, hline_after = F) %>%
      #Header row is row 0
      row_spec(0, bold=T, font_size = 11) %>%
      row_spec(5, bold=T, extra_latex_after = ) %>%
      row_spec(10, bold=T) %>%
      row_spec(14, bold=F, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      row_spec(15, bold=T) %>%
   footnote(general_title = "Note: ",
            general = "Explain", 
            symbol = "CC")
   
   #CUSTOM LATEX CHANGES
   #insert hold position header
   table1_tex <- gsub(pattern = "{table}[t]", 
                      repl    = "{table}[H]", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\midrule", 
                      repl    = "", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\hline", 
                      repl    = "\\hline \\addlinespace[0.4em]", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\vphantom{1}", 
                      repl    = "", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\hspace{1em}T", 
                      repl    = "T", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\textbf{System Type}", 
                      repl    = "\\vspace{0.3em}\\textbf{System Type}", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "Small SSU & 0", 
                      repl    = "Small SSU & N/A", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\multicolumn{6}{l}{\\textit{Note: }}\\\\
\\multicolumn{6}{l}{Explain}\\\\
\\multicolumn{6}{l}{\\textsuperscript{*} CC}\\\\",
                     repl    = "\\addlinespace
\\multicolumn{6}{l}{ \\multirow{}{}{\\parbox{14cm}{\\textsuperscript{*} Small SSU demands are county-wide estimates of private well usage below 300,000 gallons a month. The number of private wells is not known.}}}\\\\",
                     x       = table1_tex, fixed = T )
   table1_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_summary_yes_power_table",file_ext,sep=""))
   
   #------------------------------------------------------------------------
   #NO power (excluding power generation)
   sql_A <- sqldf(paste('SELECT a.system_type, 
                        (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND MP_bundle = "intake"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count", ',
                        aggregate_select,'
                     FROM mb_mps a
                     WHERE a.MP_bundle = "intake"
                     AND facility_ftype NOT LIKE "%power"
                     GROUP BY a.system_type
                     ORDER BY a.system_type',sep=""))
   sql_A[nrow(sql_A) + 1,] <- list("Small SSU",0,0.00,0.00,0.00,0.00)
   A <- append_totals(sql_A,"Total SW")
   
   sql_B <- sqldf(paste('SELECT a.system_type,
                        (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND MP_bundle = "well"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count", ',
                        aggregate_select,'
                     FROM mb_mps a
                     WHERE a.MP_bundle = "well"
                     AND facility_ftype NOT LIKE "%power"
                     GROUP BY a.system_type
                     ORDER BY a.system_type',sep=""))
   B <- append_totals(sql_B,"Total GW")
   
   sql_C <- sqldf(paste('SELECT a.system_type, (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count", ',
                        aggregate_select,'
                     FROM mb_mps a
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY a.system_type
                     ORDER BY a.system_type',sep=""))
   
   sql_D <- append_totals(sql_C,"Minor Basin Total")
   
   # sql_D <-  sqldf(paste('SELECT "Minor Basin Total" AS system_type, ',
   #                       aggregate_select,'
   #                   FROM mb_mps a',sep=""))
   
   table_1 <- rbind(A,B,sql_D)
   table_1[is.na(table_1)] <- 0
   
   #KABLE   
   table1_tex <- kable(table_1,align = c('l','c','c','c','c','c'),  booktabs = T,
         caption = paste("Summary of ",mb_name," Minor Basin Water Demand by Source Type and System Type (excluding Power Generation)",sep=""),
         label = paste("summary_no_power_",mb_code,sep=""),
         col.names = c("System Type",
                       "Source Count",
                       kable_col_names[3:6]))%>%
      kable_styling(font_size = 10) %>%
      column_spec(1, width = "11em") %>%
      column_spec(2, width = "6em") %>%
      column_spec(3, width = "6em") %>%
      column_spec(4, width = "6em") %>%
      column_spec(5, width = "6em") %>%
      column_spec(6, width = "6em") %>%
      pack_rows("Surface Water", 1, 5, hline_before = T, hline_after = F) %>%
      pack_rows("Groundwater", 6, 10, hline_before = T, hline_after = F) %>%
      pack_rows("Total (SW + GW)", 11, 14, hline_before = T, hline_after = F) %>%
      #Header row is row 0
      row_spec(0, bold=T, font_size = 11) %>%
      row_spec(5, bold=T, extra_latex_after = ) %>%
      row_spec(10, bold=T) %>%
      row_spec(14, bold=F, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      row_spec(15, bold=T) %>%
      footnote(general_title = "Note: ",
               general = "Explain", 
               symbol = "CC")
   
   #CUSTOM LATEX CHANGES
   #insert hold position header
   table1_tex <- gsub(pattern = "{table}[t]", 
                      repl    = "{table}[H]", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\midrule", 
                      repl    = "", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\hline", 
                      repl    = "\\hline \\addlinespace[0.4em]", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\vphantom{1}", 
                      repl    = "", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\hspace{1em}T", 
                      repl    = "T", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\textbf{System Type}", 
                      repl    = "\\vspace{0.3em}\\textbf{System Type}", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "Small SSU & 0", 
                      repl    = "Small SSU & N/A", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\multicolumn{6}{l}{\\textit{Note: }}\\\\
\\multicolumn{6}{l}{Explain}\\\\
\\multicolumn{6}{l}{\\textsuperscript{*} CC}\\\\",
                      repl    = "\\addlinespace
\\multicolumn{6}{l}{ \\multirow{}{}{\\parbox{14cm}{\\textsuperscript{*} Small SSU demands are county-wide estimates of private well usage below 300,000 gallons a month. The number of private wells is not known.}}}\\\\",
                      x       = table1_tex, fixed = T )
   table1_tex %>%
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
   
   #APPEND TOTALS to TOP 5 Groundwater Users table 
   top_5_gw <- append_totals(top_5_gw, "Total GW")
   
   #need to select the BB for the YES power (including)
   top_5_gw$pct_total_use <- round((top_5_gw$MGD_2040 / BB$MGD_2040[5]) * 100,2)
   
   gw_header <- data.frame("facility_name" = 'Groundwater',
                           "system_type" = '',
                           "fips_name" = '',
                           "MGD_2020" = '',
                           "MGD_2030" ='',
                           "MGD_2040" ='',
                           "pct_change" = '',
                           "pct_total_use" = '% of Total Groundwater')
   
   top_5 <- rbind(top_5_sw, gw_header, top_5_gw)
   
   top_5$facility_name <- str_to_title(top_5$facility_name)
   top_5$facility_name <- gsub(x = top_5$facility_name, pattern = "wtp", replacement = "WTP", ignore.case = T)
   top_5$facility_name <- gsub(x = top_5$facility_name, pattern = "Water Treatment Plant", replacement = "WTP", ignore.case = T)
   top_5$facility_name <- gsub(x = top_5$facility_name, pattern = "Total sw", replacement = "Total SW", ignore.case = T)
   top_5$facility_name <- gsub(x = top_5$facility_name, pattern = "Total gw", replacement = "Total GW", ignore.case = T)
   
   top_5[is.na(top_5)] <- "0.00"
   top_5[top_5 == 0] <- "0.00"
   top_5[top_5 == "Agriculture"] <- "AG"
   
   # OUTPUT TABLE IN KABLE FORMAT
   table5_tex <- kable(top_5,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
         caption = paste("Top 5 Users in 2040 by Source Type in the ",mb_name," Minor Basin (including Power Generation)",sep=""),
         label = paste("top_5_yes_power",mb_code,sep=""),
         col.names = c("Facility Name",
                       "System Type",
                       "Locality",
                       kable_col_names[3:6],
                       "% of Total Surface Water")) %>%
      kable_styling(latex_options = latexoptions) %>%
      column_spec(1, width = "9em") %>%
      column_spec(2, width = "3em") %>%
      column_spec(3, width = "4em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      column_spec(6, width = "4em") %>%
      column_spec(7, width = "4em") %>%
      column_spec(8, width = "7em") %>%
      row_spec(0, bold=T, font_size = 9) %>%
      pack_rows("Surface Water", 1, 6) %>%
      row_spec(6, extra_latex_after = "\\hline") %>%
      row_spec(7, bold=T, hline_after = F, extra_css = "border-top: 1px solid") 
   
   #CUSTOM LATEX CHANGES
   #insert hold position header
   table5_tex <- gsub(pattern = "{table}[t]", 
                      repl    = "{table}[H]", 
                      x       = table5_tex, fixed = T )
   table5_tex <- gsub(pattern = "\\hspace{1em}", 
                      repl    = "", 
                      x       = table5_tex, fixed = T )
   table5_tex <- gsub(pattern = "\\hline", 
                      repl    = "\\addlinespace[0.3em] \\hline \\addlinespace[0.4em]", 
                      x       = table5_tex, fixed = T )
   table5_tex <- gsub(pattern = "\\textbf{Facility Name}", 
                      repl    = "\\vspace{0.3em}\\textbf{Facility Name}", 
                      x       = table5_tex, fixed = T )
   table5_tex <- gsub(pattern = "\\textbf{Locality}", 
                      repl    = "\\vspace{0.3em}\\textbf{Locality}", 
                      x       = table5_tex, fixed = T )
   table5_tex %>%
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
   
   #APPEND TOTALS to TOP 5 Groundwater Users table 
   top_5_gw_no <- append_totals(top_5_gw_no, "Total GW")
   
   top_5_gw_no$pct_total_use <- round((top_5_gw_no$MGD_2040 / B$MGD_2040[5]) * 100,2)
   
   gw_header <- data.frame("facility_name" = 'Groundwater',
                           "system_type" = '',
                           "fips_name" = '',
                           "MGD_2020" = '',
                           "MGD_2030" ='',
                           "MGD_2040" ='',
                           "pct_change" = '',
                           "pct_total_use" = '% of Total Groundwater')
   
   top_5_no <- rbind(top_5_sw_no, gw_header, top_5_gw_no)
   
   top_5_no$facility_name <- str_to_title(top_5_no$facility_name)
   top_5_no$facility_name <- gsub(x = top_5_no$facility_name, pattern = "wtp", replacement = "WTP", ignore.case = T)
   top_5_no$facility_name <- gsub(x = top_5_no$facility_name, pattern = "Water Treatment Plant", replacement = "WTP", ignore.case = T)
   top_5_no$facility_name <- gsub(x = top_5_no$facility_name, pattern = "Total sw", replacement = "Total SW", ignore.case = T)
   top_5_no$facility_name <- gsub(x = top_5_no$facility_name, pattern = "Total gw", replacement = "Total GW", ignore.case = T)
   
   top_5_no[is.na(top_5_no)] <- "0.00"
   top_5_no[top_5_no == 0] <- "0.00"
   top_5_no[top_5_no == "Agriculture"] <- "AG"
   
   # OUTPUT TABLE IN KABLE FORMAT
   table5_tex <- kable(top_5_no,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
         caption = paste("Top 5 Users in 2040 by Source Type in the ",mb_name," Minor Basin (excluding Power Generation)",sep=""),
         label = paste("top_5_no_power",mb_code,sep=""),
         col.names = c("Facility Name",
                       "System Type",
                       "Locality",
                       kable_col_names[3:6],
                       "% of Total Surface Water")) %>%
      kable_styling(latex_options = latexoptions) %>%
      column_spec(1, width = "9em") %>%
      column_spec(2, width = "3em") %>%
      column_spec(3, width = "4em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      column_spec(6, width = "4em") %>%
      column_spec(7, width = "4em") %>%
      column_spec(8, width = "7em") %>%
      row_spec(0, bold=T, font_size = 9) %>%
      pack_rows("Surface Water", 1, 6) %>%
      row_spec(6, extra_latex_after = "\\hline") %>%
      row_spec(7, bold=T, hline_after = F, extra_css = "border-top: 1px solid") 
   
   #CUSTOM LATEX CHANGES
   #insert hold position header
   table5_tex <- gsub(pattern = "{table}[t]", 
                      repl    = "{table}[H]", 
                      x       = table5_tex, fixed = T )
   table5_tex <- gsub(pattern = "\\hspace{1em}", 
                      repl    = "", 
                      x       = table5_tex, fixed = T )
   table5_tex <- gsub(pattern = "\\hline", 
                      repl    = "\\addlinespace[0.3em] \\hline \\addlinespace[0.4em]", 
                      x       = table5_tex, fixed = T )
   table5_tex <- gsub(pattern = "\\textbf{Facility Name}", 
                      repl    = "\\vspace{0.3em}\\textbf{Facility Name}", 
                      x       = table5_tex, fixed = T )
   table5_tex <- gsub(pattern = "\\textbf{Locality}", 
                      repl    = "\\vspace{0.3em}\\textbf{Locality}", 
                      x       = table5_tex, fixed = T )
   table5_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_top5_no_power_table",file_ext,sep=""))
   
}

   #---- UNMET/CONSTRAINED DEMAND TABLE --------------------------------------------------------------
   unmet30 <- sqldf('SELECT pid,
                           featureid,
                           CASE
                           WHEN propname LIKE "Manassas WTP & Service Area:T. Nelson Elliott Dam"
                           THEN "Manassas WTP & Service Area (Reservoir)"
                           ELSE propname
                           END AS propname,
                           round(runid_11,2) AS runid_11,
                           round(runid_12,2) AS runid_12,
                           round(runid_13,2) AS runid_13,
                           round(runid_17,2) AS runid_17,
                           round(runid_18,2) AS runid_18,
                           riverseg,
                           substr(riverseg,1,2) AS mb_code
                 from unmet30_raw
                 WHERE hydrocode NOT LIKE "wsp_%"
                 AND riverseg NOT LIKE "%_0000%"
                 AND pid != 5685622
                 ORDER BY mb_code DESC, runid_18 DESC')
   
   
   unmet30$mb_code <- recode(unmet30$mb_code, EL = "ES")
   unmet30$runid_17[is.na(unmet30$runid_17)] <- "-"

   #filter the 5 runids
   a_unmet30 <- sqldf('SELECT featureid,
                           propname,
                           runid_11,
                           runid_12,
                           runid_13,
                           runid_17,
                           runid_18,
                           mb_code
                 FROM unmet30
                      WHERE (runid_11 > 0.0099
                       OR runid_12 > 0.0099
                       OR runid_13 > 0.0099
                       OR runid_17 > 0.0099
                       OR runid_18 > 0.0099)')

   #write.csv(a_unmet30, file = "C:\\Users\\maf95834\\Documents\\R\\a_unmet30.csv", row.names = F)

   # # No Minor Basin
   # 
   # null_unmet30 <- sqldf('SELECT pid,
   #                            featureid,
   #                            propname,
   #                            runid_11,
   #                            runid_12,
   #                            runid_13,
   #                            runid_17,
   #                            runid_18,
   #                            mb_code
   #                  FROM unmet30
   #       WHERE riverseg LIKE ""
   #       ORDER BY runid_18 DESC')
   # 
   # write.csv(null_unmet30, file = "C:\\Users\\maf95834\\Documents\\R\\null_unmet30.csv", row.names = F)

   #------------------------------------------------------------------------------------------------------------

   unmet_table <- sqldf(paste('SELECT *
                             FROM a_unmet30
                             WHERE mb_code = "',mb_code,'"', sep = ''))

   unmet_table$propname <- str_to_title(gsub(x = unmet_table$propname, pattern = ":.*$", replacement = ""))

   unmet_table$propname <- gsub(x = unmet_table$propname, pattern = "wtp", replacement = "WTP", ignore.case = T)
   unmet_table$propname <- gsub(x = unmet_table$propname, pattern = "Water Treatment Plant", replacement = "WTP", ignore.case = T)

   if (nrow(unmet_table) == 0) {
      unmet_table[1,2] <- "No Facilities Detected"
      #unmet_table[1,2] <- "\\multicolumn{6}{c}{\\textbf{No facilities detected to have unmet demand}}\\\\"
   } else {
      unmet_table[unmet_table == 0] <- "0.00"
   }
   
   # OUTPUT TABLE IN KABLE FORMAT
   unmet_tex <- kable(unmet_table[2:7],align = c('l','c','c','c','c','c'),  booktabs = T,
         caption = paste("Change in Highest 30 Day Potential Unmet Demand (MGD) in ",mb_name," Minor Basin",sep=""),
         label = paste("unmet30_",mb_code,sep=""),
         col.names = c("Facility",
                       "2020 Demand",
                       "2030 Demand",
                       "2040 Demand",
                       "Dry Climate",
                       "Exempt User")) %>%
      kable_styling(latex_options = c("scale_down","striped")) %>%
      row_spec(0, bold = T) %>%
      column_spec(1, width = "11em") %>%
      column_spec(2, width = "5em") %>%
      column_spec(3, width = "5em") %>%
      column_spec(4, width = "5em") %>%
      column_spec(5, width = "4em") %>%
      column_spec(6, width = "3em") %>%
      #footnote(symbol = "This table shows demand values greater than 1.0 MGD.") %>%
      #footnote(c("Footnote Symbol 1; Climate scenarios were not completed in areas located outside of the Chesapeake Bay Basin", "Footnote Symbol 2")) %>%
      footnote(general_title = "Note: ",
               general = "Explain", 
               symbol = "CC")

   unmet_tex <- gsub(pattern = "{table}[t]",
                     repl    = "{table}[H]",
                     x       = unmet_tex, fixed = T )
   unmet_tex <- gsub(pattern = "\\multicolumn{6}{l}{\\textit{Note: }}\\\\
\\multicolumn{6}{l}{Explain}\\\\
\\multicolumn{6}{l}{\\textsuperscript{*} CC}\\\\",
                     repl    = "\\addlinespace \\multicolumn{6}{l}{\\textsuperscript{*} Climate scenarios were not completed in areas located outside of the Chesapeake Bay Basin}\\\\ \\addlinespace 
\\multicolumn{6}{l}{ \\multirow{}{}{\\parbox{14cm}{\\textit{Note:} Potential unmet demand is the portion of surface water demand for a specific facility that is limited by available streamflow as simulated in a given model scenario, including any known operational limits such as flow-by requirements. This unmet demand, if realized, could be managed through water conservation, alternative sources, operational changes, or from available storage.}}}\\\\",
                     x       = unmet_tex, fixed = T )

      unmet_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_unmet30_table",file_ext,sep=""))

   
}

### RUN TABLE GENERATION FUNCTION ########################
TABLE_GEN_func(minorbasin = 'PU', file_extension = '.tex')

# call summary table function in for loop to iterate through basins
basins <- c('PS', 'NR', 'YP', 'TU', 'RL', 'OR', 'ES', 'PU', 'RU', 'YM', 'JA', 'MN', 'PM', 'YL', 'BS', 'PL', 'OD', 'JU', 'JB', 'JL')

ext <- c(".html",".tex")
ext <- c(".tex")

tic()
for (b in basins) {
   tic(paste(b,"Minor Basin"))
   print(paste("Begin",b,"Table Generation"))
   
   for (e in ext) {
      print(paste("Begin",e,"Table Generation"))
      TABLE_GEN_func(b,e) 
      print(paste(e,"Tables Complete"))
   }
  
   print(paste(b,"Minor Basin Tables Complete"))
   toc()
}
toc()

