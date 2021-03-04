library(hydrotools)
library("stringr") #for str_remove()
library("kableExtra")
library("sqldf")

dfm <- data.frame(
  'model_version' = c('vahydro-1.0', 'CFBASE30Y20180615','usgs-1.0',  'vahydro-1.0', 'usgs-1.0',  'CFBASE30Y20180615', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'vahydro-1.0', 'CFBASE30Y20180615','usgs-1.0', 'CFBASE30Y20180615','usgs-1.0'),
  'runid' = c('runid_11', 'runid_11', 'runid_11', 'runid_11', 'runid_11', 'runid_11', 'runid_1151', 'runid_1153', 'runid_13', 'runid_13', 'runid_11', 'runid_11', 'runid_11', 'runid_11'),
  'runlabel' = c('VAH_Qout', 'CBP6_Qout', 'USGS_Qout', 'VAH_l90', 'USGS', 'CBP6', 'VAH 6 hr', 'VAH 3 hr', 'VAH_2040_l90', 'wd 2040', 'CBP_l30', 'usgs_l30', 'usgs_7q10', 'CBP_7q10'),
  'metric' = c('Qout', 'Overall Mean Flow', 'Overall Mean Flow', 'l90_Qout','90 Day Min Low Flow','90 Day Min Low Flow','l90_Qout','l90_Qout','l90_Qout', 'wd_mgd','30 Day Min Low Flow','30 Day Min Low Flow', '7q10', '7q10')
)

dfm <- rbind(
  dfm, 
  data.frame(runid='runid_11', metric='l30_Qout',
             runlabel='VAH_L30', model_version = 'vahydro-1.0')
)
dfm <- rbind(
  dfm, 
  data.frame(runid='runid_13', metric='l30_Qout',
             runlabel='VAH_2040_L30', model_version = 'vahydro-1.0')
)
dfm <- rbind(
  dfm, 
  data.frame(runid='runid_11', metric='7q10',
             runlabel='VAH_7q10', model_version = 'vahydro-1.0')
)
dfm <- rbind(
  dfm, 
  data.frame(runid='runid_13', metric='7q10',
             runlabel='VAH_2040_7q10', model_version = 'vahydro-1.0')
)
dfm <- rbind(
  dfm, 
  data.frame(runid='runid_13', metric='Qout',
             runlabel='VAH_2040_Qout', model_version = 'vahydro-1.0')
)
# choose one to test
#df <- as.data.frame(df[3,])

wshed_data <- om_vahydro_metric_grid(metric, dfm)
wshed_data$vah_err <- round((wshed_data$VAH_l90 - wshed_data$USGS) / wshed_data$USGS,3)
wshed_data$cbp_err_l90 <- round((wshed_data$CBP6 - wshed_data$USGS) / wshed_data$USGS,3)
wshed_data$cbp_mean_err <- round((wshed_data$CBP6_Qout - wshed_data$USGS_Qout) / wshed_data$USGS_Qout, 3)
wshed_data$cbp_err_l30 <- round((wshed_data$CBP_l30 - wshed_data$usgs_l30) / wshed_data$usgs_l30,3)
wshed_data$cbp_err_7q10 <- round((wshed_data$CBP_7q10 - wshed_data$usgs_7q10) / wshed_data$usgs_7q10,3)

