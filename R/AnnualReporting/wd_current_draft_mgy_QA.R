##################################################################################
#This script is the QA on Annual Reporting data
#It compares the prior 5yr avg against the current draft 5yr avg and prioritizes MP changes for planners to look at 
##################################################################################

library(sqldf)
baseoath <- '/var/www/R'
source(paste0(basepath,'/config.local.private'))

#prevents scientific notation
options(scipen = 20)
#Purpose: Compare the new draft (wd_current_draft_mgy; 2017-2021) that has been set to the previous year's set 5-year avg (wd_current_mgy; 2016-2020)
cyear <- format(Sys.time(), "%Y")
syear <- as.numeric(cyear)-5
eyear <- as.numeric(cyear)-1

##Dates are hardcoded into the drupal view. Changing the dates on 03-07-24 made everything 0
draft_qa <- read.csv("https://deq1.bse.vt.edu/d.dh/current-average-use-workflow-compare-export?hydroid_op=%3D&hydroid%5Bvalue%5D=&hydroid%5Bmin%5D=&hydroid%5Bmax%5D=&name_op=contains&name=&bundle_op=in&bundle=All")


#first round of QA - all MPs and their difference and pct_change
draft1 <- sqldf('SELECT *, 
                round("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.",2) AS diff_mgy,round(("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.")/365.25,2) AS diff_mgd,
                round(( ("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.") / "wd_current_mgy_.propvalue.") * 100,2) AS pct_chg 
               FROM draft_qa
               ORDER BY diff_mgd desc
               ')
write.csv(draft1, file = paste0(foundation_location,"/OWS/Report Development/Annual Water Resources Report/October ",eyear+1," Report/May_QA/draft1_all.csv"))

#2021 annual report cycle: planners specifically expected municipal intakes to show a difference
sqldf('SELECT sum("wd_current_draft_mgy_.propvalue.")/365 as draft_mgd, 
              sum("wd_current_mgy_.propvalue.")/365 as current_mgd, 
              (sum("wd_current_draft_mgy_.propvalue.") - sum("wd_current_mgy_.propvalue."))/365 as sum_diff
      from draft1
      where Facility_Use_Type = "municipal"
      AND MP_Bundle LIKE "Surface Water Intake"')
#--------------------------------------------------------------------------------- 
#second round of QA - any MPs that are negative draft values OR have a percent change greater than 50%
draft2 <- sqldf('SELECT *,
                round("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.",2) AS diff_mgy,
                round(("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.")/365.25,2) AS diff_mgd,
                round(( ("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.") / "wd_current_mgy_.propvalue.") * 100,2) AS pct_chg
               FROM draft_qa
               WHERE "wd_current_draft_mgy_.propvalue." < 0
               OR pct_chg > 50
               ORDER BY diff_mgd desc
               ')


#third round of QA - any MPs that are negative draft values OR have a percent change greater than 100%
#newly added poultry farms skew this because they have 2018 currents that are only the sum of a few months instead of a whole year - they of course show a large pct_change
draft3 <- sqldf('SELECT *,
                round("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.",2) AS diff_mgy,
                round(("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.")/365.25,2) AS diff_mgd,
                round(( ("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.") / "wd_current_mgy_.propvalue.") * 100,2) AS pct_chg
               FROM draft_qa
               WHERE "wd_current_draft_mgy_.propvalue." < 0
               OR pct_chg > 100
               ORDER BY diff_mgd desc
               ')

#3.5 round of QA - young MPs that only have a draft current spanning a single year
draft3.5 <- sqldf('SELECT *,
                round("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.",2) AS diff_mgy,
                round(("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.")/365.25,2) AS diff_mgd,
                round(( ("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.") / "wd_current_mgy_.propvalue.") * 100,2) AS pct_chg
               FROM draft_qa
               WHERE "wd_current_draft_mgy_.enddate." - "wd_current_draft_mgy_.startdate." = 1
               ORDER BY diff_mgd desc
               ')
#write.csv(draft3.5, file = paste0(foundation_location,"/OWS/Report Development/Annual Water Resources Report/October ",eyear+1," Report/May_QA/draft3.5.csv"))


#fourth round of QA - any MPs that are negative draft values OR have a percent change greater than 100% (only include MPs that are >= 2 years old)
draft4 <- sqldf('SELECT *,
                round("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.",2) AS diff_mgy,
                round(("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.")/365.25,2) AS diff_mgd,
                round(( ("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.") / "wd_current_mgy_.propvalue.") * 100,2) AS pct_chg,
                "wd_current_draft_mgy_.enddate." - "wd_current_draft_mgy_.startdate." as date_length
               FROM draft_qa
               WHERE ("wd_current_draft_mgy_.propvalue." < 0
               OR pct_chg > 100)
               AND "wd_current_draft_mgy_.enddate." - "wd_current_draft_mgy_.startdate." > 1
               ORDER BY diff_mgd desc
               ')

#---------------------------------------------------------------------------------------
#fifth round of QA - any MPs that are negative draft values OR have a percent change greater than |50%|(only include MPs that are >= 2 years old)
draft5 <- sqldf('SELECT *,
                round("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.",2) AS diff_mgy,
                round(("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.")/365.25,2) AS diff_mgd,
                round(( ("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.") / "wd_current_mgy_.propvalue.") * 100,2) AS pct_chg,
                "wd_current_draft_mgy_.enddate." - "wd_current_draft_mgy_.startdate." as date_length
               FROM draft_qa
               WHERE ("wd_current_draft_mgy_.propvalue." < 0
               OR pct_chg > 50
               OR pct_chg < -50)
               AND "wd_current_draft_mgy_.enddate." - "wd_current_draft_mgy_.startdate." > 1
               ORDER BY diff_mgd desc
               ')
write.csv(draft5, file = paste0(foundation_location,"/OWS/Report Development/Annual Water Resources Report/October ",eyear+1," Report/May_QA/draft5_pctchg_50.csv"))

#short table summary of different changes
top_sums <- sqldf('SELECT sum(diff_mgd) AS "Total MGD Difference",
                          (SELECT sum(diff_mgd)
                          FROM (SELECT * from draft5 limit 5) as T) AS "Top_5_total_mgd",
                          (SELECT sum(diff_mgd)
                          FROM (SELECT * from draft5 limit 10) as U) AS "Top_10_total_mgd",
                          (SELECT sum(diff_mgd)
                          FROM (SELECT * from draft5 limit 20) as V) AS "Top_20_total_mgd",
                          (SELECT sum(diff_mgd)
                          FROM (SELECT * from draft5 ORDER BY diff_mgd asc limit 5) as W) AS "Bottom_5_total_mgd",
                          (SELECT sum(diff_mgd)
                          FROM (SELECT * from draft5 ORDER BY diff_mgd asc limit 10) as W) AS "Bottom_10_total_mgd",
                          (SELECT sum(diff_mgd)
                          FROM (SELECT * from draft5 ORDER BY diff_mgd asc limit 20) as W) AS "Bottom_20_total_mgd"
                  FROM draft5 X
                  ')
top_sums
#write.csv(top_sums, file = paste0(foundation_location,"/OWS/Report Development/Annual Water Resources Report/October ",eyear+1," Report/May_QA/draft5_top_sums.csv"))

draft5_top <- sqldf('SELECT * FROM draft5 ORDER BY diff_mgd desc LIMIT 20')
draft5_bottom <- sqldf('SELECT * FROM draft5 ORDER BY diff_mgd asc LIMIT 5')
draft5_neg <- sqldf('SELECT * FROM draft5 WHERE "wd_current_draft_mgy_.propvalue." < 0 ORDER BY diff_mgd desc')
draft5_check <- rbind(draft5_top,draft5_bottom,draft5_neg)
write.csv(draft5_check, file = paste0(foundation_location,"/OWS/Report Development/Annual Water Resources Report/October ",eyear+1," Report/May_QA/draft5_check.csv"))

########################################################################################################################
# OPTIONAL, COMPARE CURRENT YEAR TO PRIOR YEAR #########################################################################
########################################################################################################################

# ##### METHOD USED in 2023 #############
# syear = 2021
# eyear = 2022
# #Download map export for 2021-2022
# BothYear <- read.csv("C:\\Users\\rnv55934\\Downloads\\ows_annual_report_map_exports (12).csv")
# dup_check<- sqldf('select * from BothYear group by MP_hydroid, Year, "Water.Use.MGY" having count(*)>1')
# LastYear <- sqldf('select * from BothYear where Year == 2021')
# ThisYear <- sqldf('select * from BothYear where Year == 2022')
# JoinYear <- sqldf('select a.MP_hydroid, a.MP_name, a.facility_name, a."Water.Use.MGY" as MGY_2022,b."Water.Use.MGY" as MGY_2021
#                   FROM ThisYear a
#                   LEFT OUTER JOIN LastYear b
#                   ON a.MP_hydroid = b.MP_hydroid')
# ChangeMGY <- sqldf('SELECT *,
#                   round(MGY_2022 - MGY_2021,2) AS diff_mgy,
#                   round(((MGY_2022 - MGY_2021)/MGY_2021)*100,2) AS pct_chg
#                   FROM JoinYear')
# QAannual <- sqldf('SELECT * FROM ChangeMGY
#                   WHERE pct_chg < -80
#                   OR pct_chg > 500
#                   ORDER BY diff_mgy desc ')


##### REPRODUCIBLE METHOD ############
library('hydrotools')
rest_uname = FALSE
rest_pw = FALSE
basepath ='/var/www/R'
source(paste0(basepath,'/auth.private'))
source(paste0(basepath,'/config.R'))
# ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", rest_uname)
# ds$get_token(rest_pw)

syear <- as.numeric(cyear)-2

# #load in MGY from Annual Map Exports view
# tsdef_url <- paste0(site,"/ows-awrr-map-export/wd_mgy?ftype_op=%3D&ftype=&tstime_op=between&tstime%5Bvalue%5D=&tstime%5Bmin%5D=",syear,"-01-01&tstime%5Bmax%5D=",eyear,"-12-31&bundle%5B0%5D=well&bundle%5B1%5D=intake")
# multi_yr_data <- ds$auth_read(tsdef_url, content_type = "text/csv", delim = ",")

## Now pulling the data from the foundation dataset
multi_yr_data <- read.csv(paste0(foundation_location,'//OWS//foundation_datasets//awrr//',cyear,'//awrr_foundation_',cyear,'.csv'))

#Check for duplicates
dup_check<- sqldf('SELECT * FROM multi_yr_data GROUP BY MP_hydroid, Year HAVING count(*) > 1') #should be zero obs.

# Widen dataset to allow for comparison
LastFewYrs <- sqldf(paste0('SELECT * FROM multi_yr_data where Year >= ',eyear-4))
JoinYear <- pivot_wider(LastFewYrs,id_cols = c('mp_hydroid','source_type','mp_name','facility_hydroid','facility','use_type','locality','five_yr_avg'),
                        names_from = year,values_from = tsvalue)

names(JoinYear) <- gsub('(^[0-9]+)','MGY_\\1',names(JoinYear))

# calculate percent change from last reporting year (previous 3 years)

ChangeMGY <- sqldf(paste0('
SELECT *,
CASE
  WHEN MGY_',eyear-1,' IS NOT NULL THEN round(MGY_',eyear,' - MGY_',eyear - 1,',2) 
  WHEN MGY_',eyear-2,' IS NOT NULL THEN round(MGY_',eyear,' - MGY_',eyear - 2,',2)
  WHEN MGY_',eyear-3,' IS NOT NULL THEN round(MGY_',eyear,' - MGY_',eyear - 3,',2)
  ELSE NULL
END AS diff_mgy,
CASE
  WHEN MGY_',eyear-1,' IS NOT NULL THEN round(((MGY_',eyear,' - MGY_',eyear - 1,')/MGY_',eyear - 1,')*100,2) 
  WHEN MGY_',eyear-2,' IS NOT NULL THEN round(((MGY_',eyear,' - MGY_',eyear - 2,')/MGY_',eyear - 2,')*100,2) 
  WHEN MGY_',eyear-3,' IS NOT NULL THEN round(((MGY_',eyear,' - MGY_',eyear - 3,')/MGY_',eyear - 3,')*100,2) 
END AS pct_chg

FROM JoinYear
'))

#identify MPs to QA visually
## Added a few more criteria to stop showing very small changes on very small withdrawal MPs
## Also when MGY_2023 = 0 it should not show as a -100% difference
QAannual <- sqldf('
SELECT * 
FROM ChangeMGY

WHERE MGY_2023 != 0 
  AND (diff_mgy > 0.1 OR diff_mgy < -0.1) 
  AND(  pct_chg < -80
    OR pct_chg > 500)

ORDER BY diff_mgy desc 
')


write.csv(QAannual, file = paste0(foundation_location,"/OWS/Report Development/Annual Water Resources Report/October ",eyear+1," Report/May_QA/draft_annual_check.csv"))

#if there are too many MPs to manually check in VAHydro
#can develop the following line so the MPs already in the draft5_check QA are not repeated here
#sqldf('select * from QAannual where MP_hydoid NOT IN (select MP_hydroid from draft5)')
#and consider reducing results by repeating the whole process at the facility level