# Annual Reporting PART 1 - Load and save the foundational datasets --------------------------------------------
# MUST BE ON VPN

# This script generates:
#### mp_all_XXXX-XXXX
#### mp_all_1982-current
#### mp_all_wide_XXXX-XXXX
#### mp_permitted_XXXX

library('tidyverse') #loads in tidyr, dplyr, ggplot2, etc
library('httr')
library('stringr')
library("kableExtra")
library('stringr')
library('sqldf')
library("hydrotools")
library("RCurl")

options(scipen = 999)

#NOTE: The start and end year need to be updated every year
syear = 1982
#syear = 2018
eyear = 2022

#NOTE: switch between file types to save in common drive folder; html or latex
#file_extension <- ".html"
file_extension <- ".tex"

##Generate REST token for authentication --------------------------------------------
#(note for 2024- REST no longer needed if generating foundation data through SQL)
rest_uname = FALSE
rest_pw = FALSE
basepath ='/var/www/R'
source(paste0(basepath,'/auth.private'))
source(paste0(basepath,'/config.R'))

# ds <- RomDataSource$new(site)
# ds$get_token()
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
ds$get_token(rest_pw)
#also, line 111, changed to mp_all_power. Not sure what MayQA section does. Also (eyear-4) in line 189/190


#resume running here
export_path <- "U:/OWS/foundation_datasets/awrr/"

#GLOBAL VARIABLES --------------------------------------------------------------------
if (file_extension == ".html") {
  options(knitr.table.format = "html") #"html" for viewing in Rstudio Viewer pane
  file_ext <- ".html" #view in R or browser
} else {
  options(knitr.table.format = "latex") #"latex" when ready to output to Overleaf
  file_ext <- ".tex" #for easy upload to Overleaf
}
#Kable Styling
latexoptions <- c("scale_down")

year.range <- (eyear-4):eyear

#Join in FIPS name to data
#fips <- read.csv(file = paste0(github_location,"/vahydro/R/wsp/wsp2020/FoundationDataset/fips_codes.csv"))
#note for 2024 - locality names are now already in the foundation and this isnt needed, but may still need to correct for 'county' / 'city of' naming convention
fips <- read.csv(file = "U:\\OWS\\Report Development\\Annual Water Resources Report\\October 2022 Report\\fips_codes_propernames.csv")

############### PULL DIRECTLY FROM VAHYDRO #################################################
#Use this section only if you want 5yr data, use SQL for full 1982-current foundation data

# #load in MGY from Annual Map Exports view
# tsdef_url <- paste0(site,"/ows-awrr-map-export/wd_mgy?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",syear,"-01-01&tstime%5Bmax%5D=",eyear,"-12-31&bundle%5B0%5D=well&bundle%5B1%5D=intake")
# 
# #NOTE: this takes 5-8 minutes (grab a snack; stay hydrated)
# multi_yr_data <- ds$auth_read(tsdef_url, content_type = "text/csv", delim = ",")
# #exclude dalecarlia
# multi_yr_data <- multi_yr_data[-which(multi_yr_data$Facility=='DALECARLIA WTP'),]
# #backup<- multi_yr_data
# #multi_yr_data <- backup
# # duplicate_check <- sqldf('SELECT MP_hydroid, "MP Name", "Facility", "FIPS Code", "OWS Planner", count(MP_hydroid)
# #       FROM multi_yr_data
# #       GROUP BY MP_hydroid, Year
# #       HAVING count(MP_hydroid) > 1')


