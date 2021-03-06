options(scipen=999) #Disable scientific notation
options(digits = 9)
memory.limit(size=100000000)
library(rgdal)
library(raster)
library(sf)
library(dplyr)
library(rgeos)
library(tmap)
library(tmaptools)
library(htmlwidgets)

#Load databases and extract required layers
HUC8<-readOGR("C:/Users/hp/Google Drive/VDEQ/Withdrawal_data/code_previously/HUC.gdb",layer='WBDHU8')
VA<-readOGR('C:/Users/hp/Google Drive/VDEQ/Withdrawal_data/code_previously/EvapInputs.gdb',layer="VA")

#Reproject shapefiles to NAD83=EPSG Code of 4269
HUC8<-sp::spTransform(HUC8, CRS("+init=epsg:4269"))
VA<-sp::spTransform(VA, CRS("+init=epsg:4269"))

#Crop Watersheds to Virginia State Boundaries
HUC8_Clipped<-gIntersection(HUC8,VA,id=as.character(HUC8@data$HUC8),byid=TRUE,drop_lower_td=TRUE)

#Create HUC8 Dataframe that will be used in future overlay processes
HUC8_Overlay<-HUC8 #Keep integrity of spatial dataframe
HUC8_Overlay@data<-HUC8_Overlay@data[,c(11,12)] 
names(HUC8_Overlay@data)<-c("HUC8","HUC8Name")

wdata<-read.csv("withdrawal_data.csv", header = T, sep = ",", na.strings=c("","NA"))
wdata<-filter(wdata,Facility_Status !="duplicate")

wdata$mp_latitude<-ifelse(wdata$mp_latitude <"34"| wdata$mp_latitude>"40"| is.na(wdata$mp_latitude),wdata$facility_latitude,wdata$mp_latitude)

wdata$mp_longitude<-ifelse(wdata$mp_longitude <"-74"| wdata$mp_longitude>"-84"| is.na(wdata$mp_longitude),wdata$facility_longitude,wdata$mp_longitude)

badlatlong<-filter(wdata,mp_latitude <"34"| mp_latitude>"40"  | mp_longitude>"-84" | mp_longitude <"-74" | 
                     is.na(mp_latitude)|is.na(mp_longitude))

#Removing bad latlong
wdata<-wdata %>% anti_join(badlatlong)

#seperate power and non power
target <- c("fossilpower", "nuclearpower")
facilities_power<-filter(wdata, Facility.Type %in% target)
facilities_nonpower<-filter(wdata, !Facility.Type %in% target)
summary(facilities_nonpower$Facility.Type)

#read the required file
#wdata<-facilities_power
wdata<-facilities_nonpower
summary(wdata)

#renaming coloums

names(wdata)[names(wdata)=="Max_Pre.89_.MGY."] <-"max_pre89_mgy"
names(wdata)[names(wdata)=="Intake_Capacity_.MGD."]<-"intake_capacity_mgd"
names(wdata)[names(wdata)=="VDH_Total_Pumping_Capacity_.MGD."] <-"VDH_total_pumping_cap_mgd"
names(wdata)[names(wdata)=="X401_Certification_Limit_.MGD."]<-"w401_certification_limit_mgd"
names(wdata)[names(wdata)=="Max_Pre.89_.MGM."]<-"max_pre89_mgm"
colnames(wdata)

wdata$VDH_total_pumping_cap_mgd<- as.numeric(wdata$max_pre89_mgm) / 31 #convert to mgd
wdata$max_pre89_mgd_f_mgy<- as.numeric(wdata$max_pre89_mgy) / 365 #convert to mgd

active_facilities<-filter(wdata, Facility_Status=="active")
inactive_facilities<-filter(wdata, Facility_Status=="inactive")
abandoned_facilities<-filter(wdata, Facility_Status=="abandoned")
duplicate_facilities<-filter(wdata, Facility_Status=="duplicate")
proposed_facilities<-filter(wdata, Facility_Status=="proposed")



##############################################################################################

####################################code for HUC8#############################################

colnames(wdata)[17:18]<-c("mp_latitude","mp_longitude")
colnames(wdata)[4]<-c("Facility_Name")

wdata_db<-sp::SpatialPointsDataFrame(data.frame(Facility_Longitude=wdata$mp_longitude,
                                                Facility_Latitude=wdata$mp_latitude),
                                     wdata,proj4string = CRS("+init=epsg:4269"))#projecting to NAD83

wdata_db@data$Facility_Name<-as.character(wdata_db$Facility_Name)
wdata_db@data$VDH_total_pumping_cap_mgd<-as.numeric(wdata_db@data$VDH_total_pumping_cap_mgd)

#--Overlay with HUC8 Shapefile--#
HUC8_Facilities<-over(wdata_db,HUC8_Overlay)
wdata_db@data$HUC8<-HUC8_Facilities$HUC8
wdata_db@data$HUC8Name<-HUC8_Facilities$HUC8Name

#remove NAs i.e. outside virginia
wdata_db <- wdata_db[!is.na(wdata_db@data$HUC8Name),]

wdata_db.test<-as.data.frame(wdata_db@data)

#wdata_db.test<-wdata_db.test[complete.cases(wdata_db.test[ ,26]),] 


data_summary<-wdata_db.test%>%
  dplyr::group_by(HUC8Name)%>%
  dplyr::summarise(Facility_Name=first(HUC8Name),
                   mp_latitude=first(mp_latitude),
                   mp_longitude=first(mp_longitude),    
                   VDH_total_pumping_cap_mgd=sum(VDH_total_pumping_cap_mgd))%>%
  arrange(desc(VDH_total_pumping_cap_mgd))
library(openxlsx)


################################################################################################################

##################################plotting######################################################################
extra_huc<-as.data.frame(union(setdiff(HUC8@data$Name,data_summary$HUC8Name),
                               setdiff(data_summary$HUC8Name, HUC8@data$Name))) #identify the values not present
colnames(extra_huc)<-c("HUC_name")
extra_huc<-cbind( extra_huc,withdrawal = 0)
df1<-data_summary[,c(1,5)]
names(df1) <- c("Name", "VDH_total_pumping_cap")
df2<-extra_huc
names(df2) <- c("Name", "VDH_total_pumping_cap")
data_summary1<-rbind.data.frame(df1,df2)


new<-HUC8
new<-append_data(HUC8,data_summary1,key.shp = "Name", key.data = "Name")

library(openxlsx)
write.xlsx(data_summary1, "HUC8_VDH_total_pumping_cap.xlsx")



tm_map<-tm_shape(new)+
  tm_polygons("VDH_total_pumping_cap", breaks = c(0, 1, 2, 3, 5,10,15,30,45,90,150,200,230, Inf), id="Name")

tm_map
tmap_mode("view")

tmap_save(tm_map, "VDH_total_pumping_cap_nonpower.html")


sqldf("select * from wdata where Organization like '%Fairfax Water%'")
