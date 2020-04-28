#library("knitr")
library("kableExtra")
library("sqldf")

#---------------------INITIALIZE GLOBAL VARIABLES------------------------#
#change minor basin code
minorbasin <- "PS" #PS, NR, YP, TU, RL, OR, EL, ES, PU, RU, YM, JA, MN, PM, YL, BS, PL, OD, JU, JB, JL
#mb_name <- "Potomac Shenandoah"

#switch between file types to save in common drive folder; html or latex

options(knitr.table.format = "html") #"html" for viewing in Rstudio Viewer pane
file_ext <- ".html" #view in R

#options(knitr.table.format = "latex") #"latex" when ready to output to Overleaf
#file_ext <- ".tex" #for easy upload to Overleaf

#Kable Styling
latexoptions <- c("scale_down")

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
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS pct_change'

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

#--------------------------------LOAD DATA-------------------------------#
basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
#folder <- "C:/Users/maf95834/Documents/vpn_connection_down_folder/" #JM use when vpn can't connect to common drive

data_raw <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))
mp_all <- data_raw

########################### CHOOSE A MINOR BASIN ##############################
#Output all Minor Basin options
mb_options <- sqldf('SELECT DISTINCT MinorBasin_Name, MinorBasin_Code
      FROM mp_all
      ')
#select minor basin code to know folder to save in
mb_code <- sqldf(paste('SELECT MinorBasin_Code
                   From mb_options
                   WHERE MinorBasin_Code = ','\"',minorbasin,'\"','
              ',sep=""))
mb_name <- sqldf(paste('SELECT MinorBasin_Name
                   From mb_options
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

write.csv(mb_mps, paste(folder,"kable_tables/",mb_name,"/all_mps_",mb_code,".csv", sep=""))

#---------------------------------------------------------------#
# ## select MPs with no minor basin
# null_minorbasin <- sqldf("SELECT *
#       FROM mp_all
#       WHERE MinorBasin_Name IS NULL")
# write.csv(null_minorbasin, paste(folder,"/null_minorbasin_mp.csv", sep=""))

#---------------------------------------------------------------#
#All Minor Basins in a single table for comparison (including power generation)
mb_totals_sql <- paste('SELECT 
                     MinorBasin_Name,',
                       aggregate_select,'
                     FROM mp_all
                     GROUP BY MinorBasin_Name', sep="")
mb_totals_yes_power <- sqldf(mb_totals_sql)

# OUTPUT TABLE IN KABLE FORMAT
kable(mb_totals_yes_power,  booktabs = T,
      caption = "All Minor Basins Withdrawal Demand (including Power Generation)",
      label = "mb_totals_yes_power",
      col.names = c("Minor Basin",kable_col_names[3:6])) %>%
   kable_styling(latex_options = latexoptions) %>%
   cat(., file = paste(folder,"kable_tables/mb_totals_yes_power_kable",file_ext,sep=""))



mb_totals_system_sql <- paste('SELECT  
                     MinorBasin_Name,system_type,',
                       aggregate_select,'
                     FROM mp_all
                     GROUP BY MinorBasin_Name, system_type', sep="")
mb_totals_system_yes_power <- sqldf(mb_totals_system_sql)

# OUTPUT TABLE IN KABLE FORMAT
kable(mb_totals_system_yes_power,  booktabs = T,
      caption = "All Minor Basins Withdrawal Demand by System (including Power Generation)",
      label = "mb_totals_system_yes_power",
      col.names = c("Minor Basin",kable_col_names[2:6])) %>%
   kable_styling(latex_options = latexoptions) %>%
   cat(., file = paste(folder,"kable_tables/mb_totals_system_yes_power_kable",file_ext,sep=""))

mb_totals_source_sql <- paste('SELECT 
                     MinorBasin_Name, source_type,',
                       aggregate_select,'
                     FROM mp_all
                     GROUP BY MinorBasin_Name, source_type', sep="")
mb_totals_source_yes_power <- sqldf(mb_totals_source_sql)
# OUTPUT TABLE IN KABLE FORMAT
kable(mb_totals_source_yes_power,  booktabs = T,
      caption = "All Minor Basins Withdrawal Demand by Source (including Power Generation)",
      label = "mb_totals_source_yes_power",
      col.names = c("Minor Basin","Source Type",kable_col_names[3:6])) %>%
   kable_styling(latex_options = latexoptions) %>%
   cat(., file = paste(folder,"kable_tables/mb_totals_source_yes_power_kable",file_ext,sep=""))

#---------------------------------------------------------------#
#All Minor Basins in a single table for comparison (excluding power generation)
mb_totals_sql <- paste('SELECT 
                     MinorBasin_Name,',
                       aggregate_select,'
                     FROM mp_all
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY MinorBasin_Name', sep="")
mb_totals_no_power <- sqldf(mb_totals_sql)

# OUTPUT TABLE IN KABLE FORMAT
kable(mb_totals_no_power,  booktabs = T,
      caption = "All Minor Basins Withdrawal Demand (excluding Power Generation)",
      label = "mb_totals_no_power",
      col.names = c("Minor Basin",kable_col_names[3:6])) %>%
   kable_styling(latex_options = latexoptions) %>%
   cat(., file = paste(folder,"kable_tables/mb_totals_no_power_kable",file_ext,sep=""))

mb_totals_system_sql <- paste('SELECT  
                     MinorBasin_Name,system_type,',
                              aggregate_select,'
                     FROM mp_all
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY MinorBasin_Name, system_type', sep="")
mb_totals_system_no_power <- sqldf(mb_totals_system_sql)

# OUTPUT TABLE IN KABLE FORMAT
kable(mb_totals_system_no_power,  booktabs = T,
      caption = "All Minor Basins Withdrawal Demand by System (excluding Power Generation)",
      label = "mb_totals_system_no_power",
      col.names = c("Minor Basin",kable_col_names[2:6])) %>%
   kable_styling(latex_options = latexoptions) %>%
   cat(., file = paste(folder,"kable_tables/mb_totals_system_no_power_kable",file_ext,sep=""))

mb_totals_source_sql <- paste('SELECT 
                     MinorBasin_Name, source_type,',
                              aggregate_select,'
                     FROM mp_all
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY MinorBasin_Name, source_type', sep="")
mb_totals_source_no_power <- sqldf(mb_totals_source_sql)
# OUTPUT TABLE IN KABLE FORMAT
kable(mb_totals_source_no_power,  booktabs = T,
      caption = "All Minor Basins Withdrawal Demand by Source (excluding Power Generation)",
      label = "mb_totals_source_no_power",
      col.names = c("Minor Basin","Source Type",kable_col_names[3:6])) %>%
   kable_styling(latex_options = latexoptions) %>%
   cat(., file = paste(folder,"kable_tables/mb_totals_source_no_power_kable",file_ext,sep=""))
#---------------------------------------------------------------#
#SINGLE BASIN SUMMARIES

#Demand by System Type 
system_sql <- paste('SELECT 
                     system_type,',
                     aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY wsp_ftype', sep="")

by_system_type <- sqldf(system_sql)
   
by_system_type <- append_totals(by_system_type)

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
 
by_system_type <- append_totals(by_system_type)

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

 #Demand by Source Type 
 source_sql <- paste('SELECT 
                     source_type,',
                     aggregate_select,'
                     FROM mb_mps
                     WHERE facility_ftype NOT LIKE "%power"
                     GROUP BY MP_bundle', sep="")
 
 by_source_type <- sqldf(source_sql)
 
 by_source_type <- append_totals(by_source_type)
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_source_type,  booktabs = T,
       caption = paste("Withdrawal Demand by Source Type (excluding Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demand_source_type_no_power_",mb_abbrev,sep=""),
       col.names = c("","Source Type",kable_col_names[3:6])) %>%
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
 
 by_source_type <- append_totals(by_source_type)
 
 # OUTPUT TABLE IN KABLE FORMAT
 kable(by_source_type,  booktabs = T,
       caption = paste("Withdrawal Demand by Source Type (including Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demand_source_type_yes_power_",mb_abbrev,sep=""),
       col.names = c("","Source Type",kable_col_names[3:6])) %>%
     kable_styling(latex_options = latexoptions) %>%
   #column_spec(1, width = "5em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demand_source_type_yes_power_",mb_abbrev,"_kable",file_ext,sep=""))
 
############################################################################
 #GRAPH
 #Demand by System & Source Type with count
 system_source_sql <- paste('SELECT 
                     system_type, source_type,',
                            aggregate_select,'
                     FROM mb_mps
                     GROUP BY wsp_ftype, MP_bundle', sep="")
 
 system_source <- sqldf(system_source_sql)
 
#####################################################
 #  #BAR GRAPH
#  e <- system_source[1:6]
#  e[6] <- system_source[6] / 2
#  e <- melt(e, id=c("system_type","source_type"))
#  
# v1 <- ggplot(e, aes(x = source_type, y = value, fill =  system_type)) + 
#     geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
#     theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom", legend.title = element_text(size = 9), legend.key.width = unit(.3, "cm")) +
#     xlab(label = element_blank())  +
#     labs(title = paste(mb_name," Minor Basin",sep=""), subtitle = "Withdrawal Demand by System and Source Type", fill = "System Type: ", caption = "*Agriculture and Large Self-Supplied User systems predict 0% change in demand") +
#     facet_grid(~ variable,
#                labeller = as_labeller( # redefine the text that shows up for the facets
#                   c(MGD_2020 = "Total 2020 Demand", MGD_2030 = "Total 2030 Demand", MGD_2040 = "Total 2040 Demand", pct_change = "Demand Change"))) +
#     scale_y_continuous(name = "MGD", 
#                        sec.axis = sec_axis(~ . * 2 , name = "Percent Change (%)")) +
#     
#     ggsave(path = paste(folder,"kable_tables/",mb_name,"/", sep=""),filename = paste("demand_system_source_",mb_abbrev,"_v1_graph.png",sep=""))
#  
# #BAR GRAPH GW VS. SW
# v2 <- ggplot(e, aes(x = system_type, y = value, fill = variable )) + 
#     geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
#     theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), legend.position = "bottom", legend.title = element_text(size = 10)) +
#     xlab(label = element_blank())  +
#     labs(title = paste(mb_name," Minor Basin",sep=""), subtitle = "Water Withdrawal Demand by System", fill = "Demand: ", caption = "*Agriculture and Large Self-Supplied User systems predict 0% change in demand") +
#     facet_grid(~ source_type) +
#    scale_fill_discrete(labels = c("2020","2030","2040","Change")) +
#     scale_y_continuous(name = "MGD",
#                        sec.axis = sec_axis(~ . * 2 , name = "Percent Change (%)")) +
#     
#     ggsave(path = paste(folder,"kable_tables/",mb_name,"/", sep=""),filename = paste("demand_system_source_",mb_abbrev,"_v2_graph.png",sep=""))
# 
# 
# #LINE GRAPH 
# 
# e <- system_source[1:6]
# e <- melt(e, id=c("system_type","source_type", "pct_change"))
# e[e == 0] <- NA
# h <- sqldf("SELECT *,
#             ( select CASE
#             WHEN pct_change IS NOT NULL
#             THEN round(pct_change,1) || '%'
#             ELSE pct_change IS NULL
#             END
#             FROM e
#             WHERE variable LIKE '%2040%'
#             AND system_type = a.system_type
#             AND source_type = a.source_type
#             AND variable = a.variable) as pct_change2
#             FROM e as a
#             ")
# h$pct_change2 <- na_if(h$pct_change2,1)
# 
# g <- ggplot(data=h, aes(x=variable, y=value, group=system_type,colour = system_type, label = pct_change2))  +
#    geom_line(size = 1.6) +
#    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 11), legend.position = "bottom", legend.title = element_text(size = 9)) +
#    xlab(label = element_blank())  +
#    labs(title = paste(mb_name," Minor Basin",sep=""), subtitle = "Water Withdrawal Demand by System", colour = "System: ", caption = "*Agriculture and Large Self-Supplied User systems predict 0% change in demand") +
#    facet_grid(~ source_type) +
#    scale_x_discrete(labels = c("2020","2030","2040")) +
#    scale_y_continuous(name = "MGD") +
#    geom_text(show.legend = F, check_overlap = F, nudge_y = 1.4, nudge_x = -.3, na.rm = T) +
#    
#  guides(colour = guide_legend(ncol = 2, byrow = TRUE)) +
# 
#     ggsave(path = paste(folder,"kable_tables/",mb_name,"/", sep=""),filename = paste("demand_system_source_",mb_abbrev,"_line_graph.png",sep=""))
########################################################
 
#BAR GRAPH V3 - with percent change line and label
e <- system_source[1:6]
e <- melt(e, id=c("system_type","source_type", "pct_change"))
e[e == 0] <- NA
h <- sqldf("SELECT *,
            ( select CASE
            WHEN pct_change IS NOT NULL
            THEN round(pct_change,1) || '%'
            ELSE pct_change IS NULL
            END
            FROM e
            WHERE variable LIKE '%2040%'
            AND system_type = a.system_type
            AND source_type = a.source_type
            AND variable = a.variable) as pct_change2
            FROM e as a
            ")
h$pct_change2 <-if_else(h$pct_change2 == 1, "0%",h$pct_change2)

v3 <- ggplot(h, aes(x = system_type, y = value, fill = variable, label = pct_change2)) + 
   geom_bar(position= position_dodge2(preserve = "single"), stat="identity") +
   theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8), legend.position = "bottom", legend.title = element_text(size = 10)) +
   xlab(label = element_blank())  +
   labs(title = paste(mb_name," Minor Basin",sep=""), subtitle = "Water Withdrawal Demand by System", fill = "Demand: "
#        , caption = "*Agriculture and Large Self-Supplied User systems predict 0% change in demand"
        ) +
   facet_grid(~ source_type) +
   scale_fill_discrete(labels = c("2020","2030","2040")) +
   scale_y_continuous(name = "MGD") +
   geom_text(show.legend = F, check_overlap = F, nudge_y = 2, na.rm = T) +
   
   ggsave(path = paste(folder,"kable_tables/",mb_name,"/", sep=""),filename = paste("demand_system_source_",mb_abbrev,"_v3_graph.png",sep=""))

system_source <- append_totals(system_source)

 # OUTPUT TABLE IN KABLE FORMAT
 kable(system_source,  booktabs = T,
       caption = paste("Withdrawal Demand by System and Source Type (including Power Generation) in ",mb_name," Minor Basin",sep=""),
       label = paste("demand_source_type_no_power_",mb_abbrev,sep=""),
       col.names = c("","System Type","Source Type",kable_col_names[3:6])) %>%
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
                     "Locality",kable_col_names[3:6])) %>%
    kable_styling(latex_options = latexoptions) %>%
    #column_spec(1, width = "5em") %>%
    #column_spec(2, width = "5em") %>%
    #column_spec(3, width = "5em") %>%
    #column_spec(4, width = "4em") %>%
    cat(., file = paste(folder,"kable_tables/",mb_name,"/demand_locality_",mb_abbrev,"_kable",file_ext,sep=""))
############################################################################
 if (mb_abbrev == 'PS') {
    hanover_mps <- sqldf("SELECT *
                           FROM mb_mps
                           WHERE fips_name like '%hanover'")
    hanover_mps$fips_code <- '51171'
    hanover_mps$fips_name <- 'Shenandoah'
    no_hanover <- sqldf("SELECT *
                           FROM mb_mps
                           WHERE fips_name not like '%hanover'")
    ps_mb_mps <- sqldf("SELECT *
                     from hanover_mps 
                    UNION  Select * from no_hanover
                    ")
    by_county_source_sql <- paste('SELECT 
                     fips_code,
                     fips_name,
                     source_type,
                     ',aggregate_select,'
                     FROM ps_mb_mps
                     GROUP BY fips_code, MP_bundle
                     ORDER BY fips_code, MP_bundle DESC', sep="")
    by_county_source <- sqldf(by_county_source_sql)
 } else {
  by_county_source_sql <- paste('SELECT 
                     fips_code,
                     fips_name,
                     source_type,
                     ',aggregate_select,'
                     FROM mb_mps
                     GROUP BY fips_code, MP_bundle
                     ORDER BY fips_code, MP_bundle DESC', sep="")
 by_county_source <- sqldf(by_county_source_sql)   
    
 }

 write.csv(by_county_source, paste(folder,"kable_tables/",mb_name,"/county_source_type_demand_",mb_abbrev,".csv", sep=""))
 
 kable(by_county_source[1:7],  booktabs = T,
       caption = paste("GW vs. SW Withdrawal Demand by Locality in ",mb_name," Minor Basin",sep=""),
       label = paste("demand_locality_by_source",mb_abbrev,sep=""),
       col.names = c("Fips Code",
                     "Locality",
                     "Source Type",kable_col_names[3:6])) %>%
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
      caption = paste("Withdrawal Demand by System and Source Type in ",mb_name," Minor Basin",sep=""),
      label = paste("demand_system_source_specific_count",mb_abbrev,sep=""),
      col.names = c("",
                    "System Type",
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
   #column_spec(1, width = "6em") %>%
   #column_spec(2, width = "5em") %>%
   #column_spec(3, width = "5em") %>%
   #column_spec(4, width = "4em") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/demand_system_source_with_count_",mb_abbrev,"_kable",file_ext,sep=""))

############################################################################
 #Top 5 Users by Source Type
top_5_gw_sql <- paste('SELECT facility_name, system_type, 
               ',aggregate_select,',
               round(((sum(mp_2040_mgy)/365.25) /
               (SELECT (sum(mp_2040_mgy)/365.25)
                     FROM mb_mps
                     )) * 100,2) as pct_total_use
               ,fips_name
               FROM mb_mps
               WHERE MP_bundle = "well"
               AND wsp_ftype NOT LIKE "%ssusm"
               GROUP BY Facility_hydroid
               ORDER BY MGD_2040 DESC
               LIMIT 5', sep="")

top_5_gw <- sqldf(top_5_gw_sql)

top_5_gw <- append_totals(top_5_gw)

top_5_sw_sql <- paste('SELECT facility_name, system_type, 
               ',aggregate_select,',
               round(((sum(mp_2040_mgy)/365.25) /
               (SELECT (sum(mp_2040_mgy)/365.25)
                     FROM mb_mps
                     )) * 100,2) as pct_total_use
               ,fips_name
               FROM mb_mps
               WHERE MP_bundle = "intake"
               AND wsp_ftype NOT LIKE "%ssusm"
               GROUP BY Facility_hydroid
               ORDER BY MGD_2040 DESC
               LIMIT 5', sep="")

top_5_sw <- sqldf(top_5_sw_sql)

top_5_sw <- append_totals(top_5_sw)

sw_header <- cbind(' '='Surface Water', 
                   data.frame("facility_name" = '',
                           "system_type" = '',
                           "MGD_2020" = '',
                           "MGD_2030" ='',
                           "MGD_2040" ='',
                           "pct_change" = '',
                           "pct_total_use" = '% of Total Surface Water',
                           "fips_name" = ''))

top_5 <- rbind(top_5_gw, sw_header, top_5_sw)

top_5[1] <- c('A','B','C','D','E','Total','Surface Water','F','G','H','I','J','Total')

# #initcaps attempt
# sqldf("SELECT upper(substr(facility_name, 1,1)) || lower(substr(facility_name, 2)) as name
#                   from top_5_sw
#                   WHERE facility_name > 0")

# OUTPUT TABLE IN KABLE FORMAT
kable(top_5[1:6],align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
      caption = paste("Top 5 Users by Source Type in ",mb_name," Minor Basin",sep=""),
      label = paste("top_5_",mb_abbrev,sep=""),
      col.names = c("",
                    "Facility Name",
                    "System Type",
                    kable_col_names[3:6],
                    "% of Total Groundwater",
                    "Locality")) %>%
   kable_styling(latex_options = latexoptions) %>%
   column_spec(2, width = "10em") %>%
   pack_rows("Groundwater", 1, 6) %>%
   pack_rows(" ", 7, 13, label_row_css = FALSE, latex_gap_space = "2em") %>%
   #horizontal solid line depending on html or latex output
   row_spec(7, bold=T, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/Top_5_",mb_abbrev,"_kable",file_ext,sep=""))


top_5[2] <- c('Merck & Co Elkton Plant','Rockingham Co. Three Springs','Augusta Co. Service Authority','The Lycra Company','Town of Dayton','','','City of Winchester','City of Staunton WTP','City of Harrisonburg WTP','Frederick County Sanitation','Town of Front Royal WTP','')
#presentation table
# OUTPUT TABLE IN KABLE FORMAT
kable(top_5,align = c('l','l','l','c','c','c','c','c','l'),  booktabs = T,
      caption = "",
      label = paste("top_5_",mb_abbrev,sep=""),
      col.names = c("",
                    "Organization Name",
                    "System Type",
                    kable_col_names[3:6],
                    "% of Total Groundwater",
                    "Locality")) %>%
   kable_styling(latex_options = latexoptions) %>%
   column_spec(2, width = "10em") %>%
   pack_rows("Groundwater", 1, 6) %>%
   pack_rows(" ", 7, 13, label_row_css = FALSE, latex_gap_space = "2em") %>%
   #horizontal solid line depending on html or latex output
   row_spec(7, bold=T, hline_after = T, extra_css = "border-bottom: 1px solid") %>%
   cat(., file = paste(folder,"kable_tables/",mb_name,"/PPT_Top_5_",mb_abbrev,"_kable",file_ext,sep=""))

############################################################################