# FIPS IN MINOR BASINS

library(ggplot2)
library(rgeos)
library(ggsn)
library(rgdal) # needed for readOGR()
library(dplyr) # needed for case_when()
library(sf) # needed for st_read()
library(sqldf)
library(kableExtra)
library(viridis) #magma
library(wicket) #wkt_centroid() 
library(cowplot) #plot static legend
library(magick) #plot static legend
library(ggrepel) #needed for geom_text_repel()
library(ggmap) #used for get_stamenmap, get_map

###################################################################################################### 
# LOAD FILES
######################################################################################################

#site <- "https://deq1.bse.vt.edu/d.dh/"
site <- "http://deq2.bse.vt.edu/d.dh/"

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))
localpath <- tempdir()

#DOWNLOAD MINOR BASIN LAYER DIRECT FROM GITHUB
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)

#DOWNLOAD FIPS LAYER DIRECT FROM VAHYDRO
fips_filename <- paste("vahydro_usafips_export.csv",sep="")
fips_destfile <- paste(localpath,fips_filename,sep="\\")
download.file(paste(site,"usafips_geom_export",sep=""), destfile = fips_destfile, method = "libcurl")
fips.csv <- read.csv(file=paste(localpath , fips_filename,sep="\\"), header=TRUE, sep=",")

#LOAD MINOR BASIN EXTENT FUNCTION 
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/mb.extent.R",sep = '/'))

