library("readxl")
library("kableExtra")
library("sqldf")

# Location of source data
source <- "wsp2020.fac.all.csv"
#source <- "wsp2020.mp.all.csv"
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"

# Location of GIS_functions and gdb
localpath <-"C:/Users/nrf46657/Desktop/VAHydro Development/GitHub/"
source(paste(localpath,'hydro-tools/GIS_LAYERS','GIS_functions.R',sep='/'));

gdb_path <- "hydro-tools/GIS_LAYERS/HUC.gdb" #Location of HUC .gdb
layer_name <- 'WBDHU6' #HUC6 layer withing the HUC .gdb
#HUC6_code <- '020700'
HUC6_code <- 'all'


data_raw <- read.csv(paste(folder,source,sep=""))
data_sp <- data_raw

###########################################################################
# PERFORM SPATIAL CONTAINMENT
data_sp <- data_sp[-which(data_sp$Latitude > 90),]

#Set NA, -99, or 99 coordinates to 0.0; This step is required for coordinates() function
data_sp$Latitude[is.na(data_sp$Latitude)] = 0.0 #-9999 
data_sp$Longitude[is.na(data_sp$Longitude)] = 0.0
data_sp$Latitude[data_sp$Latitude == 99] = 0.0
data_sp$Latitude[data_sp$Latitude == -99] = 0.0
data_sp$Longitude[data_sp$Longitude == 99] = 0.0
data_sp$Longitude[data_sp$Longitude == -99] = 0.0

coordinates(data_sp) <- c("Longitude", "Latitude") #sp_contain() requires a coordinates column

data_sp_cont <- sp_contain(paste(localpath,gdb_path,sep=""),layer_name,HUC6_code,data_sp)
data_sp_cont <- data.frame(data_sp_cont)
###########################################################################


#Select only Potomac facilities, Restict output to columns of interest
data <- sqldf('SELECT facility_name, 
                      facility_ftype, 
                      fac_2020_mgy, 
                      fac_2040_mgy, 
                      Poly_Name
                  FROM data_sp_cont 
                  WHERE Poly_Name = "Potomac"
                  ORDER BY fac_2020_mgy DESC
                  LIMIT 5
              ')


# OUTPUT TABLE IN KABLE FORMAT
kable(data, "latex", booktabs = T,
      caption = "Top 5 Users in Potomac HUC 6", 
      label = "Top5_Potomac",
      col.names = c("Facility Name",
                    "Facility Type",
                    "2020 (MGY)",
                    "2040 (MGY)",
                    "HUC6")) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>% 
  #column_spec(1, width = "5em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/","Top5_Potomac","_kable.tex",sep=""))

###########################################################################

