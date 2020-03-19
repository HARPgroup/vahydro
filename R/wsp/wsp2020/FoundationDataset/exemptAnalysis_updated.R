library(dplyr)
library(sqldf)
library(openxlsx)


options(scipen=999) #Disable scientific notation
options(digits = 9)

wdata_original<- read.csv(file="C:/Users/hp/Google Drive/VDEQ/updated_exempt/withdrawaldata_updated.csv",header = T, sep = ",", 
                 na.strings=c("","NA")) #Permiting Issuing Authority-All


#removing the duplicate entries based on mp_hydroid

wdata = wdata_original[order(wdata_original[,'mp_hydroid'],-wdata_original[,'mp_hydroid']),]
wdata = wdata_original[!duplicated(wdata_original$mp_hydroid),]
duplicate<-wdata_original[duplicated(wdata_original$mp_hydroid),]


# #seperate power and non power
# target <- c("fossilpower", "nuclearpower")
# facilities_power<-filter(wdata, Facility.Type %in% target)
# facilities_nonpower<-filter(wdata, !Facility.Type %in% target)
# summary(facilities_nonpower$Facility.Type)
# summary(facilities_power$Facility.Type)
# 
# #read the required file
# wdata<-facilities_power
# #wdata<-facilities_nonpower
# summary(wdata)


names(wdata)[names(wdata)=="Max_Pre.89_.MGY."] <-"max_pre89_mgy"
names(wdata)[names(wdata)=="Intake_Capacity_.MGD."]<-"intake_capacity_mgd"
names(wdata)[names(wdata)=="VDH_Total_Pumping_Capacity_.MGD."] <-"VDH_total_pumping_cap_mgd"
names(wdata)[names(wdata)=="X401_Certification_Limit_.MGD."]<-"w401_certification_limit_mgd"
names(wdata)[names(wdata)=="Max_Pre.89_.MGM."]<-"max_pre89_mgm"
names(wdata)[names(wdata)=="X2005_Safe_Yield_.MGD."]<-"X2005_Safe_Yield_mgd"
names(wdata)[names(wdata)=="X1985_Safe_Yield_.MGD."]<-"X1985_Safe_Yield_mgd"
names(wdata)[names(wdata)=="rfi_wd_capacity_mgy"]<-"rfi_wd_capacity_mgy"

#sqldf("select * from wdata where MP_Name like 'LAKE ANNA UNIT #1%'") #check
#write.xlsx(wdata, "noduplicates.xlsx",sep = ",", quote = FALSE, row.names = T)

wdata$max_pre89_mgd_f_mgm<- as.numeric(wdata$max_pre89_mgm) / 31 #convert to mgd
wdata$max_pre89_mgd_f_mgy<- as.numeric(wdata$max_pre89_mgy) / 365 #convert to mgd
wdata$rfi_wd_capacity_mgd_f_mgy<- as.numeric(wdata$rfi_wd_capacity_mgy) / 365 #convert to mgd


limit401<-(filter(wdata, w401_certification_limit_mgd != 0)) 
limit401$emempt<-limit401$w401_certification_limit_mgd


##########################################################################
############################################################################
wdata$intake_capacity_mgd <- as.numeric(gsub(",","",wdata$intake_capacity_mgd))
wdata$intake_capacity_mgd <- as.numeric(wdata$intake_capacity_mgd)
sum(is.na(wdata$intake_capacity_mgd))


