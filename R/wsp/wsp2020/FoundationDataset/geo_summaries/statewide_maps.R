library(tictoc) #time elapsed
library(beepr) #play beep sound when done running

###################################################################################################### 
# LOAD FILES
######################################################################################################
#site <- "https://deq1.bse.vt.edu/d.dh/"
site <- "http://deq2.bse.vt.edu/d.dh/"

basepath <- "/var/www/R/"
source(paste(basepath,"config.local.private",sep = '/'))

#DOWNLOAD STATES AND MINOR BASIN LAYERS DIRECT FROM GITHUB
STATES <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/cbp6/master/code/GIS_LAYERS/STATES.tsv', sep = '\t', header = TRUE)
MinorBasins.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MinorBasins.csv', sep = ',', header = TRUE)

#DOWNLOAD RSEG LAYER DIRECT FROM VAHYDRO
localpath <- tempdir()
filename <- paste("vahydro_riversegs_export.csv",sep="")
destfile <- paste(localpath,filename,sep="\\")
download.file(paste(site,"vahydro_riversegs_export",sep=""), destfile = destfile, method = "libcurl")
RSeg.csv <- read.csv(file=paste(localpath , filename,sep="\\"), header=TRUE, sep=",")
MajorRivers.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/GIS_LAYERS/MajorRivers.csv', sep = ',', header = TRUE)
#MajorRivers.csv <- read.table(file = 'https://raw.githubusercontent.com/HARPgroup/hydro-tools/rivnames/GIS_LAYERS/MajorRivers.csv', sep = ',', header = TRUE)


#DOWNLOAD FIPS LAYER DIRECT FROM VAHYDRO
fips_filename <- paste("vahydro_usafips_export.csv",sep="")
fips_destfile <- paste(localpath,fips_filename,sep="\\")
download.file(paste(site,"usafips_centroid_export",sep=""), destfile = fips_destfile, method = "libcurl")
fips.csv <- read.csv(file=paste(localpath , fips_filename,sep="\\"), header=TRUE, sep=",")

#LOAD RAW mp.all FILE
# mp.all <- read.csv(paste(folder,"wsp2020.mp.all.MinorBasins_RSegs.csv",sep=""))

#DOWNLOAD RESERVOIR LAYER FROM LOCAL REPO
WBDF <- read.table(file=paste(hydro_tools,"GIS_LAYERS","WBDF.csv",sep="/"), header=TRUE, sep=",")


#LOAD MAPPING FUNCTIONS
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.R",sep = '/'))
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/minorbasin.mapgen.SINGLE.SCENARIO.R",sep = '/'))
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/mb.extent.R",sep = '/'))

source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/statewide.mapgen.R",sep = '/'))
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/statewide.mapgen.SINGLE.SCENARIO.R",sep = '/'))
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/statewide.mapgen.OVERVIEW.R",sep = '/'))
source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/statewide.mapgen.ELFGEN.R",sep = '/'))

######################################################################################################
### SCENARIO COMPARISONS #############################################################################
######################################################################################################
#----------- RUN SINGLE MAP --------------------------
# statewide.mapgen(metric = "l30_Qout",
#                  runid_a = "runid_11",
#                  runid_b = "runid_13")
# 
# statewide.mapgen(metric = "l30_cc_Qout",
#                  runid_a = "runid_11",
#                  runid_b = "runid_17")


# #----------- RUN MAPS IN BULK --------------------------
#ALL 21 MINOR BASINS (9 figs)
metric <- c("l30_Qout","l90_Qout","7q10")
runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
runid_b <- c("runid_12","runid_13","runid_18")

# 
#NORTHERN BASINS ONLY (FOR CC SCENARIOS) (6 figs)
metric <- c("l30_cc_Qout", "l90_cc_Qout")
runid_a <- "runid_11" # NOTE: LOOP ONLY ACCEPTS A SINGLE runid_a
runid_b <- c("runid_17","runid_19","runid_20")

