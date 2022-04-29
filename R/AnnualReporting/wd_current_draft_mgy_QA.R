library(sqldf)

#prevents scientific notation
options(scipen = 20)
#Purpose: Compare the new draft (wd_current_draft_mgy; 2017-2021) that has been set to the previous year's set 5-year avg (wd_current_mgy; 2016-2020)
cyear <- format(Sys.time(), "%Y")
syear <- as.numeric(cyear)-5
eyear <- as.numeric(cyear)-1

draft_qa <- read.csv("https://deq1.bse.vt.edu/d.dh/current-average-use-workflow-compare-export?hydroid_op=%3D&hydroid%5Bvalue%5D=&hydroid%5Bmin%5D=&hydroid%5Bmax%5D=&name_op=contains&name=&bundle_op=in&bundle=All")


#first round of QA - all MPs and their difference and pct_change
draft1 <- sqldf('SELECT *, 
                round("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.",2) AS diff_mgy,round(("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.")/365.25,2) AS diff_mgd,
                round(( ("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.") / "wd_current_mgy_.propvalue.") * 100,2) AS pct_chg 
               FROM draft_qa
               ORDER BY diff_mgd desc
               ')
write.csv(draft1, file = paste0("U:/OWS/Report Development/Annual Water Resources Report/October ",eyear+1," Report/May_QA/draft1_all.csv"))

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
                round(("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.")/365,2) AS diff_mgd,
                round(( ("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.") / "wd_current_mgy_.propvalue.") * 100,2) AS pct_chg
               FROM draft_qa
               WHERE "wd_current_draft_mgy_.propvalue." < 0
               OR pct_chg > 50
               ORDER BY diff_mgd desc
               ')


#third round of QA - any MPs that are negative draft values OR have a percent change greater than 100%
#newly added poultry farms skew this because they have 2018 currents that are only the sum of a few months instead of a whole year - they of course show a large pct_change
draft3 <- sqldf('SELECT *,
                round("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.",2) AS diff_mgy,round(("wd_current_draft_mgy_.propvalue." - "wd_current_mgy_.propvalue.")/365.25,2) AS diff_mgd,
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
write.csv(draft5, file = paste0("U:/OWS/Report Development/Annual Water Resources Report/October ",eyear+1," Report/May_QA/draft5_pctchg_50.csv"))

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
#write.csv(top_sums, file = paste0("U:/OWS/Report Development/Annual Water Resources Report/October ",eyear+1," Report/May_QA/draft5_top_sums.csv"))

draft5_top <- sqldf('SELECT * FROM draft5 ORDER BY diff_mgd desc LIMIT 20')
draft5_bottom <- sqldf('SELECT * FROM draft5 ORDER BY diff_mgd asc LIMIT 5')
draft5_neg <- sqldf('SELECT * FROM draft5 WHERE "wd_current_draft_mgy_.propvalue." < 0 ORDER BY diff_mgd desc')
draft5_check <- rbind(draft5_top,draft5_bottom,draft5_neg)
write.csv(draft5_check, file = paste0("U:/OWS/Report Development/Annual Water Resources Report/October ",eyear+1," Report/May_QA/draft5_check.csv"))
