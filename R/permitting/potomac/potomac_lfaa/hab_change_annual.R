# Expects time series alt_lf to be created

yrs = c(1930, 2002, 2007, 2008, 2015, 2016,2019)
yrs = c(1930)

for (yr in yrs) {
  # Box Plot for 1931
  alt_lf_yr <- sqldf(paste("select * from alt_lf where year = ", yr))

  # just look at the box plot
  yrplot <- pothab_plot(
    wua_lf, alt_lf_yr, "Flow", "Flow_curr",
    1.0, ifim_da_sqmi,
    "Little Falls", "Current"
  )
  yrplot +
    labs(title = paste("Habitat Change, ICPRB Max Demand Little Falls,", yr, "only.") )
  + ylim(c(-100,100))

  plot(alt_lf_yr$Flow ~ nat_lf_yr$Date, col='blue', ylim=c(0,5000))
  points(alt_lf_yr$Flow_curr ~ alt_lf_yr$Date, col='red')

  pd_nat_flow_table <- om_flow_table(nat_lf_yr, "Flow")
  pd_alt_flow_table <- om_flow_table(alt_lf_yr, "Flow")


  yrplot$data$pctchg <- round(yrplot$data$pctchg, 2)
  yrplot$data[is.na(yrplot$data$pctchg),]$pctchg <- 0.0
  ifim_sumdata_yr <- xtabs(pctchg ~ metric + flow, data = yrplot$data)
  ifim_mat <- as.data.frame.matrix(ifim_sumdata_yr)
  ifim_mat <- cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
  yrplot$data.formatted <-  cbind(MAF = ifim_mat[,"MAF"], ifim_mat[,month.abb])
  tbls5pct <- as.data.frame(yrplot$data.formatted)
  write.table(
    tbls5pct$data.formatted,
    file = paste(export_path,'ifim_wua_chg',yr,elid,'.csv',sep=""),
    sep = ","
  )
}