wshed_data$modmod_error <- round((wshed_data$VAH_l90 - wshed_data$CBP6) / wshed_data$CBP6,3)
wshed_data$flow_alt_pct <- round(100.0 * (wshed_data$VAH_2040_l90 - wshed_data$VAH_l90) / wshed_data$VAH_l90, 1)
wshed_data$USGS <- round(wshed_data$USGS)
wshed_data$CBP6_Qout <- round(wshed_data$CBP6_Qout)
wshed_data$CBP6 <- round(wshed_data$CBP6)
wshed_data$USGS_Qout <- round(wshed_data$USGS_Qout)
wshed_data$VAH_Qout <- round(wshed_data$VAH_Qout)
wshed_data$VAH_l90 <- round(wshed_data$VAH_l90)
wshed_data$VAH_2040_l90 <- round(wshed_data$VAH_2040_l90)
wshed_data$alt_pct_l30 <- round(100.0 * (wshed_data$VAH_2040_L30 - wshed_data$VAH_L30) / wshed_data$VAH_L30, 1)
wshed_data$alt_pct_7q10 <- round(100.0 * (wshed_data$VAH_2040_7q10 - wshed_data$VAH_7q10) / wshed_data$VAH_7q10, 1)
wshed_data$alt_pct_Qout <- round(100.0 * (wshed_data$VAH_2040_7q10 - wshed_data$VAH_7q10) / wshed_data$VAH_7q10, 1)

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
notiny_calib_data <- sqldf(
  "select * from wshed_data 
   where USGS is not null 
   and CBP6 is not null
   and USGS > 1.0"
)
med_calib_data <- sqldf(
  "select * from wshed_data 
   where USGS is not null 
   and CBP6 is not null
   and USGS < 100.0
   and USGS > 10.0"
)
small_calib_data <- sqldf(
  "select * from wshed_data 
   where USGS is not null 
   and CBP6 is not null
   and USGS < 10.0"
)
qmax <- max(calib_data$VAHl90, calib_data$USGS)
plot(calib_data$VAH_l90 ~ calib_data$USGS, ylim=c(0,qmax), xlim=c(0,qmax))
creg = lm(calib_data$VAH_l90 ~ calib_data$USGS)
abline(creg)
summary(creg)

qmax <- max(med_calib_data$VAHl90, med_calib_data$USGS)
plot(med_calib_data$VAH_l90 ~ med_calib_data$USGS, ylim=c(0,qmax), xlim=c(0,qmax))
creg = lm(med_calib_data$VAH_l90 ~ med_calib_data$USGS)
abline(creg)
summary(creg)

qmax <- max(small_calib_data$VAHl90, small_calib_data$USGS)
plot(small_calib_data$VAH_l90 ~ small_calib_data$USGS, ylim=c(0,qmax), xlim=c(0,qmax))
creg = lm(small_calib_data$VAH_l90 ~ small_calib_data$USGS)
abline(creg)
summary(creg)


qmax <- max(calib_data$VAHl90, calib_data$USGS)
plot(calib_data$VAH_l90 ~ calib_data$USGS, ylim=c(0,qmax), xlim=c(0,qmax))


quantile(calib_data$cbp_err_l90)
boxplot(calib_data$cbp_err_l90, ylim=c(-1,5))
creg = lm(calib_data$VAH_l90 ~ calib_data$USGS)
abline(creg)
sqldf("select * from calib_data where abs(vah_err) > 10")
modmod_error_data <- sqldf(
  "select * from wshed_data 
   where abs(modmod_error) > 0.2
   and abs(vah_err) < abs(cbp_err_l90) 
   and abs(flow_alt_pct) > 0.05
  "
)
sqldf(
  "select * from wshed_data 
   where abs(flow_alt_pct) > 0.05
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
  "select propname, USGS, CBP6, VAH_l90, cbp_err_l30, cbp_err_7q10,
     VAH_2040_l90, flow_alt_pct, alt_pct_l30, alt_pct_7q10,alt_pct_Qout,
     USGS + (VAH_2040_l90 - VAH_l90) as adj_2040_l90,
  case 
    when cbp_err_l90 is not null then flow_alt_pct * (cbp_err_l90+ 1.0)
    ELSE NULL
  END as adj_alt_pct,
  case 
    when usgs_l30 < 1.0 then NULL
    when cbp_err_l30 is not null then alt_pct_l30 * (cbp_err_l30 + 1.0)
    ELSE NULL
  END as adj_alt_l30,
  case 
    when USGS_7q10 < 0.50 then NULL
    when alt_pct_7q10 is not null then alt_pct_7q10 * (cbp_err_7q10 + 1.0)
    ELSE NULL
  END as adj_alt_7q10,
  case 
    when USGS_Qout < 0.50 then NULL
    when alt_pct_Qout is not null then alt_pct_Qout * (cbp_mean_err + 1.0)
    ELSE NULL
  END as adj_alt_Qout
  from wshed_data 
  where vah_err is not null
   and cbp_err_l90 is not null"
)


