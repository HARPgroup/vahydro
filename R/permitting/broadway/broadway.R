basepath='/var/www/R';
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#source("/var/www/R/config.local.private");
source(paste(basepath,'config.R',sep='/'))
ds = RomDataSource$new(site, rest_uname)
ds$get_token(rest_pw)

# Town of Broadway
facid = 74345
riverid = 67830
rpid = 4713853
fpid = 4829190
relid = 229937

# generate
rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/VWP_CIA_Summary.Rmd', 
  output_file = '/usr/local/home/git/vahydro/R/permitting/broadway/te_broadway_v01.docx', 
  params = list( 
    rseg.hydroid = 67830, 
    fac.hydroid = 74345, 
    runid.list = c("runid_11", "runid_400","runid_600"), 
    intake_stats_runid = 400,
    upstream_rseg_ids=c(469965) 
  )
)

rt_broad4 <- om_get_rundata(relid , 400, site = omsite)
rt_broad6 <- om_get_rundata(relid , 600, site = omsite)
rt_broad13 <- om_get_rundata(relid , 13, site = omsite)
rt_broad11 <- om_get_rundata(relid , 11, site = omsite)
wd_r4 = om_flow_table(rt_broad4, 'wd_cumulative_mgd')
wd_r13 = om_flow_table(rt_broad13, 'wd_cumulative_mgd')
q_r6 = om_flow_table(rt_broad6, 'Qout')

# this translates the consumptive use as a negative percentage, so that it 
# shows up in a comparable table to the flow percentage table.  
# the can therefore be merged.
rt_broad6$Qbaseline <- rt_broad6$Qout + (rt_broad6$wd_cumulative_mgd - rt_broad6$ps_cumulative_mgd) * 1.547
rt_broad6$cu_daily <- (
  -100.0 * (rt_broad6$wd_cumulative_mgd - rt_broad6$ps_cumulative_mgd) * 1.547 
  / (
    rt_broad6$Qout + (rt_broad6$wd_cumulative_mgd - rt_broad6$ps_cumulative_mgd) * 1.547
  )
)
cu_r6 = om_flow_table(rt_broad6, 'cu_daily')

qcu_table = q_r6
for (r in rownames(q_r6)) {
  for (c in colnames(q_r6[r,])) {
    qcu_table[r,c] <- paste0(q_r6[r,c], " (", cu_r6[r,c],"%)")
  }
}
kable(qcu_table)