Anydata<-sqldf("select * from wdata where max_pre89_mgd_f_mgm != 0 OR max_pre89_mgd_f_mgy !=0 OR intake_capacity_mgd !=0 OR
                   w401_certification_limit_mgd !=0 OR VDH_total_pumping_cap_mgd !=0 OR X2005_Safe_Yield_mgd
               OR X1985_Safe_Yield_mgd OR rfi_wd_capacity_mgd_f_mgy")

DF<-sqldf("select VDH_total_pumping_cap_mgd,max_pre89_mgd_f_mgm,max_pre89_mgd_f_mgy,intake_capacity_mgd
          ,X2005_Safe_Yield_mgd, X1985_Safe_Yield_mgd,rfi_wd_capacity_mgd_f_mgy from Anydata")


Anydata$exempt<-colnames(DF)[max.col(DF,ties.method="first")]

Anydata$exempt<-ifelse(Anydata$w401_certification_limit_mgd >0,"w401_certification_limit_mgd",Anydata$exempt)

Anydata$exempt_value<-with(Anydata, pmax(max_pre89_mgd_f_mgm, max_pre89_mgd_f_mgy,intake_capacity_mgd,VDH_total_pumping_cap_mgd,
                                         X2005_Safe_Yield_mgd,X1985_Safe_Yield_mgd,rfi_wd_capacity_mgd_f_mgy))
Anydata$exempt_value<-ifelse(Anydata$w401_certification_limit_mgd >0,
                             Anydata$w401_certification_limit_mgd,Anydata$exempt_value)

write.xlsx(Anydata, "exempt_value.xlsx",sep = ",", quote = FALSE, row.names = T)

safe_yield_2005<-filter(Anydata, exempt=="X2005_Safe_Yield_mgd")
  

safe_yield_1985<-filter(Anydata, exempt=="X1985_Safe_Yield_mgd")

summary(safe_yield_1985$exempt_value)
summary(safe_yield_2005$exempt_value)



######################check for 1985
Anydata<-sqldf("select * from wdata where max_pre89_mgd_f_mgm != 0 OR max_pre89_mgd_f_mgy !=0 OR intake_capacity_mgd !=0 OR
                   w401_certification_limit_mgd !=0 OR VDH_total_pumping_cap_mgd !=0 OR X2005_Safe_Yield_mgd
               OR X1985_Safe_Yield_mgd OR rfi_wd_capacity_mgd_f_mgy")

DF<-sqldf("select VDH_total_pumping_cap_mgd,max_pre89_mgd_f_mgm,max_pre89_mgd_f_mgy,intake_capacity_mgd
          , X1985_Safe_Yield_mgd,rfi_wd_capacity_mgd_f_mgy from Anydata")


Anydata$exempt85<-colnames(DF)[max.col(DF,ties.method="first")]

Anydata$exempt85<-ifelse(Anydata$w401_certification_limit_mgd >0,"w401_certification_limit_mgd",Anydata$exempt)

Anydata$exempt_value85<-with(Anydata, pmax(max_pre89_mgd_f_mgm, max_pre89_mgd_f_mgy,intake_capacity_mgd,VDH_total_pumping_cap_mgd,
                                         X1985_Safe_Yield_mgd,rfi_wd_capacity_mgd_f_mgy))
Anydata$exempt_value85<-ifelse(Anydata$w401_certification_limit_mgd >0,
                             Anydata$w401_certification_limit_mgd,Anydata$exempt_value)
Exempt85<-filter(Anydata, exempt85=="X1985_Safe_Yield_mgd")
summary(Exempt85$exempt_value85)
sum(Exempt85$exempt_value85)

#####################################Check for 2005
Anydata1<-sqldf("select * from wdata where max_pre89_mgd_f_mgm != 0 OR max_pre89_mgd_f_mgy !=0 OR intake_capacity_mgd !=0 OR
                   w401_certification_limit_mgd !=0 OR VDH_total_pumping_cap_mgd !=0 OR X2005_Safe_Yield_mgd
                OR rfi_wd_capacity_mgd_f_mgy")

DF<-sqldf("select VDH_total_pumping_cap_mgd,max_pre89_mgd_f_mgm,max_pre89_mgd_f_mgy,intake_capacity_mgd
          ,X2005_Safe_Yield_mgd,rfi_wd_capacity_mgd_f_mgy from Anydata1")


Anydata1$exempt05<-colnames(DF)[max.col(DF,ties.method="first")]

Anydata1$exempt05<-ifelse(Anydata1$w401_certification_limit_mgd >0,"w401_certification_limit_mgd",Anydata1$exempt)

Anydata1$exempt_value05<-with(Anydata1, pmax(max_pre89_mgd_f_mgm, max_pre89_mgd_f_mgy,intake_capacity_mgd,VDH_total_pumping_cap_mgd,
                                             X2005_Safe_Yield_mgd,rfi_wd_capacity_mgd_f_mgy))
Anydata1$exempt_value05<-ifelse(Anydata1$w401_certification_limit_mgd >0,
                                Anydata1$w401_certification_limit_mgd,Anydata1$exempt_value)

Exempt05<-filter(Anydata1, exempt05=="X2005_Safe_Yield_mgd")
summary(Exempt05$exempt_value05)
sum(Exempt05$exempt_value05)