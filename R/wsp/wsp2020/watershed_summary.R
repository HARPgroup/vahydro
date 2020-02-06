# dirs/URLs
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))

# Camp Creek - 279187, South Anna - 207771, James River - 214907, Rapp above Hazel confluence 257471
# Rapidan above Rapp - 258123
elid = 230533     
runid = 11

omsite = site <- "http://deq2.bse.vt.edu"
dat <- fn_get_runfile(elid, runid, site= omsite,  cached = FALSE)
syear = min(dat$year)
eyear = max(dat$year)
if (syear != eyear) {
  sdate <- as.Date(paste0(syear,"-10-01"))
  edate <- as.Date(paste0(eyear,"-09-30"))
} else {
  sdate <- as.Date(paste0(syear,"-02-01"))
  edate <- as.Date(paste0(eyear,"-12-31"))
}
dat <- window(dat, start = sdate, end = edate);
mode(dat) <- 'numeric'

amn <- 10.0 * mean(as.numeric(dat$Qin))

amnwd <- 1.1 * max(as.numeric(dat$wd_cumulative_mgd))

dat <- window(dat, start = as.Date("1984-10-01"), end = as.Date("2014-09-30"));
datdf <- as.data.frame(dat, stringsAsFactors = FALSE)
modat <- sqldf(
  "select month, avg(wd_cumulative_mgd) as wd_cumulative_mgd, 
    round(avg(wd_mgd),2) as wd_mgd , 
    round(avg(ps_cumulative_mgd),2) as ps_cumulative_mgd, 
    round(avg(ps_mgd),2) as ps_mgd 
  from datdf 
  group by month")

mot <- t(as.matrix(modat[,c('wd_cumulative_mgd', 'wd_mgd', 'ps_cumulative_mgd', 'ps_mgd')]) )
mode(mot) <- 'numeric'
barplot(mot, main="Monthly Mean Withdrawals",
  xlab="Month", col=c("darkblue","lightblue", "darkgreen", "lightgreen"),
  legend = c('WD Cumulative', 'WD Local','PS Cumulative', 'PS Local'), beside=TRUE)

datdf <- as.data.frame(dat)
Qyear <- sqldf("select year, avg(Qout) from datdf group by year order by year")

# For some reason we need to convert these numeric fields to char, then to number
# before sending to zoo since their retrieval is classifying them as factors instead of nums
# now there may be away to get around that but...
flows <- zoo(as.numeric(as.character( dat$Qout )), order.by = dat$thisdate);

#flows <- fn_get_rundata(elid, runid);
if (!is.null(flows)) {
  x7q10 = round(fn_iha_7q10(flows),2);
  alf = round(fn_iha_mlf(flows, 8),2);
} else {
  x7q10 = 'na';
  alf = 'na';
}
wds <- zoo(as.numeric(as.character( dat$wd_cumulative_mgd )), order.by = dat$thisdate);
drainage <- mean(dat$area_sqmi );
#wds <- fn_get_rundata(elid, runid, "wd_cumulative_mgd");
if (is.numeric(wds)) {
  mean_wd = round(mean(wds),2);
  max_wd = round(max(wds),2);
} else {
  mean_wd = 'na';
  max_wd = 'na';
}
# aggregate: https://stackoverflow.com/questions/5556135/how-to-get-the-date-of-maximum-values-of-rainfall-in-programming-language-r
if (!is.null(flows)) {
  # this is the 90 day low flow, better for Drought of Record?
  loflows <- group2(flows);
  l90 <- loflows["90 Day Min"];
  ndx = which.min(as.numeric(l90[,"90 Day Min"]));
  dor_flow = round(loflows[ndx,]$"90 Day Min",1);
  dor_year = loflows[ndx,]$"year";
  
  #moflows <- aggregate(flows, function(tt) as.Date(as.yearmon(tt), na.rm = TRUE), mean);
  #ndx = which.min(moflows);
  #x2a <- aggregate(flows, as.Date(as.yearmon(flows), na.rm = TRUE), mean);
  #dor_flow = round(moflows[ndx],2);
  #dor_year = index(moflows[ndx]);
} else {
  dor_flow = 'na';
  dor_year = 1776;
}
newline = data.frame( 
  "Run ID" = runid, 
  "Segment Name (D. Area)" = paste(
    fname, 
    " (", as.character(drainage), ")", sep=""), 
  "7Q10/ALF/DoR" = paste(
    as.character(x7q10), 
    as.character(alf),
    paste(
      as.character(dor_flow), 
      " (", 
      dor_year, 
      ")", 
      sep=''
    ),
    sep="/"
  ),
  "WD (mean/max)" = paste(as.character(mean_wd),as.character(max_wd),sep="/")
);

wshed_summary_tbl <- rbind(wshed_summary_tbl, newline);
dat$wd_cumulative_mgd <- as.numeric(dat$wd_cumulative_mgd);
dat$month <- as.numeric(dat$month);
# Monthly Mean Withdrawal table
mo_wds <- group1(wds,'calendar','mean');
if (length(mostash) == 0) {
  mostash <- cbind(mo_wds[1,]);
} else {
  mostash <- cbind(mostash, mo_wds[1,])
}
# Monthly Median Low-Flow table
mo_lows <- group1(flows,'calendar','min');
molo = apply(mo_lows,2,function (x) median(x, na.rm = TRUE))
if (length(molo_stash) == 0) {
  molo_stash <- molo;
} else {
  molo_stash <- rbind(molo_stash, molo)
}

colnames(wshed_summary_tbl) <- c(
  "Run ID", 
  "Segment Name (D. Area)", 
  "7Q10/ALF/Min Month", 
  "WD (mean/max)" 
);
