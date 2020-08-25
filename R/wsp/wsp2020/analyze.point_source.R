library('rjson') # must do unloadNamespace('jsonlite')
# OR
library('jsonlite') # must do unloadNamespace('rjson')
library('sqldf') #
# Facility monthly variation in demand as % of annual
# use 
fname = "http://deq2.bse.vt.edu/d.dh/dh-properties-json/dh_feature/all/all/wd_current_mon_factors"
cn <- c('pct_of_annual', 'pct_of_annual.1', 'pct_of_annual.2', 'pct_of_annual.3', 'pct_of_annual.4', 'pct_of_annual.5', 'pct_of_annual.6', 'pct_of_annual.7', 'pct_of_annual.8', 'pct_of_annual.9', 'pct_of_annual.10', 'pct_of_annual.11')

# colname vary based on the header row
cn <- c(2,4,6,8,10,12,14,16,18,20,22,24)
# use ^ instead of named columns which varies
#cn <- c('xFrac', 'xFrac.1', 'xFrac.2', 'xFrac.3', 'xFrac.4', 'xFrac.5', 'xFrac.6', 'xFrac.7', 'xFrac.8', 'xFrac.9', 'xFrac.10', 'xFrac.11')
#cn <- c('mo_frac', 'mo_frac.1', 'mo_frac.2', 'mo_frac.3', 'mo_frac.4', 'mo_frac.5', 'mo_frac.6', 'mo_frac.7', 'mo_frac.8', 'mo_frac.9', 'mo_frac.10', 'mo_frac.11')
fname = "http://deq2.bse.vt.edu/d.dh/dh-properties-json/dh_properties/4824507/all/consumption_monthly"
# Use percent withdrawal to recalculate consumption
cn <- c(2,4,6,8,10,12,14,16,18,20,22,24)


get_props_json <- function(xfile) {
  
  prop_tbl = NULL
  for (i in 1:length(xfile$entity_properties)) {
    # jsonlite
    prop <- as.data.frame(xfile$entity_properties[[i]]$property)
     # rjson
   # prop$pid <- xfile$entity_properties[[i]]$property$pid
    if (is.null(prop_tbl) ) {
      prop_tbl <- prop
    } else {
      prop_tbl <- rbind(prop_tbl, prop)
    }
  }
  return(prop_tbl)
}

get_matrix_tbl <- function(xfile, cn = c(2,4,6,8,10,12,14,16,18,20,22,24)) {
  
  mofrac_tbl = NULL
  for (i in 1:length(xfile$entity_properties)) {
    # jsonlite
    xfact<- as.data.frame(fromJSON(xfile$entity_properties[[i]]$property$prop_matrix))
    
    mofrac <- xfact[cn]
    mofrac$pid <- xfile$entity_properties[[i]]$property$pid
    mofrac$featureid <- xfile$entity_properties[[i]]$property$entity_id
    mofrac$propvalue <- xfile$entity_properties[[i]]$property$propvalue
    colnames(mofrac) <- c('jan','feb','mar','apr','may','jun','jul','aug','sept','oct','nov','dec', 'pid', 'featureid', 'propvalue')               
    # rjson
    mofrac$pid <- xfile$entity_properties[[i]]$property$pid
    if (is.null(mofrac_tbl) ) {
      mofrac_tbl <- mofrac
    } else {
      mofrac_tbl <- rbind(mofrac_tbl, mofrac)
    }
  }
  return(mofrac_tbl)
}

# dh-properties-json: entity_type/featureid/varkey/propname/propcode
# Need:
# facility ->
#   Model ->
fname = "http://deq2.bse.vt.edu/d.dh/dh-properties-json/dh_feature/all/all/all/vahydro-1.0"
# rjson
dh_xjson_file <-  fromJSON(file = fname)
#     Withdrawal fracs
fname = "http://deq2.bse.vt.edu/d.dh/dh-properties-json/dh_properties/all/all/historic_monthly_pct"
# rjson
dh_xjson_file <-  fromJSON(file = fname)
# jsonlite
# xfile <-  fromJSON(fname)

