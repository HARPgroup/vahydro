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

unmet30_raw <- read.csv(paste(folder,"metrics_facility_unmet30_mgd.csv",sep=""))

#--------select MPs with no minor basin---------------------------------------
# ## select MPs with no minor basin
# null_minorbasin <- sqldf("SELECT *
#       FROM mp_all
#       WHERE MinorBasin_Name IS NULL")
# write.csv(null_minorbasin, paste(folder,"tables_maps/Xtables/NA_minorbasin_mp.csv", sep=""))

######### TABLE GENERATION FUNCTION #############################
TABLE_GEN_func <- function(minorbasin = "RL", file_extension = ".tex"){

   
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
   
   sql_A <- sqldf(paste('SELECT system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "intake"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   sql_A[nrow(sql_A) + 1,] <- list("Small Self-Supplied User",0.00,0.00,0.00,0.00)
   A <- append_totals(sql_A,"Total SW")
   
   sql_B <- sqldf(paste('SELECT system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "well"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   B <- append_totals(sql_B,"Total GW")
   
   sql_C <- sqldf(paste('SELECT system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   
   sql_D <-  sqldf(paste('SELECT "Minor Basin Total" AS system_type, ',
                         aggregate_select,'
                     FROM mb_mps',sep=""))
   table_1 <- rbind(A,B,sql_C,sql_D)
   table_1[is.na(table_1)] <- 0
#KABLE   
   table1_tex <- kable(table_1,align = c('l','l','c','c','c'),  booktabs = T,
         caption = paste("Summary of ",mb_name$MinorBasin_Name," Minor Basin Water Demand by Source Type and System Type",sep=""),
         label = paste("summary_no_power_",mb_code,sep=""),
         col.names = c(
                       "System Type",
                       kable_col_names[3:6])) %>%
      kable_styling(latex_options = "scale_down") %>%
      column_spec(1, width = "12em") %>%
      column_spec(2, width = "4em") %>%
      column_spec(3, width = "4em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      pack_rows("Surface Water", 1, 5, hline_before = T, hline_after = F) %>%
      pack_rows("Groundwater", 6, 10, hline_before = T, hline_after = F) %>%
      pack_rows("Total (GW + SW)", 11, 14, hline_before = T, hline_after = F,extra_latex_after = ) %>%
      #horizontal solid line depending on html or latex output
      row_spec(14, bold=F, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      row_spec(5, bold=T) %>%
      row_spec(10, bold=T) %>%
      row_spec(15, bold=T) 
      
   #CUSTOM LATEX CHANGES
   #insert hold position header
   table1_tex <- gsub(pattern = "{table}[t]", 
                    repl    = "{table}[ht!]", 
                    x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\midrule", 
                      repl    = "", 
                      x       = table1_tex, fixed = T )
   table1_tex %>%
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
   
# #APPEND LETTERED INDEX TO TOP 5 Surface Water Users table   
#    index <- list()
#    
#    for (i in 1:nrow(top_5_sw_no)) {
#       
#       index <- rbind(index, LETTERS[i])
#       #print(index)
#    }
#    top_5_sw_no <- cbind(index, top_5_sw_no)
   
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
   
# #APPEND LETTERED INDEX TO TOP 5 Surface Water Users table   
#    index <- list()
#    
#    for (i in 1:nrow(top_5_gw_no)) {
#       
#       index <- rbind(index, LETTERS[i])
#       #print(index)
#    }
#    top_5_gw_no <- cbind(index, top_5_gw_no)
   
#APPEND TOTALS to TOP 5 Surface Water Users table   
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
   top_5_no[is.na(top_5_no)] <- 0
   
   # OUTPUT TABLE IN KABLE FORMAT
   table5_tex <- kable(top_5_no,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
         caption = paste("Top 5 Users by Source Type in ",mb_name$MinorBasin_Name," Minor Basin",sep=""),
         label = paste("top_5_no_power_",mb_code,sep=""),
         col.names = c("Facility Name",
                       "System Type",
                       "Locality",
                       kable_col_names[3:6],
                       "% of Total Surface Water")) %>%
      kable_styling(latex_options = latexoptions) %>%
      column_spec(1, width = "9em") %>%
      column_spec(2, width = "3em") %>%
      column_spec(3, width = "3em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      column_spec(6, width = "4em") %>%
      column_spec(7, width = "4em") %>%
      column_spec(8, width = "7em") %>%
      pack_rows("Surface Water", 1, 6) %>%
      #pack_rows("Groundwater", 7, 13, label_row_css = "border-top: 1px solid", hline_after = F,hline_before = F) %>%
      #horizontal solid line depending on html or latex output
      row_spec(7, bold=T, hline_after = F, extra_css = "border-top: 1px solid") %>%
      row_spec(6, extra_latex_after = "\\hline")
   
   #CUSTOM LATEX CHANGES
   #insert hold position header
   table5_tex <- gsub(pattern = "{table}[t]", 
                      repl    = "{table}[ht!]", 
                      x       = table5_tex, fixed = T )
   table5_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_top5_no_power_table",file_ext,sep=""))
   
   #-------------- Table - Demand by System & Source Type (NO POWER detected) ---------------------
   system_source <- sqldf(paste('SELECT 
                     source_type,system_type,',
                                aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY wsp_ftype, MP_bundle
                     ORDER BY source_type,system_type', sep=""))
   
   system_source <- append_totals(system_source)
   
   # # OUTPUT TABLE IN KABLE FORMAT
   # kable(system_source,  booktabs = T,
   #       caption = paste("Withdrawal Demand by System and Source Type (excluding Power Generation) in ",mb_name$MinorBasin_Name," Minor Basin",sep=""),
   #       label = paste("demand_source_type_yes_power_",mb_code,sep=""),
   #       col.names = c("Source Type","System Type",kable_col_names[3:6])) %>%
   #    kable_styling(latex_options = latexoptions) %>%
   #    cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_demand_no_power_table",file_ext,sep=""))
   
   #---------BAR GRAPH Demand by System & Source Type (NO POWER detected) -------------------------------
   system_source <- melt(system_source, id=c("system_type","source_type", "pct_change"))
   system_source[is.na(system_source)] <- 0
   h <- sqldf("SELECT *
            FROM system_source as a
            WHERE source_type IN ('Groundwater','Surface Water')
            ")
  
   # v3 <- ggplot(h, aes(x = system_type, y = value, fill = variable)) + 
   #    geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
   #    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), legend.position = "bottom", legend.title = element_text(size = 10)) +
   #    xlab(label = element_blank())  +
   #    labs(title = paste(mb_name$MinorBasin_Name," Minor Basin",sep=""), subtitle = "Water Withdrawal Demand by Source Type", fill = "Demand: ") +
   #    facet_grid(~ source_type) +
   #    scale_fill_discrete(labels = c("2020","2030","2040")) +
   #    scale_y_continuous(name = "MGD") +
   #    geom_text(data = sqldf('SELECT * FROM h WHERE variable LIKE "MGD_2040"'),aes(x = system_type, y = value, label = paste0(pct_change,"%")),inherit.aes = F, show.legend = F, check_overlap = F, nudge_y = 1, na.rm = T)
   # 
   # ggsave(plot = v3, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_demand_graph.png",sep=""))
   
   #make 2 separate plots so that scale won't be an issue; then plot together with cowplot::plot_grid()
   
   #SURFACE WATER GRAPH
   swplot <- ggplot(sqldf('SELECT * FROM h WHERE source_type LIKE "Surface Water"'), aes(x = system_type, y = value, fill = variable)) + 
      geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12), legend.position = "bottom", legend.title = element_text(size = 13)) +
      xlab(label = element_blank())  +
      labs(title = "Surface Water", fill = "Demand: ") +
      scale_fill_discrete(labels = c("2020","2030","2040")) +
      scale_y_continuous(name = "MGD") +
      geom_text(data = sqldf('SELECT * FROM h WHERE variable LIKE "MGD_2040" AND source_type LIKE "Surface Water"'),aes(x = system_type, y = value, label = paste0(pct_change,"%")),inherit.aes = F, show.legend = F, check_overlap = F, nudge_y = .35, na.rm = T, size = 6)
   #ggsave(width = 7.2,height = 6,units = "in",plot = swplot, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_sw_demand_graph.png",sep=""))
   
   #GROUNDWATER GRAPH
   gwplot <- ggplot(sqldf('SELECT * FROM h WHERE source_type LIKE "Groundwater"'), aes(x = system_type, y = value, fill = variable)) + 
      geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12), legend.position = "bottom", legend.title = element_text(size = 13)) +
      xlab(label = element_blank())  +
      labs(title = "Groundwater", fill = "Demand: ") +
      scale_fill_discrete(labels = c("2020","2030","2040")) +
      scale_y_continuous(name = "MGD") +
      geom_text(data = sqldf('SELECT * FROM h WHERE variable LIKE "MGD_2040" AND source_type LIKE "Groundwater"'),aes(x = system_type, y = value, label = paste0(pct_change,"%")),inherit.aes = F, show.legend = F, check_overlap = F, nudge_y = .35, na.rm = T, size = 6)
   #ggsave(width = 7.2,height = 6,units = "in",plot = gwplot, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_gw_demand_graph.png",sep=""))
   
   #COMBINE PLOTS
   plot_row <- plot_grid(swplot, gwplot)
   
   # now add the title
   title <- ggdraw() + 
      draw_label(
         paste(mb_name$MinorBasin_Name," - Water Withdrawal Demand",sep=""),
         fontface = 'bold',
         x = 0,
         hjust = 0) +
      theme(
         # add margin on the left of the drawing canvas,
         # so title is aligned with left edge of first plot
         plot.margin = margin(0, 0, 0, 7))
   
   demand_graph <- plot_grid(
      title, plot_row,
      ncol = 1,
      # rel_heights values control vertical title margins
      rel_heights = c(0.1, 1)
   )
   ggsave(width = 7.2,height = 6,units = "in",plot = demand_graph, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_demand_no_power_graph.png",sep=""))
   
   

   
} else {

   ### when 'power' IS detected in facility ftype column, then generate 2 separate summary tables for yes/no power
   
   #YES power (including power generation)
   sql_A <- sqldf(paste('SELECT system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "intake"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   sql_A[nrow(sql_A) + 1,] <- list("Small Self-Supplied User",0.00,0.00,0.00,0.00)
   AA <- append_totals(sql_A,"Total SW")
   
   sql_B <- sqldf(paste('SELECT system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "well"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   BB <- append_totals(sql_B,"Total GW")
   
   sql_C <- sqldf(paste('SELECT system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   sql_D <-  sqldf(paste('SELECT "Minor Basin Total" AS system_type, ',
                         aggregate_select,'
                     FROM mb_mps',sep=""))
   table_1 <- rbind(AA,BB,sql_C,sql_D)
   table_1[is.na(table_1)] <- 0
   
#KABLE   
   table1_tex <- kable(table_1,align = c('l','c','c','c','c'),  booktabs = T,
         caption = paste("Summary of ",mb_name$MinorBasin_Name," Minor Basin Water Demand by Source Type and System Type (including Power Generation)",sep=""),
         label = paste("summary_yes_power_",mb_code,sep=""),
         col.names = c("System Type",
                       kable_col_names[3:6])) %>%
      kable_styling(latex_options = "scale_down")  %>%
      column_spec(1, width = "12em") %>%
      column_spec(2, width = "4em") %>%
      column_spec(3, width = "4em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      pack_rows("Surface Water", 1, 5, hline_before = T, hline_after = F) %>%
      pack_rows("Groundwater", 6, 10, hline_before = T, hline_after = F) %>%
      pack_rows("Total (GW + SW)", 11, 14, hline_before = T, hline_after = F,extra_latex_after = ) %>%
      #horizontal solid line depending on html or latex output
      row_spec(14, bold=F, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      row_spec(5, bold=T) %>%
      row_spec(10, bold=T) %>%
      row_spec(15, bold=T) 
   
   #CUSTOM LATEX CHANGES
   #insert hold position header
   table1_tex <- gsub(pattern = "{table}[t]", 
                      repl    = "{table}[ht!]", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\midrule", 
                      repl    = "", 
                      x       = table1_tex, fixed = T )
   table1_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_summary_yes_power_table",file_ext,sep=""))
   
   #------------------------------------------------------------------------
   #NO power (excluding power generation)
   sql_A <- sqldf(paste('SELECT system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "intake"
                     AND facility_ftype NOT LIKE "%power"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   sql_A[nrow(sql_A) + 1,] <- list("Small Self-Supplied User",0.00,0.00,0.00,0.00)
   A <- append_totals(sql_A,"Total SW")
   
   sql_B <- sqldf(paste('SELECT system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE MP_bundle = "well"
                     AND facility_ftype NOT LIKE "%power"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   B <- append_totals(sql_B,"Total GW")
   
   sql_C <- sqldf(paste('SELECT system_type, ',
                        aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY system_type
                     ORDER BY system_type',sep=""))
   sql_D <-  sqldf(paste('SELECT "Minor Basin Total" AS system_type, ',
                         aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"',sep=""))
   table_1 <- rbind(A,B,sql_C,sql_D)
   table_1[is.na(table_1)] <- 0
   
   #KABLE   
   table1_tex <- kable(table_1,align = c('l','c','c','c','c'),  booktabs = T,
         caption = paste("Summary of ",mb_name$MinorBasin_Name," Minor Basin Water Demand by Source Type and System Type (excluding Power Generation)",sep=""),
         label = paste("summary_no_power_",mb_code,sep=""),
         col.names = c("System Type",
                       kable_col_names[3:6])) %>%
      kable_styling(latex_options = "scale_down") %>%
      column_spec(1, width = "12em") %>%
      column_spec(2, width = "4em") %>%
      column_spec(3, width = "4em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      pack_rows("Surface Water", 1, 5, hline_before = T, hline_after = F) %>%
      pack_rows("Groundwater", 6, 10, hline_before = T, hline_after = F) %>%
      pack_rows("Total (GW + SW)", 11, 14, hline_before = T, hline_after = F,extra_latex_after = ) %>%
      #horizontal solid line depending on html or latex output
      row_spec(14, bold=F, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
      row_spec(5, bold=T) %>%
      row_spec(10, bold=T) %>%
      row_spec(15, bold=T) 
   
   #CUSTOM LATEX CHANGES
   #insert hold position header
   table1_tex <- gsub(pattern = "{table}[t]", 
                      repl    = "{table}[ht!]", 
                      x       = table1_tex, fixed = T )
   table1_tex <- gsub(pattern = "\\midrule", 
                      repl    = "", 
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
   
   # #APPEND LETTERED INDEX TO TOP 5 Surface Water Users table   
   # index <- list()
   # 
   # for (i in 1:nrow(top_5_sw)) {
   #    
   #    index <- rbind(index, LETTERS[i])
   #    #print(index)
   # }
   # top_5_sw <- cbind(index, top_5_sw)
   
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
   
   # #APPEND LETTERED INDEX TO TOP 5 Groundwater Users table   
   # index <- list()
   # 
   # for (i in 1:nrow(top_5_gw)) {
   #    
   #    index <- rbind(index, LETTERS[i])
   #    #print(index)
   # }
   # top_5_gw <- cbind(index, top_5_gw)
   
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
   top_5[is.na(top_5)] <- 0
   
   # OUTPUT TABLE IN KABLE FORMAT
   table5_tex <- kable(top_5,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
         caption = paste("Top 5 Users by Source Type in ",mb_name$MinorBasin_Name," Minor Basin (including Power Generation)",sep=""),
         label = paste("top_5_yes_power",mb_code,sep=""),
         col.names = c("Facility Name",
                       "System Type",
                       "Locality",
                       kable_col_names[3:6],
                       "% of Total Surface Water")) %>%
      kable_styling(latex_options = latexoptions) %>%
      column_spec(1, width = "9em") %>%
      column_spec(2, width = "3em") %>%
      column_spec(3, width = "3em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      column_spec(6, width = "4em") %>%
      column_spec(7, width = "4em") %>%
      column_spec(8, width = "7em") %>%
      pack_rows("Surface Water", 1, 6) %>%
      #pack_rows("Groundwater", 7, 13, label_row_css = "border-top: 1px solid", hline_after = F,hline_before = F) %>%
      #horizontal solid line depending on html or latex output
      row_spec(7, bold=T, hline_after = F, extra_css = "border-top: 1px solid") %>%
      row_spec(6, extra_latex_after = "\\hline")
   
   #CUSTOM LATEX CHANGES
   #insert hold position header
   table5_tex <- gsub(pattern = "{table}[t]", 
                      repl    = "{table}[ht!]", 
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
   
   # #APPEND LETTERED INDEX TO TOP 5 Surface Water Users table   
   # index <- list()
   # 
   # for (i in 1:nrow(top_5_sw_no)) {
   #    
   #    index <- rbind(index, LETTERS[i])
   #    #print(index)
   # }
   # top_5_sw_no <- cbind(index, top_5_sw_no)
   
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
   
   # #APPEND LETTERED INDEX TO TOP 5 Groundwater Users table   
   # index <- list()
   # 
   # for (i in 1:nrow(top_5_gw_no)) {
   #    
   #    index <- rbind(index, LETTERS[i])
   #    #print(index)
   # }
   # top_5_gw_no <- cbind(index, top_5_gw_no)
   
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
   top_5_no[is.na(top_5_no)] <- 0
   
   # OUTPUT TABLE IN KABLE FORMAT
   table5_tex <- kable(top_5_no,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
         caption = paste("Top 5 Users by Source Type in ",mb_name$MinorBasin_Name," Minor Basin (excluding Power Generation)",sep=""),
         label = paste("top_5_no_power",mb_code,sep=""),
         col.names = c("Facility Name",
                       "System Type",
                       "Locality",
                       kable_col_names[3:6],
                       "% of Total Surface Water")) %>%
      kable_styling(latex_options = latexoptions) %>%
      column_spec(1, width = "9em") %>%
      column_spec(2, width = "3em") %>%
      column_spec(3, width = "3em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      column_spec(6, width = "4em") %>%
      column_spec(7, width = "4em") %>%
      column_spec(8, width = "7em") %>%
      pack_rows("Surface Water", 1, 6) %>%
      #pack_rows("Groundwater", 7, 13, label_row_css = "border-top: 1px solid", hline_after = F,hline_before = F) %>%
      #horizontal solid line depending on html or latex output
      row_spec(7, bold=T, hline_after = F, extra_css = "border-top: 1px solid") %>%
      row_spec(6, extra_latex_after = "\\hline")
   
   #CUSTOM LATEX CHANGES
   #insert hold position header
   table5_tex <- gsub(pattern = "{table}[t]", 
                      repl    = "{table}[ht!]", 
                      x       = table5_tex, fixed = T )
   table5_tex %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_top5_no_power_table",file_ext,sep=""))
   
   #-------------- Table - Demand by System & Source Type (NO POWER detected) ---------------------
   system_source <- sqldf(paste('SELECT 
                     source_type,system_type,',
                                aggregate_select,'
                     FROM mb_mps
                     GROUP BY wsp_ftype, MP_bundle
                     ORDER BY source_type,system_type', sep=""))
   
   system_source <- append_totals(system_source)
   
   # # OUTPUT TABLE IN KABLE FORMAT
   # kable(system_source,  booktabs = T,
   #       caption = paste("Withdrawal Demand by System and Source Type (excluding Power Generation) in ",mb_name$MinorBasin_Name," Minor Basin",sep=""),
   #       label = paste("demand_source_type_yes_power_",mb_code,sep=""),
   #       col.names = c("Source Type","System Type",kable_col_names[3:6])) %>%
   #    kable_styling(latex_options = latexoptions) %>%
   #    cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_demand_no_power_table",file_ext,sep=""))
   
   #---------BAR GRAPH Demand by System & Source Type (YES POWER detected) -------------------------------
   system_source <- melt(system_source, id=c("system_type","source_type", "pct_change"))
   system_source[is.na(system_source)] <- 0
   h <- sqldf("SELECT *
            FROM system_source as a
            WHERE source_type IN ('Groundwater','Surface Water')
            ")
   
   # v3 <- ggplot(h, aes(x = system_type, y = value, fill = variable)) +
   #    geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
   #    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), legend.position = "bottom", legend.title = element_text(size = 10)) +
   #    xlab(label = element_blank())  +
   #    labs(title = paste(mb_name$MinorBasin_Name," Minor Basin",sep=""), subtitle = "Water Withdrawal Demand by Source Type", fill = "Demand: ") +
   #    facet_grid(~ source_type) +
   #    scale_fill_discrete(labels = c("2020","2030","2040")) +
   #    scale_y_continuous(name = "MGD") +
   #    geom_text(data = sqldf('SELECT * FROM h WHERE variable LIKE "MGD_2040"'),aes(x = system_type, y = value, label = paste0(pct_change,"%")),inherit.aes = F, show.legend = F, check_overlap = F, nudge_y = 1, na.rm = T)
   # 
   # ggsave(plot = v3, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_demand_yes_power_graph2.png",sep=""))
   
   #make 2 separate plots so that scale won't be an issue; then plot together with cowplot::plot_grid()
   
   #SURFACE WATER GRAPH
   swplot <- ggplot(sqldf('SELECT * FROM h WHERE source_type LIKE "Surface Water"'), aes(x = system_type, y = value, fill = variable)) + 
      geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12), legend.position = "bottom", legend.title = element_text(size = 13)) +
      xlab(label = element_blank())  +
      labs(title = "Surface Water", fill = "Demand: ") +
      scale_fill_discrete(labels = c("2020","2030","2040")) +
      scale_y_continuous(name = "MGD") +
      geom_text(data = sqldf('SELECT * FROM h WHERE variable LIKE "MGD_2040" AND source_type LIKE "Surface Water"'),aes(x = system_type, y = value, label = paste0(pct_change,"%")),inherit.aes = F, show.legend = F, check_overlap = F, nudge_y = .35, na.rm = T, size = 6)
   #ggsave(width = 7.2,height = 6,units = "in",plot = swplot, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_sw_demand_graph.png",sep=""))
   
   #GROUNDWATER GRAPH
   gwplot <- ggplot(sqldf('SELECT * FROM h WHERE source_type LIKE "Groundwater"'), aes(x = system_type, y = value, fill = variable)) + 
      geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12), legend.position = "bottom", legend.title = element_text(size = 13)) +
      xlab(label = element_blank())  +
      labs(title = "Groundwater", fill = "Demand: ") +
      scale_fill_discrete(labels = c("2020","2030","2040")) +
      scale_y_continuous(name = "MGD") +
      geom_text(data = sqldf('SELECT * FROM h WHERE variable LIKE "MGD_2040" AND source_type LIKE "Groundwater"'),aes(x = system_type, y = value, label = paste0(pct_change,"%")),inherit.aes = F, show.legend = F, check_overlap = F, nudge_y = .35, na.rm = T, size = 6)
   #ggsave(width = 7.2,height = 6,units = "in",plot = gwplot, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_gw_demand_graph.png",sep=""))
   
   #COMBINE PLOTS
   plot_row <- plot_grid(swplot, gwplot)
   
   # now add the title
   title <- ggdraw() + 
      draw_label(
         paste(mb_name$MinorBasin_Name," - Water Withdrawal Demand (including Power Generation)",sep=""),
         fontface = 'bold',
         x = 0,
         hjust = 0) +
      theme(
         # add margin on the left of the drawing canvas,
         # so title is aligned with left edge of first plot
         plot.margin = margin(0, 0, 0, 7))
   
   demand_graph <- plot_grid(
      title, plot_row,
      ncol = 1,
      # rel_heights values control vertical title margins
      rel_heights = c(0.1, 1)
   )
   ggsave(width = 7.2,height = 6,units = "in",plot = demand_graph, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_demand_yes_power_graph.png",sep=""))
   
   
   
   #-------------- Table - Demand by System & Source Type (NO POWER detected) ---------------------
   system_source <- sqldf(paste('SELECT 
                     source_type,system_type,',
                                aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY wsp_ftype, MP_bundle
                     ORDER BY source_type,system_type', sep=""))
   
   system_source <- append_totals(system_source)
   
   # # OUTPUT TABLE IN KABLE FORMAT
   # kable(system_source,  booktabs = T,
   #       caption = paste("Withdrawal Demand by System and Source Type (excluding Power Generation) in ",mb_name$MinorBasin_Name," Minor Basin",sep=""),
   #       label = paste("demand_source_type_yes_power_",mb_code,sep=""),
   #       col.names = c("Source Type","System Type",kable_col_names[3:6])) %>%
   #    kable_styling(latex_options = latexoptions) %>%
   #    cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_demand_no_power_table",file_ext,sep=""))
   
   #---------BAR GRAPH Demand by System & Source Type (NO POWER detected) -------------------------------
   system_source <- melt(system_source, id=c("system_type","source_type", "pct_change"))
   system_source[is.na(system_source)] <- 0
   h <- sqldf("SELECT *
            FROM system_source as a
            WHERE source_type IN ('Groundwater','Surface Water')
            ")
   
   # v3 <- ggplot(h, aes(x = system_type, y = value, fill = variable)) +
   #    geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
   #    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), legend.position = "bottom", legend.title = element_text(size = 10)) +
   #    xlab(label = element_blank())  +
   #    labs(title = paste(mb_name$MinorBasin_Name," Minor Basin",sep=""), subtitle = "Water Withdrawal Demand by Source Type", fill = "Demand: ") +
   #    facet_grid(~ source_type) +
   #    scale_fill_discrete(labels = c("2020","2030","2040")) +
   #    scale_y_continuous(name = "MGD") +
   #    geom_text(data = sqldf('SELECT * FROM h WHERE variable LIKE "MGD_2040"'),aes(x = system_type, y = value, label = paste0(pct_change,"%")),inherit.aes = F, show.legend = F, check_overlap = F, nudge_y = 1, na.rm = T)
   # 
   # ggsave(plot = v3, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_demand_no_power_graph2.png",sep=""))
   
   #make 2 separate plots so that scale won't be an issue; then plot together with cowplot::plot_grid()
   
   #SURFACE WATER GRAPH
   swplot <- ggplot(sqldf('SELECT * FROM h WHERE source_type LIKE "Surface Water"'), aes(x = system_type, y = value, fill = variable)) + 
      geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12), legend.position = "bottom", legend.title = element_text(size = 13)) +
      xlab(label = element_blank())  +
      labs(title = "Surface Water", fill = "Demand: ") +
      scale_fill_discrete(labels = c("2020","2030","2040")) +
      scale_y_continuous(name = "MGD") +
      geom_text(data = sqldf('SELECT * FROM h WHERE variable LIKE "MGD_2040" AND source_type LIKE "Surface Water"'),aes(x = system_type, y = value, label = paste0(pct_change,"%")),inherit.aes = F, show.legend = F, check_overlap = F, nudge_y = .35, na.rm = T, size = 6)
   #ggsave(width = 7.2,height = 6,units = "in",plot = swplot, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_sw_demand_graph.png",sep=""))
   
   #GROUNDWATER GRAPH
   gwplot <- ggplot(sqldf('SELECT * FROM h WHERE source_type LIKE "Groundwater"'), aes(x = system_type, y = value, fill = variable)) + 
      geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12), legend.position = "bottom", legend.title = element_text(size = 13)) +
      xlab(label = element_blank())  +
      labs(title = "Groundwater", fill = "Demand: ") +
      scale_fill_discrete(labels = c("2020","2030","2040")) +
      scale_y_continuous(name = "MGD") +
      geom_text(data = sqldf('SELECT * FROM h WHERE variable LIKE "MGD_2040" AND source_type LIKE "Groundwater"'),aes(x = system_type, y = value, label = paste0(pct_change,"%")),inherit.aes = F, show.legend = F, check_overlap = F, nudge_y = .35, na.rm = T, size = 6)
   #ggsave(width = 7.2,height = 6,units = "in",plot = gwplot, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_gw_demand_graph.png",sep=""))
   
   #COMBINE PLOTS
   plot_row <- plot_grid(swplot, gwplot)
   
   # now add the title
   title <- ggdraw() + 
      draw_label(
         paste(mb_name$MinorBasin_Name," - Water Withdrawal Demand (excluding Power Generation)",sep=""),
         fontface = 'bold',
         x = 0,
         hjust = 0) +
      theme(
         # add margin on the left of the drawing canvas,
         # so title is aligned with left edge of first plot
         plot.margin = margin(0, 0, 0, 7))
   
   demand_graph <- plot_grid(
      title, plot_row,
      ncol = 1,
      # rel_heights values control vertical title margins
      rel_heights = c(0.1, 1)
   )
   ggsave(width = 7.2,height = 6,units = "in",plot = demand_graph, path = paste(folder,"tables_maps/Xtables/", sep=""),filename = paste(mb_code,"_demand_no_power_graph.png",sep=""))
   
   
}
 ### SOURCE COUNT TABLE
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
       GROUP BY a.wsp_ftype
       ORDER BY a.system_type', sep=""))
   
   system_specific_facility_sw <- sqldf(paste('SELECT a.system_type,  count(MP_hydroid) as "count_with_county_estimates",
            (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND MP_bundle = "intake"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count",',
                                              aggregate_select,'
                     FROM mb_mps a
       WHERE facility_ftype NOT LIKE "%power"
         AND MP_bundle = "intake"
       GROUP BY a.wsp_ftype
       ORDER BY a.system_type', sep=""))
   system_specific_facility_sw[nrow(system_specific_facility_sw) + 1,] <- list("Small Self-Supplied User",0,0)
   system_specific_facility_gw <- sqldf(paste('SELECT a.system_type,  count(MP_hydroid) as "count_with_county_estimates",
            (SELECT count(MP_hydroid)
             FROM mb_mps
             WHERE facility_ftype NOT LIKE "wsp%"
             AND facility_ftype NOT LIKE "%power"
             AND MP_bundle = "well"
             AND wsp_ftype = a.wsp_ftype) AS "specific_count",',
                                              aggregate_select,'
                     FROM mb_mps a
       WHERE facility_ftype NOT LIKE "%power"
         AND MP_bundle = "well"
       GROUP BY a.wsp_ftype
       ORDER BY a.system_type', sep=""))
   
   count_total <- data.frame("system_type" = 'Total',
                             "count_with_county_estimates" = colSums(system_specific_facility[2]),
                             "specific_count" = colSums(system_specific_facility[3]),row.names = NULL ) 
   count_table <- rbind(system_specific_facility_sw[1:3],system_specific_facility_gw[1:3],system_specific_facility[1:3], count_total)
   
   # OUTPUT TABLE IN KABLE FORMAT
   kable(count_table, align = c('l','c','c'),  booktabs = T,
         caption = paste("Source Count in ",mb_name$MinorBasin_Name," Minor Basin",sep=""),
         label = paste("source_count_",mb_code,sep=""),
         col.names = c("System Type",
                       "Count with County Estimates","Specific Count")) %>%
      kable_styling(latex_options = latexoptions)  %>%
      pack_rows("Surface Water", 1, 4, hline_before = T, hline_after = F) %>%
      pack_rows("Groundwater", 5, 8, hline_before = T, hline_after = F) %>%
      pack_rows("Total (GW + SW)", 9, 13, hline_before = T, hline_after = F ) %>%
      row_spec(13, bold=T) %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_source_count",file_ext,sep=""))
   
   #---- UNMET DEMAND TABLE -------------------------------------------------------------------------------
   
   unmet30 <- sqldf('SELECT pid,
                           featureid, 
                           propname, 
                           round(runid_11,2) AS runid_11, 
                           round(runid_12,2) AS runid_12, 
                           round(runid_13,2) AS runid_13, 
                           round(runid_15,2) AS runid_15, 
                           round(runid_18,2) AS runid_18,
                           riverseg,
                           substr(riverseg,1,2) AS mb_code
                 from unmet30_raw
                 WHERE hydrocode NOT LIKE "wsp_%"
                 AND riverseg NOT LIKE "%_0000%"
                 ORDER BY mb_code DESC, runid_18 DESC')
   
   
   #filter the 5 runids
   a_unmet30 <- sqldf('SELECT featureid, 
                           propname, 
                           runid_11, 
                           runid_12, 
                           runid_13, 
                           runid_15, 
                           runid_18, 
                           mb_code
                 FROM unmet30')
   
   write.csv(a_unmet30, file = "C:\\Users\\maf95834\\Documents\\R\\a_unmet30.csv", row.names = F)
   
   # #filter >.5 mgd
   # b_unmet30 <- sqldf('SELECT featureid, 
   #                            propname, 
   #                            runid_11, 
   #                            runid_12, 
   #                            runid_13, 
   #                            runid_15, 
   #                            runid_18, 
   #                            mb_code
   #                  FROM unmet30
   #                    WHERE runid_11 > 0.5
   #                    OR runid_12 > 0.5
   #                    OR runid_13 > 0.5
   #                    OR runid_15 > 0.5
   #                    OR runid_18 > 0.5')
   # 
   # write.csv(b_unmet30, file = "C:\\Users\\maf95834\\Documents\\R\\b_unmet30.csv", row.names = F)
   # 
   # #filter >1 mgd
   # c_unmet30 <- sqldf('SELECT featureid, 
   #                            propname, 
   #                            runid_11, 
   #                            runid_12, 
   #                            runid_13, 
   #                            runid_15, 
   #                            runid_18, 
   #                            mb_code
   #                  FROM unmet30
   #                    WHERE runid_11 > 1
   #                    OR runid_12 > 1
   #                    OR runid_13 > 1
   #                    OR runid_15 > 1
   #                    OR runid_18 > 1')
   # 
   # write.csv(c_unmet30, file = "C:\\Users\\maf95834\\Documents\\R\\c_unmet30.csv", row.names = F)
   # 
   # # No Minor Basin
   # 
   # null_unmet30 <- sqldf('SELECT pid,
   #                            featureid, 
   #                            propname, 
   #                            runid_11, 
   #                            runid_12, 
   #                            runid_13, 
   #                            runid_15, 
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
   
   # OUTPUT TABLE IN KABLE FORMAT
   kable(unmet_table[2:7],align = c('l','l','l','l','l','l','c'),  booktabs = T,
         caption = paste("Unmet Demand (MGD) in ",mb_name$MinorBasin_Name," Minor Basin",sep=""),
         label = paste("unmet30_",mb_code,sep=""),
         col.names = c("Facility",
                       "2020 Demand",
                       "2030 Demand",
                       "2040 Demand",
                       "Dry Climate",
                       "Exempt User")) %>%
      #kable_styling(latex_options = latexoptions) %>%
      column_spec(1, width = "7em") %>%
      column_spec(2, width = "4em") %>%
      column_spec(3, width = "4em") %>%
      column_spec(4, width = "4em") %>%
      column_spec(5, width = "4em") %>%
      column_spec(6, width = "3em") %>%
      #footnote(symbol = "This table shows demand values greater than 1.0 MGD.") %>%
      #footnote(c("Footnote Symbol 1; Climate scenarios were not completed in areas located outside of the Chesapeake Bay Basin", "Footnote Symbol 2")) %>%
      footnote(symbol = "Climate scenarios were not completed in areas located outside of the Chesapeake Bay Basin") %>%
      cat(., file = paste(folder,"tables_maps/Xtables/",mb_code,"_unmet30_table",file_ext,sep=""))
   
   
}

### RUN TABLE GENERATION FUNCTION ########################
TABLE_GEN_func(minorbasin = 'PL', file_extension = 'tex')

# call summary table function in for loop to iterate through basins
basins <- c('PS', 'NR', 'YP', 'TU', 'RL', 'OR', 'EL', 'ES', 'PU', 'RU', 'YM', 'JA', 'MN', 'PM', 'YL', 'BS', 'PL', 'OD', 'JU', 'JB', 'JL')
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

