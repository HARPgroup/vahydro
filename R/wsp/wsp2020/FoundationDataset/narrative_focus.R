#NARRATIVE FOCUS - planners use this file to view data in bulk for narrative comparison

library(sqldf)
library(kableExtra)
library(sjmisc)
options(scipen = 999999999)

#LOAD MP ALL DEMAND FILE
mp_all <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))

#LOAD CONSUMPTIVE USE FRACTION FILE
CU_frac <- read.csv(paste(folder,"metrics_watershed_consumptive_use_frac.csv",sep=""))

### METRICS WATERSHED FOCUS ######################################

metrics_wshed_focus.gen <- function(metric, folder){
# RETRIEVE RIVERSEG MODEL METRIC SUMMARY DATA
  RSeg_summary <- read.csv(paste(folder,"metrics_watershed_",metric,".csv",sep=""))
  RSeg_data <- paste('SELECT a.*,
                    case
                    when a.runid_11 = 0
                    then 0
                    when a.runid_12 IS NULL
                    then NULL
                    else round(((a.runid_12 - a.runid_11) / a.runid_11) * 100,2)
                    end AS pct_chg_11_12,
                    
                    case
                    when a.runid_11 = 0
                    then 0
                    when a.runid_13 IS NULL
                    then NULL
                    else round(((a.runid_13 - a.runid_11) / a.runid_11) * 100,2)
                    end AS pct_chg_11_13,
                    
                    case
                    when a.runid_11 = 0
                    then 0
                    when a.runid_18 IS NULL
                    then NULL
                    else round(((a.runid_18 - a.runid_11) / a.runid_11) * 100,2)
                    end AS pct_chg_11_18,
                    
                    case
                    when a.runid_11 = 0
                    then 0
                    when a.runid_17 IS NULL
                    then NULL
                    else round(((a.runid_17 - a.runid_11) / a.runid_11) * 100,2)
                    end AS pct_chg_11_17,
                    
                    case
                    when a.runid_11 = 0
                    then 0
                    when a.runid_19 IS NULL
                    then NULL
                    else round(((a.runid_19 - a.runid_11) / a.runid_11) * 100,2)
                    end AS pct_chg_11_19,
                    
                    case
                    when a.runid_11 = 0
                    then 0
                    when a.runid_20 IS NULL
                    then NULL
                    else round(((a.runid_20 - a.runid_11) / a.runid_11) * 100,2)
                    end AS pct_chg_11_20,
                    
                    round(b.runid_12,2) AS CU_runid_12,
                    round(b.runid_13,2) AS CU_runid_13,
                    round(b.runid_17,2) AS CU_runid_17,
                    round(b.runid_18,2) AS CU_runid_18,
                    round(b.runid_19,2) AS CU_runid_19,
                    round(b.runid_20,2) AS CU_runid_20,
                    substr(a.hydrocode,17,2) AS mb_code
                    FROM RSeg_summary AS a
                    LEFT OUTER JOIN CU_frac AS b 
                    ON (a.pid = b.pid)
                    WHERE a.hydrocode NOT LIKE "%_0000"
                    ORDER BY pct_chg_11_13',sep = '')  
  RSeg_data <- sqldf(RSeg_data)

  if (str_contains(metric, "cc_Qout") == T) {
    RSeg_data <- sqldf("SELECT pid, propname, hydrocode, featureid,
                        runid_11,
                        runid_17,
                        runid_19,
                        runid_20,
                        pct_chg_11_17,
                        pct_chg_11_19,
                        pct_chg_11_20,
                        CU_runid_17,
                        CU_runid_19,
                        CU_runid_20,
                        mb_code
                        FROM RSeg_data
                        ORDER BY CU_runid_17
                        ")
  }
   else {
    RSeg_data <- sqldf("SELECT pid, propname, hydrocode, featureid,
                      runid_11,
                      runid_12,
                      runid_13,
                      runid_18,
                      pct_chg_11_12,
                      pct_chg_11_13,
                      pct_chg_11_18,
                      CU_runid_12,
                      CU_runid_13,
                      CU_runid_18,
                      mb_code
                      FROM RSeg_data
                      ORDER BY CU_runid_13")
    
   }
  return(RSeg_data)

}

#----------- RUN FILES --------------------------
metric <- c("l30_Qout","l90_Qout","7q10","l30_cc_Qout", "l90_cc_Qout")

for (met in metric) {
  print(paste("...PROCESSING METRIC: ",met,sep=""))
  RSeg_data <- metrics_wshed_focus.gen(met, folder) 
  write.csv(RSeg_data, paste(folder,"tables_maps/narrative_focus/metrics_watershed_",met,"_focus.csv",sep=""), row.names = F)
      
}

### CHAPTER 3 - WATER SUPPLY USE AND DEMAND BY BASINS ###################################################

#GROUP BY BASIN AND CATEGORY
total <- sqldf('SELECT MinorBasin_Code,
"Total" AS wsp_ftype,
"Total" AS system_type,
round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040,
round(((sum(mp_2040_mgy/365.25) - sum(mp_2020_mgy/365.25)) / sum(mp_2020_mgy/365.25))*100, 2) AS pct_change

           FROM mp_all
           WHERE MinorBasin_Code IS NOT NULL
           GROUP BY MinorBasin_Code
           ORDER BY pct_change DESC')

by_category <- sqldf('SELECT MinorBasin_Code,
wsp_ftype,
system_type,
round(sum(mp_2020_mgy)/365.25,2) AS MGD_2020,
round(sum(mp_2030_mgy)/365.25,2) AS MGD_2030, 
round(sum(mp_2040_mgy)/365.25,2) AS MGD_2040,
round(((sum(mp_2040_mgy/365.25) - sum(mp_2020_mgy/365.25)) / sum(mp_2020_mgy/365.25))*100, 2) AS pct_change

           FROM mp_all
           WHERE MinorBasin_Code IS NOT NULL
           GROUP BY MinorBasin_Code, wsp_ftype
           ORDER BY wsp_ftype, pct_change DESC')

#COMBINE categories and totals
demand_by_basin <- rbind(by_category, total)

#WRITE DEMAND BY BASIN FILE
write.csv(demand_by_basin, file = "U:/OWS/foundation_datasets/wsp/wsp2020/tables_maps/narrative_focus/category_demand_by_basin.csv", row.names = F )

