# Load base info in jrcc.R

# Find river seg facilities: JU3_6950_7330  
sqldf("select * from fac_data where riverseg = 'JU3_6950_7330'")
# Find river seg facilities: JU3_6950_7330  
sqldf("select * from wshed_case where riverseg = 'JU3_6950_7330'")
sqldf("select * from fac_data where riverseg = 'JU3_6380_6900'")
sqldf("select * from wshed_case where riverseg = 'JU3_6380_6900'")

cobb400 <- om_get_rundata(337692 , 400, site = omsite)
quantile(cobb400$Qout, probs=c(0,0.25,0.5,0.75,0.8,0.85,0.9,0.95,1.0))
quantile(cobb400$refill_pump_mgd, probs=c(0,0.25,0.5,0.75,0.8,0.85,0.9,0.95,1.0))
acart13 <- om_get_rundata(211097 , 13, site = omsite)  
acart400 <- om_get_rundata(211097 , 400, site = omsite)  
quantile(acart400$wd_mgd, probs=c(0,0.25,0.5,0.75,0.8,0.85,0.9,0.95,1.0))
om_flow_table(acart400, "Qout")
om_flow_table(acart400, "wd_cumulative_mgd")
om_flow_table(acart400, "ps_cumulative_mgd")
om_flow_table(acart13, "Qout")
om_flow_table(acart13, "wd_cumulative_mgd")
om_flow_table(acart13, "ps_cumulative_mgd")
mean(acart400$wd_mgd)

om_flow_table(cobb400, "Qout")
mean(cobb400$refill_pump_mgd)

cart400 <- om_get_rundata(210731 , 400, site = omsite)  
quantile(cart400$wd_cumulative_mgd, probs=c(0,0.25,0.5,0.75,0.8,0.85,0.9,0.95,1.0))
rseg.hydroid = 68265
rseg.model <- om_get_model(site, rseg.hydroid)
rseg.elid <- om_get_prop(site, rseg.model$pid, entity_type = 'dh_properties','om_element_connection')$propvalue

#FAC MODEL INFO
fac.model <- om_get_model(site, fac.hydroid, model_varkey = 'om_water_system_element')
fac.elid <- om_get_prop(site, fac.model$pid, entity_type = 'dh_properties','om_element_connection')$propvalue

#fac_obj_url <- paste(json_obj_url, fac.model$pid, sep="/")
#fac_model_info <- om_auth_read(fac_obj_url, token,  "text/json", "")
#fac_model_info <- fromJSON(fac_model_info)

rseg_obj_url <- paste(json_obj_url, rseg.model$pid, sep="/")
rseg_model_info <- om_auth_read(rseg_obj_url, token,  "text/json", "")
rseg_model_info <- fromJSON(rseg_model_info)
# get report cusomtizations
fac_report_info = find_name(fac_model_info, "reports")