#pull in each of the 4 metrics: l30, l90, 7Q10, CU
library(sqldf)
library(kableExtra)
options(scipen = 999999999)

folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"

# RETRIEVE RIVERSEG MODEL METRIC SUMMARY DATA
scenario <- c("runid_13","runid_17","runid_18")
metric <- c("d_l30_cc_Qout","d_l90_cc_Qout","d_7q10", "d_consumptive_use_frac")

for (s in scenario) {
if (s == "runid_13") {
  scen <- "Future Demand"
} else if (s == "runid_17"){
  scen <- "Dry Climate"
} else if (s == "runid_18") {
  scen <- "Exempt User"
}
  
  for (m in metric) {
  filepath <- file.path(paste(folder,"metrics_watershe",m,".csv",sep=""))
  assign(m, read.csv(filepath,stringsAsFactors = F))
  
  #filter out tidal (0000); add MB_CODE and count # of rsegs
  assign(paste0("count_",m), sqldf(paste('SELECT count(pid) AS total_count, substr(hydrocode,17,1) AS mb_code
      FROM',m,' 
      WHERE hydrocode NOT LIKE "vahydrosw_wshed_JA%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_PL%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_RL%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_YL%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_YM%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_YP%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_EL%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_JB%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_MN%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_ES%_0000"
      GROUP BY mb_code
      ORDER BY runid_11 DESC')))
  
  #filter out tidal (0000); only keep riversegs with more than 10% reduction in streamflow compared to 2020
  assign(m, sqldf(paste('SELECT *, substr(hydrocode,17,1) AS mb_code
      FROM',m,' 
      WHERE ',s,' < runid_11 * 0.90
      AND (hydrocode NOT LIKE "vahydrosw_wshed_JA%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_PL%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_RL%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_YL%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_YM%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_YP%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_EL%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_JB%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_MN%_0000" OR
                       hydrocode NOT LIKE "vahydrosw_wshed_ES%_0000")
      ORDER BY runid_11 DESC')))

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

#Join on minorbasin & remove null values
assign(paste0(s,"_table"),sqldf(paste0('SELECT a.mb_code, b.pct_strmflow_redux AS ',s,'_7q10, c.pct_strmflow_redux AS ',s,'_l30, d.pct_strmflow_redux AS ',s,'_l90, e.pct_strmflow_redux AS ',s,'_CU
                    FROM count_d_7q10 AS a
                    LEFT OUTER JOIN pct_d_7q10 AS b
                    ON a.mb_code = b.mb_code
                    LEFT OUTER JOIN pct_d_l30_Qout AS c
                    ON b.mb_code = c.mb_code
                    LEFT OUTER JOIN pct_d_l90_Qout AS d
                    ON c.mb_code = d.mb_code
                    LEFT OUTER JOIN pct_d_consumptive_use_frac AS e
                    ON d.mb_code = e.mb_code
                    WHERE (',s,'_7q10 IS NOT NULL
                    OR ',s,'_l30 IS NOT NULL
                    OR ',s,'_l90 IS NOT NULL
                    OR  ',s,'_CU IS NOT NULL)')))

#KABLE   
table1_tex <- kable(paste0(s,"_table"),align = c('l','c','c','c','c'),  booktabs = T,
                    caption = paste("Percentage of Major Basins with a >10% Stream Flow Reduction in the ",scen," Scenario",sep=""),
                    label = paste("streamflow_reduction_",s,"_VA"),
                    col.names = c(
                      "Minor Basin",
                      "Lowest 30 Day Low Flow",
                      "Lowest 90 Day Low Flow",
                      "7q10",
                      "Overall Change in Flow")) %>%
  # kable_styling(font_size = 10) %>%
  # column_spec(1, width = "11em") %>%
  # column_spec(2, width = "6em") %>%
  # column_spec(3, width = "6em") %>%
  # column_spec(4, width = "6em") %>%
  # column_spec(5, width = "6em") %>%
  # column_spec(6, width = "6em") %>%
  #Header row is row 0
  row_spec(0, bold=T, font_size = 11)

#CUSTOM LATEX CHANGES
#insert hold position header
table1_tex <- gsub(pattern = "{table}[t]", 
                   repl    = "{table}[H]", 
                   x       = table1_tex, fixed = T )
table1_tex <- gsub(pattern = "\\midrule", 
                   repl    = "", 
                   x       = table1_tex, fixed = T )
table1_tex <- gsub(pattern = "\\hline", 
                   repl    = "\\hline \\addlinespace[0.4em]", 
                   x       = table1_tex, fixed = T )
table1_tex <- gsub(pattern = "\\vphantom{1}", 
                   repl    = "", 
                   x       = table1_tex, fixed = T )
table1_tex <- gsub(pattern = "\\hspace{1em}T", 
                   repl    = "T", 
                   x       = table1_tex, fixed = T )

table1_tex %>%
  cat(., file = paste(folder,"tables_maps/Xtables/VA_",s,"__table",file_ext,sep=""))

}
