library('knitr')
library('kableExtra')
# Ni Reservoir
qs <- NULL
for (i in c(11,13,17,19)) {
  
  dat <- om_get_rundata(352004 , i)
  datdf <- as.data.frame(dat)
  drawdown <- sqldf(
    "select year, max(impoundment_lake_elev), 
   min(impoundment_lake_elev), 
   (max(impoundment_lake_elev) - min(impoundment_lake_elev)) as drawdown 
   from datdf 
   group by year 
   order by year
  ")
  seepdays <- sqldf(
    "select year, count(*) as numdays
   from datdf 
   where Qout < 1.0
   group by year 
   order by year
  ")
  sm = median(seepdays$numdays)
  qi <- round(quantile(drawdown$drawdown),1)
  qi <- data.frame(rbind(qi))
  qi$runid <- i
  qi$lfdays <- sm
  col_order <- c("runid", "X0.", "X25.",
                   "X50.", "X75.", "X100.", "lfdays")
  qi <- qi[, col_order]
  names(qi) <- c('runid', '0%', '25%', '50%', '75%', '100%', 'Median Days < 1 cfs')
  if (is.null(qs)) {
    qs <- qi
  } else {
    qs <- rbind(qs, qi)
  }
}
qs

# OUTPUT TABLE IN KABLE FORMAT
qs_tex <- kable(
  qs,  booktabs = T,format = "latex",
  caption = "Ni River reservoir lake surface drawdown quantiles by model run.",
  label = "Ni Reservoir"
  #col.names = "Localities"
) %>%
kable_styling(latex_options = "striped") 
qs_tex