#LOAD VIRGINIA POPULATION PROJECTION FILE
vapop_folder <- "U:/OWS/foundation_datasets/wsp/Population Data/"
vapop <- read.csv(paste0(vapop_folder, "VAPopProjections_Total_2020-2040_final.csv"))
vapop <- sqldf('SELECT FIPS, Geography_Name, round(x2020,0), round(x2030,0), round(x2040,0), round(((X2040 - X2020) / X2020)*100, 2) AS pct_change
               FROM vapop')
###############################################################################################
#START FUNCTION ###############################################################################
###############################################################################################

FIPS_in_basins <- function(minorbasin){
  
  # # SELECT MINOR BASIN NAME
  # mb_name <-sqldf(paste('SELECT name
  #             FROM "MinorBasins.csv" 
  #             WHERE code == "',minorbasin,'"',sep=""))
  
  #select minor basin code to know folder to save in
  mb_code <- minorbasin
  
  # change all EL minorbasin_code values to ES
  if (minorbasin == 'ES') {
    mp_all$MinorBasin_Code <- recode(mp_all$MinorBasin_Code, EL = "ES")
    mb_name <- "Eastern Shore"
    
  } else {
    mb_name <- sqldf(paste('SELECT distinct MinorBasin_Name
                   From mp_all
                   WHERE MinorBasin_Code = ','\"',minorbasin,'\"','
              ',sep=""))
    mb_name <- as.character(levels(mb_name$MinorBasin_Name)[mb_name$MinorBasin_Name])
    
  }
  
  #switch around the minor basin names to more human readable labels
  mb_name <- case_when(
    mb_name == "James Bay" ~ "Lower James",
    mb_name == "James Lower" ~ "Middle James",
    mb_name == "James Upper" ~ "Upper James",
    mb_name == "Potomac Lower" ~ "Lower Potomac",
    mb_name == "Potomac Middle" ~ "Middle Potomac",
    mb_name == "Potomac Upper" ~ "Upper Potomac",
    mb_name == "Rappahannock Lower" ~ "Lower Rappahannock",
    mb_name == "Rappahannock Upper" ~ "Upper Rappahannock",
    mb_name == "Tennessee Upper" ~ "Upper Tennessee",
    mb_name == "York Lower" ~ "Lower York",
    mb_name == "Eastern Shore Atlantic" ~ "Eastern Shore",
    mb_name == mb_name ~ mb_name) #this last line is the else clause to keep all other names supplied that don't need to be changed
  
  print(paste("PROCESSING: ",mb_name,sep=""))
  
  ######################################################################################################
  # DETERMINE MAP EXTENT FROM MINOR BASIN CENTROID
  extent <- mb.extent(minorbasin,MinorBasins.csv)
  ######################################################################################################
  
  # BOUNDING BOX
  bb=readWKT(paste0("POLYGON((",extent$x[1]," ",extent$y[1],",",extent$x[2]," ",extent$y[1],",",extent$x[2]," ",extent$y[2],",",extent$x[1]," ",extent$y[2],",",extent$x[1]," ",extent$y[1],"))",sep=""))
  bbProjected <- SpatialPolygonsDataFrame(bb,data.frame("id"), match.ID = FALSE)
  bbProjected@data$id <- rownames(bbProjected@data)
  bbPoints <- fortify(bbProjected, region = "id")
  bbDF <- merge(bbPoints, bbProjected@data, by = "id")
  
  
  ######################################################################################################
  ### PROCESS Minor Basin LAYER  #######################################################################
  ######################################################################################################
  mb_data <- MinorBasins.csv
  
  MB_df_sql <- paste('SELECT *
              FROM mb_data 
              WHERE code = "',minorbasin,'"'
                     ,sep="")
  mb_data <- sqldf(MB_df_sql)
  
  mb_data$id <- as.character(row_number(mb_data$code))
  MB.list <- list()
  
  
  for (z in 1:length(mb_data$code)) {
    MB_geom <- readWKT(mb_data$geom[z])
    MB_geom_clip <- gIntersection(bb, MB_geom)
    MBProjected <- SpatialPolygonsDataFrame(MB_geom_clip, data.frame('id'), match.ID = TRUE)
    MBProjected@data$id <- as.character(z)
    MB.list[[z]] <- MBProjected
  }
  MB <- do.call('rbind', MB.list)
  MB@data <- merge(MB@data, mb_data, by = 'id')
  MB@data <- MB@data[,-c(2:3)]
  MB.df <- fortify(MB, region = 'id')
  MB.df <- merge(MB.df, MB@data, by = 'id')
  
  ######################################################################################################
  ### PROCESS FIPS CENTROID WITHIN MINOR BASIN #########################################################
  ######################################################################################################
  
  # #PADDING TO ENSURE FIPS NAMES DONT GO BEYOND PLOT WINDOW
  # fips_extent <- data.frame(x = c(extent$x[1]+0.25, extent$x[2]-0.25),
  #                           y = c(extent$y[1]+0.25, extent$y[2]-0.25))
  # fips_bb=readWKT(paste0("POLYGON((",fips_extent$x[1]," ",fips_extent$y[1],",",fips_extent$x[2]," ",fips_extent$y[1],",",fips_extent$x[2]," ",fips_extent$y[2],",",fips_extent$x[1]," ",fips_extent$y[2],",",fips_extent$x[1]," ",fips_extent$y[1],"))",sep=""))
  
  fips_layer <- fips.csv
  fips_layer$id <- fips_layer$fips_hydroid
  fips.list <- list()
  
  for (f in 1:length(fips_layer$fips_hydroid)) {
    fips_geom <- readWKT(fips_layer$fips_centroid[f])
    fips_geom_clip <- gIntersection(MB_geom, fips_geom) #SHOW ONLY FIPS NAMES WITHIN MINOR BASIN
    
    if (is.null(fips_geom_clip) == TRUE) {
      # print("FIPS OUT OF MINOR BASIN EXTENT - SKIPPING") 
      next
    }
    
    fipsProjected <- SpatialPointsDataFrame(fips_geom_clip, data.frame('id'), match.ID = TRUE)
    fipsProjected@data$id <- as.character(fips_layer[f,]$id)
    fips.list[[f]] <- fipsProjected
  }
  
  length(fips.list)
  #REMOVE THOSE FIPS THAT WERE SKIPPED ABOVE (OUT OF MINOR BASIN EXTENT)
  fips.list <- fips.list[which(!sapply(fips.list, is.null))]
  length(fips.list)
  
  if (length(fips.list) != 0) {
    #  print("NO FIPS GEOMS WITHIN MINOR BASIN EXTENT - SKIPPING")
    fips <- do.call('rbind', fips.list)
    fips@data <- merge(fips@data, fips_layer, by = 'id')
    fips@data <- fips@data[,-c(2:3)]
    fips_centroid.df <- data.frame(fips)
  } else {
    print("NO FIPS GEOMS WITHIN MINOR BASIN EXTENT")
    
    fips_centroid.df <- data.frame(id=c(1,2),
                          fips_latitude =c(1,2), 
                          fips_longitude =c(1,2),
                          fips_name = c(1,2),
                          stringsAsFactors=FALSE) 
    
  }
  
#append minor basin name to fips_centroid.df
  
  fips_centroid.df$mb_name <- mb_name
  
  fips_centroid.df$mb_code <- minorbasin
  #print(fips_centroid.df)
  
  
  ######################################################################################################
  ### PROCESS FIPS BOUNDARY GEOMETRY WITHIN MINOR BASIN ################################################
  ######################################################################################################
  
  fips_layer <- fips.csv
  fips_layer$id <- fips_layer$fips_hydroid
  fips.list <- list()
  
  for (f in 1:length(fips_layer$fips_hydroid)) {
    fips_geom <- readWKT(fips_layer$fips_geom[f])
    fips_geom_clip <- gIntersection(MB_geom, fips_geom) #SHOW ONLY FIPS NAMES WITHIN MINOR BASIN
    
    if (is.null(fips_geom_clip) == TRUE) {
      # print("FIPS OUT OF MINOR BASIN EXTENT - SKIPPING") 
      next
    }
    
    fipsProjected <- SpatialPointsDataFrame(fips_geom_clip, data.frame('id'), match.ID = TRUE)
    fipsProjected@data$id <- as.character(fips_layer[f,]$id)
    fips.list[[f]] <- fipsProjected
  }
  
  length(fips.list)
  #REMOVE THOSE FIPS THAT WERE SKIPPED ABOVE (OUT OF MINOR BASIN EXTENT)
  fips.list <- fips.list[which(!sapply(fips.list, is.null))]
  length(fips.list)
  
  if (length(fips.list) != 0) {
    #  print("NO FIPS GEOMS WITHIN MINOR BASIN EXTENT - SKIPPING")
    fips <- do.call('rbind', fips.list)
    fips@data <- merge(fips@data, fips_layer, by = 'id')
    fips@data <- fips@data[,-c(2:3)]
    fips.df <- data.frame(fips)
  } else {
    print("NO FIPS GEOMS WITHIN MINOR BASIN EXTENT")
    
    fips.df <- data.frame(id=c(1,2),
                          fips_latitude =c(1,2), 
                          fips_longitude =c(1,2),
                          fips_name = c(1,2),
                          stringsAsFactors=FALSE) 
    
  }
  
  #append minor basin name to fips.df
  
  fips.df$mb_name <- mb_name
  
  fips.df$mb_code <- minorbasin
  
  
  
  fips.df <- sqldf('SELECT a.fips_name, b.pct_change, a.fips_code, a.fips_centroid, a.mb_name, a.mb_code
                   FROM "fips.df" as a
                   LEFT OUTER JOIN vapop as b
                   ON a.fips_code = b.FIPS
                   WHERE a.fips_code LIKE "51%"')
  
  fips.df <- sqldf('SELECT fips_name as "Localities", pct_change as "20 Year % Change"
                   FROM "fips.df"
                   WHERE fips_name != "Bedford City"')
  #return(fips.df),

  
  # OUTPUT TABLE IN KABLE FORMAT
  localities_tex <- kable(fips.df,  booktabs = T,format = "latex", align = c("l","c"),
        caption = paste0("Population Trend by Locality in ", mb_name, " Basin"),
        label = paste0(minorbasin,"_localities")) %>%
    kable_styling(latex_options = "striped") 
  
  end_wraptext <- if (nrow(fips.df) < 15) {
                  nrow(fips.df) + 10
                  } else if (nrow(fips.df) < 20){ 
                    nrow(fips.df) + 4  
                    } else {nrow(fips.df)}
  
  #print(end_wraptext)
  #CUSTOM LATEX CHANGES
  #change to wraptable environment
  localities_tex <- gsub(pattern = "\\begin{table}[t]",
                     repl    = paste0("\\begin{wraptable}[",end_wraptext,"]{r}{5cm}"),
                     x       = localities_tex, fixed = T )
  localities_tex <- gsub(pattern = "\\end{table}",
                         repl    = "\\end{wraptable}",
                         x       = localities_tex, fixed = T )
  localities_tex <- gsub(pattern = "\\addlinespace",
                         repl    = "",
                         x       = localities_tex, fixed = T )
  localities_tex %>%
    cat(., file = paste(folder,"tables_maps/Xtables/",minorbasin,"_localities_table.tex",sep=""))

  localities_tex
}
################ RUN FIPS IN BASINS FUNCTION ##################################################
# SINGLE BASIN
PU_fips <- FIPS_in_basins(minorbasin = "PU")

# ALL BASINS
basins <- c('PS', 'NR', 'YP', 'TU', 'RL', 'OR', 'EL', 'ES', 'PU', 'RU', 'YM', 'JA', 'MN', 'PM', 'YL', 'BS', 'PL', 'OD', 'JU', 'JB', 'JL')

all_basins <- list()

for (b in basins) {
  
  basin_b <- FIPS_in_basins(minorbasin = b)
  
  all_basins <- rbind(all_basins,basin_b)
  
}

write.csv(all_basins, file = "U:\\OWS\\foundation_datasets\\wsp\\wsp2020\\tables_maps\\Xtables\\VA_fips_in_minorbasins.csv" , row.names = F)

