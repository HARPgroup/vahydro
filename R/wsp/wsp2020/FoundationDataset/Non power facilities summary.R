library(dplyr)
options(scipen=999) #Disable scientific notation
options(digits = 9)
memory.limit(size=100000000)

wdata<- read.csv(file="C:/Users/hp/Google Drive/VDEQ/Withdrawal_data/withdrawal_data.csv",header = T, sep = ",", 
                 na.strings=c("","NA")) #Permiting Issuing Authority-All
#different facility types
active_facilities<-filter(wdata, Facility_Status=="active")
inactive_facilities<-filter(wdata, Facility_Status=="inactive")
abandoned_facilities<-filter(wdata, Facility_Status=="abandoned")
duplicate_facilities<-filter(wdata, Facility_Status=="duplicate")
proposed_facilities<-filter(wdata, Facility_Status=="proposed")

wdata<-filter(wdata,Facility_Status !="duplicate")

active_facilities<-filter(wdata, Facility_Status=="active")
inactive_facilities<-filter(wdata, Facility_Status=="inactive")
abandoned_facilities<-filter(wdata, Facility_Status=="abandoned")
duplicate_facilities<-filter(wdata, Facility_Status=="duplicate")
proposed_facilities<-filter(wdata, Facility_Status=="proposed")

#seperate power and non power
target <- c("fossilpower", "nuclearpower")
facilities_nonpower<-filter(wdata, !Facility.Type %in% target)
summary(facilities_nonpower$Facility.Type)
wdata<-facilities_nonpower

names(wdata)[names(wdata)=="Max_Pre.89_.MGY."] <-"max_pre89_mgy"
names(wdata)[names(wdata)=="Intake_Capacity_.MGD."]<-"intake_capacity_mgd"
names(wdata)[names(wdata)=="VDH_Total_Pumping_Capacity_.MGD."] <-"VDH_total_pumping_cap_mgd"
names(wdata)[names(wdata)=="X401_Certification_Limit_.MGD."]<-"w401_certification_limit_mgd"
names(wdata)[names(wdata)=="Max_Pre.89_.MGM."]<-"max_pre89_mgm"
colnames(wdata)

#use facility cordinates for missing mp cordinates

wdata$mp_latitude<-ifelse(wdata$mp_latitude <"34"| wdata$mp_latitude>"40"| is.na(wdata$mp_latitude),wdata$facility_latitude,wdata$mp_latitude)

wdata$mp_longitude<-ifelse(wdata$mp_longitude <"-74"| wdata$mp_longitude>"-84"| is.na(wdata$mp_longitude),wdata$facility_longitude,wdata$mp_longitude)

badlatlong<-filter(wdata,mp_latitude <"34"| mp_latitude>"40"  | mp_longitude>"-84" | mp_longitude <"-74" | 
                     is.na(mp_latitude)|is.na(mp_longitude))


# #Removing bad latlong
# wdata<-wdata %>% anti_join(badlatlong)
# summary(is.na(wdata$mp_latitude))

wdata$max_pre89_mgd_f_mgm<- as.numeric(wdata$max_pre89_mgm) / 31 #convert to mgd
wdata$max_pre89_mgd_f_mgy<- as.numeric(wdata$max_pre89_mgy) / 365 #convert to mgd

active_facilities<-filter(wdata, Facility_Status=="active")
inactive_facilities<-filter(wdata, Facility_Status=="inactive")
abandoned_facilities<-filter(wdata, Facility_Status=="abandoned")
duplicate_facilities<-filter(wdata, Facility_Status=="duplicate")
proposed_facilities<-filter(wdata, Facility_Status=="proposed")

#different exemption codes
exemption_code_0 <-filter(wdata, Exemption_Code=="0") # Not known
exemption_code_1 <-filter(wdata, Exemption_Code=="1") # Valid Exemption according to VWP regulations
exemption_code_2 <-filter(wdata, Exemption_Code=="2") # Valid Exemption according to VWP regulations
exemption_code_3 <-filter(wdata, Exemption_Code=="3") # Withdrawal Start date not provided
exemption_code_4 <-filter(wdata, Exemption_Code=="4") # Additional Info needed
exemption_code_5 <-filter(wdata, Exemption_Code=="5") # No response

#converting type
wdata$intake_capacity_mgd <- as.numeric(gsub(",","",wdata$intake_capacity_mgd))
wdata$intake_capacity_mgd <- as.numeric(as.character(wdata$intake_capacity_mgd))
sum(is.na(wdata$intake_capacity_mgd))
intake_capacity_data<-((filter(wdata, intake_capacity_mgd != 0)))


#maxpre89

max_pre89_mgm<-(filter(wdata, max_pre89_mgd_f_mgm != 0))
max_pre89_mgy<-(filter(wdata, max_pre89_mgd_f_mgy !=0))

#pumping capacity

VDH_total_pumping_cap_mgd <-as.data.frame(filter(wdata, VDH_total_pumping_cap_mgd !="0"))
X401_Certification_Limit<-as.data.frame(filter(wdata,w401_certification_limit_mgd !="0"))

Max_pre89_mgy_non_zero<-as.data.frame(max_pre89_mgy$max_pre89_mgd_f_mgy)
Max_pre89_mgm_non_zero<-as.data.frame(max_pre89_mgm$max_pre89_mgd_f_mgm)
VDH_total_pumping_non_zero<-as.data.frame(VDH_total_pumping_cap_mgd$VDH_total_pumping_cap_mgd)
X401_Certification_non_zero<-as.data.frame(X401_Certification_Limit$X401_certification_comment)
intake_capacity_non_zero<-as.data.frame(intake_capacity_data$intake_capacity_mgd)

