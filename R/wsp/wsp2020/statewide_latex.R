#STATEWIDE 
library("knitr")
library("kableExtra")
library("sqldf")

#---------------------INITIALIZE GLOBAL VARIABLES------------------------#
#"html" for viewing in Rstudio Viewer pane; "latex" when ready to output to Overleaf
#options(knitr.table.format = "latex")
options(knitr.table.format = "html")

#Kable Styling
latexoptions <- c("striped","hold_position","scale_down")
width <- T
kable_col_names <- c("",
                     "Type",
                     #"2020 Demand (MGY)",
                     #"2030 Demand (MGY)",
                     #"2040 Demand (MGY)",
                     "2020 Demand (MGD)",
                     "2030 Demand (MGD)",
                     "2040 Demand (MGD)",
                     "20 Year Percent Change")

#switch between file types to save in common drive folder
file_ext <- ".html" #view in R
#file_ext <- ".tex" #for easy upload to Overleaf

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
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
#source <- "wsp2020.fac.all.MinorBasins_RSegs.csv"
source <- "wsp2020.mp.all.MinorBasins_RSegs.csv"

data_raw <- read.csv(paste(folder,source,sep=""))
mp_all <- data_raw

#Select measuring points, Restict output to columns of interest
sql <- paste('SELECT  MP_hydroid,
                      MP_bundle,
                      Facility_hydroid, 
                      facility_name, 
                      facility_ftype,
                      wsp_ftype,
                      mp_2020_mgy,
                      mp_2030_mgy,
                      mp_2040_mgy, 
                      MinorBasin_Name,
                      fips_code,
                      fips_name
                  FROM mp_all
                  ORDER BY mp_2020_mgy DESC
              ',sep="")

mps <- sqldf(sql)

#---------------------------------------------------------------#
#Demand by System Type 
system_sql <- paste('SELECT 
                     wsp_ftype,',
                    aggregate_select,'
                     FROM mps
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
      caption = "Statewide Withdrawal Demand by System Type (excluding Power Generation)",
      label = "demand_system_type_no_power_statewide",
      col.names = kable_col_names) %>%
   kable_styling(latex_options = latexoptions) %>%
  #column_spec(1, width = "6em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/demand_system_type_no_power_kable",file_ext,sep=""))

#---------------------------------------------------------------#
#Demand by System Type 
system_sql <- paste('SELECT 
                     wsp_ftype,',
                    aggregate_select,'
                     FROM mps
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
      caption = "Statewide Withdrawal Demand by System Type (including Power Generation)",
      label = "demand_system_type_yes_power_statewide",
      col.names = kable_col_names) %>%
   kable_styling(latex_options = latexoptions) %>%
  #column_spec(1, width = "6em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/demand_system_type_yes_power_kable",file_ext,sep=""))
#---------------------------------------------------------------#
#Demand by Source Type 
source_sql <- paste('SELECT 
                     MP_bundle,',
                    aggregate_select,'
                     FROM mps
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
      caption = "Withdrawal Demand by Source Type (excluding Power Generation)",
      label = "demand_source_type_no_power_statewide",
      col.names = kable_col_names) %>%
   kable_styling(latex_options = latexoptions) %>%
  #column_spec(1, width = "5em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/demand_source_type_no_power_kable",file_ext,sep=""))


#---------------------------------------------------------------#
#Demand by Source Type 
source_sql <- paste('SELECT 
                     MP_bundle,',
                    aggregate_select,'
                     FROM mps
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
      caption = "Withdrawal Demand by Source Type (including Power Generation)",
      label = "demand_source_type_yes_power_statewide",
      col.names = kable_col_names) %>%
  kable_styling(latex_options = latexoptions) %>%
  #column_spec(1, width = "5em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/demand_source_type_yes_power_kable",file_ext,sep=""))

#---------------------------------------------------------------#
#Transform
#Demand by County 
by_county <- sqldf("SELECT 
fips_code, 
fips_name, 
sum(mp_2020_mgy)/365.25 AS 'MGD_2020',
sum(mp_2030_mgy)/365.25 AS 'MGD_2030', 
sum(mp_2040_mgy)/365.25 AS 'MGD_2040',
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS 'pct_change'
                        FROM mps 
                        GROUP BY fips_code
                        ORDER BY pct_change DESC")
# OUTPUT TABLE IN KABLE FORMAT
kable(by_county[1:6],  booktabs = T,
      caption = "Withdrawal Demand by Locality",
      label = "demand_locality_statewide",
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
  cat(., file = paste(folder,"kable_tables/statewide/demand_locality_statewide_kable",file_ext,sep=""))
#---------------------------------------------------------------#

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
                    "Count of Sources",
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


#---------------------------------------------------------------#

#Demand by System & Source Type with count
system_source_sql <- paste('SELECT 
                     wsp_ftype, MP_bundle, count(MP_hydroid) AS sources,',
                    aggregate_select,'
                     FROM mps
                     GROUP BY wsp_ftype, MP_bundle', sep="")

system_source <- sqldf(system_source_sql)
#calculate columns sums 
totals <- as.data.frame(lapply(system_source[1:6], totals_func),stringsAsFactors = F)
#calculate total percentage change
totals <- sqldf("SELECT *, 
round(((sum(MGD_2040) - sum(MGD_2020)) / sum(MGD_2020)) * 100,2) AS 'pct_change'
      FROM totals")
#append totals to table
system_source <- rbind(cbind(' '=' ', system_source),
                        cbind(' '='Total', totals))

# OUTPUT TABLE IN KABLE FORMAT
kable(system_source,  booktabs = T,
      caption = "Statewide Withdrawal Demand by System and Source Type (including Power Generation)",
      label = "demand_system_source_yes_power_statewide",
      col.names = c("",
                    "System Type",
                    "Source Type",
                    "Count of Sources",
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
  cat(., file = paste(folder,"kable_tables/statewide/demand_system_source_yes_power_kable",file_ext,sep=""))
#---------------------------------------------------------------#

#SSU Demand by County 
by_ssu_county <- sqldf("SELECT 
fips_code, 
fips_name, a.MP_bundle,
sum(mp_2020_mgy)/365.25 AS 'MGD_2020',
sum(mp_2030_mgy)/365.25 AS 'MGD_2030', 
sum(mp_2040_mgy)/365.25 AS 'MGD_2040',
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS 'pct_change'
                        FROM mps
                        where wsp_ftype like '%ssusm'
                        GROUP BY fips_code, MP_bundle
                        ORDER BY pct_change DESC")

write.csv(by_ssu_county, paste(folder,"ssu_county.csv", sep=""))

# OUTPUT TABLE IN KABLE FORMAT
kable(by_ssu_county[1:6],  booktabs = T,
      caption = "Small Self-Supplied Users Withdrawal Demand by Locality",
      label = "demand_ssu_locality_statewide",
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
  cat(., file = paste(folder,"kable_tables/statewide/demand_ssu_locality_statewide_kable",file_ext,sep=""))

#---------------------------------------------------------------#
#POWERPOINT PRESENTATION BRIEFING
by_county_source <- sqldf("SELECT 
fips_code, 
fips_name, MP_bundle,
sum(mp_2020_mgy)/365.25 AS 'MGD_2020',
sum(mp_2030_mgy)/365.25 AS 'MGD_2030', 
sum(mp_2040_mgy)/365.25 AS 'MGD_2040',
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS 'pct_change'
                        FROM mps 
                        WHERE facility_ftype NOT LIKE '%power'
                        GROUP BY fips_code, MP_bundle
                        ORDER BY pct_change DESC")
write.csv(by_county_source, paste(folder,"county_source_type_demand_no_power.csv", sep=""))

#Tidal vs. Non-tidal
tidal_vs_nontidal_power <- sqldf("SELECT *
                    FROM mp_all
                     WHERE facility_ftype LIKE '%power'
                      AND MP_bundle = 'intake'
                      AND VAHydro_RSeg_Code LIKE '%_0000' ")
write.csv(tidal_vs_nontidal_power, paste(folder,"tidal_vs_nontidal_power.csv", sep=""))
#---------------------------------------------------------------#

#Transform
#permitted vs. unpermitted by source type