wshed_adj$adj_alt_pct <- round(wshed_adj$adj_alt_pct,3)
wshed_adj$adj_alt_7q10 <- round(wshed_adj$adj_alt_7q10,3)
wshed_adj$adj_alt_l30 <- round(wshed_adj$adj_alt_l30,3)
wshed_adj$adj_alt_Qout <- round(wshed_adj$adj_alt_Qout,3)
notiny_wshed_adj <- sqldf("select * from wshed_adj where USGS >= 10.0")
alt_quants <- round(quantile(
  wshed_adj$flow_alt_pct, 
  probs=c(0.01,0.05,0.1), 
  na.rm = TRUE), 1
)
alt_quants <- rbind(alt_quants, 
  round(
    quantile(
      wshed_adj$adj_alt_pct, 
      probs=c(0.01,0.05,0.1), 
      na.rm = TRUE
    )
  )
)
row.names(alt_quants) <- c('Modeled Alterations', 'Adjusted Alterations')
colnames(alt_quants) <- c("Highest 1%", "Highest 5%", "Highest 10%")
alt_quants

alt_delta_quants <- quantile(
  (wshed_adj$flow_alt_pct - wshed_adj$adj_alt_pct), 
  na.rm=TRUE, 
  probs=c(0,0.01,0.05,0.10, 0.25, 0.5, 0.75,0.9,0.95,0.99,1.0)
)
alt_delta_quants

boxplot(
  wshed_adj$flow_alt_pct, 
  wshed_adj$adj_alt_pct,
  ylim=c(-5,5)
)

wshed_adj_gt500 <- sqldf("select * from wshed_adj where USGS > 500")
wshed_adj_lte500 <- sqldf("select * from wshed_adj where USGS <= 500")
wshed_adj_gt100 <- sqldf("select * from wshed_adj where USGS > 100")
wshed_adj_lte100 <- sqldf("select * from wshed_adj where USGS <= 100")

plot(
  wshed_adj$adj_alt_Qout
  ~ wshed_adj$alt_pct_Qout,
  xlim = c(-50,50),
  ylim = c(-50,50),
  xlab="Base Mean Flow Change (%)",
  ylab="Adjusted Mean Flow Change (%)",
  main="Change in Mean Flow 2020 to 2040"
)
alm <- lm( wshed_adj$adj_alt_Qout
           ~ wshed_adj$alt_pct_Qout  )
abline(alm)
salm <- summary(alm)
text(-30,40, paste(
  "7q10a = ", round(salm$coefficients[1],3), "+", 
  round(salm$coefficients[2],3),"* 7q10"
))
text(-30,35, paste(
  "R^2 = ", round(salm$adj.r.squared,2), ", p-value =", 
  round(salm$coefficients[,4][2],3)
))


plot(
  wshed_adj$adj_alt_pct
  ~ wshed_adj$flow_alt_pct,
  xlim = c(-50,50),
  ylim = c(-50,50),
  xlab="Base Model L90 Change (%)",
  ylab="Adjusted L90 Change (%)",
  main="Change in 90 Day Low Flow 2020 to 2040"
)
alm <- lm( wshed_adj$adj_alt_pct
           ~ wshed_adj$flow_alt_pct  )