Intake_Capacity <- intake_capacity_non_zero%>%
  dplyr::summarise("min" = min(intake_capacity_non_zero$`intake_capacity_data$intake_capacity_mgd`),
                   "Q25"=quantile(intake_capacity_non_zero$`intake_capacity_data$intake_capacity_mgd`,0.25),
                   "median" = median(intake_capacity_non_zero$`intake_capacity_data$intake_capacity_mgd`),
                   "Q75"=quantile(intake_capacity_non_zero$`intake_capacity_data$intake_capacity_mgd`,0.75),
                   "max" = max(intake_capacity_non_zero$`intake_capacity_data$intake_capacity_mgd`),
                   "mean" = mean(intake_capacity_non_zero$`intake_capacity_data$intake_capacity_mgd`),
                   "sum" = sum(intake_capacity_non_zero$`intake_capacity_data$intake_capacity_mgd`))

Max_pre_89_mgm<-Max_pre89_mgm_non_zero%>%
  dplyr::summarise("min" = min(Max_pre89_mgm_non_zero$`max_pre89_mgm$max_pre89_mgd_f_mgm`),
                   "Q25"=quantile(Max_pre89_mgm_non_zero$`max_pre89_mgm$max_pre89_mgd_f_mgm`,0.25),
                   "median" = median(Max_pre89_mgm_non_zero$`max_pre89_mgm$max_pre89_mgd_f_mgm`),
                   "Q75"=quantile(Max_pre89_mgm_non_zero$`max_pre89_mgm$max_pre89_mgd_f_mgm`,0.75),
                   "max" = max(Max_pre89_mgm_non_zero$`max_pre89_mgm$max_pre89_mgd_f_mgm`),
                   "mean" = mean(Max_pre89_mgm_non_zero$`max_pre89_mgm$max_pre89_mgd_f_mgm`),
                   "sum" = sum(Max_pre89_mgm_non_zero$`max_pre89_mgm$max_pre89_mgd_f_mgm`))

Max_pre_89_mgy <-Max_pre89_mgy_non_zero%>%
  dplyr::summarise("min" = min(Max_pre89_mgy_non_zero$`max_pre89_mgy$max_pre89_mgd_f_mgy`),
                   "Q25"=quantile(Max_pre89_mgy_non_zero$`max_pre89_mgy$max_pre89_mgd_f_mgy`,0.25),
                   "median" = median(Max_pre89_mgy_non_zero$`max_pre89_mgy$max_pre89_mgd_f_mgy`),
                   "Q75"=quantile(Max_pre89_mgy_non_zero$`max_pre89_mgy$max_pre89_mgd_f_mgy`,0.75),
                   "max" = max(Max_pre89_mgy_non_zero$`max_pre89_mgy$max_pre89_mgd_f_mgy`),
                   "mean" = mean(Max_pre89_mgy_non_zero$`max_pre89_mgy$max_pre89_mgd_f_mgy`),
                   "sum" = sum(Max_pre89_mgy_non_zero$`max_pre89_mgy$max_pre89_mgd_f_mgy`))


VDH_Pumping_Capacity<-VDH_total_pumping_non_zero%>%
  dplyr::summarise("min" = min(VDH_total_pumping_non_zero$`VDH_total_pumping_cap_mgd$VDH_total_pumping_cap_mgd`),
                   "Q25"=quantile(VDH_total_pumping_non_zero$`VDH_total_pumping_cap_mgd$VDH_total_pumping_cap_mgd`,0.25),
                   "median" = median(VDH_total_pumping_non_zero$`VDH_total_pumping_cap_mgd$VDH_total_pumping_cap_mgd`),
                   "Q75"=quantile(VDH_total_pumping_non_zero$`VDH_total_pumping_cap_mgd$VDH_total_pumping_cap_mgd`,0.75),
                   "max" = max(VDH_total_pumping_non_zero$`VDH_total_pumping_cap_mgd$VDH_total_pumping_cap_mgd`),
                   "mean" = mean(VDH_total_pumping_non_zero$`VDH_total_pumping_cap_mgd$VDH_total_pumping_cap_mgd`),
                   "sum" = sum(VDH_total_pumping_non_zero$`VDH_total_pumping_cap_mgd$VDH_total_pumping_cap_mgd`))



X401_certification <-X401_Certification_non_zero%>%
  dplyr::summarise("min" = min(X401_Certification_non_zero$`X401_Certification_Limit$X401_certification_comment`),
                   "Q25"=quantile(X401_Certification_non_zero$`X401_Certification_Limit$X401_certification_comment`,0.25),
                   "median" = median(X401_Certification_non_zero$`X401_Certification_Limit$X401_certification_comment`),
                   "Q75"=quantile(X401_Certification_non_zero$`X401_Certification_Limit$X401_certification_comment`,0.75),
                   "max" = max(X401_Certification_non_zero$`X401_Certification_Limit$X401_certification_comment`),
                   "mean" = mean(X401_Certification_non_zero$`X401_Certification_Limit$X401_certification_comment`),
                   "sum" = sum(X401_Certification_non_zero$`X401_Certification_Limit$X401_certification_comment`))


Facility_summary_Nonpower<-rbind.data.frame("Intake Capacity"= (Intake_Capacity),"Max pre 89 mgm"=Max_pre_89_mgm ,"Max pre 89 mgy"=Max_pre_89_mgy,
                                   "VDH pumping Capacity"= VDH_Pumping_Capacity)



Facility_summary_Nonpower[,'min']=format(round(Facility_summary_Nonpower[,'min'],4),nsmall=4)
Facility_summary_Nonpower[,2:7]=format(round(Facility_summary_Nonpower[,2:7],2),nsmall=2)
library(openxlsx)
write.xlsx(Facility_summary_Nonpower, "Facility_summary_Nonpower.xlsx",sep = ",", quote = FALSE, row.names = T)

