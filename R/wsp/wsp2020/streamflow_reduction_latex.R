# #pull in each of the 4 metrics: l30, l90, 7Q10, CU
# library(sqldf)
# library(kableExtra)
# options(scipen = 999999999)
options(knitr.kable.NA = '0.00')

folder <- "U:/OWS/foundation_datasets/wsp/wsp2020/"
major_basin <- read.csv(paste0(folder, "major_basin_names.csv"))

scenario <- c("runid_13","runid_17","runid_18")


for (s in scenario) {
if (s == "runid_13") {
  scen <- "Future Demand"
  metric <- c("d_l30_Qout","d_l90_Qout","d_7q10", "d_consumptive_use_frac")
  Qout <- "_Qout"
} else if (s == "runid_17"){
  scen <- "Dry Climate"
  metric <- c("d_l30_cc_Qout","d_l90_cc_Qout","d_7q10", "d_consumptive_use_frac")
  Qout <- "_cc_Qout"
} else if (s == "runid_18") {
  scen <- "Exempt User"
  metric <- c("d_l30_Qout","d_l90_Qout","d_7q10", "d_consumptive_use_frac")
  Qout <- "_Qout"
}
  
  for (m in metric) {
  # RETRIEVE RIVERSEG MODEL METRIC SUMMARY DATA
  filepath <- file.path(paste(folder,"metrics_watershe",m,".csv",sep=""))
  assign(m, read.csv(filepath,stringsAsFactors = F))
  
  #filter out tidal (0000); add MB_CODE and count # of rsegs
  assign(paste0("count_",m), sqldf(paste('SELECT count(pid) AS total_count, substr(hydrocode,17,1) AS mb_code
      FROM',m,'
      WHERE hydrocode NOT LIKE "%0000%"
      GROUP BY mb_code
      ORDER BY runid_11 DESC')))
  
  #filter out tidal (0000); only keep riversegs with more than 10% reduction in streamflow compared to 2020
  assign(m, sqldf(paste('SELECT *, substr(hydrocode,17,1) AS mb_code
      FROM',m,' 
      WHERE ',s,' < runid_11 * 0.90
      AND hydrocode NOT LIKE "%0000%"
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
assign(paste0(s,"_table"),sqldf(paste0('SELECT a.mb_code, round(b.pct_strmflow_redux,2) AS ',s,'_7q10, round(c.pct_strmflow_redux,2) AS ',s,'_l30, round(d.pct_strmflow_redux,2) AS ',s,'_l90, round(e.pct_strmflow_redux,2) AS ',s,'_CU
                    FROM count_d_7q10 AS a
                    LEFT OUTER JOIN pct_d_7q10 AS b
                    ON a.mb_code = b.mb_code
                    LEFT OUTER JOIN pct_d_l30',Qout,' AS c
                    ON b.mb_code = c.mb_code
                    LEFT OUTER JOIN pct_d_l90',Qout,' AS d
                    ON c.mb_code = d.mb_code
                    LEFT OUTER JOIN pct_d_consumptive_use_frac AS e
                    ON d.mb_code = e.mb_code
                    ')))
#where clause to only keep Basins that have non-null values
# WHERE (',s,'_7q10 IS NOT NULL
#        OR ',s,'_l30 IS NOT NULL
#        OR ',s,'_l90 IS NOT NULL
#        OR  ',s,'_CU IS NOT NULL)


assign(paste0(s,"_table"), sqldf(paste0('SELECT b.Major_Basin_Name, a.',s,'_l30, a.',s,'_l90, a.',s,'_7q10, a.',s,'_CU 
                                 FROM ',s,'_table AS a
                                 LEFT OUTER JOIN major_basin AS b
                                 ON a.mb_code = b.Major_Basin_Code
                                 ORDER BY b.Major_Basin_Name')))

##recode NA to - for the Basins that are outside of the chesapeake bay drainage
if (paste0(s,"_table") == "runid_17_table") {

  runid_17_table <- sqldf('SELECT Major_Basin_Name, runid_17_l30, runid_17_l90, runid_17_7q10
        FROM runid_17_table')
  runid_17_table[is.na(runid_17_table)] <- "-"
  
  
  ##KABLE
  table1_tex <- kable(get(paste0(s,"_table")),align = c('l','c','c','c','c'),  booktabs = T, format = "latex",
                      caption = paste("Percentage of Major Basins with a $>$10\\% Stream Flow Reduction in the ",scen," Scenario",sep=""),
                      label = paste("streamflow_reduction_",s,"_VA"),
                      col.names = c("Major Basin",
                                    "Lowest 30 Day Low Flow",
                                    "Lowest 90 Day Low Flow",
                                    "7q10")) %>%
    #kable_styling(latex_options = "scale_down") %>%
    kable_styling(font_size = 11) %>%
    column_spec(1, width = "9em") %>%
    column_spec(2, width = "9em") %>%
    column_spec(3, width = "9em") %>%
    column_spec(4, width = "8em") %>%
    #Header row is row 0
    row_spec(0, bold=T, font_size = 11) %>%
    footnote(general_title = "Note: ",
             general = "Explain", 
             symbol = "CC")
  
  table1_tex <- gsub(pattern = "\\multicolumn{4}{l}{\\textit{Note: }}\\\\
\\multicolumn{4}{l}{Explain}\\\\
\\multicolumn{4}{l}{\\textsuperscript{*} CC}\\\\",
                     repl    =  "\\addlinespace \\multicolumn{4}{l}{\\textsuperscript{*} Calculations for these metrics are based on comparison to the 2020 Demand Scenario.}\\\\ \\addlinespace 
\\multicolumn{4}{l}{ \\multirow{}{}{\\parbox{15cm}{\\textit{Note:} Climate scenarios were not completed in areas located outside of the Chesapeake Bay Basin.}}}\\\\",
                     x       = table1_tex, fixed = T )
  
} else {

##KABLE
table1_tex <- kable(get(paste0(s,"_table")),align = c('l','c','c','c','c'),  booktabs = T, format = "latex",
                    caption = paste("Percentage of Major Basins with a $>$10\\% Stream Flow Reduction in the ",scen," Scenario",sep=""),
                    label = paste("streamflow_reduction_",s,"_VA"),
                    col.names = c("Major Basin",
                      "Lowest 30 Day Low Flow",
                      "Lowest 90 Day Low Flow",
                      "7q10",
                      "Overall Change in Flow")) %>%
  #kable_styling(latex_options = "scale_down") %>%
  kable_styling(font_size = 11) %>%
  column_spec(1, width = "8em") %>%
  column_spec(2, width = "7em") %>%
  column_spec(3, width = "7em") %>%
  column_spec(4, width = "4em") %>%
  column_spec(5, width = "7em") %>%
  #Header row is row 0
  row_spec(0, bold=T, font_size = 11) %>%
  footnote(general_title = "Note: ",general = "Explain",symbol = "CC")
  
  table1_tex <- gsub(pattern = "\\multicolumn{5}{l}{\\textit{Note: }}\\\\
\\multicolumn{5}{l}{Explain}\\\\
\\multicolumn{5}{l}{\\textsuperscript{*} CC}\\\\",
                     repl    = "\\multicolumn{5}{l}{\\textsuperscript{*} Calculations for these metrics are based on comparison to the 2020 Demand Scenario.}\\\\",
                     x       = table1_tex, fixed = T )
}

#CUSTOM LATEX CHANGES
#insert hold position header
table1_tex <- gsub(pattern = "{table}[t]",
                   repl    = "{table}[H]",
                   x       = table1_tex, fixed = T )
table1_tex <- gsub(pattern = "\\addlinespace",
                   repl    = "",
                   x       = table1_tex, fixed = T )
table1_tex <- gsub(pattern = "Lowest 30 Day Low Flow}\\endgroup & \\begingroup\\fontsize{11}{13}\\selectfont \\textbf{Lowest 90 Day Low Flow}\\endgroup & \\begingroup\\fontsize{11}{13}\\selectfont \\textbf{7q10",
                   repl    = "Lowest 30 Day Low Flow*}\\endgroup & \\begingroup\\fontsize{11}{13}\\selectfont \\textbf{Lowest 90 Day Low Flow*}\\endgroup & \\begingroup\\fontsize{11}{13}\\selectfont \\textbf{7q10*",
                   x       = table1_tex, fixed = T )

table1_tex %>%
  cat(., file = paste(folder,"tables_maps/Xtables/VA_streamflow_redux_",s,"__table.tex",sep=""))

print(paste0("COMPLETE: ",scen," Scenario Streamflow Reduction Table"))
}
