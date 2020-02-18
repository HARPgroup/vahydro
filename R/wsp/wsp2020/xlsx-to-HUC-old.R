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
# # PERFORM SPATIAL CONTAINMENT
# data_sp <- data_sp[-which(data_sp$Latitude > 90),]
# 
# #PERFORM THIS PART IN SQL AS WELL:
# #Set NA, -99, or 99 coordinates to 0.0; This step is required for coordinates() function
# data_sp$Latitude[is.na(data_sp$Latitude)] = 0.0 #-9999 
# data_sp$Longitude[is.na(data_sp$Longitude)] = 0.0
# data_sp$Latitude[data_sp$Latitude == 99] = 0.0
# data_sp$Latitude[data_sp$Latitude == -99] = 0.0
# data_sp$Longitude[data_sp$Longitude == 99] = 0.0
# data_sp$Longitude[data_sp$Longitude == -99] = 0.0

###########################################################################



fips_join <- paste("SELECT *
                  FROM data_sp AS a
                  LEFT OUTER JOIN fips_centroids AS b
                  ON (a.fips_code = b.fips_code)")  
fips_join <- sqldf(fips_join)

# bogus_geom <- paste("SELECT *
#                       FROM fips_join 
#                       WHERE Latitude == 0 OR
#                             Longitude == 0 OR
#                             Latitude > 90 OR
#                             Latitude == -99 OR
#                             Longitude == 99 OR
#                             Longitude == -99 
#                     ")  
# bogus_geom <- sqldf(bogus_geom)
# bogus_geom$Latitude <- bogus_geom$fips_latitude
# bogus_geom$Longitude <- bogus_geom$fips_longitude
# 
# 
#  df <- sqldf(c("update fips_join
#  	            set Latitude=999999
#  	            where Latitude=0",
#               "select * from fips_join"))
#  


#extent <- data.frame(x = c(-84, -75), 
#                     y = c(35, 41))  

#Set geoms equal to fips centroid if NA or outside of VA bounding box 
data_sp <- sqldf("SELECT *,
              CASE
                WHEN Latitude IS NULL THEN fips_latitude
                WHEN Latitude > 35 THEN fips_latitude
                WHEN Latitude < 41 THEN fips_latitude
                ELSE Latitude
              END AS corrected_latitude,
              CASE
                WHEN Latitude IS NULL THEN fips_latitude
                WHEN Longitude > -75 THEN fips_longitude
                WHEN Longitude < -84 THEN fips_longitude
                ELSE Longitude
              END AS corrected_longitude
              FROM fips_join")


###########################################################################

#library(DBI)
#library(RMySQL)
# geom_update <- paste(c("UPDATE fips_join
#                       SET Latitude = fips_latitude
#                       WHERE Latitude == 0", 
#                       "SELECT * FROM fips_join
#                     "))
# 
# 
# df<-sqldf(c("update fips_join
# 	            set Latitude=16
# 	            where Latitude=0",
#               "select * from fips_join"))

# bogus <- paste("SELECT Latitude = fips_latitude
#                       FROM bogus_geom 
#                     ")  
# bogus <- sqldf(bogus)




###########################################################################
#data_sp[is.na(data_sp$Latitude)] 
#which(is.na(data_sp$Latitude))
#which(fips_centroids$fips_code == 51001)
#data_sp[which(is.na(data_sp$Latitude)),]


# fips_join <- paste("SELECT *
#                   FROM data_sp AS a
#                   LEFT OUTER JOIN fips_centroids AS b
#                   ON (a.fips_code = b.fips_code)")  
# fips_join.df <- sqldf(fips_join)
# fips_join.df$forced_geom <- ''
# 
# #Do all of this in SQL? or simplify with ORs, ANDs
# #NA lat
# fips_join.df[which(is.na(fips_join.df$Latitude)),]$forced_geom = 'fips_centroid'
# fips_join.df[which(is.na(fips_join.df$Latitude)),]$Latitude = fips_join.df[which(is.na(fips_join.df$Latitude)),]$fips_latitude
# #NA Long
# fips_join.df[which(is.na(fips_join.df$Longitude)),]$forced_geom = 'fips_centroid'
# fips_join.df[which(is.na(fips_join.df$Longitude)),]$Longitude = fips_join.df[which(is.na(fips_join.df$Longitude)),]$fips_longitude
# #99 lat 
# fips_join.df[which(fips_join.df$Latitude == 99),]$forced_geom = 'fips_centroid'
# fips_join.df[which(fips_join.df$Latitude == 99),]$Latitude = fips_join.df[which(fips_join.df$Latitude == 99),]$fips_latitude
# #99 long 
# fips_join.df[which(fips_join.df$Longitude == 99),]$forced_geom = 'fips_centroid'
# fips_join.df[which(fips_join.df$Longitude == 99),]$Longitude = fips_join.df[which(fips_join.df$Longitude == 99),]$fips_longitude
# #-99 lat 
# fips_join.df[which(fips_join.df$Latitude == -99),]$forced_geom = 'fips_centroid'
# fips_join.df[which(fips_join.df$Latitude == -99),]$Latitude = fips_join.df[which(fips_join.df$Latitude == -99),]$fips_latitude
# #-99 long 
# fips_join.df[which(fips_join.df$Longitude == -99),]$forced_geom = 'fips_centroid'
# fips_join.df[which(fips_join.df$Longitude == -99),]$Longitude = fips_join.df[which(fips_join.df$Longitude == -99),]$fips_longitude
# #>90 lat
# fips_join.df[which(fips_join.df$Latitude > 90),]$forced_geom = 'fips_centroid'
# fips_join.df[which(fips_join.df$Latitude > 90),]$Latitude = fips_join.df[which(fips_join.df$Latitude > 90),]$fips_latitude
# 
# 
# data_sp <- fips_join.df
# data_sp_raw <- fips_join.df
###########################################################################
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

