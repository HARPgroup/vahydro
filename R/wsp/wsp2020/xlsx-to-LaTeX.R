library("readxl")
library("kableExtra")
library("sqldf")

# Location of source data
source <- "wsp2020.fac.all.csv"
#source <- "wsp2020.mp.all.csv"
folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"

# Location of GIS_functions and gdb
localpath <-"C:/usr/local/home/git/"
source('https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/GIS_functions.R');
gdb_path <- "hydro-tools/GIS_LAYERS/HUC.gdb" #Location of HUC .gdb
layer_name <- 'WBDHU6' #HUC6 layer withing the HUC .gdb

data_raw <- read.csv(paste(folder,source,sep=""))
data_sp <- data_raw

###########################################################################
# PERFORM SPATIAL CONTAINMENT
data_sp <- data_sp[-which(data_sp$Latitude > 90),]

#RATHER THAN SET THESE TO ZERO, SHOULD SET TO COORDINATES OF COUNTY CENTROID:
#Set NA, -99, or 99 coordinates to 0.0; This step is required for coordinates() function
data_sp$Latitude[is.na(data_sp$Latitude)] = 0.0 
data_sp$Longitude[is.na(data_sp$Longitude)] = 0.0
data_sp$Latitude[data_sp$Latitude == 99] = 0.0
data_sp$Latitude[data_sp$Latitude == -99] = 0.0
data_sp$Longitude[data_sp$Longitude == 99] = 0.0
data_sp$Longitude[data_sp$Longitude == -99] = 0.0

coordinates(data_sp) <- c("Longitude", "Latitude") #sp_contain() requires a coordinates column
data_sp_cont <- sp_contain(paste(localpath,gdb_path,sep=""),layer_name,'all',data_sp)
data_sp_cont <- data.frame(data_sp_cont)
###########################################################################

coverage_name <- "state"
cov_label <- "HUC6"

#Output all watershed options
sqldf('SELECT DISTINCT Poly_Name
      FROM data_sp_cont
      ')

#Select facilities within HUC of interest, Restict output to columns of interest
sql <- '
  SELECT facility_name, 
    facility_ftype,
    fac_2020_mgy, 
    fac_2040_mgy, 
    Poly_Name
  FROM data_sp_cont
  WHERE facility_ftype NOT LIKE \'wsp%\' '
if (coverage_name != 'state') {
  sql <- paste(sql, paste0('WHERE Poly_Name = ' , '\"', coverage_name,'\"') )
}
sql <- paste0(sql,
  'ORDER BY fac_2020_mgy DESC
                  LIMIT 5',
  sep="")
data <- sqldf(sql)


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


# OUTPUT TABLE IN KABLE FORMAT
kable(data, "latex", booktabs = T,
      caption = paste("Top 5 Users in ",coverage_name," HUC 6",sep=""), 
      label = paste("Top5_",coverage_name,sep=""),
      col.names = c("Facility Name",
                    "Facility Type",
                    "2020 (MGY)",
                    "2040 (MGY)",
                    cov_label)) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>% 
  #column_spec(1, width = "5em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/","Top5_",coverage_name,"_kable.tex",sep=""))

###########################################################################

