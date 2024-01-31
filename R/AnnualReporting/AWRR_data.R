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
fips <- read.csv(file = "U:\\OWS\\Report Development\\Annual Water Resources Report\\October 2022 Report\\fips_codes_propernames.csv")

##Legacy VAHydro code
# ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
# ds$get_token(rest_pw)
# tsdef_url <- paste0(site,"/ows-awrr-map-export/wd_mgy?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",
#                     syear,"-01-01&tstime%5Bmax%5D=",eyear,"-12-31&bundle%5B0%5D=well&bundle%5B1%5D=intake")
# # multi_yr_data <- ds$auth_read(tsdef_url, content_type = "text/csv", delim = ",")

################ PULL DIRECTLY FROM DEQ2 USING SQL ############################
#Pull foundation data through SQL,VAHydro Issue #848
#read in the resulting file
multi_yr_data <- read.csv(paste0(export_path,eyear+1,"/awrr_foundation_",eyear+1,".csv"))
duplicate_check <- sqldf('SELECT *, count(mp_hydroid)
      FROM multi_yr_data
      WHERE Use_Type NOT LIKE "gw2_%"
      GROUP BY mp_hydroid, year
      HAVING count(mp_hydroid) > 1')

#Group the MPs by HydroID, Year to account for MPs that are linked to multiple Facilities (GW2 & Permitted) 
## Added in locality name matching (corrects locality names form hydro)
multi_yr_data <- sqldf('SELECT awrr.mp_hydroid as "MP_hydroid", awrr.hydrocode as "Hydrocode", 
CASE
  WHEN LOWER(awrr.Source_Type) LIKE "%well%" THEN "Groundwater"
  WHEN LOWER(awrr.Source_Type) LIKE "%intake%" THEN "Surface Water"
  ELSE LOWER(awrr.Source_Type)
END AS "Source_Type", 
awrr.MP_Name, awrr.facility_hydroid as "Facility_hydroid", awrr.facility as "Facility", 
CASE 
  WHEN LOWER(awrr.Use_Type) LIKE "%agriculture%" THEN "agriculture"
  WHEN LOWER(awrr.Use_Type) LIKE "%industrial%" THEN "manufacturing"
  ELSE LOWER(awrr.Use_Type)
END AS Use_Type, awrr.latitude as "Latitude", awrr.longitude as "Longitude", awrr.FIPS_Code, 
f.name as "Locality", awrr.OWS_Planner, MAX(awrr."year") AS Year, MAX(awrr.tsvalue) AS "Water_Use_MGY"

FROM multi_yr_data awrr
LEFT JOIN fips f
  ON awrr.FIPS_Code = f.code
  
WHERE awrr.Use_Type NOT LIKE "gw2_%"
AND awrr."Facility" != "DALECARLIA WTP"
GROUP BY "MP_hydroid", "Hydrocode","Source_Type", "MP_Name","FIPS_Code","Year" 
      ')

##MP FOUNDATION DATASET - BEGINNING 1982 -----------------------------------------------------------------------------------------------------------------
mp_foundation_dataset <- pivot_wider(data = multi_yr_data, id_cols = c("MP_hydroid", "Hydrocode", 
                        "Source_Type", "MP_Name", "Facility_hydroid", "Facility", "Use_Type", 
                        "Latitude", "Longitude", "FIPS_Code", "Locality", "OWS_Planner"), 
                           names_from = "Year", values_from = "Water_Use_MGY", names_sort = T)

write.csv(mp_foundation_dataset, paste0(export_path,eyear+1,"/foundation_dataset_mgy_",syear,"-",eyear,".csv"), row.names = F)

#Add 5yr avg calculation to the foundation dataset. 
#To improve, do this using sql and confirm that NAs are not counted in the average, then perpetuate this change into the script
fiveyr_avg_mgy <- round((rowMeans(mp_foundation_dataset[(length(mp_foundation_dataset)-4):length(mp_foundation_dataset)], na.rm = TRUE, dims = 1)),2)
mp_foundation_dataset <- cbind(mp_foundation_dataset,fiveyr_avg_mgy)
write.csv(mp_foundation_dataset, paste0(export_path,eyear+1,"/foundation_dataset_mgy_",syear,"-",eyear,"_5ya.csv"), row.names = F)

##split into 2 datasets: POWER & NON-POWER -------------------------------------------------------------------------------------------------
#Al
mp_all <- sqldf(paste0('
SELECT MP_hydroid, Hydrocode, Source_Type, MP_Name, Facility_hydroid, Facility, Use_Type, Latitude, 
Longitude, FIPS_Code, "Locality", "OWS_Planner","',eyear-4,'","',eyear-3,'","',eyear-2,'","',eyear-1,'","',eyear,'"
FROM mp_foundation_dataset
WHERE "Use Type" NOT LIKE "%hydropower%"'))

write.csv(mp_all, paste0(export_path,eyear+1,"/mp_all_mgy_",eyear-4,"-",eyear,".csv"), row.names = F)  

#POWER
mp_all_power <-  sqldf(paste0('
SELECT "MP_hydroid", "Hydrocode", "Source_Type", "MP_Name", "Facility_hydroid", "Facility", "Use_Type",
"Latitude", "Longitude", "FIPS_Code", "Locality", "OWS_Planner","',
eyear-4,'","',eyear-3,'","',eyear-2,'","',eyear-1,'","',eyear,'"
FROM mp_foundation_dataset
WHERE "Use Type" LIKE "%power%"
'))

write.csv(mp_all_power, paste0(export_path,eyear+1,"/mp_power_mgy_",eyear-4,"-",eyear,".csv"), row.names = F)  

# TABLE 1 SUMMARY -----------------------------------------------------------------------------------
mp_all <- sqldf(' SELECT * FROM mp_foundation_dataset
                WHERE Use_Type NOT IN ("hydropower","agricultural")
                  AND Use_Type NOT LIKE "%facility%"')

sql_year_calc <- paste0('round(SUM("',eyear-4,'")/365,2),
round(SUM("',eyear-3,'")/365,2),
round(SUM("',eyear-2,'")/365,2),
round(SUM("',eyear-1,'")/365,2),
round(SUM("',eyear,'")/365,2)')

cat_table <- sqldf(paste0('SELECT "Source_Type" AS "Source Type", 
"Use_Type" AS "Use Type",',sql_year_calc,'
                       FROM mp_all
                       GROUP BY "Source Type", "Use Type"'))

cat_table_aggreg <- sqldf(paste0('SELECT "Total (GW + SW)" AS "Source Type", 
"Use_Type" AS "Use Type",',sql_year_calc,'
                       FROM mp_all
                       GROUP BY "Use Type"'))

cat_table_gw_np <- sqldf(paste0('SELECT " " AS "Source Type", 
"Total Groundwater" AS "Use Type",', sql_year_calc,'
                       FROM mp_all
                       WHERE "Source_Type" LIKE "Groundwater"
                          AND "Use_Type" NOT LIKE "%power%"'))
cat_table_sw_np <- sqldf(paste0('SELECT " " AS "Source Type", 
"Total Surface Water" AS "Use Type",', sql_year_calc,'
                       FROM mp_all
                       WHERE "Source_Type" LIKE "Surface Water"
                          AND "Use_Type" NOT LIKE"%power%"'))
cat_table_totals_np <- sqldf(paste0('SELECT " " AS "Source Type", 
"Total (GW + SW)" AS "Use Type",', sql_year_calc,'
                       FROM mp_foundation_dataset
                       WHERE "Use_Type" NOT LIKE "%power%"'))

cat_table_gw_pow <- sqldf(paste0('SELECT " " AS "Source Type", 
"Total Groundwater" AS "Use Type",', sql_year_calc,'
                       FROM mp_all
                       WHERE "Source_Type" LIKE "Groundwater"
                          AND "Use_Type" LIKE "%power%"'))
cat_table_sw_pow <- sqldf(paste0('SELECT " " AS "Source Type", 
"Total Surface Water" AS "Use Type",', sql_year_calc,'
                       FROM mp_all
                       WHERE "Source_Type" LIKE "Surface Water"
                          AND "Use_Type" LIKE"%power%"'))
cat_table_totals_pow <- sqldf(paste0('SELECT " " AS "Source Type", 
"Total (GW + SW)" AS "Use Type",', sql_year_calc,'
                       FROM mp_all
                       WHERE "Use_Type" LIKE "%power%"'))

cat_table_totals <- sqldf(paste0('SELECT " " AS "Source Type", 
                       "Total (GW + SW)" AS "Use Type",', sql_year_calc,'
                       FROM mp_foundation_dataset'))


#rowbind/union the rows together
cat_table <- rbind(cat_table,cat_table_aggreg, cat_table_gw_np, cat_table_sw_np, 
                   cat_table_totals_np,cat_table_gw_pow,cat_table_sw_pow,cat_table_totals_pow,
                   cat_table_totals)

#An ugly line just to get fossil and nuclear power next to each other
cat_table <- cat_table[c(1,2,4:7,3,8,9:10,12:15,11,16,17:18,20:23,19,24,25:31),]

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

#Change Municipal to public water supply
cat_table$Category[cat_table$Category == 'Municipal'] <- 'Public Water Supply'

#view and check Table 1
print(cat_table)

## SAVE TABLE 1 SUMMARY --------------------------------------------------------------------------------------------

#save the cat_table to use for data reference - we can refer to that csv when asked questions about the data
write.csv(cat_table, paste(export_path,eyear+1,"/Table1_",eyear-4,"-",eyear,".csv",sep = ""), row.names = F)

# Create a non-power form of table1
cat_table_np <- cat_table[c(1:7,9:15,17:22,25:27),]
write.csv(cat_table_np, paste(export_path,eyear+1,"/Table1_NoPower_",eyear-4,"-",eyear,".csv",sep = ""), row.names = F)


#IS THERE A STATIC TABLE? READ THAT IN AND BEGIN FROM HERE ##########################################################

export_path <- "U:/OWS/foundation_datasets/awrr/"

#redefine year range
syear <- 2018
eyear <- 2022
eyearX <- paste0("X",eyear) 
year.range <- syear:eyear

cat_table <- read.csv(file = paste(export_path,eyear+1,"/Table1_",eyear-4,"-",eyear,".csv",sep = ""))
rownames(cat_table) <- c()

colnames(cat_table)[colnames(cat_table)=="multi_yr_avg"] <- "5 Year Avg."
colnames(cat_table)[colnames(cat_table)==paste0("X..Change.",eyear,".to.Avg.")] <- paste0("% Change ",eyear," to Avg.")
for (s in 1:length(year.range)) {colnames(cat_table)[colnames(cat_table)==paste0("X",year.range[s])] <- year.range[s]}


#colnames(cat_table) <- c('Source Type', 'Category',year.range,'multi_yr_avg', paste('% Change',eyear,'to Avg.'))

multi_yr_data <- read.csv(file = paste0(export_path,eyear+1,"/mp_all_mgy_",eyear-4,"-",eyear,".csv"))

#calculate the Multi Year Avg column
fiveyr_avg_mgy <- round((rowMeans(multi_yr_data[(length(multi_yr_data)-4):length(multi_yr_data)], na.rm = TRUE, dims = 1)),2)
multi_yr_data <- cbind(multi_yr_data,fiveyr_avg_mgy)

#rename columns so R and SQL statements recognize the column names
colnames(multi_yr_data)[colnames(multi_yr_data)=="Use.Type"] <- "Use_Type"
colnames(multi_yr_data)[colnames(multi_yr_data)=="Source.Type"] <- "Source_Type"
colnames(multi_yr_data)[colnames(multi_yr_data)=="FIPS.Code"] <- "FIPS"

#make Category values capital
multi_yr_data$Use_Type <- str_to_title(multi_yr_data$Use_Type)
multi_yr_data$Facility <- str_to_title(multi_yr_data$Facility)



## End read in section, now can continue or jump to the individual table sections #############################################################

################### MAY QA CHECK ##########################################
# kable(cat_table, booktabs = T) %>%
#   kable_styling(latex_options = c("striped", "scale_down")) %>%
#   column_spec(8, width = "5em") %>%
#   column_spec(9, width = "5em") %>%
#   cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",
#   eyear+1," Report\\May_QA\\summary_table_vahydro_",eyear+1,"_",Sys.Date(),".html",sep = ""))


# Total Facilities Count ##################

## Fac_all #########################

#write fac_all for total withdrawals per facility
mp_foundation <- read.csv(file = paste0(export_path,eyear+1,"/foundation_dataset_mgy_1982-",eyear,".csv"))

#Remake long version so that we can sum the mgy for all MPs of each Facility hydroid
mp_long <- pivot_longer(mp_foundation, cols = starts_with("X"), names_to = "Year", names_prefix = "X", values_to = "mgy")
fac_all <- sqldf('
SELECT "Facility_hydroid", "Facility", "Year", sum("mgy") as mgy, sum(("mgy")/365) as mgd, "Use_Type" as "Use_Type", "FIPS_Code" as FIPS, Locality AS Locality
FROM mp_long
GROUP BY Facility_hydroid, Year
')
#export long format
write.csv(fac_all, paste(export_path,eyear+1,"\\fac_all_1982-",eyear,".csv",sep = ""), row.names = F)



## 1982-Current Total Fac and Use (optional) #####

## Counts total number of reporting facilities and total use for 1982-eyear, currently for internal analysis not for in report

### Including power
fac_all <- sqldf('SELECT * FROM fac_all WHERE Use_Type NOT IN ("hydropower","facility")')
fac_wide <- pivot_wider(data = fac_all, id_cols = c("Facility_hydroid", "Facility","Use_Type", "FIPS","Locality"), 
                        names_from = "Year", values_from = "mgy", names_sort = T)

year.range.f <- 1982:eyear
#Put year range in empty dataframe
count_3D <- data.frame(Year = year.range.f, "Num_Reporting_Fac"= NA, BGD = NA)

#sapply with each year
count_3D$BGD <- sapply(count_3D$Year,function(x) {sum(fac_all$mgd[fac_all$Year==x],na.rm = TRUE)})/1000
count_3D$Num_Reporting_Fac <- sapply(count_3D$Year,function(x) {sum(fac_all$Year == x & !is.na(fac_all$mgy), na.rm = TRUE)})

write.csv(count_3D, paste("U:\\OWS\\foundation_datasets\\awrr\\",eyear+1,"\\total_fac_wpower_1982-",eyear,".csv",sep = ""), row.names = F)


### Excluding power
mp_foundation_np <-  sqldf(paste0('SELECT * FROM mp_foundation WHERE "Use_Type" NOT LIKE "%power%"'))

mp_long_np <- pivot_longer(mp_foundation_np, cols = starts_with("X"), names_to = "Year", names_prefix = "X", values_to = "mgy")
fac_all_np <- sqldf('SELECT "Facility_hydroid", "Facility", "Year", sum("mgy") as mgy, sum(("mgy")/365) as mgd, "Use_Type" as Use_Type, "FIPS_Code" as FIPS
                    FROM mp_long_np
                    GROUP BY Facility_hydroid, Year')
#Count total number of reporting facilities for each year
mp_wide_np <- pivot_wider(data = fac_all_np, id_cols = c("Facility_hydroid", "Facility","Use_Type", "FIPS"), names_from = "Year", values_from = "mgy", names_sort = T)

year.range.f <- 1982:eyear
count_3D <- data.frame(Year = year.range.f, "Num_Reporting_Fac"= NA, BGD = NA)

count_3D$BGD <- sapply(count_3D$Year,function(x) {sum(fac_all$mgd[fac_all$Year==x],na.rm = TRUE)})/1000
count_3D$Num_Reporting_Fac <- sapply(count_3D$Year,function(x) {sum(fac_all$Year == x & !is.na(fac_all$mgy), na.rm = TRUE)})


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
print(paste0("The total number of facilities presented in the report includes nuclear & fossil power, 
             excludes hydropower and includes Dalecarlia: ", totalfac+1," facilites"))


#TABLE 1 : w/o power Summary ##########################################
#ONlY RUN THIS IF YOU WANT TABLE 1 WITHOUT POWER, OTHERWISE MOVE TO TABLE1 :wPOWER SECTION
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
  cat(., file = paste(export_path,"summary_table1.tex",sep = ''))

################### TABLE 4 : TOP 20 USERS ##########################################

#To run this section, read in the static table section first

data_all <-multi_yr_data

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
data_all_fac <- sqldf(paste('
SELECT Facility_HydroID, Facility, Source_Type, Use_Type, Locality,
round((sum(',paste('"',eyearX,'"', sep = ''),')/365),1) AS mgd, 
round((sum(fiveyr_avg_mgy)/365),1) as fiveyr_avg_mgd, 
sum(GW_type) AS GW_type, sum(SW_type) AS SW_type
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
                WHERE Use_Type NOT LIKE "%power%"
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

# TOP USERS BY USE TYPE (TABLES 6, 8, 10, 12, 14, 15,  17, 20) ############################
#Chapter 3 Top5 tables
#This section requires Table 4 Top 20 section to be run first, through the creation of data_all and data_all_fac

 ### Ag Irr Com Min Pow Top5 -------------
#Table: Highest Reported  Withdrawals in eyear (MGD)
use_types <- list("Agriculture", "Commercial", "Irrigation", "Mining", "Power")

for (u in use_types) {
  print(paste('PROCESSING TOP 5 TABLE: ',u),sep = '')
  
    top5 <- sqldf(paste0('SELECT Facility_HydroID, Facility, 
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
                WHERE Use_Type LIKE "%',u,'%"
                ORDER BY mgd DESC
                LIMIT 5'))
    
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
      ut <- "PublicWaterSupply"
    }
    
    #group by source type from data_all
    #group by facility
    data_all_source <- sqldf(paste0('
  SELECT Facility_HydroID, Facility, Source_Type, Use_Type, Locality, 
   round((sum(',paste('"',eyearX,'"', sep = ''),')/365),1) AS mgd, 
   round((sum(fiveyr_avg_mgy)/365),1) as fiveyr_avg_mgd, sum(GW_type) AS GW_type, sum(SW_type) AS SW_type
  FROM data_all
  GROUP BY Facility_HydroID, Source_Type
  '))
    
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



# By Source Type - Tables + Graphs ##################################################
# This section of tables requires the static table section to be read in first, and is expecting cat_table to be Table1 WITHOUT power.


### AG #####
agtable5 <- cat_table[c(1,9,17),-2]

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
  cat(., file = paste("U:/OWS/Report Development/Annual Water Resources Report/October ",eyear+1," Report/overleaf/Agriculture_table",file_ext,sep = ''))

# #use this as an interim view and check
# #kable(cat_table, booktabs = T) %>% 
#   kable_styling(latex_options = c("striped", "scale_down")) %>%
#   column_spec(8, width = "5em") %>%
#   column_spec(9, width = "5em") %>%
#   cat(., file = paste("U:\\OWS\\Report Development\\Annual Water Resources Report\\October ",
#   eyear+1," Report\\May_QA\\summary_table_vahydro_",eyear+1,"_",Sys.Date(),".html",sep = ""))

### BAR GRAPH ###################################################################################
#transform wide to long table
agtable5 <- agtable5[-3,-8]
colnames(agtable5)[colnames(agtable5)=="Source.Type"] <- "Source" #Source is called in the ggplot
colnames(agtable5)[colnames(agtable5)==paste((eyear-syear)+1,"Year Avg.")] <- "Average"

agtable5 <- pivot_longer(data = agtable5, cols = paste0(syear):paste0(eyear), names_to = "Year", values_to = "MGD")

#plot bar graph
ggplot(data=agtable5, aes(x=Year, y=MGD, fill = Source)) +
  geom_col(position=position_dodge(), colour = "gray") + 
  geom_hline(aes(yintercept = agtable5$multi_yr_avg, colour = Source), size = .8, linetype = "dashed") +
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
  annotate("text", y=agtable5$multi_yr_avg, x=5.85, label = paste(agtable5$multi_yr_avg, " MGD")) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)")

filename <- "Agriculture_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/overleaf",sep = " "), width=12, height=6)

### irrig ######################################################################################
#irrig
irrigtable7 <- cat_table[c(3,11,19),-2]

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
  geom_hline(aes(yintercept = irrigtable7$multi_yr_avg, colour = Source), size = .8, linetype = "dashed") +
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
  annotate("text", y=irrigtable7$multi_yr_avg, x=5.85, label = paste(irrigtable7$multi_yr_avg, " MGD")) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)")


filename <- "Irrigation_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf",sep = " "), width=12, height=6)

### commercial####################################################################################
commtable9 <- cat_table[c(2,10,18),-2]

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
  geom_hline(aes(yintercept = commtable9$multi_yr_avg, colour = Source), size = .8, linetype = "dashed") +
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
  annotate("text", y=commtable9$multi_yr_avg, x=5.85, label = paste(commtable9$multi_yr_avg, " MGD")) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)")

filename <- "Commercial_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf",sep = " "), width=12, height=6)


###mining #########################################################################################
#mining
mintable11 <- cat_table[c(5,13,21),-2]

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
  geom_hline(aes(yintercept = mintable11$multi_yr_avg, colour = Source), size = .8, linetype = "dashed") +
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
  annotate("text", y=mintable11$multi_yr_avg, x=5.85, label = paste(mintable11$multi_yr_avg, " MGD")) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)")
  
#+ annotate("text", y=mintable11$Average-1.8, x=.79, label ="5 Year Avg.") 
#+ annotate("text", y=mintable11$Average-3, x=.79, label = paste('=',mintable11$Average, " MGD"))

filename <- "Mining_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf",sep = " "), width=12, height=6)


###manufacturing #####################################################################################
#manufacturing
mantable13 <- cat_table[c(4,12,20),-2]

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
  geom_hline(aes(yintercept = mantable13$multi_yr_avg, colour = Source), size = .8, linetype = "dashed") +
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
  annotate("text", y=mantable13$multi_yr_avg, x=5.85, label = paste(mantable13$multi_yr_avg, " MGD")) +
  scale_fill_brewer(palette = "Dark2", direction = -1) +
  scale_colour_brewer(palette = "Dark2", direction = -1, name = "5 Year Avg. (MGD)")


filename <- "Manufacturing_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf",sep = " "), width=12, height=6)


###municipal aka public water supply ########################################################
#muni aka pws
munitable16 <- cat_table[c(6,14,22),-2]

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
  geom_hline(aes(yintercept = munitable16$multi_yr_avg, colour = Source), size = .8, linetype = "dashed") +
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
  annotate("text", y=munitable16$multi_yr_avg, x=5.85, label = paste(munitable16$multi_yr_avg, " MGD")) +
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

pws10 <- sqldf(paste0('
SELECT "MP_hydroid", "Hydrocode", "Source_Type", "MP_Name", "Facility_hydroid", "Facility",
 "Use_Type", "Latitude", "Longitude", "FIPS_Code", "Locality", "OWS_Planner", ',
 Xyears[1],', ',Xyears[2],', ',Xyears[3],', ',Xyears[4],', ',Xyears[5],', ',Xyears[6],', ',Xyears[7],', ',Xyears[8],', ',Xyears[9],', ',Xyears[10],'
FROM mp_foundation_dataset
WHERE "Use_Type" LIKE "municipal"'))

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




###Power #########################################################################################
powtable19 <- cat_table[c(7:8,28,15:16,29,30),]

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


### POWER BAR GRAPH ############################################################

#transform wide to long table
power <- cat_table[c(7:8,15:16),-9]
colnames(power) <- c('Source', 'Power', year.range, 'Average')

power <- pivot_longer(power,cols = all_of(as.character(year.range)), names_to = "Year", values_to = "MGD")

mean_mgd <- power[c(1,6,11,16),1:3]
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
  facet_grid(Source~Power, scales = "free_y") +
  theme(strip.text.x = element_text(size = 15),strip.text.y = element_text(size = 12)) ##Changed facet title font sizes

filename <-"Power_BarGraph.pdf"
ggsave(file=filename, path = paste("U:/OWS/Report Development/Annual Water Resources Report/October",eyear+1,"Report/Overleaf/",sep = " "), width=12, height=6)