# 
tic("Total")
it <- 1 #INITIALIZE ITERATION FOR PRINTING IN LOOP
print(paste("PROCESSING VA",sep=""))
  for (met in metric) {
    print(paste("...PROCESSING METRIC: ",met,sep=""))
    for (rb in runid_b) {
      print(paste("......PROCESSING runid_b: ",rb,sep=""))
      statewide.mapgen(met,runid_a,rb)
    } #CLOSE runid FOR LOOP
  } #CLOSE metric FOR LOOP
  it <- it + 1
toc()
beep(3)
# #------------------------------------------------------------------
# 
# ######################################################################################################
# ### SINGLE SCENARIO ##################################################################################
# ######################################################################################################
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/statewide.mapgen.SINGLE.SCENARIO.R",sep = '/'))
# #----------- RUN SINGLE MAP --------------------------
# statewide.mapgen.SINGLE.SCENARIO(metric = "consumptive_use_frac",
#                                  runid_a = "runid_13")

 # statewide.mapgen.SINGLE.SCENARIO(metric = "consumptive_use_frac",
 #                                  runid_a = "runid_18")

# #----------- RUN MAPS IN BULK --------------------------
# #ALL 21 MINOR BASINS - SINGLE SCENARIO (4 figs)
metric <- "consumptive_use_frac"
runid_a <- c("runid_11","runid_12","runid_13","runid_18")
# 
# # #NORTHERN BASINS ONLY (FOR CC SCENARIO) (3 figs)
# metric <- "consumptive_use_frac"
# runid_a <- c("runid_17","runid_19","runid_20")

# 
tic("Total")
it <- 1 #INITIALIZE ITERATION FOR PRINTING IN LOOP
print(paste("PROCESSING VA",sep=""))
  for (met in metric) {
    print(paste("...PROCESSING METRIC: ",met,sep=""))
    for (rb in runid_a) {
      print(paste("......PROCESSING runid_a: ",rb,sep=""))
      statewide.mapgen.SINGLE.SCENARIO(met,rb)
    } #CLOSE runid FOR LOOP
  } #CLOSE metric FOR LOOP
  it <- it + 1
toc()
beep(3)
# #------------------------------------------------------------------


# ######################################################################################################
# ### ELFGEN ##################################################################################
# ######################################################################################################
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/statewide.mapgen.ELFGEN.R",sep = '/'))
#----------- RUN SINGLE MAP --------------------------

runid <- "runid_18"
huc_level <- "huc8"
richness_chg <- "richness_change_abs"
elfgen_dataset <- read.csv(paste(site,"vahydro_riversegs_elfgen_export?propname=",runid,"&propname_2=elfgen_EDAS_",huc_level,"&propname_3=",richness_chg,sep=""))

statewide.mapgen.ELFGEN(metric = "consumptive_use_frac",
                        runid_a = runid,
                        huc_level = huc_level,
                        richness_chg = richness_chg,
                        elfgen_dataset = elfgen_dataset
                        )





#-----------------------------------------------------------------------------------------------------
# QA AND ANALYSIS
#-----------------------------------------------------------------------------------------------------
# PULL IN DATASET
runid <- "runid_11"
huc_level <- "huc8"
richness_chg <- "richness_change_abs"
elfgen_dataset_11 <- read.csv(paste(site,"vahydro_riversegs_elfgen_export?propname=",runid,"&propname_2=elfgen_EDAS_",huc_level,"&propname_3=",richness_chg,sep=""))

