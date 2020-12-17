#pull in each of the 4 metrics: l30, l90, 7Q10, CU
library(sqldf)
options(scipen = 999999999)

folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"

# RETRIEVE RIVERSEG MODEL METRIC SUMMARY DATA
metric <- c("d_l30_Qout","d_l90_Qout","d_7q10", "d_consumptive_use_frac")

for (m in metric) {
  filepath <- file.path(paste(folder,"metrics_watershe",m,".csv",sep=""))
  assign(m, read.csv(filepath,stringsAsFactors = F))
  
  
  #filter out tidal (0000); add MB_CODE and count column
  assign(paste0("count_",m), sqldf(paste('SELECT count(pid) AS total_count, substr(riverseg,1,2) AS mb_code
      FROM',m,' 
      WHERE riverseg NOT LIKE "%_0000%"
      GROUP BY mb_code
      ORDER BY runid_11 DESC
')))
  
  #filter out tidal (0000); only keep riversegs with more than 10% reduction in streamflow compared to 2020
  assign(m, sqldf(paste('SELECT *, substr(riverseg,1,2) AS mb_code
      FROM',m,' 
      WHERE runid_13 < runid_11 * 0.90
      AND riverseg NOT LIKE "%_0000%"
      ORDER BY runid_11 DESC
')))
  

  #aggregate each by minorbasin and count number of riversegs with a >10% streamflow reduction
  assign(paste0("redux_",m), sqldf(paste('SELECT mb_code, count(pid) as count_strmflow_redux
      FROM ',m,'
      GROUP BY mb_code')))
         

  #calculate percentage out of total riversegs
    assign(paste0("pct_",m), sqldf(paste0('SELECT a.mb_code, b.count_strmflow_redux, a.total_count, ((cast (b.count_strmflow_redux as real) / a.total_count) * 100) AS pct_strmflow_redux
      FROM count_',m,' AS a
      LEFT OUTER JOIN redux_',m,' AS b
      ON a.mb_code = b.mb_code
      WHERE b.count_strmflow_redux IS NOT NULL')))
  }

#Join on minorbasin
table_2040 <- sqldf('SELECT a.mb_code, b.pct_strmflow_redux AS future_7q10, c.pct_strmflow_redux AS future_l30, d.pct_strmflow_redux AS future_l90, e.pct_strmflow_redux AS future_CU
                    FROM count_d_7q10 AS a
                    LEFT OUTER JOIN pct_d_7q10 AS b
                    ON a.mb_code = b.mb_code
                    LEFT OUTER JOIN pct_d_l30_Qout AS c
                    ON b.mb_code = c.mb_code
                    LEFT OUTER JOIN pct_d_l90_Qout AS d
                    ON c.mb_code = d.mb_code
                    LEFT OUTER JOIN pct_d_consumptive_use_frac AS e
                    ON d.mb_code = e.mb_code')