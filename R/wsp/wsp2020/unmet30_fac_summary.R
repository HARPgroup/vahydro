# Upper and Middle Potomac cia table for model debugging
# where is the extra water comingfrom in 2040 baseline flows?

library("sqldf")
library("stringr") #for str_remove()
library(kableExtra)

# Load Libraries
basepath='/var/www/R';
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
source("/var/www/R/config.local.private"); 
source(paste(basepath,'config.R',sep='/'))
source(paste(hydro_tools_location,'/R/om_vahydro_metric_grid.R', sep = ''));
folder <- "C:/Workspace/tmp/"

df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0',  'vahydro-1.0', 'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_13','runid_11', 'runid_13','runid_11', 'runid_13','runid_11', 'runid_13'),
  'metric' = c('wd_mgd', 'wd_mgd', 'unmet7_mgd', 'unmet7_mgd', 'unmet30_mgd', 'unmet30_mgd', 'unmet90_mgd', 'unmet90_mgd'),
  'runlabel' = c('wd_2020', 'wd_2040', 'unmet7_mgd_2020', 'unmet7_mgd_2040', 'unmet30_mgd_2020', 'unmet30_mgd_2040', 'unmet90_mgd_2020', 'unmet90_mgd_2040')
)
fac_data <- om_vahydro_metric_grid( metric, df, 'all', 'dh_feature', 'facility','all')
fac_case <- sqldf(
  "select * from fac_data 
   where riverseg not like '%0000%' 
   and hydrocode not in ('vwuds_0231', 'Dickerson_Generating_Station')
  "
)

sum_tbl <- sqldf(
  "select 'Withdrawal' as cat, 
     round(sum(wd_2020)) as x2020, 
     round(sum(wd_2040)) as x2040
   from fac_case
   UNION
   select 'Unmet 7-day' as cat, 
     round(sum(unmet7_mgd_2020)) as x2020, 
     round(sum(unmet7_mgd_2040)) as x2040
   from fac_case
   UNION
   select 'Unmet 30-day' as cat, 
     round(sum(unmet30_mgd_2020)) as x2020, 
     round(sum(unmet30_mgd_2040)) as x2040
   from fac_case
   UNION
   select 'Unmet 90-day' as cat, 
     round(sum(unmet90_mgd_2020)) as x2020, 
     round(sum(unmet90_mgd_2040)) as x2040
   from fac_case
  "
)

sum_tbl
sum_file <- paste(save_directory,'unmet_summary_tbl.csv',sep='/')
names(sum_tbl) <- c(
  'Metric', 
  '2020 (mgd)',
  '2040 (mgd)'
)
#WRITE KABLE TABLE
table_tex <- kable(sum_tbl,align = "l",  booktabs = T,format = "latex",longtable =T,
                   caption = "Unmet Demand Summaries, 2020 versus 2040 demands.",
                   label = "Unmet Demand Summary") %>%
  kable_styling(latex_options = "striped") %>%
  column_spec(2, width = "12em")

table_tex <- gsub(pattern = "{table}[t]", 
                  repl    = "{table}[H]", 
                  x       = table_tex, fixed = T )
table_tex %>%
  cat(., file = paste0(export_path,"\\unmet_summary_tbl.tex"),sep="")


