library(hydrotools)
library("stringr") #for str_remove()
library("kableExtra")

df <- data.frame(
  'model_version' = c('vahydro-1.0', 'CFBASE30Y20180615','usgs-1.0',  'vahydro-1.0', 'usgs-1.0',  'CFBASE30Y20180615', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0'),
  'runid' = c('runid_11', 'runid_11', 'runid_11', 'runid_11', 'runid_11', 'runid_11', 'runid_1151', 'runid_1153', 'runid_13', 'runid_13'),
  'runlabel' = c('VAH_Qout', 'CBP6_Qout', 'USGS_Qout', 'VAH_l90', 'USGS', 'CBP6', 'VAH 6 hr', 'VAH 3 hr', 'VAH_2040_l90', 'wd 2040'),
  'metric' = c('Qout', 'Overall Mean Flow', 'Overall Mean Flow', 'l90_Qout','90 Day Min Low Flow','90 Day Min Low Flow','l90_Qout','l90_Qout','l90_Qout', 'wd_mgd')
)
# choose one to test
#df <- as.data.frame(df[3,])

wshed_data <- om_vahydro_metric_grid(metric, df)
wshed_data$vah_err <- round((wshed_data$VAH_l90 - wshed_data$USGS) / wshed_data$USGS,3)
wshed_data$cbp_err <- round((wshed_data$CBP6 - wshed_data$USGS) / wshed_data$USGS,3)
wshed_data$cbp_mean_err <- round((wshed_data$CBP6_Qout - wshed_data$USGS_Qout) / wshed_data$USGS_Qout, 3)
wshed_data$modmod_error <- round((wshed_data$VAH_l90 - wshed_data$CBP6) / wshed_data$CBP6,3)
wshed_data$flow_alter <- round(100.0 * (wshed_data$VAH_2040_l90 - wshed_data$VAH_l90) / wshed_data$VAH_l90, 1)
wshed_data$USGS <- round(wshed_data$USGS)
wshed_data$CBP6_Qout <- round(wshed_data$CBP6_Qout)
wshed_data$CBP6 <- round(wshed_data$CBP6)
wshed_data$USGS_Qout <- round(wshed_data$USGS_Qout)
wshed_data$VAH_Qout <- round(wshed_data$VAH_Qout)
wshed_data$VAH_l90 <- round(wshed_data$VAH_l90)
wshed_data$VAH_2040_l90 <- round(wshed_data$VAH_2040_l90)

calib_data <- sqldf(
  "select * from wshed_data 
   where USGS is not null 
   and CBP6 is not null
  ")
big_calib_data <- sqldf(
  "select * from wshed_data 
   where USGS is not null 
   and CBP6 is not null
   and USGS > 10.0"
)
qmax <- max(calib_data$VAHl90, calib_data$USGS)
plot(calib_data$VAH_l90 ~ calib_data$USGS, ylim=c(0,qmax), xlim=c(0,qmax))
creg = lm(calib_data$VAH_l90 ~ calib_data$USGS)
abline(creg)
sqldf("select * from calib_data where abs(vah_err) > 10")
modmod_error_data <- sqldf(
  "select * from wshed_data 
   where abs(modmod_error) > 0.2
   and abs(vah_err) < abs(cbp_err) 
   and abs(flow_alter) > 0.05
  "
)
sqldf(
  "select * from wshed_data 
   where abs(flow_alter) > 0.05
   and abs(modmod_error) > 0.1
  "
)
sqldf(
  "select * from wshed_data 
   where abs(modmod_error) > 0.1
  "
)

# Adjusted alteration
wshed_adj <- sqldf(
  "select propname, USGS, CBP6, VAH_l90, VAH_2040_l90, flow_alter,
  case 
    when cbp_err is not null then flow_alter * (cbp_err+ 1.0)
    WHEN vah_err is not null then flow_alter * (vah_err+ 1.0)
    ELSE NULL
  END as adj_alter
  from wshed_data 
  where vah_err is not null
   and cbp_err is not null"
)
wshed_adj$adj_alter <- round(wshed_adj$adj_alter,3)

quantile(
  wshed_adj$flow_alter, 
  probs=c(0.01,0.05,0.1,0.5,0.95), 
  na.rm = TRUE
)
quantile(
  wshed_adj$adj_alter, 
  probs=c(0.01,0.05,0.1,0.5,0.95), 
  na.rm = TRUE
)

# Specific watershed with some gage data
sqldf(
  "select propname, USGS, VAH_l90, CBP6, VAH_2040_l90, flow_alter,
  case 
    when cbp_err is not null then flow_alter * (cbp_err+ 1.0)
    WHEN vah_err is not null then flow_alter * (vah_err+ 1.0)
    ELSE NULL
  END as adj_alter
  from wshed_data 
  where hydrocode like '%OR%' and vah_err is not null"
)



boxplot(
  calib_data$cbp_err * 100.0,
  names = c('CBP'), 
  xlab = 'CBP Model Calibration, 90 Day Low Flow',
  ylab = 'Model Error %',
  ylim=c(-300, +300),
  main=paste('All Data, n =', nrow(calib_data))
)

boxplot(
  calib_data$cbp_mean_err * 100.0,
  calib_data$cbp_err * 100.0,
  names = c('Mean Daily Flow', '90 Day Low Flow'),
  ylab = 'Model Error %',
  ylim=c(-300, +300),
  main=paste('CBP Model Calibration, All Data, n =', nrow(calib_data))
)

qmax <- max(calib_data$VAH_Qout, calib_data$USGS_Qout)
plot(calib_data$VAH_Qout ~ calib_data$USGS_Qout, ylim=c(0,qmax), xlim=c(0,qmax))
creg = lm(calib_data$VAH_Qout ~ calib_data$USGS_Qout)
abline(creg)

boxplot(
  calib_data$cbp_err, calib_data$vah_err, 
  names = c('CBP', 'VAHydro'), 
  xlab = '90 day low-flow model error',
  ylim=c(-3, +3),
  main=paste('All Data, n =', nrow(calib_data))
)
boxplot(
  big_calib_data$cbp_err, big_calib_data$vah_err, 
  names = c('CBP', 'VAHydro'), 
  xlab = '90 day low-flow model error',
  main=paste('Watersheds > 50sqmi, n =', nrow(big_calib_data))
)
quantile(calib_data$cbp_err)
quantile(calib_data$vah_err)
quantile(big_calib_data$cbp_err)
quantile(big_calib_data$vah_err)
plot(calib_data$CBP6 ~ calib_data$USGS)
plot(log(calib_data$CBP6) ~ log(calib_data$USGS))
exp(4)
# find some examples
sqldf(
  "select * from wshed_data 
   where abs(cbp_err) > 0.4 
   and abs(cbp_err) < 0.9
  ")
# find where vah better than cbp
sqldf(
  "select * from wshed_data 
   where abs(cbp_err) >  abs(vah_err)
  ")
# THIS REALLY MATTERS!!! How many do we have?
# Actually, only 5
sqldf(
  "select * from wshed_data 
   where abs(flow_alter) > 0.1
  and USGS is not null"
)


# Outputs here 

quantile(
  abs(calib_data$cbp_mean_err), 
  probs=c(0.01,0.05,0.1,0.5, 0.75, 0.8, 0.9,0.95), 
  na.rm = TRUE
)
quantile(
  abs(calib_data$cbp_err), 
  probs=c(0.01,0.05,0.1,0.25, 0.5, 0.8, 0.9,0.95), 
  na.rm = TRUE
)
quantile(
  abs(big_calib_data$cbp_err), 
  probs=c(0.01,0.05,0.1,0.25, 0.5, 0.8, 0.9,0.95), 
  na.rm = TRUE
)
boxplot(
  calib_data$cbp_mean_err * 100.0, big_calib_data$cbp_mean_err * 100.0, 
  calib_data$cbp_err * 100.0, big_calib_data$cbp_err * 100.0, 
  names = c( 
    'Mean Q, All', 
    paste('Mean Q > 50sqmi'),
    paste('All L90'), 
    paste('L90 > 50sqmi')
  ), 
  ylim = c(-300, 300),
  ylab="Model Error %",
  main=paste('Model Error by Watershed Size')
)

names( wshed_adj) <- c(
  'Watershed', 
  'USGS 90-Day LF, 1984-2014',
  'CBP Model 90-Day LF, 1984-2014',
  'VAHydro 90-Day LF, 2020 Demand',
  'VAHydro 90-Day LF, 2040 Demand',
  'Flow Alteration',
  'Flow Alteration Adjusted'
)

boxplot(
  wshed_adj$`Flow Alteration`, 
  wshed_adj$`Flow Alteration Adjusted`,
  ylab = 'Flow Alteration %',
  names = c('Modeled 90-day Low Flow', 'Error Adjusted 90-day Low Flow')
)

emax <- max(abs(calib_data$cbp_err))
plot( 
  wshed_adj$`Flow Alteration` ~ 
  wshed_adj$`Flow Alteration Adjusted`,
  xlab="Modeled Flow Alteration %",
  ylab="Error Adjusted Flow Alteration %"
)
ereg = lm(wshed_adj$`Flow Alteration Adjusted`~ wshed_adj$`Flow Alteration` )
summary(ereg)

#abline(ereg)
hist(calib_data$cbp_err)
#WRITE KABLE TABLE
table_tex <- kable(wshed_adj,align = "l",  booktabs = T,format = "latex",longtable =T,
                   caption = "Modeled flow alteration in 2040, adjusted for CBP model error.",
                   label = "Error Adjusted Flow Alteration") %>%
  kable_styling(latex_options = "striped") %>%
  column_spec(2, width = "12em")

table_tex <- gsub(pattern = "{table}[t]", 
                  repl    = "{table}[H]", 
                  x       = table_tex, fixed = T )
table_tex %>%
  cat(., file = paste0(export_path,"\\model_error_adjust_tbl.tex"),sep="")

