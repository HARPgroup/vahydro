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

###gdb_path <- "hydro-tools/GIS_LAYERS/HUC.gdb" #Location of HUC .gdb
###layer_name <- 'WBDHU6' #HUC6 layer withing the HUC .gdb


gdb_path <- "hydro-tools/GIS_LAYERS/WBD.gdb"
layer_name <- 'WBDHU10' 

fips_centroids <- read.csv(paste("https://deq1.bse.vt.edu/d.dh/usafips_centroid_export",sep=""))



data_raw <- read.csv(paste(folder,source,sep=""))
data_sp <- data_raw

###########################################################################
# join fips centroids 
fips_join <- paste("SELECT *
                  FROM data_sp AS a
                  LEFT OUTER JOIN fips_centroids AS b
                  ON (a.fips_code = b.fips_code)")  
fips_join <- sqldf(fips_join)

#Set geoms equal to fips centroid if NA or outside of VA bounding box 
data_sp <- sqldf("SELECT *,
              CASE
                WHEN Latitude IS NULL THEN fips_latitude
                WHEN Latitude > 35 THEN fips_latitude
                WHEN Latitude < 41 THEN fips_latitude
                ELSE Latitude
              END AS corrected_latitude,
              CASE
                WHEN Latitude IS NULL THEN fips_longitude
                WHEN Longitude > -75 THEN fips_longitude
                WHEN Longitude < -84 THEN fips_longitude
                ELSE Longitude
              END AS corrected_longitude
              FROM fips_join")
###########################################################################

#coordinates(data_sp) <- c("Longitude", "Latitude") #sp_contain() requires a coordinates column
coordinates(data_sp) <- c("corrected_longitude", "corrected_latitude") #sp_contain() requires a coordinates column
data_sp_cont <- sp_contain(paste(localpath,gdb_path,sep=""),layer_name,data_sp)
data_sp_cont <- data.frame(data_sp_cont)
###########################################################################
###########################################################################
data_huc6 <- paste('SELECT Facility_hydroid, 
                                  Poly_Name as HUC6_Name, 
                                  Poly_Code as HUC6_Code
                          FROM data_sp_cont
                          ',sep="")
data_huc6 <- sqldf(data_huc6)
###########################################################################
###########################################################################
data_huc8 <- paste('SELECT Facility_hydroid, 
                                  Poly_Name as HUC8_Name, 
                                  Poly_Code as HUC8_Code
                          FROM data_sp_cont
                          ',sep="")
data_huc8 <- sqldf(data_huc8)
###########################################################################
###########################################################################
data_huc10 <- paste('SELECT Facility_hydroid, 
                                  Poly_Name as HUC10_Name, 
                                  Poly_Code as HUC10_Code
                          FROM data_sp_cont
                          ',sep="")
data_huc10 <- sqldf(data_huc10)
###########################################################################
###########################################################################
data_sp_raw <- data_sp_cont

# this first query was using data raw
data_query <- paste("SELECT *
                  FROM data_sp_raw AS a
                  LEFT OUTER JOIN data_huc6 AS b
                  ON (a.Facility_hydroid = b.Facility_hydroid)")  
data_HUCs <- sqldf(data_query)
add_huc8 <- paste("SELECT *
                  FROM data_HUCs AS a
                  LEFT OUTER JOIN data_huc8 AS b
                  ON (a.Facility_hydroid = b.Facility_hydroid)")  
data_HUCs <- sqldf(add_huc8)
add_huc10 <- paste("SELECT *
                  FROM data_HUCs AS a
                  LEFT OUTER JOIN data_huc10 AS b
                  ON (a.Facility_hydroid = b.Facility_hydroid)")  
data_HUCs <- sqldf(add_huc10)
###########################################################################
###########################################################################

write.csv(data_HUCs, paste(folder,"wsp2020.fac.all.HUC.csv",sep=""))
###########################################################################
###########################################################################

data_huc_raw <- read.csv(paste(folder,"wsp2020.fac.all.HUC.csv",sep=""))

sql <- paste('SELECT HUC6_Name,
              HUC6_Code,
              sum(fac_2020_mgy),
              sum(fac_2040_mgy)
              FROM data_huc_raw 
              GROUP BY HUC6_Code
              ',sep="")
data <- sqldf(sql)
###########################################################################
###########################################################################
###########################################################################
###########################################################################


huc_name <- "Upper James"

#Output all watershed options
sqldf('SELECT DISTINCT Poly_Name
      FROM data_sp_cont
      ')

#Select facilities within HUC of interest, Restict output to columns of interest
sql <- paste('SELECT facility_name, 
                      facility_ftype, 
                      fac_2020_mgy, 
                      fac_2040_mgy, 
                      Poly_Name
                  FROM data_sp_cont 
                  WHERE Poly_Name = ','\"',huc_name,'\"','
                  ORDER BY fac_2020_mgy DESC
                  LIMIT 5
              ',sep="")
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
      caption = paste("Top 5 Users in ",huc_name," HUC",sep=""), 
      label = paste("Top5_",huc_name,sep=""),
      col.names = c("Facility Name",
                    "Facility Type",
                    "2020 (MGY)",
                    "2040 (MGY)",
                    "HUC")) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>% 
  #column_spec(1, width = "5em") %>%
  #column_spec(2, width = "5em") %>%
  #column_spec(3, width = "5em") %>%
  #column_spec(4, width = "4em") %>%
  cat(., file = paste(folder,"kable_tables/","Top5_",huc_name,"_kable.tex",sep=""))

###########################################################################

