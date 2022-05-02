# :ittle Falls Habitat data

# INPUTS #######################################################################################
ifim_featureid <- 397295 #Potomac 8&9
wshed_featureid <- 68346 #Potomac River Great Falls
pprunid <- 13 # will have this set to 6 once draft run is confirmed
pctile <- 0.1

################################################################################################
# RETRIEVE RSEG MODEL
ds <- RomDataSource$new(site, 'restws_admin')
ds$get_token(rest_pw)
wshed_model <- RomProperty$new(ds,list(featureid = wshed_featureid, entity_type = 'dh_feature', propcode = 'vahydro-1.0'), TRUE)
elid <- om_get_model_elementid(base_url, wshed_model$pid)

################################################################################################
# RETRIEVE IFIM SITE FEATURE
ifim_site <- getFeature(list(hydroid = ifim_featureid), token, site, feature)
ifim_site_name <- as.character(ifim_site$name)

################################################################################################
# RETRIEVE WUA TABLE
ifim_dataframe <- vahydro_prop_matrix(ifim_featureid, 'dh_feature','ifim_habitat_table')
wua_gf <- t(ifim_dataframe)
targets <- colnames(wua_gf)[-1]
write.table(
  wua_gf,
  file = paste(github_location,"/vahydro/R/permitting/potomac_lfaa/",'wua_gf','.csv',sep=""),
  sep = ","
)
################################################################################################
# DERIVE MULTIPLYING FACTOR FOR AREA-WEIGHTING FLOWS AT MODEL OUTLET TO IFIM SITE LOCATION

# RETRIEVE IFIM SITE DA SQMI
ifim_da_sqmi <- getProperty(list(varkey = 'nhdp_drainage_sqmi',featureid = ifim_featureid,entity_type = 'dh_feature'),site,prop)
ifim_da_sqmi <- as.numeric(ifim_da_sqmi$propvalue)
# RETRIEVE RSEG DA SQMI
rseg_da_sqmi <- getProperty(list(varkey = 'wshed_drainage_area_sqmi',featureid = wshed_featureid,entity_type = 'dh_feature'),site,prop)
rseg_da_sqmi <- as.numeric(rseg_da_sqmi$propvalue)
gf_da_sqmi = rseg_da_sqmi

weighting_factor <- ifim_da_sqmi/rseg_da_sqmi
if (weighting_factor == 0) {
  weighting_factor = 1.0
  ifim_da_sqmi <- rseg_da_sqmi
}
