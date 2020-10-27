library(sqldf)
library(kableExtra)
library(sjmisc)
options(scipen = 999999999)


CU_frac <- read.csv(paste(folder,"metrics_watershed_consumptive_use_frac.csv",sep=""))


metrics_wshed_focus.gen <- function(metric){
  
# RETRIEVE RIVERSEG MODEL METRIC SUMMARY DATA
RSeg_summary <- read.csv(paste(folder,"metrics_watershed_",metric,".csv",sep=""))
######################################################################################################
### PROCESS RSegs
######################################################################################################
# RSeg_data <- paste('SELECT *,
#                   case
#                   when b.',runid_a,' = 0
#                   then 0
#                   when b.',runid_b,' IS NULL
#                   then NULL
#                   else round(((b.',runid_b,' - b.',runid_a,') / b.',runid_a,') * 100,2)
#                   end AS pct_chg
#                   FROM RSeg_summary AS b
#                   ORDER BY abs(pct_chg) DESC
#                   LIMIT 20',sep = '')  
# 
# RSeg_data <- paste('SELECT *,
#                   case
#                   when b.runid_11 = 0
#                   then 0
#                   when b.runid_13 IS NULL
#                   then NULL
#                   else round(((b.runid_13 - b.runid_11) / b.runid_11) * 100,2)
#                   end AS pct_chg_11_13
#                   FROM RSeg_summary AS b
#                   ORDER BY abs(pct_chg_11_13) DESC
#                   LIMIT 20',sep = '')  

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

write.csv(RSeg_data, paste(folder,"tables_maps/metrics_focus/metrics_watershed_",metric,"_focus.csv",sep=""), row.names = F)
}

#----------- RUN MAPS IN BULK --------------------------

metric <- "l30_Qout"
metric <- c("l30_Qout","l90_Qout","7q10","l30_cc_Qout", "l90_cc_Qout")

for (met in metric) {
    print(paste("...PROCESSING METRIC: ",met,sep=""))
      metrics_wshed_focus.gen(met) 
  }

