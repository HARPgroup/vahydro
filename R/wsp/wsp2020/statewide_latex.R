#STATEWIDE 

library("knitr")
library("kableExtra")
#"html" for viewing in Rstudio Viewer pane; "latex" when ready to output to Overleaf
options(knitr.table.format = "html")
library("sqldf")

# Location of source data
#source <- "wsp2020.fac.all.MinorBasins_RSegs.csv"
source <- "wsp2020.mp.all.MinorBasins_RSegs.csv"
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"

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
                      MinorBasin_Name
                  FROM mp_all
                  ORDER BY mp_2020_mgy DESC
              ',sep="")

mps <- sqldf(sql)

#---------------------------------------------------------------#
#Transform
#Demand by System Type 
by_system_type <- sqldf("SELECT wsp_ftype, sum(mp_2020_mgy) AS 'Demand 2020 (MGY)',sum(mp_2030_mgy) AS 'Demand 2030 (MGY)', sum(mp_2040_mgy) AS 'Demand 2040 (MGY)', round(((sum(mp_2040_mgy) - sum(mp_2020_mgy)) / sum(mp_2020_mgy)) * 100,2) AS 'pct_change'
                        FROM mps
                        WHERE facility_ftype NOT LIKE '%power'
                        GROUP BY wsp_ftype
                        ORDER BY pct_change DESC")

# OUTPUT TABLE IN KABLE FORMAT
kable(by_system_type,  booktabs = T,
      caption = "Statewide Withdrawal Demand by System Type (excluding Power Generation)",
      label = "demand_system_type_no_power_statewide",
      col.names = c("System Type",
                    "2020 Demand (MGY)",
                    "2030 Demand (MGY)",
                    "2040 Demand (MGY)",
                    "20 Year Percent Change")) %>%
  kable_styling(latex_options = c("striped", "full_width")) %>%
  #column_spec(1, width = "6em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/statewide/demand_system_type_no_power_kable.tex",sep=""))