################ PULL DIRECTLY FROM DEQ2 USING SQL ############################
#Pull foundation data through SQL,VAHydro Issue #848
#read in the resulting file
multi_yr_data <- read.csv(paste0(export_path,eyear+1,"/awrr_foundation_2023.csv"))
no_gw2 <- sqldf('select * from multi_yr_data WHERE "Use.Type" NOT LIKE "gw2_%"')
duplicate_check <- sqldf('SELECT *, count(mp_hydroid)
      FROM no_gw2
      GROUP BY mp_hydroid, year
      HAVING count(mp_hydroid) > 1')

#Group the MPs by HydroID, Year to account for MPs that are linked to multiple Facilities (GW2 & Permitted) 
multi_yr_data <- sqldf('SELECT mp_hydroid as "MP_hydroid", hydrocode as "Hydrocode", 
CASE
WHEN LOWER("Source.Type") LIKE "%well%" THEN "Groundwater"
WHEN LOWER("Source.Type") LIKE "%intake%" THEN "Surface Water"
ELSE LOWER("Source.Type")
END AS "Source Type", 
"MP.Name" as "MP Name", facility_hydroid as "Facility_hydroid", facility as "Facility", 
CASE 
WHEN LOWER("Use.Type") LIKE "%agriculture%" THEN "agriculture"
WHEN LOWER("Use.Type") LIKE "%industrial%" THEN "manufacturing"
ELSE LOWER("Use.Type")
END AS "Use Type", latitude as "Latitude", longitude as "Longitude", "FIPS.Code" as "FIPS Code", locality as "Locality", "OWS.Planner" as "OWS Planner", MAX("year") AS Year, MAX(tsvalue) AS "Water Use MGY"
      FROM multi_yr_data
      WHERE "Use.Type" NOT LIKE "gw2_%"
      AND "Facility" != "DALECARLIA WTP"
      GROUP BY "MP_hydroid", "Hydrocode", "Source Type", "MP Name", "Latitude", "Longitude", "FIPS Code", "OWS Planner", "Year" 
      ')

##MP FOUNDATION DATASET - BEGINNING 1982 -----------------------------------------------------------------------------------------------------------------
mp_foundation_dataset <- pivot_wider(data = multi_yr_data, id_cols = c("MP_hydroid", "Hydrocode", "Source Type", "MP Name", "Facility_hydroid", "Facility", "Use Type", "Latitude", "Longitude", "FIPS Code", "Locality", "OWS Planner"), names_from = "Year", values_from = "Water Use MGY", names_sort = T)

write.csv(mp_foundation_dataset, paste0(export_path,eyear+1,"/foundation_dataset_mgy_",syear,"-",eyear,".csv"), row.names = F)

#Add 5yr avg calculation to the foundation dataset. 
#To improve, do this using sql and confirm that NAs are not counted in the average, then perpetuate this change into the script
fiveyr_avg_mgy <- round((rowMeans(mp_foundation_dataset[(length(mp_foundation_dataset)-4):length(mp_foundation_dataset)], na.rm = TRUE, dims = 1)),2)
mp_foundation_dataset <- cbind(mp_foundation_dataset,fiveyr_avg_mgy)
write.csv(mp_foundation_dataset, paste0(export_path,eyear+1,"/foundation_dataset_mgy_",syear,"-",eyear,"_5ya.csv"), row.names = F)

##split into 2 datasets: POWER & NON-POWER -------------------------------------------------------------------------------------------------
#NON-POWER
mp_all <- sqldf(paste0('SELECT "MP_hydroid", "Hydrocode", "Source Type", "MP Name", "Facility_hydroid", "Facility", "Use Type", "Latitude", "Longitude", "FIPS Code", "Locality", "OWS Planner","',eyear-4,'","',eyear-3,'","',eyear-2,'","',eyear-1,'","',eyear,'"
                FROM mp_foundation_dataset
                WHERE "Use Type" NOT LIKE "%power%"'))
write.csv(mp_all, paste0(export_path,eyear+1,"/mp_all_mgy_",eyear-4,"-",eyear,".csv"), row.names = F)  

#POWER
mp_all_power <-  sqldf(paste0('SELECT "MP_hydroid", "Hydrocode", "Source Type", "MP Name", "Facility_hydroid", "Facility", "Use Type", "Latitude", "Longitude", "FIPS Code", "Locality", "OWS Planner","',eyear-4,'","',eyear-3,'","',eyear-2,'","',eyear-1,'","',eyear,'"
                FROM mp_foundation_dataset
                WHERE "Use Type" LIKE "%power%"'))
write.csv(mp_all_power, paste0(export_path,eyear+1,"/mp_power_mgy_",eyear-4,"-",eyear,".csv"), row.names = F)  

# TABLE 1 SUMMARY -----------------------------------------------------------------------------------
sql_year_calc <- paste0('round(SUM("',eyear-4,'")/365,2),
round(SUM("',eyear-3,'")/365,2),
round(SUM("',eyear-2,'")/365,2),
round(SUM("',eyear-1,'")/365,2),
round(SUM("',eyear,'")/365,2)')

cat_table <- sqldf(paste0('SELECT "Source Type", 
"Use Type",',sql_year_calc,'
                       FROM mp_all
                       GROUP BY "Source Type", "Use Type"'))

cat_table_aggreg <- sqldf(paste0('SELECT "Total (GW + SW)" AS "Source Type", 
"Use Type",',sql_year_calc,'
                       FROM mp_all
                       GROUP BY "Use Type"'))

cat_table_gw <- sqldf(paste0('SELECT " " AS "Source Type", 
"Total Groundwater" AS "Use Type",', sql_year_calc,'
                       FROM mp_all
                       WHERE "Source Type" LIKE "Groundwater"'))
cat_table_sw <- sqldf(paste0('SELECT " " AS "Source Type", 
"Total Surface Water" AS "Use Type",', sql_year_calc,'
                       FROM mp_all
                       WHERE "Source Type" LIKE "Surface Water"'))
cat_table_totals <- sqldf(paste0('SELECT " " AS "Source Type", 
"Total (GW + SW)" AS "Use Type",', sql_year_calc,'
                       FROM mp_all'))

#rowbind/union the rows together
cat_table <- rbind(cat_table,cat_table_aggreg, cat_table_gw, cat_table_sw, cat_table_totals)

#calculate the Multi Year Avg column
multi_yr_avg <- round((rowMeans(cat_table[3:7], na.rm = FALSE, dims = 1)),2)

#columnbind/append the columns together
cat_table <- cbind(cat_table, multi_yr_avg)

#rename the columns
colnames(cat_table) <- c('Source Type', 'Category',year.range,'multi_yr_avg')

#calculate the percent change column
pct_chg <- round(((cat_table[paste(eyear)]-cat_table["multi_yr_avg"])/cat_table["multi_yr_avg"])*100, 1)

#rename the columns
names(pct_chg) <- paste('% Change',eyear,'to Avg.')

#columnbind/append the columns together
cat_table <- cbind(cat_table,'pct_chg' = pct_chg)

#make Category values capital
cat_table$Category <- str_to_title(cat_table$Category)

#check if there are any 'agricultural' sums
print(cat_table)

#remove 'agricultural' keep 'agriculture', and remove null facilities for orphaned wells
cat_table <- sqldf('select * from cat_table
                   where Category != "Agricultural"
                   AND Category != "Facility"')

#view and check Table 1
print(cat_table)

## SAVE TABLE 1 SUMMARY --------------------------------------------------------------------------------------------

#save the cat_table to use for data reference - we can refer to that csv when asked questions about the data
write.csv(cat_table, paste(export_path,eyear+1,"/Table1_",eyear-4,"-",eyear,".csv",sep = ""), row.names = F)

#IS THERE A STATIC TABLE? READ THAT IN AND BEGIN FROM HERE ##########################################################


cat_table <- read.csv(file = paste(export_path,eyear+1,"/Table1_",eyear-4,"-",eyear,".csv",sep = ""))
#colnames(cat_table) <- c('Source Type', 'Category',year.range,'multi_yr_avg', paste('% Change',eyear,'to Avg.'))

multi_yr_data <- read.csv(file = paste0(export_path,eyear+1,"/mp_all_mgy_",eyear-4,"-",eyear,".csv"))

#calculate the Multi Year Avg column
fiveyr_avg_mgy <- round((rowMeans(multi_yr_data[(length(multi_yr_data)-4):length(multi_yr_data)], na.rm = TRUE, dims = 1)),2)
multi_yr_data <- cbind(multi_yr_data,fiveyr_avg_mgy)

#redefine year range
syear <- 2018
eyear <- 2022
eyearX <- paste0("X",eyear) #for sql statements that need X2021 column
year.range <- syear:eyear

## End read in section, now can continue or jump to the individual table sections #############################################################

################### MAY QA CHECK ##########################################
# kable(cat_table, booktabs = T) %>%
#   kable_styling(latex_options = c("striped", "scale_down")) %>%
#   column_spec(8, width = "5em") %>%
#   column_spec(9, width = "5em") %>%
#   cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\May_QA\\summary_table_vahydro_",eyear+1,"_",Sys.Date(),".html",sep = ""))


# Total Facilities Count ##################

## Fac_all #########################

#write fac_all for total withdrawals per facility
mp_foundation <- read.csv(file = paste0(export_path,eyear+1,"/foundation_dataset_mgy_1982-",eyear,".csv"))

#Remake long version so that we can sum the mgy for all MPs of each Facility hydroid
mp_long <- pivot_longer(mp_foundation, cols = starts_with("X"), names_to = "Year", names_prefix = "X", values_to = "mgy")
fac_all <- sqldf('SELECT "Facility_hydroid", "Facility", "Year", sum("mgy") as mgy, sum(("mgy")/365) as mgd, "Use.Type" as "Use_Type", "FIPS.Code" as FIPS
                  FROM mp_long
                  GROUP BY Facility_hydroid, Year')
#export long format
write.csv(fac_all, paste("U:\\OWS\\foundation_datasets\\awrr\\",eyear+1,"\\fac_all_1982-",eyear,".csv",sep = ""), row.names = F)



## 1982-Current Total Fac and Use (optional) #####

## Counts total number of reporting facilities and total use for 1982-eyear, currently for internal analysis not for in report

## note: section runs, but can be improved by finishing making it more succint, or adding by use type counts and graphs if we need them

### Including power
mp_wide <- pivot_wider(data = fac_all, id_cols = c("Facility_hydroid", "Facility","Use_Type", "FIPS"), names_from = "Year", values_from = "mgy", names_sort = T)

year.range.f <- 1982:eyear
count_3D <- data.frame(Year = matrix(NA, nrow = length(year.range.f)), "Num_Reporting_Fac"=matrix(NA, nrow = length(year.range.f)), BGD = matrix(NA, nrow=length(year.range.f)))
i<-0
for (x in year.range.f) {
  i=i+1
  test <- sqldf(paste0('SELECT "',x,'" FROM mp_wide WHERE "',x,'" IS NOT NULL'))
  count_3D[i,1] <- year.range.f[i]
  count_3D[i,2] <- nrow(test)
  count_3D[i,3] <- sum(test)/1000/365
} 

write.csv(count_3D, paste("U:\\OWS\\foundation_datasets\\awrr\\",eyear+1,"\\total_fac_wpower_1982-",eyear,".csv",sep = ""), row.names = F)


### Excluding power
mp_foundation_np <-  sqldf(paste0('SELECT * FROM mp_foundation WHERE "Use.Type" NOT LIKE "%power%"'))

mp_long_np <- pivot_longer(mp_foundation_np, cols = starts_with("X"), names_to = "Year", names_prefix = "X", values_to = "mgy")
fac_all_np <- sqldf('SELECT "Facility_hydroid", "Facility", "Year", sum("mgy") as mgy, sum(("mgy")/365) as mgd, "Use.Type" as Use_Type, "FIPS.Code" as FIPS
                    FROM mp_long_np
                    GROUP BY Facility_hydroid, Year')
#Count total number of reporting facilities for each year
mp_wide_np <- pivot_wider(data = fac_all_np, id_cols = c("Facility_hydroid", "Facility","Use_Type", "FIPS"), names_from = "Year", values_from = "mgy", names_sort = T)

count_3D_np <- data.frame(Year = matrix(NA, nrow = length(year.range.f)), "Num_Reporting_Fac"=matrix(NA, nrow = length(year.range.f)), BGD = matrix(NA, nrow=length(year.range.f)))
year.range.f <- 1982:eyear
i<-0
for (x in year.range.f) {
  i=i+1
  test <- sqldf(paste0('SELECT "',x,'" FROM mp_wide_np WHERE "',x,'" IS NOT NULL'))
  count_3D_np[i,1] <- year.range.f[i]
  count_3D_np[i,2] <- nrow(test)
  count_3D_np[i,3] <- sum(test)/1000/365
} 

write.csv(count_3D_np, paste("U:\\OWS\\foundation_datasets\\awrr\\",eyear+1,"\\total_fac_nonpower_1982-",eyear,".csv",sep = ""), row.names = F)


## Just for eyear, use this for report ####################

#Calculate the total number of facilities for current reporting year
mp_foundation <- read.csv(file = paste0(export_path,eyear+1,"/foundation_dataset_mgy_1982-",eyear,".csv"))
colnames(mp_foundation)[colnames(mp_foundation)=="Use.Type"] <- "Use_Type"

count_fac <- sqldf(paste('SELECT *
                          FROM mp_foundation
                          WHERE ',eyearX,' IS NOT NULL AND
                           Use_Type NOT LIKE "hydropower"
                          GROUP BY Facility_hydroid', sep=''))
totalfac <- nrow(count_fac)
print(paste0("The total number of facilities presented in the report includes nuclear & fossil power, excludes hydropower and includes Dalecarlia: ", totalfac+1," facilites"))




#TABLE 1 : w/o power Summary ##########################################
#ONlY RUN THIS IF YOU WANT TABLE 1 WITHOUT POWER, OTHERWISE MOVE TO TABLE1 :wPOWER SECTION
cat_table$Category <- recode(cat_table$Category, "Municipal" = "Public Water Supply")
table1_latex <- kable(cat_table[2:9],'latex', booktabs = T,
                      caption = paste("Summary of Virginia Water Withdrawals by Use Category and Source Type",eyear-4,"-",eyear,"(MGD)",sep=" "),
                      label = paste("Summary of Virginia Water Withdrawals by Use Category and Source Type",eyear-4,"-",eyear,"(MGD)",sep=" "),
                      col.names = c(
                        'Category',
                        year.range,
                        paste((eyear-syear)+1,"Year Avg."),
                        paste('% Change', eyear,'to Avg.', sep = ' '))) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>%
  column_spec(1, width = "10em") %>%
  pack_rows("Groundwater", 1, 6, hline_before = T, hline_after = F) %>%
  pack_rows("Surface Water", 7, 12, hline_before = T, hline_after = F) %>%
  pack_rows("Total (GW + SW)", 13, 18, hline_before = T, hline_after = F) %>%
  pack_rows("Total", 19, 20, hline_before = T, hline_after = F) %>%
  row_spec(21, bold=T, extra_css = "border-top: 1px solid") 

#CUSTOM LATEX CHANGES
#insert hold position header
table1_tex <- gsub(pattern = "{table}[t]", 
                   repl    = "{table}[ht!]", 
                   x       = table1_latex, fixed = T )
table1_tex

table1_tex %>%
  cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\overleaf\\summary_table1_",eyear+1,".tex",sep = ''))

########### TABLE1: wPower ##############
#Make a new Table 1 that includes Power data
cat_table <- read.csv(file = paste(export_path,eyear+1,"/Table1_",eyear-4,"-",eyear,".csv",sep = ""))
#pow_table comes from running POWER PULL FROM VAHYDRO section (currently towards the bottom of script), then return here and read in cat_table
pow_table <- read.csv(file = paste(export_path,eyear+1,"/Table1_Power_",eyear-4,"-",eyear,".csv",sep = ""))
cat_table <- rbind(cat_table, pow_table)
cat_table <- cat_table[c(1:6,22:23, 7:12,24:25, 13:18,26:27, 19:21,28:30),] #rearange rows to merge power lines
rownames(cat_table)<-1:nrow(cat_table) #correct index
cat_table$Category <- recode(cat_table$Category, "fossilpower" = "Fossil Power")
cat_table$Category <- recode(cat_table$Category, "nuclearpower" = "Nuclear Power")
cat_table$Category <- recode(cat_table$Category, "Municipal" = "Public Water Supply")
cat_table$Category <- recode(cat_table$Category, "Total (Gw + Sw)" = "Total (GW + SW)")

#Calculate the total with power included
#need to manually update year column names in next several lines
cat_table2 <- cat_table %>%  filter(Category %in% c("Total (Gw + Sw)","Total (GW + SW)")) %>% select(X2018, X2019, X2020, X2021, X2022, multi_yr_avg,X..Change.2022.to.Avg.) 
statesum <- colSums(cat_table2, na.rm=FALSE)
statesum["X..Change.2022.to.Avg."] <- round(((statesum[eyearX]-statesum["multi_yr_avg"])/statesum["multi_yr_avg"])*100,1)
statesum<-as.data.frame(t(statesum))
statesum <-statesum %>% add_column(Category = "Total (GW + SW)", .before = "X2018") %>% add_column(Source.Type = "", .before = "Category")
cat_table <- rbind(cat_table,statesum)
#write.csv(cat_table, paste0(export_path,eyear+1,"/Table1_TempCheck_",eyear-4,"-",eyear,".csv"), row.names = F) 
write.csv(cat_table, paste0(export_path,eyear+1,"/Table1_All_",eyear-4,"-",eyear,".csv"), row.names = F) 


table1_latex <- kable(cat_table[2:9],'latex', booktabs = T,
                      caption = paste("Summary of Virginia Water Withdrawals by Use Category and Source Type",eyear-4,"-",eyear,"(MGD)",sep=" "),
                      label = paste("Summary of Virginia Water Withdrawals by Use Category and Source Type",eyear-4,"-",eyear,"(MGD)",sep=" "),
                      col.names = c(
                        'Category',
                        year.range,
                        paste((eyear-syear)+1,"Year Avg."),
                        paste('% Change', eyear,'to Avg.', sep = ' '))) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>%
  column_spec(1, width = "12em") %>%
  pack_rows("Groundwater", 1, 8, hline_before = T, hline_after = F) %>%
  pack_rows("Surface Water", 9, 16, hline_before = T, hline_after = F) %>%
  pack_rows("Total (GW + SW)", 17, 24, hline_before = T, hline_after = F) %>%
  pack_rows("Total - without power", 25, 27, hline_before = T, hline_after = F, latex_gap_space = "1em") %>%
  row_spec(27, bold=T, extra_css = "border-top: 1px solid") %>%
  pack_rows("Total - power only", 28, 30, hline_before = T, hline_after = F, latex_gap_space = "1em") %>%
  row_spec(30, bold=T, extra_css = "border-top: 1px solid") %>%
  pack_rows("Total All Categories", 31,31, hline_before = T, hline_after = F, latex_gap_space = "1em") %>%
  row_spec(31, bold=T, extra_css = "border-top: 1px solid")


#CUSTOM LATEX CHANGES
#insert hold position header
table1_tex <- gsub(pattern = "{table}[t]", 
                   repl    = "{table}[ht!]", 
                   x       = table1_latex, fixed = T )
table1_tex

table1_tex %>%
  cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\overleaf\\summary_table1.tex",sep = ''))

################### TABLE 4 : TOP 20 USERS ##########################################

#To run this section, read in the static table section first

#rename columns so R and SQL statements recognize the column names
colnames(multi_yr_data)[colnames(multi_yr_data)=="Use.Type"] <- "Use_Type"
colnames(multi_yr_data)[colnames(multi_yr_data)=="Source.Type"] <- "Source_Type"
colnames(multi_yr_data)[colnames(multi_yr_data)=="FIPS.Code"] <- "FIPS"

#make Category values capital
multi_yr_data$Use_Type <- str_to_title(multi_yr_data$Use_Type)
multi_yr_data$Facility <- str_to_title(multi_yr_data$Facility)

data_all <-multi_yr_data
# #2023 note - commenting out the reassignment of locality names now that foundation locality column is fixed
# colnames(data_all)[colnames(data_all)=="Locality"] <- "Locality_NA
# data_all <- sqldf('SELECT a.*, b.name AS Locality
#                   FROM data_all a
#                   LEFT OUTER JOIN fips b
#                   ON a.FIPS = b.code')

data_all <- sqldf('SELECT a.*, 
                        CASE WHEN Source_Type = "Groundwater"
                        THEN 1
                        END AS GW_type,
                        CASE
                        WHEN Source_Type = "Surface Water"
                        THEN 1
                        END AS SW_Type
                  FROM data_all AS a')

#no longer need to print a wide copy, foundation is now already wide
#write.csv(data_all, paste("U:\\OWS\\foundation_datasets\\awrr\\",eyear+1,"\\mp_all_wide_",syear,"-",eyear,".csv",sep = ""), row.names = F)


#group by facility
data_all_fac <- sqldf(paste('SELECT Facility_HydroID, Facility, Source_Type, Use_Type, Locality, round((sum(',paste('"',eyearX,'"', sep = ''),')/365),1) AS mgd, round((sum(fiveyr_avg_mgy)/365),1) as fiveyr_avg_mgd, sum(GW_type) AS GW_type, sum(SW_type) AS SW_type
                      FROM data_all
                      GROUP BY Facility_HydroID',sep = ''))

#limit 20
top_20 <- sqldf('SELECT Facility_HydroID, Facility, 
                        Locality, 
                        CASE WHEN GW_Type > 0 AND SW_Type IS NULL
                        THEN "GW"
                        WHEN SW_Type > 0 AND GW_Type IS NULL
                        THEN "SW"
                        WHEN GW_Type > 0 AND SW_Type > 0
                        THEN "SW/GW"
                        END AS Type,
                        fiveyr_avg_mgd,
                        mgd,
                        Use_Type AS Category
                FROM data_all_fac
                ORDER BY mgd DESC
                LIMIT 20')

#KABLE
table4_latex <- kable(top_20[2:7],'latex', booktabs = T, align = c('l','l','c','c','c','l') ,
                      caption = paste("Top 20 Reported Water Withdrawals in",eyear,"Excluding Power Generation (MGD)",sep=" "),
                      label = paste("Top 20 Reported Water Withdrawals in",eyear,"Excluding Power Generation (MGD)",sep=" "),
                      col.names = c(
                        'Facility',
                        'Locality',
                        'Type',
                        paste((eyear-syear)+1,"Year Avg."),
                        paste(eyear, 'Withdrawal', sep = ' '),
                        'Category')) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>%
  column_spec(1, width = "12em")

#CUSTOM LATEX CHANGES
#insert hold position header
table4_tex <- gsub(pattern = "{table}[t]", 
                   repl    = "{table}[ht!]", 
                   x       = table4_latex, fixed = T )
table4_tex

table4_tex %>%
  cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\Overleaf\\summary_table4.tex",sep = ''))

################### TOP USERS BY USE TYPE (TABLES 6, 8, 10, 12, 14, 15,  17, 20, ############################
#Chapter 3 Top5 tables
#This section requires Table 4 Top 20 section to be run first, through the creation of data_all and data_all_fac

#-------------- Ag Irr Com Min Top5 -------
#Table: Highest Reported  Withdrawals in eyear (MGD)
use_types <- list("Agriculture", "Commercial", "Irrigation", "Mining")

for (u in use_types) {
  print(paste('PROCESSING TOP 5 TABLE: ',u),sep = '')
  
    top5 <- sqldf(paste('SELECT Facility_HydroID, Facility, 
                        Locality, 
                        CASE 
                        WHEN GW_Type > 0 AND SW_Type IS NULL
                        THEN "GW"
                        WHEN SW_Type > 0 AND GW_Type IS NULL
                        THEN "SW"
                        WHEN GW_Type > 0 AND SW_Type > 0
                        THEN "SW/GW"
                        END AS Type,
                        fiveyr_avg_mgd,
                        mgd,
                        Use_Type AS Category
                FROM data_all_fac
                WHERE Use_Type LIKE',paste('"',u,'"', sep = ''),'
                ORDER BY mgd DESC
                LIMIT 5',sep = ''))
    
    #KABLE
    top5_latex <- kable(top5[2:6],'latex', booktabs = T, align = c('l','l','c','c','c') ,
                        caption = paste("Highest Reported",u,"Withdrawals in",eyear,"(MGD)",sep=" "),
                        label = paste("Highest Reported",u,"Withdrawals in",eyear,"(MGD)",sep=" "),
                        col.names = c(
                          'Facility',
                          'Locality',
                          'Type',
                          paste((eyear-syear)+1,"Year Avg."),
                          paste(eyear, 'Withdrawal', sep = ' '))) %>%
      kable_styling(latex_options = c("striped", "scale_down")) %>%
      column_spec(1, width = "12em")
    
    #CUSTOM LATEX CHANGES
    #insert hold position header
    top5_tex <- gsub(pattern = "{table}[t]", 
                     repl    = "{table}[ht!]", 
                     x       = top5_latex, fixed = T )
    top5_tex
    
    top5_tex %>%
      cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\Overleaf\\",u,"_top5.tex",sep = ''))
    
  }

#-------------- Man Pws Top5 GM New Loop-------
#Manufacturing and Municipal get 2 tables (Top5 SW, and Top5 GW), and a custom title
use_types <- list("Municipal", "Manufacturing")

for (u in use_types) {
  print(paste('PROCESSING TOP 5 TABLE: ',u),sep = '')
  for (s in list("Groundwater","Surface Water")) {
  if (u == "Manufacturing"){
    captiontext <- paste("Highest Reported Manufacturing and Industrial",s,"Withdrawals in",eyear,"(MGD)",sep=" ")
    labeltext <- paste("Highest Reported Manufacturing and Industrial",s,"Withdrawals in",eyear,"(MGD)",sep=" ")
    ut <- "Manufacturing"}
  else {
    captiontext = paste("Highest Reported Public Water Supply",s,"Withdrawals in",eyear,"(MGD)",sep=" ")
    labeltext = paste("Highest Reported Public Water Supply",s,"Withdrawals in",eyear,"(MGD)",sep=" ")
    ut <- "PublicWaterSupply"}
    
    #group by source type from data_all
    #group by facility
    data_all_source <- sqldf(paste('SELECT Facility_HydroID, Facility, Source_Type, Use_Type, Locality, round((sum(',paste('"',eyearX,'"', sep = ''),')/365),1) AS mgd, round((sum(fiveyr_avg_mgy)/365),1) as fiveyr_avg_mgd, sum(GW_type) AS GW_type, sum(SW_type) AS SW_type
                      FROM data_all
                      GROUP BY Facility_HydroID, Source_Type',sep = ''))
    #top5
    top5 <- sqldf(paste('SELECT Facility_HydroID, Facility, 
                        Locality, 
                        CASE 
                        WHEN GW_Type > 0 AND SW_Type IS NULL
                        THEN "GW"
                        WHEN SW_Type > 0 AND GW_Type IS NULL
                        THEN "SW"
                        WHEN GW_Type > 0 AND SW_Type > 0
                        THEN "SW/GW"
                        END AS Type,
                        fiveyr_avg_mgd,
                        mgd,
                        Use_Type AS Category
                FROM data_all_source
                WHERE Source_Type LIKE ',paste('"',s,'"', sep = ''),' 
                AND Use_Type LIKE',paste('"',u,'"', sep = ''),'
                ORDER BY mgd DESC
                LIMIT 5',sep = ''))
    #KABLE
    top5_latex <- kable(top5[2:6],'latex', booktabs = T, align = c('l','l','c','c','c') ,
                        caption = captiontext,
                        label = labeltext,
                        col.names = c(
                          'Facility',
                          'Locality',
                          'Type',
                          paste((eyear-syear)+1,"Year Avg."),
                          paste(eyear, 'Withdrawal', sep = ' '))) %>%
      kable_styling(latex_options = c("striped", "scale_down")) %>%
      column_spec(1, width = "12em")
    
    #CUSTOM LATEX CHANGES
    #insert hold position header
    top5_tex <- gsub(pattern = "{table}[t]", 
                     repl    = "{table}[ht!]", 
                     x       = top5_latex, fixed = T )
    top5_tex
    
    top5_tex %>%
      cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\Overleaf\\",ut,"_",s,"_top5.tex",sep = ''))
  }
  }



#cat_table <- cat_table2
# bySourceType - tables 5,7,9,11,13,16,19 ##################################################
# This section of tables requires the static table section to be read in first, and is expecting cat_table to be Table1 WITHOUT power.

#change avg column name 
syear <- eyear-4
colnames(cat_table)[8] <- paste((eyear-syear)+1,"Year Avg.")
### AG #####
agtable5 <- cat_table[c(1,7,13),-2]
rownames(agtable5) <- c()

colnames(agtable5)[colnames(agtable5)==paste0("X..Change.",eyear,".to.Avg.")] <- paste0("% Change ",eyear," to Avg.")
for (s in 1:length(year.range)) {colnames(agtable5)[colnames(agtable5)==paste0("X",year.range[s])] <- year.range[s]}

ag_tex <- kable(agtable5, booktabs = T, align = c('l','c','c','c','c','c','c','c'),
                caption = paste(syear,"-",eyear,"Agriculture Water Withdrawals by Source Type (MGD)",sep=" "),
                label = paste(syear,"-",eyear,"Agriculture Water Withdrawal Trends",sep=" "),
                col.names = c("Source Type",
                              colnames(agtable5[2:8]))) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>%
  row_spec(row = 3, bold = TRUE) 

#CUSTOM LATEX CHANGES
#insert hold position header
ag_tex <- gsub(pattern = "{table}[t]", 
               repl    = "{table}[ht!]", 
               x       = ag_tex, fixed = T )

#make last column name wrap on 2 rows (adjusts column width) 
ag_tex <- gsub(pattern = "{lccccccc}", 
               repl    = "{lccccccp{2cm}}", 
               x       = ag_tex, fixed = T )

ag_tex %>%
  cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\Overleaf\\Agriculture_table",file_ext,sep = ''))

# #use this as an interim view and check
# #kable(cat_table, booktabs = T) %>% 
#   kable_styling(latex_options = c("striped", "scale_down")) %>%
#   column_spec(8, width = "5em") %>%
#   column_spec(9, width = "5em") %>%
#   cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\May_QA\\summary_table_vahydro_",eyear+1,"_",Sys.Date(),".html",sep = ""))

### BAR GRAPH ###################################################################################
#transform wide to long table
agtable5 <- agtable5[-3,-8]
colnames(agtable5)[colnames(agtable5)=="Source.Type"] <- "Source" #Source is called in the ggplot
colnames(agtable5)[colnames(agtable5)==paste((eyear-syear)+1,"Year Avg.")] <- "Average"

agtable5 <- pivot_longer(data = agtable5, cols = paste0(syear):paste0(eyear), names_to = "Year", values_to = "MGD")

#plot bar graph
ggplot(data=agtable5, aes(x=Year, y=MGD, fill = Source)) +
  geom_col(position=position_dodge(), colour = "gray") + 
  geom_hline(aes(yintercept = agtable5$Average, colour = Source), size = .8, linetype = "dashed") +
  labs( y="Million Gallons per Day", fill = "Source Type") +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major.y = element_line(colour = "light gray", size=.3),
        legend.position="bottom", 
        legend.box = "horizontal",
        axis.title.x=element_text(size=15),  # X axis title
        axis.title.y=element_text(size=15),
        axis.text.x = element_text(size=15, vjust = 1),
        axis.text.y = element_text(size=12),
        plot.margin = unit(c(0,5,1,1), "lines"),
        legend.text=element_text(size=12),
        legend.title=element_text(size=12)) + # This widens the right margin
  coord_cartesian(xlim = c(1,5), clip = "off") +
  geom_text(aes(label=MGD),
            position=position_dodge(width=0.9), 
            vjust = -.8) +
  annotate("text", y=agtable5$Average, x=5.85, label = paste(agtable5$Average, " MGD")) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)")

filename <- "Agriculture_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/overleaf",sep = " "), width=12, height=6)

### irrig ######################################################################################
#irrig
irrigtable7 <- cat_table[c(3,9,15),-2]
rownames(irrigtable7) <- c()

colnames(irrigtable7)[colnames(irrigtable7)==paste0("X..Change.",eyear,".to.Avg.")] <- paste0("% Change ",eyear," to Avg.") 
for (s in 1:length(year.range)) {colnames(irrigtable7)[colnames(irrigtable7)==paste0("X",year.range[s])] <- year.range[s]}

irrig_tex <- kable(irrigtable7,  booktabs = T, align = c('l','c','c','c','c','c','c','c'),
                   caption = paste(syear,"-",eyear,"Irrigation Water Withdrawals by Source Type (MGD)",sep=" "),
                   label = paste(syear,"-",eyear,"Irrigation Water Withdrawal Trends",sep=" "),
                   col.names = c("Source Type",
                                 colnames(irrigtable7[2:8]))) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>%
  row_spec(row = 3, bold = TRUE) 

#CUSTOM LATEX CHANGES
#insert hold position header
irrig_tex <- gsub(pattern = "{table}[t]", 
                  repl    = "{table}[ht!]", 
                  x       = irrig_tex, fixed = T )

#make last column name wrap on 2 rows (adjusts column width) 
irrig_tex <- gsub(pattern = "{lccccccc}", 
                  repl    = "{lccccccp{2cm}}", 
                  x       = irrig_tex, fixed = T )

irrig_tex %>%
  cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\Overleaf\\Irrigation_table",file_ext,sep = ''))

### BAR GRAPH ##################################################################################
#transform wide to long table
irrigtable7 <- irrigtable7[-3,-8]
colnames(irrigtable7)[colnames(irrigtable7)=="Source.Type"] <- "Source"
colnames(irrigtable7)[colnames(irrigtable7)==paste((eyear-syear)+1,"Year Avg.")] <- "Average"
irrigtable7 <- pivot_longer(data = irrigtable7, cols = paste0(syear):paste0(eyear), names_to = "Year", values_to = "MGD")

#plot bar graph
ggplot(data=irrigtable7, aes(x=Year, y=MGD, fill = Source)) +
  geom_col(position=position_dodge(), colour = "gray") + 
  geom_hline(aes(yintercept = irrigtable7$Average, colour = Source), size = .8, linetype = "dashed") +
  labs( y="Million Gallons per Day", fill = "Source Type") +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major.y = element_line(colour = "light gray", size=.3),
        legend.position="bottom", 
        legend.box = "horizontal",
        axis.title.x=element_text(size=15),  # X axis title
        axis.title.y=element_text(size=15),
        axis.text.x = element_text(size=15, vjust = 1),
        axis.text.y = element_text(size=12),
        plot.margin = unit(c(0,5,1,1), "lines"),
        legend.text=element_text(size=12),
        legend.title=element_text(size=12)) + # This widens the right margin
  coord_cartesian(xlim = c(1,5), clip = "off") +
  geom_text(aes(label=MGD),
            position=position_dodge(width=0.9), 
            vjust = -.8) +
  annotate("text", y=irrigtable7$Average, x=5.85, label = paste(irrigtable7$Average, " MGD")) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)")


filename <- "Irrigation_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf",sep = " "), width=12, height=6)

### commercial####################################################################################
commtable9 <- cat_table[c(2,8,14),-2]
rownames(commtable9) <- c()

colnames(commtable9)[colnames(commtable9)==paste0("X..Change.",eyear,".to.Avg.")] <- paste0("% Change ",eyear," to Avg.") 
for (s in 1:length(year.range)) {colnames(commtable9)[colnames(commtable9)==paste0("X",year.range[s])] <- year.range[s]}

comm_tex <- kable(commtable9,  booktabs = T, align = c('l','c','c','c','c','c','c','c'),
                  caption = paste(syear,"-",eyear,"Commercial Water Withdrawals by Source Type (MGD)",sep=" "),
                  label = paste(syear,"-",eyear,"Commercial Water Withdrawal Trends",sep=" "),
                  col.names = c("Source Type",
                                colnames(commtable9[2:8]))) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>%
  row_spec(row = 3, bold = TRUE) 

#CUSTOM LATEX CHANGES
#insert hold position header
comm_tex <- gsub(pattern = "{table}[t]", 
                 repl    = "{table}[ht!]", 
                 x       = comm_tex, fixed = T )

#make last column name wrap on 2 rows (adjusts column width) 
comm_tex <- gsub(pattern = "{lccccccc}", 
                 repl    = "{lccccccp{2cm}}", 
                 x       = comm_tex, fixed = T )

comm_tex %>%
  cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\Overleaf\\Commercial_table",file_ext,sep = ''))

### BAR GRAPH ####################################################################################
#transform wide to long table
commtable9 <- commtable9[-3,-8]
colnames(commtable9)[colnames(commtable9)=="Source.Type"] <- "Source"
colnames(commtable9)[colnames(commtable9)==paste((eyear-syear)+1,"Year Avg.")] <- "Average"
commtable9 <- pivot_longer(data = commtable9, cols = paste0(syear):paste0(eyear), names_to = "Year", values_to = "MGD")

#plot bar graph
ggplot(data=commtable9, aes(x=Year, y=MGD, fill = Source)) +
  geom_col(position=position_dodge(), colour = "gray") + 
  geom_hline(aes(yintercept = commtable9$Average, colour = Source), size = .8, linetype = "dashed") +
  labs( y="Million Gallons per Day", fill = "Source Type") +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major.y = element_line(colour = "light gray", size=.3),
        legend.position="bottom", 
        legend.box = "horizontal",
        axis.title.x=element_text(size=15),  # X axis title
        axis.title.y=element_text(size=15),
        axis.text.x = element_text(size=15, vjust = 1),
        axis.text.y = element_text(size=12),
        plot.margin = unit(c(0,5,1,1), "lines"),
        legend.text=element_text(size=12),
        legend.title=element_text(size=12)) + # This widens the right margin
  coord_cartesian(xlim = c(1,5), clip = "off") +
  geom_text(aes(label=MGD),
            position=position_dodge(width=0.9), 
            vjust = -.8) +
  annotate("text", y=commtable9$Average, x=5.85, label = paste(commtable9$Average, " MGD")) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)")

filename <- "Commercial_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf",sep = " "), width=12, height=6)


###mining #########################################################################################
#mining
mintable11 <- cat_table[c(5,11,17),-2]
rownames(mintable11) <- c()

colnames(mintable11)[colnames(mintable11)==paste0("X..Change.",eyear,".to.Avg.")] <- paste0("% Change ",eyear," to Avg.") 
for (s in 1:length(year.range)) {colnames(mintable11)[colnames(mintable11)==paste0("X",year.range[s])] <- year.range[s]} 

min_tex <- kable(mintable11,  booktabs = T, align = c('l','c','c','c','c','c','c','c'),
                 caption = paste(syear,"-",eyear,"Mining Water Withdrawals by Source Type (MGD)",sep=" "),
                 label = paste(syear,"-",eyear,"Mining Water Withdrawal Trends",sep=" "),
                 col.names = c("Source Type",
                               colnames(mintable11[2:8]))) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>%
  row_spec(row = 3, bold = TRUE) 

#CUSTOM LATEX CHANGES
#insert hold position header
min_tex <- gsub(pattern = "{table}[t]", 
                repl    = "{table}[ht!]", 
                x       = min_tex, fixed = T )

#make last column name wrap on 2 rows (adjusts column width) 
min_tex <- gsub(pattern = "{lccccccc}", 
                repl    = "{lccccccp{2cm}}", 
                x       = min_tex, fixed = T )

min_tex %>%
  cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\Overleaf\\Mining_table",file_ext,sep = ''))

### BAR GRAPH #############################################################################
#transform wide to long table
mintable11 <- mintable11[-3,-8]
colnames(mintable11)[colnames(mintable11)=="Source.Type"] <- "Source"
colnames(mintable11)[colnames(mintable11)==paste((eyear-syear)+1,"Year Avg.")] <- "Average"
mintable11 <- pivot_longer(data = mintable11, cols = paste0(syear):paste0(eyear), names_to = "Year", values_to = "MGD")

#plot bar graph
ggplot(data=mintable11, aes(x=Year, y=MGD, fill = Source)) +
  geom_col(position=position_dodge(), colour = "gray") + 
  geom_hline(aes(yintercept = mintable11$Average, colour = Source), size = .8, linetype = "dashed") +
  labs( y="Million Gallons per Day", fill = "Source Type") +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major.y = element_line(colour = "light gray", size=.3),
        legend.position="bottom", 
        legend.box = "horizontal",
        axis.title.x=element_text(size=15),  # X axis title
        axis.title.y=element_text(size=15),
        axis.text.x = element_text(size=15, vjust = 1),
        axis.text.y = element_text(size=12),
        plot.margin = unit(c(0,5,1,1), "lines"),
        legend.text=element_text(size=12),
        legend.title=element_text(size=12)) + # This widens the right margin
  coord_cartesian(xlim = c(1,5), clip = "off") +
  geom_text(aes(label=MGD),
            position=position_dodge(width=0.9), 
            vjust = -.8) +
  annotate("text", y=mintable11$Average, x=5.85, label = paste(mintable11$Average, " MGD")) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)")
  
#+ annotate("text", y=mintable11$Average-1.8, x=.79, label ="5 Year Avg.") 
#+ annotate("text", y=mintable11$Average-3, x=.79, label = paste('=',mintable11$Average, " MGD"))

filename <- "Mining_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf",sep = " "), width=12, height=6)


###manuf #####################################################################################
#manuf
mantable13 <- cat_table[c(4,10,16),-2]
rownames(mantable13) <- c()

colnames(mantable13)[colnames(mantable13)==paste0("X..Change.",eyear,".to.Avg.")] <- paste0("% Change ",eyear," to Avg.") 
for (s in 1:length(year.range)) {colnames(mantable13)[colnames(mantable13)==paste0("X",year.range[s])] <- year.range[s]} 

man_tex <- kable(mantable13,  booktabs = T, align = c('l','c','c','c','c','c','c','c'),
                 caption = paste(syear,"-",eyear,"Manufacturing and Industrial Water Withdrawals by Source Type (MGD)",sep=" "),
                 label = paste(syear,"-",eyear,"Manufacturing and Industrial Water Withdrawal Trends",sep=" "),
                 col.names = c("Source Type",
                               colnames(mantable13[2:8]))) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>%
  row_spec(row = 3, bold = TRUE) 

#CUSTOM LATEX CHANGES
#insert hold position header
man_tex <- gsub(pattern = "{table}[t]", 
                repl    = "{table}[ht!]", 
                x       = man_tex, fixed = T )

#make last column name wrap on 2 rows (adjusts column width) 
man_tex <- gsub(pattern = "{lccccccc}", 
                repl    = "{lccccccp{2cm}}", 
                x       = man_tex, fixed = T )

man_tex %>%
  cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\Overleaf\\Manufacturing_table",file_ext,sep = ''))

### BAR GRAPH #################################################################################
#transform wide to long table
mantable13 <- mantable13[-3,-8]
colnames(mantable13)[colnames(mantable13)=="Source.Type"] <- "Source"
colnames(mantable13)[colnames(mantable13)==paste((eyear-syear)+1,"Year Avg.")] <- "Average"
mantable13 <- pivot_longer(data = mantable13, cols = paste0(syear):paste0(eyear), names_to = "Year", values_to = "MGD")

#plot bar graph
ggplot(data=mantable13, aes(x=Year, y=MGD, fill = Source)) +
  geom_col(position=position_dodge(), colour = "gray") + 
  geom_hline(aes(yintercept = mantable13$Average, colour = Source), size = .8, linetype = "dashed") +
  labs( y="Million Gallons per Day", fill = "Source Type") +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major.y = element_line(colour = "light gray", size=.3),
        legend.position="bottom", 
        legend.box = "horizontal",
        axis.title.x=element_text(size=15),  # X axis title
        axis.title.y=element_text(size=15),
        axis.text.x = element_text(size=15, vjust = 1),
        axis.text.y = element_text(size=12),
        plot.margin = unit(c(0,5,1,1), "lines"),
        legend.text=element_text(size=12),
        legend.title=element_text(size=12)) + # This widens the right margin
  coord_cartesian(xlim = c(1,5), clip = "off") +
  geom_text(aes(label=MGD),
            position=position_dodge(width=0.9), 
            vjust = -.8) +
  annotate("text", y=mantable13$Average, x=5.85, label = paste(mantable13$Average, " MGD")) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)")


filename <- "Manufacturing_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf",sep = " "), width=12, height=6)


###municipal aka public water supply ########################################################
#muni aka pws
munitable16 <- cat_table[c(6,12,18),-2]
rownames(munitable16) <- c()

colnames(munitable16)[colnames(munitable16)==paste0("X..Change.",eyear,".to.Avg.")] <- paste0("% Change ",eyear," to Avg.")
for (s in 1:length(year.range)) {colnames(munitable16)[colnames(munitable16)==paste0("X",year.range[s])] <- year.range[s]} 

muni_tex <- kable(munitable16,  booktabs = T, align = c('l','c','c','c','c','c','c','c'),
                  caption = paste(syear,"-",eyear,"Public Water Supply Water Withdrawals by Source Type (MGD)",sep=" "),
                  label = paste(syear,"-",eyear,"Public Water Supply Water Withdrawal Trends",sep=" "),
                  col.names = c("Source Type",
                                colnames(munitable16[2:8]))) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>%
  row_spec(row = 3, bold = TRUE) 

#CUSTOM LATEX CHANGES
#insert hold position header
muni_tex <- gsub(pattern = "{table}[t]", 
                 repl    = "{table}[ht!]", 
                 x       = muni_tex, fixed = T )

#make last column name wrap on 2 rows (adjusts column width) 
muni_tex <- gsub(pattern = "{lccccccc}", 
                 repl    = "{lccccccp{2cm}}", 
                 x       = muni_tex, fixed = T )

muni_tex %>%
  cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\Overleaf\\Public_Water_supply_table",file_ext,sep = ''))


###BAR GRAPH ############################################################################
#transform wide to long table
munitable16 <- munitable16[-3,-8]
colnames(munitable16)[colnames(munitable16)=="Source.Type"] <- "Source"
colnames(munitable16)[colnames(munitable16)==paste((eyear-syear)+1,"Year Avg.")] <- "Average"
munitable16 <- pivot_longer(data = munitable16, cols = paste0(syear):paste0(eyear), names_to = "Year", values_to = "MGD")

#plot bar graph
ggplot(data=munitable16, aes(x=Year, y=MGD, fill = Source)) +
  geom_col(position=position_dodge(), colour = "gray") + 
  geom_hline(aes(yintercept = munitable16$Average, colour = Source), size = .8, linetype = "dashed") +
  labs( y="Million Gallons per Day", fill = "Source Type") +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major.y = element_line(colour = "light gray", size=.3),
        legend.position="bottom", 
        legend.box = "horizontal",
        axis.title.x=element_text(size=15),  # X axis title
        axis.title.y=element_text(size=15),
        axis.text.x = element_text(size=15, vjust = 1),
        axis.text.y = element_text(size=12),
        plot.margin = unit(c(0,5,1,1), "lines"),
        legend.text=element_text(size=12),
        legend.title=element_text(size=12)) + # This widens the right margin
  coord_cartesian(xlim = c(1,5), clip = "off") +
  geom_text(aes(label=MGD),
            position=position_dodge(width=0.9), 
            vjust = -.8) +
  annotate("text", y=munitable16$Average, x=5.85, label = paste(munitable16$Average, " MGD")) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)")


filename <- "PublicWaterSupply_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf",sep = " "), width=12, height=6)


###LINE GRAPH (municipal cont.) #############
mp_foundation_dataset <-read.csv(file = paste0(export_path,eyear+1,"/foundation_dataset_mgy_1982-",eyear,".csv"))

#For 10 years, but can adjust to longer timeframe
syear <- eyear-10
Xyears <- array()
ten <- 10:1
for (y in ten) { Xyears[y] = paste0("X",(eyear+1)-ten[y]) }

pws10 <- sqldf(paste0('SELECT "MP_hydroid", "Hydrocode", "Source.Type", "MP.Name", "Facility_hydroid", "Facility", "Use.Type", "Latitude", "Longitude", "FIPS.Code", "Locality", "OWS.Planner", ',Xyears[1],', ',Xyears[2],', ',Xyears[3],', ',Xyears[4],', ',Xyears[5],', ',Xyears[6],', ',Xyears[7],', ',Xyears[8],', ',Xyears[9],', ',Xyears[10],'
                FROM mp_foundation_dataset
                WHERE "Use.Type" LIKE "municipal"'))

#If we go back to the 15yr version, correct the reporting value for EARLYSVILLE FOREST WELL #2 (MP hydroid 64631), appears to be entered in gallons instead of MG #pws15[2120, 15] <- 0.0861

pws10_sum <- data.frame(matrix(nrow = length(Xyears), ncol = 2))
i=0
for (x in Xyears){
  i=i+1
  pws10_sum[i,1] <- (syear+i)
  pws10_sum[i,2] <- sqldf(paste0('SELECT 
  round(SUM("',Xyears[i],'")/365,2) AS "',Xyears[i],'"
                            FROM pws10'))
}

#Plot line graph
ggplot(pws10_sum, aes(x = X1, y = X2)) +
  geom_smooth(method = "lm", color = "grey",linetype = "dashed", se = FALSE)+ #optional trendline
  geom_line() +
  labs(x = "Year", y = "Total Annual Withdrawal (MGD)")+
  scale_x_continuous(breaks=c(eyear-9,eyear-6,eyear-3,eyear))+
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major.y = element_line(colour = "light gray", size=.3),
        axis.title.x=element_text(size=15),  # X axis title
        axis.title.y=element_text(size=15),
        axis.text.x = element_text(size=15, vjust = 1),
        axis.text.y = element_text(size=12))+
  coord_cartesian(ylim = c(725,825), clip = "off")
  

filename <- "PublicWaterSupply_LineGraph2.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf",sep = " "), width=12, height=6)



### POWER
# POWER PULL FROM VAHYDRO - REPLACE WITH POWER FILTER FROM MULTI_YR_DATA AFTER FIXING TOP SECTION TO PULL WITHOUT FILTER ON POWER ####################################
a <- c(
  'fossilpower',
  'nuclearpower'
)
b <- c('Groundwater', 'Surface Water', 'Total (GW + SW)')
cat_table<- data.frame(expand.grid(a,b))

colnames(cat_table) <- c('Use_Type', 'Source_Type')
cat_table <- arrange(cat_table, Source_Type, Use_Type )
#cat_table = FALSE
syear = 2018
eyear = 2022
year.range <- syear:eyear

multi_yr_data <- list()

for (y in year.range) {
  
  print(y)
  startdate <- paste(y, "-01-01",sep='')
  enddate <- paste(y, "-12-31", sep='')
  
  localpath <- tempdir()
  filename <- paste("data.all_",y,".csv",sep="")
  destfile <- paste(localpath,filename,sep="\\") 
  
  #has 3 issuing authorities, ONLY power
  download.file(paste("https://deq1.bse.vt.edu/d.dh/ows-awrr-map-export/wd_mgy?ftype_op=contains&ftype=power&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",startdate,"&tstime%5Bmax%5D=",enddate,"&bundle%5B0%5D=well&bundle%5B1%5D=intake&dh_link_admin_reg_issuer_target_id%5B0%5D=65668&dh_link_admin_reg_issuer_target_id%5B1%5D=91200&dh_link_admin_reg_issuer_target_id%5B2%5D=77498",sep=""), destfile = destfile, method = "libcurl")  
  data.power <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
  
  data_power <- data.power
  
  #remove duplicates (keeps one row)
  data_power <- distinct(data_power, MP_hydroid, .keep_all = TRUE)
  
  #remove hydropower
  data_power <- data_power %>% filter(Use.Type != "hydropower")
  
  if (length(which(data_power$Use.Type=='facility')) > 0) {
    data_power <- data_power[-which(data_power$Use.Type=='facility'),]
  }
  #rename columns
  colnames(data_power) <- c('HydroID', 'Hydrocode', 'Source_Type',
                            'MP_Name','Facility_hydroid','Facility', 'Use_Type', 'Year',
                            'mgy', 'mgd', 'lat', 'lon', 'fips','locality','OWS Planner')
  
  data_power$mgd <- data_power$mgy/365
  #make use type values lowercase
  data_power$Use_Type <- str_to_lower(data_power$Use_Type)
  #change 'Well' and 'Surface Water Intake' values in source_type column to match report headers
  levels(data_power$Source_Type) <- c(levels(data_power$Source_Type), "Groundwater", "Surface Water")
  data_power$Source_Type[data_power$Source_Type == 'Well'] <- 'Groundwater'
  data_power$Source_Type[data_power$Source_Type == 'Surface Water Intake'] <- 'Surface Water'
  
  #combine each year of data into a single table
  multi_yr_data <- rbind(multi_yr_data, data_power)
  
  
  catsourcesum <- sqldf(paste('SELECT Use_Type, Source_Type,
                                         sum(mgd) AS mgd,
                                         sum(mgy) AS mgy
                                  FROM data_power
                                  WHERE Source_Type = "Groundwater" OR Source_Type = "Surface Water"
                                  GROUP BY Use_Type, Source_Type
                                 ',sep = ''))

  catsourcesum$mgd = round(catsourcesum$mgy / 365.0,2)
  catsourcesum <- arrange(catsourcesum, Source_Type, Use_Type)
  
  
  catsum <- catsourcesum
  catsum$Source_Type <- "Total (GW + SW)"
  
  catsum <- sqldf('SELECT Use_Type, Source_Type,
                        sum(mgd) AS mgd,
                        sum(mgy) AS mgy
                      FROM catsum
                      GROUP BY Use_Type')

  
  year_table <- rbind(catsourcesum, catsum)
  year_table <- arrange(year_table, Source_Type, Use_Type)
  assign(paste("y", y, sep=''), year_table)
  if (is.logical(cat_table)) {
    cat_table = year_table[,1:3]
  } else {
    cat_table <- cbind(cat_table, year_table[,3])
  }
  
}

#cat_table_power <- cat_table <- cat_table_raw

cat_table <- data.frame(cat_table[2],cat_table[1],cat_table[3:(length(year.range)+2)])
names(cat_table) <- c('Source Type', 'Category', year.range)

cat_table$multi_yr_avg <- round((rowMeans(cat_table[3:(length(year.range)+2)], na.rm = FALSE, dims = 1)),2)

##Groundwater Total##
gw_table <- cat_table[cat_table$"Source Type" == 'Groundwater',]
gw_sums <- data.frame(Source_Type="",
                      Category="Total Groundwater",
                      mgd=sum(gw_table[3]),
                      mgd=sum(gw_table[4]),
                      mgd=sum(gw_table[5]),
                      mgd=sum(gw_table[6]),
                      mgd=sum(gw_table[7]),
                      mgd=sum(gw_table[8])
)
colnames(gw_sums) <- c('Source Type', 'Category',year.range,'multi_yr_avg')
##Surface Water Total##
sw_table <- cat_table[cat_table$"Source Type" == 'Surface Water',]
sw_sums <- data.frame(Source_Type="",
                      Category="Total Surface Water",
                      mgd=sum(sw_table[3]),
                      mgd=sum(sw_table[4]),
                      mgd=sum(sw_table[5]),
                      mgd=sum(sw_table[6]),
                      mgd=sum(sw_table[7]),
                      mgd=sum(sw_table[8])
)
colnames(sw_sums) <- c('Source Type', 'Category',year.range,'multi_yr_avg')
cat_table <- rbind(cat_table,gw_sums, sw_sums)


pct_chg <- round(((cat_table[paste(eyear)]-cat_table["multi_yr_avg"])/cat_table["multi_yr_avg"])*100, 1)
names(pct_chg) <- paste('% Change',eyear,'to Avg.')
cat_table <- cbind(cat_table,'pct_chg' = pct_chg)

#### ADD BOTTOM ROW OF TOTALS TO TABLE######################
# ADD BOTTOM ROW OF TOTALS TO TABLE
cat_table.total <- cat_table[c(1:4),]
multi_yr_avg.sums <- mean(c(sum(cat_table.total[3]),
                            sum(cat_table.total[4]),
                            sum(cat_table.total[5]),
                            sum(cat_table.total[6]),
                            sum(cat_table.total[7])))

total_pct_chg <- round(((sum(cat_table.total[7])-multi_yr_avg.sums)/multi_yr_avg.sums)*100, 1)

catsum.sums <- data.frame(Source_Type="",
                          Category="Total (GW + SW)",
                          mgd=sum(cat_table.total[3]),
                          mgd=sum(cat_table.total[4]),
                          mgd=sum(cat_table.total[5]),
                          mgd=sum(cat_table.total[6]),
                          mgd=sum(cat_table.total[7]),
                          mgd=multi_yr_avg.sums,
                          mgd=total_pct_chg 
)

colnames(catsum.sums) <- c('Source Type', 'Category',year.range,'multi_yr_avg',paste('% Change',eyear,'to Avg.'))
cat_table <- rbind(cat_table,catsum.sums)

print(cat_table)

#Power Table CSV Export
write.csv(cat_table, paste(export_path,eyear+1,"/Table1_Power_",eyear-4,"-",eyear,".csv",sep = ""), row.names = F)

#Note, if generating Table1 with power, can now return back to Table 1 w/power section and continue running

### POWER TABLE 19###########################################################
#This table requires the power pull to be completed first
#redefine cat_table to pull power table instead of non-power Table1
cat_table <- read.csv(file = paste(export_path,eyear+1,"/Table1_Power_",eyear-4,"-",eyear,".csv",sep = ""))
yearrangeX <- c(paste0("X",year.range[1]), paste0("X",year.range[2]), paste0("X",year.range[3]), paste0("X",year.range[4]), paste0("X",year.range[5]))

#Table 19: 20xx-20xx Power Generation Water Withdrawals by Source Type (MGD)
powtable19 <- rbind(cat_table[1:2,],cat_table[7,],cat_table[3:4,],cat_table[8,],cat_table[9,])
rownames(powtable19) <- NULL

powtable19 <- sqldf(paste0('SELECT "Source.Type",
                    CASE 
                    WHEN "Category" LIKE "%fossil%"
                    THEN "Fossil"
                    WHEN "Category" LIKE "%nuclear%"
                    THEN "Nuclear"
                    ELSE "Category"
                    END AS "Category",
                     "',yearrangeX[1],'", "',yearrangeX[2],'", "',yearrangeX[3],'", "',yearrangeX[4],'", "',yearrangeX[5],'", "multi_yr_avg", "X..Change.',eyear,'.to.Avg."
                    FROM powtable19'))

pow_tex <- kable(powtable19[2:9], booktabs = T, align = c('l','c','c','c','c','c','c','c'),
                 caption = paste(syear,"-",eyear,"Power Generation Water Withdrawals by Source Type (MGD)",sep=" "),
                 label = paste(syear,"-",eyear,"Power Generation Water Withdrawal Trends(MGD)",sep=" "),
                 col.names = c("Power Type",
                               year.range[1], year.range[2], year.range[3], year.range[4], year.range[5],
                               #colnames(powtable19[3:7]),
                               paste((eyear-syear)+1,"Year Avg."),
                               paste0("% Change ",eyear," to Avg."))) %>%
  kable_styling(latex_options = c("scale_down")) %>%
  pack_rows("Groundwater", 1, 3,  hline_after = F) %>%
  pack_rows("Surface Water", 4, 6, hline_before = T, hline_after = F) %>%
  row_spec(7, bold=T, extra_css = "border-top: 1px solid")

#CUSTOM LATEX CHANGES
#insert hold position header
pow_tex <- gsub(pattern = "{table}[t]", 
                repl    = "{table}[ht!]", 
                x       = pow_tex, fixed = T )

#make last column name wrap on 2 rows (adjusts column width) 
pow_tex <- gsub(pattern  = "{lccccccc}", 
                repl    = "{lrrrrr>{\\raggedleft\\arraybackslash}p{5em}>{\\raggedleft\\arraybackslash}p{6em}}", 
                x       = pow_tex, fixed = T,useBytes = F )

pow_tex %>%
  cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\Overleaf\\Power_table",file_ext,sep = ''))


### POWER BAR GRAPH FIGURE 26 ############################################################

#transform wide to long table
power <- cat_table[1:4,-9]
colnames(power) <- c('Source', 'Power', year.range, 'Average')

power <- gather(power,Year, MGD, paste(syear):paste(eyear), factor_key = TRUE)

mean_mgd <- power[1:4,1:3]
colnames(mean_mgd) <- c('Source', 'Power', 'MGD')

#plot bar graph
ggplot(data=power, aes(x=Year, y=MGD, fill = Source)) +
  geom_col(position=position_dodge(), colour = "gray") + 
  geom_segment(data = mean_mgd, x = .5, xend = 5.5, aes(y = MGD, yend = MGD, colour = Source), size = .8, linetype = "dashed") +
  labs( y="Million Gallons per Day", fill = "Source Type") +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major.y = element_line(colour = "light gray", size=.3),
        legend.position="bottom", 
        legend.box = "horizontal",
        axis.title.x=element_text(size=15),  # X axis title
        axis.title.y=element_text(size=15),
        axis.text.x = element_text(size=15, vjust = 1),
        axis.text.y = element_text(size=12),
        plot.margin = unit(c(0,2,1,1), "lines"),
        legend.text=element_text(size=12),
        legend.title=element_text(size=12)) + # This widens the right margin
  coord_cartesian(xlim = c(1,5.61), clip = "off") +
  geom_text(aes(label=MGD),
            position = position_stack(vjust = .5), 
            vjust = -.2)+
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)") +
  geom_text(data = mean_mgd, aes( y = MGD, label = paste0(MGD, " \n MGD")), x = 5.8) +
  facet_grid(Source~Power, scales = "free_y")

filename <-"Power_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf/",sep = " "), width=12, height=6)

################### TOP USERS BY USE TYPE  ############################

# This section is expecting the POWER PULL section multi_yr_data to be run

#Table: Highest Reported  Withdrawals in eyear (MGD)
#make Category values capital
multi_yr_data$Use_Type <- str_to_title(multi_yr_data$Use_Type)
multi_yr_data$Facility <- str_to_title(multi_yr_data$Facility)
#transform from long to wide table
data_all <- pivot_wider(data = multi_yr_data, id_cols = c(HydroID, Source_Type, MP_Name, Facility_hydroid, Facility,Use_Type, fips), names_from = Year, values_from = mgy)

data_all <- sqldf('SELECT a.*, b.name AS Locality
                  FROM data_all a
                  LEFT OUTER JOIN fips b
                  ON a.fips = b.code')

#avg mgd, order by
data_avg <- sqldf('SELECT HydroID, avg(mgy) as multi_yr_avg
                  FROM multi_yr_data
                  GROUP BY HydroID')
data_all <- sqldf('SELECT a.*,  b.multi_yr_avg, 
                        CASE WHEN Source_Type = "Groundwater"
                        THEN 1
                        END AS GW_type,
                        CASE
                        WHEN Source_Type = "Surface Water"
                        THEN 1
                        END AS SW_Type
                  FROM data_all AS a
                  LEFT OUTER JOIN data_avg AS b
                  ON a.HydroID = b.HydroID')

#group by facility
data_all_fac <- sqldf(paste('SELECT Facility_HydroID, Facility, Source_Type, Use_Type, Locality, round((sum(',paste('"',eyear,'"', sep = ''),')/365),1) AS mgd, round((sum(multi_yr_avg)/365),1) as multi_yr_avg, sum(GW_type) AS GW_type, sum(SW_type) AS SW_type
                      FROM data_all
                      GROUP BY Facility_HydroID',sep = ''))

top5 <- sqldf(paste('SELECT Facility_HydroID, Facility, 
                        Locality, 
                        CASE 
                        WHEN GW_Type > 0 AND SW_Type IS NULL
                        THEN "GW"
                        WHEN SW_Type > 0 AND GW_Type IS NULL
                        THEN "SW"
                        WHEN GW_Type > 0 AND SW_Type > 0
                        THEN "SW/GW"
                        END AS Type,
                        multi_yr_avg,
                        mgd,
                        Use_Type AS Category
                FROM data_all_fac
                WHERE Use_Type LIKE "%power%"
                ORDER BY mgd DESC
                LIMIT 5',sep = ''))

#KABLE
top5_latex <- kable(top5[2:6],'latex', booktabs = T, align = c('l','l','c','c','c') ,
                    caption = paste("Highest Reported Power Generation Withdrawals in",eyear,"(MGD)",sep=" "),
                    label = paste("Highest Reported Power Generation Withdrawals in",eyear,"(MGD)",sep=" "),
                    col.names = c(
                      'Facility',
                      'Locality',
                      'Type',
                      paste((eyear-syear)+1,"Year Avg."),
                      paste(eyear, 'Withdrawal', sep = ' '))) %>%
  kable_styling(latex_options = c("striped", "scale_down")) %>%
  column_spec(1, width = "12em")

#CUSTOM LATEX CHANGES
#insert hold position header
top5_tex <- gsub(pattern = "{table}[t]", 
                 repl    = "{table}[ht!]", 
                 x       = top5_latex, fixed = T )
top5_tex

top5_tex %>%
  cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",eyear+1," Report\\Overleaf\\Power_top5.tex",sep = ''))
