# install_github("HARPGroup/hydro-tools", force=TRUE)
library("hydrotools")
library('zoo')
basepath='/var/www/R';
source("/var/www/R/config.R")

# Set up our data source
ds <- RomDataSource$new(site, rest_uname = rest_uname)
ds$get_token(rest_pw)

sffelid <- 347350 # SF facility
sfrelid <- 352054 # SF River seg
bmelid <- 337728 # Buck Mountain Creek
icelid <-  # Ivy Creek
shelid <- 337718 # Sugar Hollow
roelid <- 352020 # runoff 
rmelid <- 337726 # Ragged Mtn
relid <- 337730 # Rivanna 
rjelid <- 214993 # Rivanna at James confluence

roelid <- 351983 # 
rodatr4 <- om_get_rundata(roelid, 801, site=omsite)

rdatr4 <- om_get_rundata(relid, 801, site=omsite)
rjdatr4 <- om_get_rundata(rjelid, 801, site=omsite)

sfdatf4 <- om_get_rundata(sffelid, 801, site=omsite)
sfdatr4 <- om_get_rundata(sfrelid, 801, site=omsite)
rmdatr4 <- om_get_rundata(rmelid, 801, site=omsite)
quantile(rmdatr4$impoundment_Qout)

mean(sfdatr4$Runit_mode)
mean(sfdatr4$Qlocal)
quantile(sfdatr4$Qout)
mean(sfdatr4$Qout)

shdatf4 <- om_get_rundata(shelid, 401, site=omsite)

sfdatf4 <- om_get_rundata(sffelid, 401, site=omsite)

bcdatf4 <- om_get_rundata(felid, 401, site=omsite)

bcdatr4 <- om_get_rundata(relid, 401, site=omsite)

bcdatro4 <- om_get_rundata(roelid, 401, site=omsite)

bmdat4 <- om_get_rundata(bmelid, 401, site=omsite)


df <- data.frame(
  'model_version' = c('vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_11', '0.%20River%20Channel', 'local_channel'),
  'runlabel' = c('QBaseline_2020', 'comp_da', 'subcomp_da'),
  'metric' = c('Qbaseline', 'drainage_area', 'drainage_area')
)
da_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu:81/d.dh/entity-model-prop-level-export"
)
da_data <- sqldf(
  "select pid, comp_da, subcomp_da,
   CASE
    WHEN comp_da is null then subcomp_da
    ELSE comp_da
    END as da
   from da_data
  ")


df <- data.frame(
  'model_version' = c('vahydro-1.0', 'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0',  'vahydro-1.0'),
  'runid' = c('runid_400', 'runid_400', 'runid_400', 'runid_600', 'runid_600', 'runid_600'),
  'metric' = c('Qout', 'l90_Qout', 'wd_mgd', 'Qout', 'wd_mgd','l90_Qout'),
  'runlabel' = c('Qout_400', 'L90_400', 'wd_mgd_400', 'Qout_600', 'wd_mgd_600', 'L90_vwpp')
)
cc_data <- om_vahydro_metric_grid(
  metric, df, "all", "dh_feature",
  "watershed", "vahydro", "vahydro-1.0",
  "http://deq1.bse.vt.edu:81/d.dh/entity-model-prop-level-export"
)

riv_data <- sqldf(
  "select a.*, b.da
   from cc_data as a
  left outer join da_data as b
  on (a.pid = b.pid)
  where hydrocode in (
    'vahydrosw_wshed_JL2_6441_6520_ivy_creek',
    'vahydrosw_wshed_JL4_6520_6710_ragged_mtn',
    'vahydrosw_wshed_JL1_6560_6440_beaver_creek',
    'vahydrosw_wshed_JL2_6440_6441_moormans_sugar_hollow',
    'vahydrosw_wshed_JL2_6440_6441_buck_mtn_creek',
    'vahydrosw_wshed_JL2_6440_6441',
    'vahydrosw_wshed_JL1_6560_6440',
    'vahydrosw_wshed_JL2_6240_6520',
    'vahydrosw_wshed_JL2_6441_6520',
    'vahydrosw_wshed_JL4_6710_6740'
  )
  order by da
  "
)

# print a tble for the issue queue
knitr::kable(riv_data,'markdown')