#------------------------------------------------------------------------------
# ADD QA COLUMNS
QA_cols <- paste("SELECT *,
                          Rseg_Outlet_MAF AS nhdplus_MAF,
                          Qout AS model_Qout,
                          Qout-Rseg_Outlet_MAF AS DIFF,
                          abs(((Qout-Rseg_Outlet_MAF)/Rseg_Outlet_MAF)*100) AS 'Diff_%'
                  FROM elfgen_dataset_11
                  ORDER BY abs(((Qout-Rseg_Outlet_MAF)/Rseg_Outlet_MAF)*100) DESC
                      ")
elfgen_dataset_11 <- sqldf(QA_cols)
#------------------------------------------------------------------------------
# REMOVE TIDAL SEGMENTS
print(length(elfgen_dataset_11[,1]))
print("REMOVING TIDAL SEGMENTS")
RSeg_tidal <- paste("SELECT *
                  FROM elfgen_dataset_11
                  WHERE hydrocode NOT LIKE 'vahydrosw_wshed_JA%_0000' AND
                        hydrocode NOT LIKE 'vahydrosw_wshed_PL%_0000' AND
                        hydrocode NOT LIKE 'vahydrosw_wshed_RL%_0000' AND
                        hydrocode NOT LIKE 'vahydrosw_wshed_YL%_0000' AND
                        hydrocode NOT LIKE 'vahydrosw_wshed_YM%_0000' AND
                        hydrocode NOT LIKE 'vahydrosw_wshed_YP%_0000' AND
                        hydrocode NOT LIKE 'vahydrosw_wshed_EL%_0000' AND
                        hydrocode NOT LIKE 'vahydrosw_wshed_JB%_0000' AND
                        hydrocode NOT LIKE 'vahydrosw_wshed_MN%_0000' AND
                        hydrocode NOT LIKE 'vahydrosw_wshed_ES%_0000'
                      ")
elfgen_dataset_11 <- sqldf(RSeg_tidal)
print(length(elfgen_dataset_11[,1]))
#write.csv(elfgen_dataset_11,paste0(export_path,"tables_maps\\Xfigures\\","elfgen_dataset","_",runid,"_",huc_level,"_",richness_chg,".csv"), row.names = FALSE)
#------------------------------------------------------------------------------
# REMOVE ANY WITH Rseg Outlet MAF > breakpt 
print(length(elfgen_dataset_11[,1]))
print("REMOVING SEGMENTS TO THE RIGHT OF BREAKPOINT")
rm_Right_Of_bkpt <- paste('SELECT *
                            FROM elfgen_dataset_11
                            WHERE Rseg_Outlet_MAF < breakpt
                            ORDER BY hydroid ASC  
                            ',sep = '')
elfgen_dataset_11 <- sqldf(rm_Right_Of_bkpt)  
print(length(elfgen_dataset_11[,1]))
write.csv(elfgen_dataset_11,paste0(export_path,"tables_maps\\Xfigures\\","elfgen_dataset","_",runid,"_",huc_level,"_",richness_chg,".csv"), row.names = FALSE)
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# JOIN 3 TABLES 
runid <- "runid_13"
elfgen_dataset_13 <- read.csv(paste(site,"vahydro_riversegs_elfgen_export?propname=",runid,"&propname_2=elfgen_EDAS_",huc_level,"&propname_3=",richness_chg,sep=""))

runid <- "runid_18"
elfgen_dataset_18 <- read.csv(paste(site,"vahydro_riversegs_elfgen_export?propname=",runid,"&propname_2=elfgen_EDAS_",huc_level,"&propname_3=",richness_chg,sep=""))

# elfgen_combine <- paste('SELECT a.*,
#                                 a.richness_change AS "2020_pct_abs",
#                                 b.richness_change AS "2040_pct_abs",
#                                 c.richness_change AS "Exempt_pct_abs",
#                                 a.p AS "2020_p",
#                                 b.p AS "2040_p",
#                                 c.p AS "Exempt_p"
#                   FROM elfgen_dataset_11 AS a
#                     LEFT OUTER JOIN elfgen_dataset_13 AS b
#                     ON (a.hydroid = b.hydroid)
#                     LEFT OUTER JOIN elfgen_dataset_18 AS c
#                     ON (a.hydroid = c.hydroid)
#                   ORDER BY a.richness_change ASC  
#                   ',sep = '')
elfgen_combine <- paste('SELECT a."Rseg.Model",
                                a.hydrocode,
                                a.richness_change AS "2020_chg_#",
                                b.richness_change AS "2040_chg_#",
                                c.richness_change AS "Exempt_chg_#",
                                a.consumptive_use_frac*100 AS "2020_consumptive_use_%",
                                b.consumptive_use_frac*100 AS "2040_consumptive_use_%",
                                c.consumptive_use_frac*100 AS "Exempt_consumptive_use_%"
                  FROM elfgen_dataset_11 AS a
                    LEFT OUTER JOIN elfgen_dataset_13 AS b
                    ON (a.hydroid = b.hydroid)
                    LEFT OUTER JOIN elfgen_dataset_18 AS c
                    ON (a.hydroid = c.hydroid)
                  ORDER BY a.richness_change ASC  
                  ',sep = '')
elfgen_combine <- sqldf(elfgen_combine)  
write.csv(elfgen_combine,paste0(export_path,"tables_maps\\Xfigures\\","elfgen_dataset_rseg_summary_",richness_chg,".csv"), row.names = FALSE)
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# JOIN PCT AND # TABLES 
elfgen_num <- read.csv(paste(export_path,"tables_maps/Xfigures/","elfgen_dataset_rseg_summary_richness_change_abs.csv",sep=""))
elfgen_pct <- read.csv(paste(export_path,"tables_maps/Xfigures/","elfgen_dataset_rseg_summary_richness_change_pct.csv",sep=""))


join_em <- paste('SELECT *
                  FROM elfgen_num AS a
                    LEFT OUTER JOIN elfgen_pct AS b
                    ON (a.hydrocode = b.hydrocode)
                  ',sep = '')
join_em <- sqldf(join_em)  
write.csv(join_em,paste0(export_path,"tables_maps\\Xfigures\\","join_em.csv"), row.names = FALSE)

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# KABLE FORMATTER
formatted_dataset <- paste('SELECT "Rseg.Model", 
                                    richness_change
                            FROM elfgen_dataset
                            ORDER BY richness_change ASC  
                            LIMIT 10',sep = '')
formatted_dataset <- sqldf(formatted_dataset)

library(kableExtra)
table_tex <- kable(formatted_dataset,align = "l",  booktabs = T,format = "latex",longtable =T,
                   caption = paste("TEST CAPTION", sep = ""),
                   label = paste("TEST LABEL", sep = "")) %>%
  kable_styling(latex_options = "striped") %>%
  column_spec(2, width = "12em") %>%
cat(., file = paste0(export_path,"tables_maps\\Xfigures\\","TEST","_",".tex"),sep="")
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------


library("readxl")
my_data <- read_excel(paste(export_path,"tables_maps/Xfigures/" , "Master_elfgen.xlsx",sep=""), sheet = "TU2")

# formatted_dataset <- paste('SELECT "Rseg.Model", 
#                                     my_data
#                             FROM elfgen_dataset
#                             ORDER BY richness_change ASC  
#                             LIMIT 10',sep = '')
# formatted_dataset <- sqldf(formatted_dataset)

library(kableExtra)
table_tex <- kable(my_data,align = "l",  booktabs = T,format = "latex",longtable =T,
                   caption = paste("Upper Tennessee elfgen Results by River Segment", sep = ""),
                   label = paste("TU_elfgen", sep = "")) %>%
  kable_styling(latex_options = "striped") %>%
  cat(., file = paste0(export_path,"tables_maps\\Xfigures\\","TU_elfgen_table.tex"),sep="")





# ######################################################################################################
# ### STATEWIDE Minor Basin OVERVIEW ###################################################################
# ######################################################################################################
# source(paste(vahydro_location,"R/wsp/wsp2020/FoundationDataset/geo_summaries/statewide.mapgen.OVERVIEW.R",sep = '/'))
#----------- RUN SINGLE MAP --------------------------
 statewide.mapgen.OVERVIEW(plot_title = "Minor Basin Units")