wd_mofracs <- get_matrix_tbl(dh_xjson_file)
sqldf(
  "select count(*) from wd_mofracs 
   where 
    (( feb * 28.25 ) > (jan * 31)) 
    AND 
    (( feb * 28.25 ) > (dec * 31)) 
    AND 
    ( jan > 0 ) 
    AND (dec > 0) 
  ")
sqldf(
  "select * from wd_mofracs 
   where 
    (( feb * 28.25 ) > (jan * 31)) 
    AND 
    (( feb * 28.25 ) > (dec * 31)) 
    AND 
    ( jan > 0 ) 
    AND (dec > 0) 
  ")

# consumption fracs
fname = "http://deq2.bse.vt.edu/d.dh/dh-properties-json/dh_properties/all/all/consumption_monthly"
dh_xjson_file <-  fromJSON(file = fname)
cu_anfracs <- get_props_json(dh_xjson_file)

xfactdf <- as.data.frame(xfact)
nrow(xfile$entity_properties[[3]])
fromJSON(xfile$entity_properties[[,]]$property$prop_matrix)

fname = "http://deq2.bse.vt.edu/d.dh/dh-properties-json/dh_properties/all/all/consumption_monthly"
dh_xjson_file <-  fromJSON(file = fname)
cu_mofracs <- get_matrix_tbl(dh_xjson_file)
mun_fracs <- sqldf(
  "select * 
   from cu_mofracs 
   where (
      NOT (  
        jul = aug 
        and sept = jun	
        and jul <> 0
      )
      AND NOT (
        may = 0.15 
        and jun = 0.15
        and jul = 0.2
        and aug = 0.15
      )
   )
")

valid_anfracs <- flatten(sqldf(
  " select a.pid, a.propvalue 
    from cu_anfracs as a 
    left outer join mun_fracs as b
    on (entity_id = b.featureid)
    where b.pid is not null
  "
))

WBRm = round(mean(as.numeric(mun_fracs$propvalue)),2)

boxplot(
  mun_fracs$jan + 0.1, mun_fracs$feb + 0.1, mun_fracs$mar + 0.1, 
  mun_fracs$apr + 0.1, mun_fracs$may + 0.1, mun_fracs$jun + 0.1, 
  mun_fracs$jul + 0.1, mun_fracs$aug + 0.1, mun_fracs$sept + 0.1, 
  mun_fracs$oct + 0.1, mun_fracs$nov + 0.1, mun_fracs$dec + 0.1,
  outline = FALSE,
  ylim = c(0,1.0),
  ylab = 'Fraction of Withdrawal to Consmptive Uses', 
  names=month.abb
)
par(lwd=3)
lines(c(1:12), rep(0.1,12), col="red")

par(lwd=1)
boxplot(
  mun_fracs$jan, mun_fracs$feb, mun_fracs$mar, 
  mun_fracs$apr, mun_fracs$may, mun_fracs$jun, 
  mun_fracs$jul, mun_fracs$aug, mun_fracs$sept, 
  mun_fracs$oct, mun_fracs$nov, mun_fracs$dec,
  outline = FALSE,
  ylim = c(0,0.4),
  ylab = 'Fraction of Withdrawal to Consmptive Uses', 
  names=month.abb,
  main="Winter Base Rate (WBR) Monthly CU Factors"
)
#par(lwd=3)
#lines(c(1:12), rep(0.1,12), col="red")

# dissag data
fname = "http://deq2.bse.vt.edu/d.dh/dh-properties-json/dh_adminreg_feature/all/wsp_current_disagg_use/all"

dh_xjson_file <-  fromJSON(file = fname)
dissag <- get_props_json(dh_xjson_file)
total_cat_use <- sqldf (
  "select entity_id, sum(propvalue) as total_use
   from dissag 
   group by entity_id
  "
)

use_cat_use <- sqldf (
  "select propcode, sum(propvalue) as total_use
   from dissag 
   group by propcode 
   order by propcode
  "
)

unloss <- sqldf(
  " select a.propvalue as unacc, total_use, 
    round(a.propvalue / b.total_use, 4) as unac_frac
    from dissag as a 
    left outer join total_cat_use as b 
    on (
      a.entity_id = b.entity_id
    )
    where a.propcode = 'Unaccounted Loss'
  "
)
unloss <- as.data.frame(unloss)
mode(unloss) <- 'numeric'
UNACd = median(unloss$unac_frac, na.rm= TRUE)
UNACq = quantile(unloss$unac_frac, na.rm= TRUE)
#       0%      25%      50%      75%     100% 
# 0.000000 0.090275 0.135200 0.265750 0.658800
UNACm = mean(unloss$unac_frac, na.rm= TRUE)
UNACt = sum(as.numeric(unloss$unacc)) / sum(unloss$total_use,na.rm = TRUE)

various <- c(
  "Lit" = 0.2, # n = ??
  "TV" = 0.25, # n = 1500, but...
  "WBR*" = WBRm, # n = 
#  "UNACd" = UNACd,
#  "UNACm" = 0.19,
#  "UNACt" = UNACt,
  "WBR+UNAC" = round(WBRm + UNACt,2)
)
xx <- barplot(
  various, 
  col = c('grey', 'grey', 'grey', 'light blue'),
  ylim = c(0,0.4),
  main="Compare Lit., Total Volume, WBR, WBR + Losses"
)
rect(3.8, round(WBRm + UNACt,2), 4.8, round(WBRm + UNACm,2),
     col=NULL, border=par("fg"), lty=NULL, lwd=par("lwd"), xpd=FALSE)
text(x = xx, y = various, label = various[1:4], pos = 3, cex = 0.8, col = "red")
text(x = xx[4,], y = round(WBRm + UNACm,2), label = round(WBRm + UNACm,2), pos = 3, cex = 0.8, col = "red")

