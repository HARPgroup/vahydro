# Load base info in jrcc.R

# Find river seg facilities: JU3_6950_7330  
sqldf("select * from fac_data where riverseg = 'JL4_6710_6740'")
# Find river seg facilities: JU3_6950_7330  
rivanna_wsheds <- sqldf(
  "select * from wshed_case where riverseg in (
      'JL2_6440_6441', 'JL2_6440_6441_buck_mtn_creek', 
      'JL2_6440_6441_moormans_sugar_hollow',
      'JL1_6560_6440_ivy_creek', 'JL1_6560_6440_beaver_creek', 
      'JL1_6560_6440'
   )
   or riverseg like 'JL4%'
  "
)
sqldf("select * from rivanna_wsheds where l30_400 > 100")

# beaver creek runoff
datbro400 <- om_get_rundata(351959, 400, site = omsite)

datbeav201 <- om_get_rundata(351963, 201, site = "http://deq1.bse.vt.edu")
datbeav400 <- om_get_rundata(351963, 400, site = omsite)
quantile(datbeav400$Qout)
quantile(datbeav400$Runit_mode)
dativy400 <- om_get_rundata(337852, 400, site = omsite)
quantile(dativy400$Runit_mode)
riva13 <- om_get_rundata(337730, 13, site = omsite)
riva400 <- om_get_rundata(337730, 400, site = omsite)
quantile(riva400$Runit_mode)
quantile(riva400$Qout)
mean(riva400$Qout)

rivawtp13 <- om_get_rundata(347350, 13, site = omsite)
rivawtp400 <- om_get_rundata(347350, 400, site = omsite)
quantile(rivawtp13$discharge_mgd)
quantile(rivawtp400$discharge_mgd,probs=c(0,0.05,0.1,0.25))

om_flow_table(riva400, "Qout")
om_flow_table(riva400, "ps_cumulative_mgd")
om_flow_table(riva13, "Qout")
om_flow_table(riva13, "ps_cumulative_mgd")

datbeavro400 <- om_get_rundata(351959, 400, site = omsite)
quantile(datbeavro400$Runit)
datbeav600 <- om_get_rundata(351963, 600, site = omsite)



om_flow_table(riva400, "Qout")
om_flow_table(riva400, "ps_cumulative_mgd")
om_flow_table(riva13, "Qout")
om_flow_table(riva13, "ps_cumulative_mgd")

buck400 <- om_get_rundata(337728 , 400, site = omsite)
sum(buck400$wd_cumulative_mgd)
sum(buck400$wd_upstream_mgd)
sum(buck400$wd_mgd)


fn_check_wdc(
  wshed_case[which(wshed_case$riverseg == 'JL1_6560_6440'),],
  wshed_case, wd_col, wdc_col)
fn_upstream2('JL1_6560_6440', wshed_case)
# mechums 337722 
me400 <- om_get_rundata(337722, 400, site = omsite)
sum(me400$wd_upstream_mgd)
sfr400 <- om_get_rundata(352054 , 400, site = omsite)
mean(sfr400$wd_upstream_mgd)

sh400 <- om_get_rundata(337718 , 400, site = omsite)
mean(sh400$wd_cumulative_mgd)