abline(alm)
salm <- summary(alm)
text(-30,40, paste(
  "7q10a = ", round(salm$coefficients[1],3), "+", 
  round(salm$coefficients[2],3),"* 7q10"
))
text(-30,35, paste(
  "R^2 = ", round(salm$adj.r.squared,2), ", p-value =", 
  round(salm$coefficients[,4][2],3)
))


plot(
  wshed_adj$adj_alt_l30
  ~ wshed_adj$alt_pct_l30,
  xlim = c(-50,50),
  ylim = c(-50,50),
  xlab="Base Model L30 Change (%)",
  ylab="Adjusted L30 Change (%)",
  main="Change in 30 Day Low Flow 2020 to 2040"
)
alm <- lm( wshed_adj$adj_alt_l30
           ~ wshed_adj$alt_pct_l30  )
abline(alm)
salm <- summary(alm)
text(-30,40, paste(
  "7q10a = ", round(salm$coefficients[1],3), "+", 
  round(salm$coefficients[2],3),"* 7q10"
))
text(-30,35, paste(
  "R^2 = ", round(salm$adj.r.squared,2), ", p-value =", 
  round(salm$coefficients[,4][2],3)
))

plot(
  wshed_adj$adj_alt_7q10
  ~ wshed_adj$alt_pct_7q10,
  xlim = c(-50,50),
  ylim = c(-50,50),
  xlab="Base Model 7q10 Change (%)",
  ylab="Adjusted 7q10 Change (%)",
  main="Change in 7q10 2020 to 2040"
)

alm <- lm( wshed_adj$adj_alt_7q10
           ~ wshed_adj$alt_pct_7q10  )
abline(alm)
salm <- summary(alm)
text(-30,40, paste(
  "7q10a = ", round(salm$coefficients[1],3), "+", 
  round(salm$coefficients[2],3),"* 7q10"
))
text(-30,35, paste(
  "R^2 = ", round(salm$adj.r.squared,2), ", p-value =", 
  round(salm$coefficients[,4][2],3)
))


quantile(notiny_wshed_adj$flow_alt_pct, na.rm=TRUE) 
quantile(notiny_wshed_adj$adj_alt_pct, na.rm=TRUE)

hist(calib_data$cbp_err_l90)
hist(round(calib_data$cbp_err_l30,3))
calib_data$cbp_err_l30
emax <- max(abs(calib_data$cbp_err_l90))
plot( 
  wshed_adj$`Flow Alteration` ~ 
    wshed_adj$`Flow Alteration Adjusted`,
  xlab="Modeled Flow Alteration %",
  ylab="Error Adjusted Flow Alteration %"
)
ereg = lm(wshed_adj$`Flow Alteration Adjusted`~ wshed_adj$`Flow Alteration` )
summary(ereg)

# Specific watershed with some gage data
sqldf(
  "select propname, USGS, VAH_l90, CBP6, VAH_2040_l90, flow_alt_pct,
  case 
    when cbp_err_l90 is not null then flow_alt_pct * (cbp_err_l90+ 1.0)
    WHEN vah_err is not null then flow_alt_pct * (vah_err+ 1.0)
    ELSE NULL
  END as adj_alt_pct
  from wshed_data 
  where hydrocode like '%OR%' and vah_err is not null"
)



boxplot(
  calib_data$cbp_err_l90 * 100.0,
  names = c('CBP'), 
  xlab = 'CBP Model Calibration, 90 Day Low Flow',
  ylab = 'Model Error %',
  ylim=c(-300, +300),
  main=paste('All Data, n =', nrow(calib_data))
)

boxplot(
  calib_data$cbp_mean_err * 100.0,
  calib_data$cbp_err_l90 * 100.0,
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
  calib_data$cbp_mean_err, 
  calib_data$cbp_err_l90 * 100.0, 
  calib_data$cbp_err_l30 * 100.0, 
  calib_data$cbp_err_7q10 * 100.0, 
  names = c('Mean Q', 'L90', 'L30', '7Q10'), 
  xlab = 'Flow Metric',
  ylab = '% Error',
  ylim=c(-100, +300),
  main=paste('CBP Calibration Stations, n =', nrow(calib_data))
)

