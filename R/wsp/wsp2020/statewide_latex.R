#STATEWIDE 

library("knitr")
library("kableExtra")
#"html" for viewing in Rstudio Viewer pane; "latex" when ready to output to Overleaf
options(knitr.table.format = "latex")
#options(knitr.table.format = "html")
latexoptions <- c("striped")
width <- T
library("sqldf")

#totals function which allows us to append column sums to table to generate in kable
totals_func <- function(z) if (is.numeric(z)) sum(z) else ''

# Location of source data
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
#source <- "wsp2020.fac.all.MinorBasins_RSegs.csv"
source <- "wsp2020.mp.all.MinorBasins_RSegs.csv"
fips_source <- "fips_codes.csv"
fips_codes <- read.csv(paste(folder,fips_source,sep=""))

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
                      fips_code
                  FROM mp_all
                  ORDER BY mp_2020_mgy DESC
              ',sep="")

mps <- sqldf(sql)

#---------------------------------------------------------------#
#Transform
#Demand by System Type 
by_system_type <- sqldf("SELECT 
wsp_ftype, 
sum(mp_2020_mgy) AS 'MGY_2020',
sum(mp_2030_mgy) AS 'MGY_2030', 
sum(mp_2040_mgy) AS 'MGY_2040', 
sum(mp_2020_mgy)/365.25 AS 'MGD_2020',
sum(mp_2030_mgy)/365.25 AS 'MGD_2030', 
sum(mp_2040_mgy)/365.25 AS 'MGD_2040',
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS 'pct_change'
                        FROM mps
                        WHERE facility_ftype NOT LIKE '%power'
                        GROUP BY wsp_ftype
                        ORDER BY pct_change DESC")

#calculate columns sums 
totals <- as.data.frame(lapply(by_system_type[1:7], totals_func),stringsAsFactors = F)
#calculate total percentage change
totals<- sqldf("SELECT *, 
round(((sum(MGY_2040) - sum(MGY_2020)) / sum(MGY_2020)) * 100,2) AS 'pct_change'
      FROM totals")
#append totals to table
by_system_type <- rbind(cbind(' '=' ', by_system_type),
                        cbind(' '='Total', totals))


# OUTPUT TABLE IN KABLE FORMAT
kable(by_system_type,  booktabs = T,
      caption = "Statewide Withdrawal Demand by System Type (excluding Power Generation)",
      label = "demand_system_type_no_power_statewide",
      col.names = c("",
                    "System Type",
                    "2020 Demand (MGY)",
                    "2030 Demand (MGY)",
                    "2040 Demand (MGY)",
                    "2020 Demand (MGD)",
                    "2030 Demand (MGD)",
                    "2040 Demand (MGD)",
                    "20 Year Percent Change")) %>%
   kable_styling(latex_options = latexoptions, full_width = width) %>%
  #column_spec(1, width = "6em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/demand_system_type_no_power_kable.tex",sep=""))

#---------------------------------------------------------------#
by_system_type <- sqldf("SELECT 
wsp_ftype, 
sum(mp_2020_mgy) AS 'MGY_2020',
sum(mp_2030_mgy) AS 'MGY_2030', 
sum(mp_2040_mgy) AS 'MGY_2040', 
sum(mp_2020_mgy)/365.25 AS 'MGD_2020',
sum(mp_2030_mgy)/365.25 AS 'MGD_2030', 
sum(mp_2040_mgy)/365.25 AS 'MGD_2040',
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS 'pct_change'
                        FROM mps
                        GROUP BY wsp_ftype
                        ORDER BY pct_change DESC")

#calculate columns sums 
totals <- as.data.frame(lapply(by_system_type[1:7], totals_func),stringsAsFactors = F)
#calculate total percentage change
totals<- sqldf("SELECT *, 
round(((sum(MGY_2040) - sum(MGY_2020)) / sum(MGY_2020)) * 100,2) AS 'pct_change'
      FROM totals")
#append totals to table
by_system_type <- rbind(cbind(' '=' ', by_system_type),
                        cbind(' '='Total', totals))

# OUTPUT TABLE IN KABLE FORMAT
kable(by_system_type,  booktabs = T,
      caption = "Statewide Withdrawal Demand by System Type (including Power Generation)",
      label = "demand_system_type_yes_power_statewide",
      col.names = c("",
                    "System Type",
                    "2020 Demand (MGY)",
                    "2030 Demand (MGY)",
                    "2040 Demand (MGY)",
                    "2020 Demand (MGD)",
                    "2030 Demand (MGD)",
                    "2040 Demand (MGD)",
                    "20 Year Percent Change")) %>%
   kable_styling(latex_options = latexoptions, full_width = width) %>%
  #column_spec(1, width = "6em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/demand_system_type_yes_power_kable.tex",sep=""))
#---------------------------------------------------------------#

#Transform
#Demand by Source Type 
by_source_type <- sqldf("SELECT 
MP_bundle, 
sum(mp_2020_mgy) AS 'MGY_2020',
sum(mp_2030_mgy) AS 'MGY_2030', 
sum(mp_2040_mgy) AS 'MGY_2040', 
sum(mp_2020_mgy)/365.25 AS 'MGD_2020',
sum(mp_2030_mgy)/365.25 AS 'MGD_2030', 
sum(mp_2040_mgy)/365.25 AS 'MGD_2040',
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS 'pct_change'
                        FROM mps
                        WHERE facility_ftype NOT LIKE '%power'
                        GROUP BY MP_bundle
                        ORDER BY pct_change DESC")

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
      caption = "Withdrawal Demand by Source Type (excluding Power Generation)",
      label = "demand_source_type_no_power_statewide",
      col.names = c("",
                    "Source Type",
                    "2020 Demand (MGY)",
                    "2030 Demand (MGY)",
                    "2040 Demand (MGY)",
                    "2020 Demand (MGD)",
                    "2030 Demand (MGD)",
                    "2040 Demand (MGD)",
                    "20 Year Percent Change")) %>%
   kable_styling(latex_options = latexoptions, full_width = width) %>%
  #column_spec(1, width = "5em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/demand_source_type_no_power_kable.tex",sep=""))


#---------------------------------------------------------------#

#Transform
#Demand by Source Type 
by_source_type <- sqldf("SELECT 
MP_bundle, 
sum(mp_2020_mgy) AS 'MGY_2020',
sum(mp_2030_mgy) AS 'MGY_2030', 
sum(mp_2040_mgy) AS 'MGY_2040', 
sum(mp_2020_mgy)/365.25 AS 'MGD_2020',
sum(mp_2030_mgy)/365.25 AS 'MGD_2030', 
sum(mp_2040_mgy)/365.25 AS 'MGD_2040',
round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS 'pct_change'
                        FROM mps
                        GROUP BY MP_bundle
                        ORDER BY pct_change DESC")
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
      caption = "Withdrawal Demand by Source Type (including Power Generation)",
      label = "demand_source_type_yes_power_statewide",
      col.names = c("",
                    "Source Type",
                    "2020 Demand (MGY)",
                    "2030 Demand (MGY)",
                    "2040 Demand (MGY)",
                    "2020 Demand (MGD)",
                    "2030 Demand (MGD)",
                    "2040 Demand (MGD)",
                    "20 Year Percent Change")) %>%
  kable_styling(latex_options = latexoptions, full_width = width) %>%
  #column_spec(1, width = "5em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/demand_source_type_yes_power_kable.tex",sep=""))

#---------------------------------------------------------------#
#Transform
#Demand by County 
by_county <- sqldf("SELECT 
b.code, 
b.name, 
sum(a.mp_2020_mgy) AS 'MGY_2020',
sum(a.mp_2030_mgy) AS 'MGY_2030', 
sum(a.mp_2040_mgy) AS 'MGY_2040', 
sum(a.mp_2020_mgy)/365.25 AS 'MGD_2020',
sum(a.mp_2030_mgy)/365.25 AS 'MGD_2030', 
sum(a.mp_2040_mgy)/365.25 AS 'MGD_2040',
round(((sum(a.mp_2040_mgy) - sum(a.mp_2020_mgy)) / sum(a.mp_2020_mgy)) * 100,2) AS 'pct_change'
                        FROM fips_codes b
                        LEFT OUTER JOIN mps a 
                        ON a.fips_code = b.code
                        GROUP BY a.fips_code
                        ORDER BY pct_change DESC")

# OUTPUT TABLE IN KABLE FORMAT
kable(by_county[1:9],  booktabs = T,
      caption = "Withdrawal Demand by Locality",
      label = "demand_locality_statewide",
      col.names = c("Fips Code",
                    "Locality",
                    "2020 Demand (MGY)",
                    "2030 Demand (MGY)",
                    "2040 Demand (MGY)",
                    "2020 Demand (MGD)",
                    "2030 Demand (MGD)",
                    "2040 Demand (MGD)",
                    "20 Year Percent Change")) %>%
  kable_styling(latex_options = latexoptions, full_width = width) %>%
  #column_spec(1, width = "5em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/demand_locality_statewide_kable.tex",sep=""))
#---------------------------------------------------------------#

#Transform
#SSU demand vs. permitted amounts

#---------------------------------------------------------------#

#Transform
#SSU demand vs. inside/outside GWMA

#---------------------------------------------------------------#

#Transform
#permitted vs. unpermitted by source type

