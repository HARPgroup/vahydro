library("knitr")
library("kableExtra")

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
cu_table = om_flow_table(rt_broad6, 'cu_daily')

q_table = om_flow_table(rt_broad6, 'Qout')
qcu_table = q_table
qcu_colors = matrix(nrow = nrow(q_table), ncol = ncol(q_table))
rn = 0
for (r in rownames(q_table)) {
  rn = rn + 1
  cn = 0
  for (c in colnames(q_table[r,])) {
    cn = cn + 1
    qcu_colors[rn,cn] = "white"
    if (cu_table[r,c] <= -10.0) {
      qcu_colors[rn,cn] = "yellow"
    } 
    if (cu_table[r,c] <= -20.0) {
      qcu_colors[rn,cn] = "orange"
    } 
    qcu_table[r,c] <- paste0( q_table[r,c], " (", cu_table[r,c],"%)")
  }
}

fqcu_table <- flextable(qcu_table)
fqcu_table <- bg(fqcu_table, bg="white")

for (i in 1:nrow(qcu_colors)) {
  for (j in 1:ncol(qcu_colors)) {
    fqcu_table <- bg(fqcu_table, i, j, bg = qcu_colors[i,j])
  }
}
fqcu_table