boxplot(
  calib_data$cbp_err_l90, calib_data$vah_err, 
  names = c('CBP', 'VAHydro'), 
  xlab = '90 day low-flow model error',
  ylim=c(-3, +3),
  main=paste('All Data, n =', nrow(calib_data))
)
boxplot(
  big_calib_data$cbp_err_l90, big_calib_data$vah_err, 
  names = c('CBP', 'VAHydro'), 
  xlab = '90 day low-flow model error',
  main=paste('Watersheds > 50sqmi, n =', nrow(big_calib_data))
)
quantile(calib_data$cbp_err_l90)
quantile(calib_data$vah_err)
quantile(big_calib_data$cbp_err_l90)
quantile(big_calib_data$vah_err)
plot(calib_data$CBP6 ~ calib_data$USGS)
plot(log(calib_data$CBP6) ~ log(calib_data$USGS))
exp(4)
# find some examples
sqldf(
  "select * from wshed_data 
   where abs(cbp_err_l90) > 0.4 
   and abs(cbp_err_l90) < 0.9
  ")
# find where vah better than cbp
sqldf(
  "select * from wshed_data 
   where abs(cbp_err_l90) >  abs(vah_err)
  ")
# THIS REALLY MATTERS!!! How many do we have?
# Actually, only 5
sqldf(
  "select * from wshed_data 
   where abs(flow_alt_pct) > 0.1
  and USGS is not null"
)


# Outputs here 

quantile(
  abs(calib_data$cbp_mean_err), 
  probs=c(0.01,0.05,0.1,0.5, 0.75, 0.8, 0.9,0.95), 
  na.rm = TRUE
)
quantile(
  abs(calib_data$cbp_err_l90), 
  probs=c(0.01,0.05,0.1,0.25, 0.5, 0.8, 0.9,0.95), 
  na.rm = TRUE
)
quantile(
  abs(big_calib_data$cbp_err_l90), 
  probs=c(0.01,0.05,0.1,0.25, 0.5, 0.8, 0.9,0.95), 
  na.rm = TRUE
)
boxplot(
  calib_data$cbp_mean_err * 100.0, big_calib_data$cbp_mean_err * 100.0, 
  calib_data$cbp_err_l90 * 100.0, big_calib_data$cbp_err_l90 * 100.0, 
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
  'USGS L90',
  'CBP L90',
  '2020 L90',
  '2040 L90',
  'Flow Alt.',
  'Flow Alt. Adjusted'
)


#abline(ereg)
hist(calib_data$cbp_err_l90)
#WRITE KABLE TABLE
table_tex <- kable(wshed_adj,align = "l",  booktabs = T,format = "latex",longtable =T,
                   caption = "Modeled flow alteration in 2040, adjusted for CBP model error.",
                   label = "Error Adjusted Flow Alteration") %>%
  kable_styling(latex_options = "striped") 

table_tex <- gsub(pattern = "{table}[t]", 
                  repl    = "{table}[H]", 
                  x       = table_tex, fixed = T )
table_tex %>%
  cat(., file = paste0(export_path,"\\model_error_adjust_tbl.tex"),sep="")


table_tex <- kable(alt_quants,align = "l",  booktabs = T,format = "latex",longtable =T,
                   caption = "Percent alteration in most highly impacted river segments in 2040, and adjusted for CBP model error.",
                   label = "Error Adjusted Flow Alteration") %>%
  kable_styling(latex_options = "striped") 

table_tex <- gsub(pattern = "{table}[t]", 
                  repl    = "{table}[H]", 
                  x       = table_tex, fixed = T )
table_tex %>%
  cat(., file = paste0(export_path,"\\error_adjust_quantiles_tbl.tex"),sep="")
