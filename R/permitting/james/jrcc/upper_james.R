# Load base info in jrcc.R

# Find river seg facilities: JU3_6950_7330  
sqldf("select * from fac_data where riverseg = 'JU3_6950_7330'")
# Find river seg facilities: JU3_6950_7330  
sqldf("select * from wshed_case where riverseg = 'JU3_6950_7330'")
sqldf("select * from fac_data where riverseg = 'JU3_6380_6900'")
sqldf("select * from wshed_case where riverseg = 'JU3_6380_6900'")

blk400 <- om_get_rundata(352056, 400, site = omsite)
quantile(blk400$Qout)

# Bath county dam 

bath13 <- om_get_rundata(209755, 13, site = omsite)
bath400 <- om_get_rundata(209755, 400, site = omsite)
om_flow_table(bath13, "Qout")
om_flow_table(bath400, "Qout")

# back creek below Bath county dam
bbb13 <- om_get_rundata(211875, 13, site = omsite)
bbb400 <- om_get_rundata(211875, 400, site = omsite)
om_flow_table(bbb13, "Qout")
om_flow_table(bbb400, "Qout")


# Little Back Creek
# this is a funny one, it is the element that is below the lake used by Bath County Dam 
# to store water for hydro use, so it uses a remote link to connect to that outflow
lbc13 <- om_get_rundata(334537 , 13, site = omsite)
lbc400 <- om_get_rundata(334537 , 400, site = omsite)
lbc1301 <- om_get_rundata(334537 , 1301, site = omsite)
om_flow_table(lbc13, "Qout")
om_flow_table(lbc400, "Qout")
om_flow_table(lbc1301, "Qout")
# The area sent to the next down is trib area so subtracts from flow
mean(lbc13$local_channel_area)
mean(lbc400$local_channel_area)
mean(lbc1301$local_channel_area)
# back creek river channel below Bath county dam
bbr13 <- as.data.frame(om_get_rundata(211911, 13, site = omsite))
bbr400 <- as.data.frame(om_get_rundata(211911, 400, site = omsite))
bbr1301 <- as.data.frame(om_get_rundata(211911, 1301, site = omsite))


# Back Creek above Gathright
bcagd13 <- om_get_rundata(211743, 13, site = omsite)
bcagd400 <- om_get_rundata(211743, 400, site = omsite)
bcagd600 <- om_get_rundata(211743, 400, site = omsite)
om_flow_table(bcagd13, "Qout")
om_flow_table(bcagd400, "Qout")
om_flow_table(bcagd600, "Qout")
 

# Gathright
gd13 <- om_get_rundata(213635, 13, site = omsite)
gd400 <- om_get_rundata(213635, 400, site = omsite)
gd600 <- om_get_rundata(213635, 400, site = omsite)
gd413 <- om_ts_diff(gd13, gd400, "Qout", "Qout", "all")

sqldf("select * from gd413 where year = 2007")
om_flow_table(gd13, "Qout")
om_flow_table(gd400, "Qout")
om_flow_table(gd600, "Qout")

om_flow_table(gd13, "ps_cumulative_mgd")
om_flow_table(gd400, "ps_cumulative_mgd")
om_flow_table(gd13, "wd_cumulative_mgd")
om_flow_table(gd400, "wd_cumulative_mgd")


sqldf(
  "select * from wshed_case
   where riverseg in ('JU3_6950_7330', 'JU4_7330_7000')
   order by riverseg
  ")

# difference in cumulative withdrawal occurs in Jackson River between 
# segment JU3_6950_7330 ( 214595 ) and segment JU4_7330_7000 ( 213253 )
# intermediary between these two is elid 213263
j6950 <- om_get_rundata(214595 , 400, site = omsite)
j7330 <- om_get_rundata(213253 , 400, site = omsite)
up7330 <- om_get_rundata(213263 , 400, site = omsite)

quantile(j6950$wd_cumulative_mgd)
quantile(up7330$wd_upstream_mgd)
quantile(j7330$wd_upstream_mgd)


lh400 <- om_get_rundata(351678, 400, site = omsite)
lh600 <- om_get_rundata(351678, 600, site = omsite)

quantile(lh400$Qintake)
quantile(lh600$Qintake)
quantile(lh400$base_demand_mgd)
quantile(lh600$base_demand_mgd)
quantile(lh400$current_mgd)
quantile(lh600$current_mgd)
