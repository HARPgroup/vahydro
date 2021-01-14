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

options(scipen = 999999999)
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

#LOAD DEMAND FILE 
data_raw <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))
mp_all <- data_raw

#LOAD VA POPULATION FILE
vapop <- read.csv("U:\\OWS\\foundation_datasets\\wsp\\Population Data\\VAPopProjections_Total_2020-2040_final.csv")

#LOAD PREVIOUS YEAR'S ANNUAL REPORT PERMITTED FILE
GWP <- read.csv("U:\\OWS\\foundation_datasets\\wsp\\wsp2020\\GWP_permit_list_12-09-2020.csv")

VWP <- read.csv("U:\\OWS\\foundation_datasets\\wsp\\wsp2020\\VWP_permit_list_12-09-2020.csv")
VWP <- sqldf('SELECT *
             FROM VWP 
             WHERE "Permit.ID" NOT IN ("10-1496", "93-0506", "98-1672", "02-1007", "08-0619", "02-1835", "95-0957")')

######### TABLE GENERATION FUNCTION #############################
TABLE_GEN_func <- function(state_abbrev = "VA", file_extension = ".tex"){
  
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
  
  if (state_abbrev == "VA") {
    mb_code <- state_abbrev
    mb_name <- "Virginia"
    mb_name$MinorBasin_Name <- "Statewide"
    #Select measuring points within minor basin of interest, Restrict output to columns of interest
    mb_mps <- sqldf('SELECT  MP_hydroid,
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
                  ORDER BY mp_2020_mgy DESC')
    
  } else {
    stop("This is the Statewide latex script. Please write correct function input == 'VA'")
  }
  #### START SUMMARY TABLE GEN ####
    #--#NO power (excluding power generation)-------------------------------------------
    
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
    
    sql_D <- append_totals(sql_C,"Virginia")
    
    # sql_D <-  sqldf(paste('SELECT "Statewide Total" AS system_type, ',
    #                       aggregate_select,'
    #                   FROM mb_mps a',sep=""))
    
    table_1 <- rbind(A,B,sql_D)
    table_1[is.na(table_1)] <- 0
    
    
    table_1_VA <- table_1[15,]
    #KABLE   
    table1_tex <- kable(table_1,align = c('l','c','c','c','c','c'),  booktabs = T,
                        caption = paste("Summary of ",mb_name[1]," Water Demand by Source Type and System Type (excluding Power Generation)",sep=""),
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
      row_spec(15, bold=T) 
    
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
    table1_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_summary_no_power_table",file_ext,sep=""))
    
    #--#YES power (including power generation) ----------------------------------------------
    
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
    
    
    sql_D <- append_totals(sql_C,"Virginia")
    
    # sql_D <-  sqldf(paste('SELECT "Statewide Total" AS system_type, ',
    #                       aggregate_select,'
    #                   FROM mb_mps a',sep=""))
    
    table_1 <- rbind(AA,BB,sql_D)
    table_1[is.na(table_1)] <- 0
    
    #KABLE   
    table1_tex <- kable(table_1,align = c('l','c','c','c','c','c'),  booktabs = T,
                        caption = paste("Summary of ",mb_name[1]," Water Demand by Source Type and System Type (including Power Generation)",sep=""),
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
      row_spec(15, bold=T) 
    
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
    table1_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_summary_yes_power_table",file_ext,sep=""))
    
    ####SUMMARY TABLE #################################################
    rownames(table_1) <- c()
    rownames(table_1_VA) <- c()
    table_1_combo <- rbind(table_1,table_1_VA)
    #KABLE   
    table1_tex <- kable(table_1_combo,align = c('l','c','c','c','c','c'),  booktabs = T,
                        caption = paste("Summary of ",mb_name[1]," Water Demand (including Power Generation)",sep=""),
                        label = paste("summary_",mb_code,sep=""),
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
      
      pack_rows("Total Including Power Generation", 15, 15, hline_before = T, hline_after = F) %>%
      
      pack_rows("Total Excluding Power Generation", 16, 16, hline_before = T, hline_after = F) %>%
      #Header row is row 0
      row_spec(0, bold=T, font_size = 11) %>%
      row_spec(5, bold=T) %>%
      row_spec(10, bold=T) %>%
      row_spec(14, bold=F, hline_after = F, extra_css = "border-bottom: 1px solid")
      #row_spec(15, bold=T) %>%
      #row_spec(16, bold=T)
    
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
    table1_tex <- gsub(pattern = "Virginia", 
                       repl    = "\\textbf{Virginia}", 
                       x       = table1_tex, fixed = T )
    table1_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_summary_table",file_ext,sep=""))
    
    ######## TOP 10 USERS Table ###############################################################
    
    #NOTE: these are sums of each source type by facility (aka the #1 groundwater user may have 4 wells that add up to a huge amount, it's not a table showing simply the largest MP withdrawal by source)
    
    #-------------- TOP 10 USERS INCLUDING POWER GENERATION (YES POWER) ---------------------
    top_sw <- sqldf('SELECT facility_name, system_type,
                        round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
                        round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
                        round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
                        fips_name 
               FROM mb_mps 
               WHERE MP_bundle = "intake"
                  AND facility_ftype NOT LIKE "wsp_plan%"
               GROUP BY Facility_hydroid')
    
    top_10_sw <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_sw
                  ORDER BY MGD_2040 DESC
                  limit 10')
    
    # #APPEND LETTERED INDEX TO TOP 10 Surface Water Users table   
    # index <- list()
    # 
    # for (i in 1:nrow(top_10_sw)) {
    #    
    #    index <- rbind(index, LETTERS[i])
    #    #print(index)
    # }
    # top_10_sw <- cbind(index, top_10_sw)
    
    #APPEND TOTALS to TOP 10 Surface Water Users table 
    top_10_sw <- append_totals(top_10_sw, "Total SW")
    
    #need to select the AA for the YES power (including)
    top_10_sw$pct_total_use <- round((top_10_sw$MGD_2040 / AA$MGD_2040[5]) * 100,2)
    
    top_gw <- sqldf('SELECT facility_name, system_type,
                        round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
                        round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
                        round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
                        fips_name 
               FROM mb_mps 
               WHERE MP_bundle = "well"
                  AND facility_ftype NOT LIKE "wsp_plan%"
               GROUP BY Facility_hydroid')
    
    top_10_gw <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_gw
                  ORDER BY MGD_2040 DESC
                  limit 10')
    
    # #APPEND LETTERED INDEX TO TOP 10 Groundwater Users table   
    # index <- list()
    # 
    # for (i in 1:nrow(top_10_gw)) {
    #    
    #    index <- rbind(index, LETTERS[i])
    #    #print(index)
    # }
    # top_10_gw <- cbind(index, top_10_gw)
    
    #APPEND TOTALS to TOP 10 Groundwater Users table 
    top_10_gw <- append_totals(top_10_gw, "Total GW")
    
    #need to select the BB for the YES power (including)
    top_10_gw$pct_total_use <- round((top_10_gw$MGD_2040 / BB$MGD_2040[5]) * 100,2)
    
    gw_header <- data.frame("facility_name" = 'Groundwater',
                            "system_type" = '',
                            "fips_name" = '',
                            "MGD_2020" = '',
                            "MGD_2030" ='',
                            "MGD_2040" ='',
                            "pct_change" = '',
                            "pct_total_use" = '% of Total Groundwater')
    
    top_10 <- rbind(top_10_sw, gw_header, top_10_gw)
    
    top_10$facility_name <- str_to_title(top_10$facility_name)
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = "wtp", replacement = "WTP", ignore.case = T)
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = "Water Treatment Plant", replacement = "WTP", ignore.case = T)
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = "Total sw", replacement = "Total SW", ignore.case = T)
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = "Total gw", replacement = "Total GW", ignore.case = T)
    
    top_10[is.na(top_10)] <- 0
    
    # OUTPUT TABLE IN KABLE FORMAT
    table10_tex <- kable(top_10,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
                        caption = paste("Top 10 Users in 2040 by Source Type in ",mb_name[1]," (including Power Generation)",sep=""),
                        label = paste("top_10_yes_power",mb_code,sep=""),
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
      pack_rows("Surface Water", 1, 11) %>%
      row_spec(11, extra_latex_after = "\\hline") %>%
      row_spec(12, bold=T, hline_after = F, extra_css = "border-top: 1px solid") 
    
    #CUSTOM LATEX CHANGES
    #insert hold position header
    table10_tex <- gsub(pattern = "{table}[t]", 
                       repl    = "{table}[H]", 
                       x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\hspace{1em}", 
                       repl    = "", 
                       x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\hline", 
                       repl    = "\\addlinespace[0.3em] \\hline \\addlinespace[0.4em]", 
                       x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\textbf{Facility Name}", 
                       repl    = "\\vspace{0.3em}\\textbf{Facility Name}", 
                       x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\textbf{Locality}", 
                       repl    = "\\vspace{0.3em}\\textbf{Locality}", 
                       x       = table10_tex, fixed = T )
    table10_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_top10_yes_power_table",file_ext,sep=""))
    
    #-------------- TOP 10 USERS EXCLUDING POWER GENERATION (NO POWER) ---------------------
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
    
    top_10_sw_no <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_sw_no
                  ORDER BY MGD_2040 DESC
                  limit 10')
    
    # #APPEND LETTERED INDEX TO TOP 10 Surface Water Users table   
    # index <- list()
    # 
    # for (i in 1:nrow(top_10_sw_no)) {
    #    
    #    index <- rbind(index, LETTERS[i])
    #    #print(index)
    # }
    # top_10_sw_no <- cbind(index, top_10_sw_no)
    
    #APPEND TOTALS to TOP 10 Groundwater Users table 
    top_10_sw_no <- append_totals(top_10_sw_no, "Total SW")
    
    top_10_sw_no$pct_total_use <- round((top_10_sw_no$MGD_2040 / A$MGD_2040[5]) * 100,2)
    
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
    
    top_10_gw_no <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_gw_no
                  ORDER BY MGD_2040 DESC
                  limit 10')
    
    # #APPEND LETTERED INDEX TO TOP 10 Groundwater Users table   
    # index <- list()
    # 
    # for (i in 1:nrow(top_10_gw_no)) {
    #    
    #    index <- rbind(index, LETTERS[i])
    #    #print(index)
    # }
    # top_10_gw_no <- cbind(index, top_10_gw_no)
    
    #APPEND TOTALS to TOP 10 Groundwater Users table 
    top_10_gw_no <- append_totals(top_10_gw_no, "Total GW")
    
    top_10_gw_no$pct_total_use <- round((top_10_gw_no$MGD_2040 / B$MGD_2040[5]) * 100,2)
    
    gw_header <- data.frame("facility_name" = 'Groundwater',
                            "system_type" = '',
                            "fips_name" = '',
                            "MGD_2020" = '',
                            "MGD_2030" ='',
                            "MGD_2040" ='',
                            "pct_change" = '',
                            "pct_total_use" = '% of Total Groundwater')
    
    top_10_no <- rbind(top_10_sw_no, gw_header, top_10_gw_no)
    
    top_10_no$facility_name <- str_to_title(top_10_no$facility_name)
    top_10_no$facility_name <- gsub(x = top_10_no$facility_name, pattern = "wtp", replacement = "WTP", ignore.case = T)
    top_10_no$facility_name <- gsub(x = top_10_no$facility_name, pattern = "Water Treatment Plant", replacement = "WTP", ignore.case = T)
    top_10_no$facility_name <- gsub(x = top_10_no$facility_name, pattern = "Total sw", replacement = "Total SW", ignore.case = T)
    top_10_no$facility_name <- gsub(x = top_10_no$facility_name, pattern = "Total gw", replacement = "Total GW", ignore.case = T)
    
    top_10_no[is.na(top_10_no)] <- 0
    
    # OUTPUT TABLE IN KABLE FORMAT
    table10_tex <- kable(top_10_no,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
                        caption = paste("Top 10 Users in 2040 by Source Type in ",mb_name[1]," (excluding Power Generation)",sep=""),
                        label = paste("top_10_no_power",mb_code,sep=""),
                        col.names = c("Facility Name",
                                      "System Type",
                                      "Locality",
                                      kable_col_names[3:6],
                                      "% of Total Surface Water")) %>%
      kable_styling(latex_options = latexoptions)%>%
      column_spec(1, width = "9em") %>%
      column_spec(2, width = "3em") %>%
      column_spec(3, width = "4em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      column_spec(6, width = "4em") %>%
      column_spec(7, width = "4em") %>%
      column_spec(8, width = "7em") %>%
      row_spec(0, bold=T, font_size = 9) %>%
      pack_rows("Surface Water", 1, 11) %>%
      row_spec(11, extra_latex_after = "\\hline") %>%
      row_spec(12, bold=T, hline_after = F, extra_css = "border-top: 1px solid") 
    
    #CUSTOM LATEX CHANGES
    #insert hold position header
    table10_tex <- gsub(pattern = "{table}[t]", 
                       repl    = "{table}[H]", 
                       x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\hspace{1em}", 
                       repl    = "", 
                       x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\hline", 
                       repl    = "\\addlinespace[0.3em] \\hline \\addlinespace[0.4em]", 
                       x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\textbf{Facility Name}", 
                       repl    = "\\vspace{0.3em}\\textbf{Facility Name}", 
                       x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\textbf{Locality}", 
                       repl    = "\\vspace{0.3em}\\textbf{Locality}", 
                       x       = table10_tex, fixed = T )
    table10_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_top10_no_power_table",file_ext,sep=""))

  
    ######## TOP 10 COUNTY-WIDE AGRICULTURE, MUNICIPAL, AND LARGE USERS Table ########################
    #-------------- TOP 10 SURFACE WATER COUNTY-WIDE ---------------------
    countywide <- c("ssuag", "cws", "ssulg")
    for (c in countywide) {
    
    top_sw <- sqldf(paste0('SELECT facility_name, system_type,
                        round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
                        round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
                        round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
                        fips_name 
               FROM mb_mps 
               WHERE MP_bundle = "intake"
                  AND wsp_ftype LIKE "wsp_plan_system-',c,'"
                  AND facility_ftype NOT LIKE "%power"
               GROUP BY Facility_hydroid'))
    
    top_10_sw <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_sw
                  ORDER BY MGD_2040 DESC
                  limit 10')
    
    #APPEND TOTALS to TOP 10 Surface Water Users table 
    top_10_sw <- append_totals(top_10_sw, "Total SW")
    
    #need to select the AA for the YES power (including)
    top_10_sw$pct_total_use <- round((top_10_sw$MGD_2040 / A$MGD_2040[5]) * 100,2)
    
    
    #-------------- TOP 10 GROUNDWATER COUNTY-WIDE ---------------------
    
    top_gw <- sqldf(paste0('SELECT facility_name, system_type,
                        round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
                        round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
                        round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
                        fips_name 
               FROM mb_mps 
               WHERE MP_bundle = "well"
                  AND wsp_ftype LIKE "wsp_plan_system-',c,'"
                  AND facility_ftype NOT LIKE "%power"
               GROUP BY Facility_hydroid'))
    
    top_10_gw <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_gw
                  ORDER BY MGD_2040 DESC
                  limit 10')
    
    #APPEND TOTALS to TOP 10 Groundwater Users table 
    top_10_gw <- append_totals(top_10_gw, "Total GW")
    
    #need to select the BB for the YES power (including)
    top_10_gw$pct_total_use <- round((top_10_gw$MGD_2040 / B$MGD_2040[5]) * 100,2)
    
    gw_header <- data.frame("facility_name" = 'Groundwater',
                            "system_type" = '',
                            "fips_name" = '',
                            "MGD_2020" = '',
                            "MGD_2030" ='',
                            "MGD_2040" ='',
                            "pct_change" = '',
                            "pct_total_use" = '% of Total Groundwater')
    
    top_10 <- rbind(top_10_sw, gw_header, top_10_gw)
    
    top_10$facility_name <- str_to_title(top_10$facility_name)
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = "wtp", replacement = "WTP", ignore.case = T)
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = "Water Treatment Plant", replacement = "WTP", ignore.case = T)
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = "Total sw", replacement = "Total SW", ignore.case = T)
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = "Total gw", replacement = "Total GW", ignore.case = T)
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = " \\(Agriculture\\)", replacement = "", ignore.case = T)
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = " \\(Community Water System\\)", replacement = "", ignore.case = T)
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = " \\(Large Self-Supplied User\\)", replacement = "", ignore.case = T)
    
    top_10[is.na(top_10)] <- 0.00
    top_10 <- sqldf('SELECT facility_name AS Locality, MGD_2020, MGD_2030, MGD_2040, pct_change, pct_total_use
                    FROM top_10')
    
    if (c == "ssuag") {
      system_type <- "Agricultural"
      colname_1 <- "Locality \\ Facility"
    } else if (c == "cws") {
      system_type <- "Municipal"
      colname_1 <- "Facility"
    } else if (c == "ssulg") {
      system_type <- "Large Self-Supplied"
      colname_1 <- "Facility"
    }

    # OUTPUT TABLE IN KABLE FORMAT
    table10_tex <- kable(top_10,align = c('l','c','c','c','c','c'),  booktabs = T,
                         caption = paste("Top 10 ",system_type," Users in 2040 in ",mb_name[1],sep=""),
                         label = paste("top_10_",c,"_",mb_code,sep=""),
                         col.names = c(colname_1,
                                       kable_col_names[3:6],
                                       "% of Total Surface Water")) %>%
      kable_styling(latex_options = latexoptions) %>%
      column_spec(1, width = "8em") %>%
      column_spec(2, width = "4em") %>%
      column_spec(3, width = "4em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      column_spec(6, width = "7em") %>%
      row_spec(0, bold=T, font_size = 9) %>%
      pack_rows("Surface Water", 1, 11) %>%
      row_spec(11,bold = T, extra_latex_after = "\\hline") %>%
      row_spec(12, bold=T, hline_after = F, extra_css = "border-top: 1px solid") %>%
      row_spec(23, bold = T)
    
    #CUSTOM LATEX CHANGES
    #insert hold position header
    table10_tex <- gsub(pattern = "{table}[t]", 
                        repl    = "{table}[H]", 
                        x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\hspace{1em}", 
                        repl    = "", 
                        x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\hline", 
                        repl    = "\\addlinespace[0.3em] \\hline \\addlinespace[0.4em]", 
                        x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\textbf{Locality}", 
                        repl    = "\\vspace{0.3em}\\textbf{Locality}", 
                        x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\textbf{\\% of Total Surface Water}", 
                        repl    = "\\vspace{0.3em}\\textbf{\\% of Total Surface Water}", 
                        x       = table10_tex, fixed = T )
    table10_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_top10_",c,"_table",file_ext,sep=""))
    
    }
    
    ######## TOP 10 COUNTY-WIDE SMALL SSU Table ###############################################################
    #-------------- THERE ARE NO SURFACE WATER COUNTY-WIDE SMALL SSU ---------------------
    #-------------- TOP 10 GROUNDWATER COUNTY-WIDE AGRICULTURE ---------------------
    
    top_gw <- sqldf('SELECT facility_name, system_type,
                        round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
                        round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
                        round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040, 
                        fips_name 
               FROM mb_mps 
               WHERE MP_bundle = "well"
                  AND facility_ftype LIKE "wsp_plan_system-ssusm"
               GROUP BY Facility_hydroid')
    
    top_10_gw <- sqldf('SELECT facility_name, 
                           system_type,
                           fips_name,
                           MGD_2020,
                           MGD_2030,
                           MGD_2040,
                           round(((MGD_2040 - MGD_2020) / MGD_2020) * 100, 2) as pct_change
                  FROM top_gw
                  ORDER BY MGD_2040 DESC
                  limit 10')
    
    #APPEND TOTALS to TOP 10 Groundwater Users table 
    top_10_gw <- append_totals(top_10_gw, "Total GW")
    
    #need to select the BB for the YES power (including)
    top_10_gw$pct_total_use <- round((top_10_gw$MGD_2040 / B$MGD_2040[5]) * 100,2)
    top_10 <- top_10_gw
    
    top_10$facility_name <- gsub(x = top_10$facility_name, pattern = " \\(Small Self-Supplied User\\)", replacement = "", ignore.case = T)
    
    top_10[is.na(top_10)] <- 0.00
    top_10 <- sqldf('SELECT facility_name AS Locality, MGD_2020, MGD_2030, MGD_2040, pct_change, pct_total_use
                    FROM top_10')
    # OUTPUT TABLE IN KABLE FORMAT
    table10_tex <- kable(top_10,align = c('l','c','c','c','c','c'),  booktabs = T,
                         caption = paste("Top 10 County-Wide Small Self-Supplied Users in 2040 in ",mb_name[1],sep=""),
                         label = paste("top_10_ssusm_",mb_code,sep=""),
                         col.names = c("Locality",
                                       kable_col_names[3:6],
                                       "% of Total Groundwater")) %>%
      kable_styling(latex_options = latexoptions) %>%
      column_spec(1, width = "8em") %>%
      column_spec(2, width = "4em") %>%
      column_spec(3, width = "4em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      column_spec(6, width = "7em") %>%
      row_spec(0, bold=T, font_size = 9) %>%
      row_spec(11,bold = T)
    
    #CUSTOM LATEX CHANGES
    #insert hold position header
    table10_tex <- gsub(pattern = "{table}[t]", 
                        repl    = "{table}[H]", 
                        x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\hspace{1em}", 
                        repl    = "", 
                        x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\hline", 
                        repl    = "\\addlinespace[0.3em] \\hline \\addlinespace[0.4em]", 
                        x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\textbf{Locality}", 
                        repl    = "\\vspace{0.3em}\\textbf{Locality}", 
                        x       = table10_tex, fixed = T )
    table10_tex <- gsub(pattern = "\\textbf{\\% of Total Groundwater}", 
                        repl    = "\\vspace{0.3em}\\textbf{\\% of Total Groundwater}", 
                        x       = table10_tex, fixed = T )
    table10_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_top10_ssusm_table",file_ext,sep=""))
    
    
    ######## STATEWIDE DEMAND by_locality ###########################################
    
    by_locality <- sqldf(paste('SELECT 
                     fips_code,
                     fips_name,
                     ',aggregate_select,'
                     FROM mb_mps
                     WHERE fips_code LIKE "51%"
                     AND fips_code NOT LIKE "51685"
                     GROUP BY fips_code
                     ORDER BY pct_change DESC', sep=""))
    by_locality[is.na(by_locality)] <- 0.00
    write.csv(by_locality, paste(folder,"tables_maps/Xtables/",mb_code,"_locality_demand.csv", sep=""), row.names = F)
    
    by_locality_sw <- sqldf(paste('SELECT 
                     fips_code,
                     fips_name,
                     ',aggregate_select,'
                     FROM mb_mps
                     WHERE fips_code LIKE "51%"
                     AND fips_code NOT LIKE "51685"
                     AND MP_bundle LIKE "intake"
                     GROUP BY fips_code
                     ORDER BY pct_change DESC', sep=""))
    by_locality_sw[is.na(by_locality_sw)] <- 0.00
    write.csv(by_locality_sw, paste(folder,"tables_maps/Xtables/",mb_code,"_sw_locality_demand.csv", sep=""), row.names = F)
    
    by_locality_gw <- sqldf(paste('SELECT 
                     fips_code,
                     fips_name,
                     ',aggregate_select,'
                     FROM mb_mps
                     WHERE fips_code LIKE "51%"
                     AND fips_code NOT LIKE "51685"
                     AND MP_bundle LIKE "well"
                     GROUP BY fips_code
                     ORDER BY fips_name DESC', sep=""))
    by_locality_gw[is.na(by_locality_gw)] <- 0.00
    write.csv(by_locality_gw, paste(folder,"tables_maps/Xtables/",mb_code,"_gw_locality_demand.csv", sep=""), row.names = F)
    
    # OUTPUT TABLE IN KABLE FORMAT
    locality_tex <- kable(by_locality[2:6],  
                          booktabs = T, 
                          longtable =T, 
                          align = c('l','c','c','c','c'),
          caption = paste("Withdrawal Demand (MGD) by Locality in ",mb_name[1],sep=""),
          label = paste(mb_code,"_locality_demand",sep=""),
          col.names = c("Locality",
                        "2020 Demand",
                        "2030 Demand",
                        "2040 Demand",
                        "20 Year % Change")) %>%
      kable_styling(latex_options = 'striped') %>%
      row_spec(0, bold = T) %>%
      column_spec(1, width = "8em") %>%
      column_spec(2, width = "4.5em") %>%
      column_spec(3, width = "4.5em") %>%
      column_spec(4, width = "4.5em") %>%
      column_spec(5, width = "6em")
      
      locality_tex <- gsub(pattern = "\\toprule
\\textbf{Locality} & \\textbf{2020 Demand} & \\textbf{2030 Demand} & \\textbf{2040 Demand} & \\textbf{20 Year \\% Change}\\\\
\\midrule", 
                        repl    = "\\toprule
\\textbf{Locality} & \\textbf{2020 Demand} & \\textbf{2030 Demand} & \\textbf{2040 Demand} & \\textbf{20 Year \\% Change}\\\\
\\endfirsthead
\\multicolumn{3}{l}{\\textbf{ \\tablename\\ \\ref{tab:VA_locality_demand} -- continued from previous page}}
\\endhead
\\midrule", 
                        x       = locality_tex, fixed = T )
    
    locality_tex %>%
    cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_locality_demand_table",file_ext,sep=""))
    
    
    
    #---- POPULATION PROJECTION TABLE -------------------------------------------------------------------------------
    
    vapop <- sqldf('SELECT FIPS, Geography_Name, round(x2020,0), round(x2030,0), round(x2040,0), round(((X2040 - X2020) / X2020)*100, 2) AS pct_change
               FROM vapop')
    vapop$Geography_Name <- str_to_title(vapop$Geography_Name)
    
    vapop$Geography_Name <- gsub(x = vapop$Geography_Name, pattern = " County", replacement = "")
    
    # OUTPUT TABLE IN KABLE FORMAT
    kable(vapop[2:6], align = c('l','c','c','c','c'),format.args = list(big.mark = ","),  booktabs = T, longtable =T,
          caption = "Virginia Population Trend",
          label = "VA_pop_proj",
          col.names = c("Locality",
                        "2020",
                        "2030",
                        "2040",
                        "20 Year Percent Change")) %>%
      kable_styling(latex_options = c("striped")) %>%
      column_spec(1, width = "10em") %>%
      cat(., file = paste(folder,"tables_maps/Xtables/VA_pop_proj_table.tex",sep=""))
    
    #---- PERMITTED vs. UNPERMITTED DEMAND TABLE -------------------------------------------------------------------------------
    #SURFACE WATER PERMITS
    mb_mps_VWP <- sqldf('SELECT a.*, 0 AS GWP, b."Permit.ID" AS VWP, b."VA.Hydro.Facility.ID"
          FROM mb_mps a
          LEFT OUTER JOIN VWP b
          ON (a.Facility_hydroid = b."VA.Hydro.Facility.ID")
          WHERE MP_bundle = "intake"')
    
    SW_perm <- sqldf(paste('SELECT system_type,',
                         aggregate_select,'
                     FROM mb_mps_VWP
                     WHERE VWP IS NOT NULL
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
    SW_perm[nrow(SW_perm) + 1,] <- list("Small SSU",0.00,0.00,0.00,0.00)
    SW_perm <- append_totals(SW_perm,"Total SW")
    
    SW_unperm <- sqldf(paste('SELECT system_type,',
                           aggregate_select,'
                     FROM mb_mps_VWP
                     WHERE VWP IS NULL
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
    SW_unperm[nrow(SW_unperm) + 1,] <- list("Small SSU",0.00,0.00,0.00,0.00)
    SW_unperm <- append_totals(SW_unperm,"Total SW")
    
    #GROUNDWATER PERMITS
    mb_mps_GWP <- sqldf('SELECT a.*, b."Permit.ID" AS GWP, 0 AS VWP, b."VA.Hydro.Facility.ID"
          FROM mb_mps a
          LEFT OUTER JOIN GWP b
          ON (a.Facility_hydroid = b."VA.Hydro.Facility.ID")
          WHERE MP_bundle = "well"')
     
    GW_perm <- sqldf(paste('SELECT system_type,',
                         aggregate_select,'
                     FROM mb_mps_GWP
                     WHERE GWP IS NOT NULL
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
    GW_perm[nrow(GW_perm) + 1,] <- list("Small SSU",0.00,0.00,0.00,0.00)
    GW_perm <- append_totals(GW_perm,"Total GW")
    
    GW_unperm <- sqldf(paste('SELECT system_type,',
                           aggregate_select,'
                     FROM mb_mps_GWP a
                     WHERE GWP IS NULL
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
    GW_unperm <- append_totals(GW_unperm,"Total GW")
    
    
    # #check to see which permits did NOT have a match in the mp.all file (most are newer permits that do not have a demand proj - makes sense)
    # GWP_nomatch <- GWP %>% anti_join(mb_mps, by = c( "VA.Hydro.Facility.ID" = "Facility_hydroid"))
    # VWP_nomatch <-  VWP %>% anti_join(mb_mps, by = c( "VA.Hydro.Facility.ID" = "Facility_hydroid"))
    # #check for facilities that are linked to multiple permits
    #a <- rbind(mb_mps_GWP, mb_mps_VWP)
    # sqldf('SELECT MP_hydroid, count(MP_hydroid), Facility_hydroid, count(Facility_hydroid), round(sum(mp_2020_mgy/365),2) as MGD, GWP, VWP
    #       FROM a
    #       GROUP BY MP_hydroid
    #       HAVING count(MP_Hydroid) > 1
    #       ORDER BY MGD desc')
    
    #VERSION 1 
    perm_table <- rbind(cbind(SW_perm, SW_unperm[2:5]),cbind(GW_perm, GW_unperm[2:5]) )
    
    #KABLE   
    perm_tex <- kable(perm_table,align = c('l','c','c','c','c','c','c','c','c'),  booktabs = T,
                        caption = paste("Permitted vs. Unpermitted ",mb_name[1]," Water Demand",sep=""),
                        label = paste("permitted_",mb_code,sep=""),
                        col.names = c("System Type",
                                      "2020",
                                      "2030",
                                      "2040",
                                      "% Change",
                                      "2020",
                                      "2030",
                                      "2040",
                                      "% Change"))%>%
      kable_styling(latex_options = latexoptions) %>%
      kable_styling(font_size = 10) %>%
      column_spec(1, width = "9em") %>%
      column_spec(2, width = "4em") %>%
      column_spec(3, width = "4em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      column_spec(6, width = "4em") %>%
      column_spec(7, width = "4em") %>%
      column_spec(8, width = "4em") %>%
      column_spec(9, width = "4em") %>%
      pack_rows("Surface Water", 1, 5, hline_before = T, hline_after = F) %>%
      pack_rows("Groundwater", 6, 10, hline_before = T, hline_after = F) %>%
      #pack_rows("Total (SW + GW)", 11, 14, hline_before = T, hline_after = F) %>%
      #Header row is row 0
      row_spec(0, bold=T, font_size = 11) %>%
      row_spec(5, bold=T, extra_latex_after = ) %>%
      add_header_above(c(" " = 1, "Permitted" = 4, "Unpermitted" = 4)) %>%
      row_spec(10, bold=T)
      # row_spec(14, bold=F, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      # row_spec(15, bold=T) 
    
    #CUSTOM LATEX CHANGES
    #insert hold position header
    perm_tex <- gsub(pattern = "{table}[t]", 
                       repl    = "{table}[H]", 
                       x       = perm_tex, fixed = T )
    perm_tex <- gsub(pattern = "\\midrule", 
                       repl    = "", 
                       x       = perm_tex, fixed = T )
    perm_tex <- gsub(pattern = "\\hline", 
                       repl    = "\\hline \\addlinespace[0.4em]", 
                       x       = perm_tex, fixed = T )
    perm_tex <- gsub(pattern = "\\vphantom{1}", 
                       repl    = "", 
                       x       = perm_tex, fixed = T )
    perm_tex <- gsub(pattern = "\\hspace{1em}T", 
                       repl    = "T", 
                       x       = perm_tex, fixed = T )
    # perm_tex <- gsub(pattern = "\\textbf{System Type}", 
    #                    repl    = "\\vspace{0.3em}\\textbf{System Type}", 
    #                    x       = perm_tex, fixed = T )
    perm_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_permitted_table",file_ext,sep=""))
    
    
#---- RUN STREAMFLOW REDUCTION LATEX FILE -------------------------------------
    print("PROCESSING: STREAMFLOW REDUCTION LATEX FILE")
    source(paste0(vahydro_location,"/R/wsp/wsp2020/streamflow_reduction_latex.R"))
    
    #---- RUN NARRATIVE FOCUS FILE -------------------------------------
    print("PROCESSING: NARRATIVE FOCUS TABLES")
    source(paste0(vahydro_location,"/R/wsp/wsp2020/FoundationDataset/narrative_focus.R"))
    
    #---- RUN WSP LOCALITY UPDATES TABLES -------------------------------------
    print("PROCESSING: WSP LOCALITY UPDATES TABLES")
    localities_updates <- read.csv(paste(folder,"localities_wsp_2018_updates.csv",sep=""))     
    #LOCALITIES WSP 2018 UPDATES TABLE
    localities_2018 <- sqldf('SELECT Localities_2018
                             FROM localities_updates')
    
    # OUTPUT TABLE IN KABLE FORMAT
    localities_2018_tex <- kable(localities_2018,  booktabs = T,format = "latex", align = c("l"),
                            caption = "2018 Locality Demand Updates",
                            label = "locality_2018_demand_updates",
                            col.names = "Localities") %>%
      kable_styling(latex_options = "striped") 
    
    #CUSTOM LATEX CHANGES
    #change to wraptable environment
    localities_2018_tex <- gsub(pattern = "\\begin{table}[t]",
                           repl    = "\\begin{wraptable}[20]{r}{7cm}",
                           x       = localities_2018_tex, fixed = T )
    localities_2018_tex <- gsub(pattern = "\\end{table}",
                           repl    = "\\end{wraptable}",
                           x       = localities_2018_tex, fixed = T )
    localities_2018_tex <- gsub(pattern = "\\addlinespace",
                           repl    = "",
                           x       = localities_2018_tex, fixed = T )
    localities_2018_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_locality_2018_demand_updates_table.tex",sep=""))
    
    #LOCALITIES WSP DEQ STAFF UPDATES TABLE
    localities_deq_staff <- sqldf('SELECT Localities_DEQ_Staff
                             FROM localities_updates')
    
    # OUTPUT TABLE IN KABLE FORMAT
    localities_2018_tex <- kable(localities_deq_staff,  booktabs = T,format = "latex", align = c("l"),
                                 caption = "DEQ Staff Locality Demand Updates",
                                 label = "locality_deq_staff_demand_updates",
                                 col.names = "Localities") %>%
      kable_styling(latex_options = "striped") 
    
    #CUSTOM LATEX CHANGES
    #change to wraptable environment
    localities_2018_tex <- gsub(pattern = "\\begin{table}[t]",
                                repl    = "\\begin{wraptable}[22]{r}{7cm}",
                                x       = localities_2018_tex, fixed = T )
    localities_2018_tex <- gsub(pattern = "\\end{table}",
                                repl    = "\\end{wraptable}",
                                x       = localities_2018_tex, fixed = T )
    localities_2018_tex <- gsub(pattern = "\\addlinespace",
                                repl    = "",
                                x       = localities_2018_tex, fixed = T )
    localities_2018_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_locality_deq_staff_demand_updates_table.tex",sep=""))
    }

### RUN TABLE GENERATION FUNCTION ########################
TABLE_GEN_func(state_abbrev = 'VA', file_extension = '.tex')







#Transform
#SSU demand vs. permitted amounts

permits_source <- "2020-01-22_mp_permits.csv"
mp_permits <- read.csv(paste(folder,permits_source,sep=""))

join1 <- sqldf("SELECT a.*, b.GWP_permit, b.VWP_permit
              FROM mps a
              left outer join mp_permits b
              on a.MP_hydroid = b.MP_hydroid")

unpermitted <- sqldf("SELECT *
             FROM join1
             where GWP_permit is null
                   and 
                   VWP_permit is null")


permitted_sql <- paste('SELECT 
                     wsp_ftype, count(MP_hydroid) AS sources,',
                           aggregate_select,'
                     FROM join1
                     WHERE GWP_permit is not null
                   OR 
                   VWP_permit is not null
                     GROUP BY wsp_ftype', sep="")

permitted_systems <- sqldf(permitted_sql)

#calculate columns sums 
totals <- as.data.frame(lapply(permitted_systems[1:5], totals_func),stringsAsFactors = F)
#calculate total percentage change
totals <- sqldf("SELECT *, 
round(((sum(MGD_2040) - sum(MGD_2020)) / sum(MGD_2020)) * 100,2) AS 'pct_change'
      FROM totals")
#append totals to table
permitted_systems <- rbind(cbind(' '=' ', permitted_systems),
                       cbind(' '='Total', totals))

ssu <- sqldf("SELECT wsp_ftype, count(MP_hydroid) AS sources,
round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040,
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS pct_change
             FROM join1
             where wsp_ftype like '%ssusm'
             group by wsp_ftype
             ")

#append permitted systems to SSU
ssu_permitted <- rbind(permitted_systems, cbind(' '=' ', ssu))

# OUTPUT TABLE IN KABLE FORMAT
kable(ssu_permitted,  booktabs = T,
      caption = "Statewide SSU Demand vs. Permitted Systems",
      label = "ssu_demand_vs_permitted_statewide",
      col.names = c("",
                    "System Type",
                    "Source Count",
                    #"2020 Demand (MGY)",
                    #"2030 Demand (MGY)",
                    #"2040 Demand (MGY)",
                    "2020 Demand (MGD)",
                    "2030 Demand (MGD)",
                    "2040 Demand (MGD)",
                    "20 Year Percent Change")) %>%
  kable_styling(latex_options = latexoptions) %>%
  #column_spec(1, width = "6em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/ssu_demand_vs_permitted_statewide_kable",file_ext,sep=""))
#---------------------------------------------------------------#
#Transform
#SSU demand vs. permitted amounts excluding power

permits_source <- "2020-01-22_mp_permits.csv"
mp_permits <- read.csv(paste(folder,permits_source,sep=""))

join1 <- sqldf("SELECT a.*, b.GWP_permit, b.VWP_permit
              FROM mps a
              left join mp_permits b
              on a.MP_hydroid = b.MP_hydroid")

unpermitted <- sqldf("SELECT *
             FROM join1
             where GWP_permit is null
                   and 
                   VWP_permit is null")


permitted_sql <- paste('SELECT 
                          wsp_ftype, count(MP_hydroid) AS sources,',
                          aggregate_select,'
                        FROM join1
                        WHERE (GWP_permit is not null
                          OR 
                              VWP_permit is not null)
                          AND facility_ftype NOT LIKE "%power"
                        GROUP BY wsp_ftype', sep="")

permitted_systems <- sqldf(permitted_sql)

#calculate columns sums 
totals <- as.data.frame(lapply(permitted_systems[2:5], totals_func),stringsAsFactors = F)
#calculate total percentage change
totals <- sqldf("SELECT 'Total' AS 'wsp_ftype', *, 
round(((sum(MGD_2040) - sum(MGD_2020)) / sum(MGD_2020)) * 100,2) AS 'pct_change'
      FROM totals")
#append totals to table with total lable in same column as system type
permitted_systems <- rbind(permitted_systems, totals)

# #append totals to table
# permitted_systems <- rbind(cbind(' '=' ', permitted_systems),
#                            cbind(' '='Total', totals))

ssu <- sqldf("SELECT wsp_ftype, count(MP_hydroid) AS sources,
round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040,
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS pct_change
             FROM join1
             where wsp_ftype like '%ssusm'
             group by wsp_ftype
             ")

#append permitted systems to SSU
#ssu_permitted <- rbind(permitted_systems, cbind(' '=' ', ssu))
ssu_permitted <- rbind(permitted_systems,ssu)

# OUTPUT TABLE IN KABLE FORMAT
kable(ssu_permitted,  booktabs = T,
      caption = "Statewide SSU Demand vs. Permitted Systems (excluding Power Generation)",
      label = "ssu_demand_vs_permitted_statewide_no_power",
      col.names = c(
                    "System Type",
                    "Source Count",
                    #"2020 Demand (MGY)",
                    #"2030 Demand (MGY)",
                    #"2040 Demand (MGY)",
                    "2020 Demand (MGD)",
                    "2030 Demand (MGD)",
                    "2040 Demand (MGD)",
                    "20 Year Percent Change")) %>%
  kable_styling(latex_options = latexoptions) %>%
  row_spec(4, bold = T) %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/ssu_demand_vs_permitted_statewide_no_power_kable",file_ext,sep=""))

