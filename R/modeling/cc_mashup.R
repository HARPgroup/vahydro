# cc manipulation
# 6.35%

#install.packages("remotes")
#remotes::install_github("earthlab/cft")

# get monthly precip coefficients
# - load landseg feature rest
# - load gcm_models
# - load property ccP10T10_delta/ccP50T50_delta/ccP90T90_delta (pointer to the 10th,50th,90th percentile)
# - 
# get monthly temperature coefficients
# load base timeseries
# apply coefficients
#


# load required packages
library(lubridate)
library(sqldf)
library(data.table)


# load synthetic_met_functions
source("https://raw.githubusercontent.com/HARPgroup/HARParchive/master/HARP-2021-2022/synthetic_met_functions.R")


# declare function inputs
in_dir <- "/backup/meteorology/out/lseg_csv/1984010100-2022123123/" # linux directory

startdate1 <- "2018-01-01"
enddate1 <- "2022-04-13"
year2 <- "1986" # todo: can find the landseg l90 year from model runs records
startdate2 <- "1986-04-14"
enddate2 <- "1986-12-31"

in_dir <- "http://deq1.bse.vt.edu:81/met/backup/meteorology/out/lseg_csv/1984010100-20220123123/" # linux directory

site <- "http://deq1.bse.vt.edu:81/met/out/lseg_csv/1984010100-2022123123/" # temporary cloud url

# 51037 drains to cub creek in Phenix VA
landseg <- "A51037"

# run get_lseg_csv to get download met data for range including mashup dates
lseg_csv <- get_lseg_csv(landseg = landseg, startdate = "1984-01-01", enddate = enddate1, site = site, dir = in_dir)

# run generate_synthetic_timeseries to append two time periods together
mash_up <- generate_synthetic_timeseries(lseg_csv = lseg_csv, startdate1 = startdate1, enddate1 = enddate1, startdate2 = startdate2, enddate2 = enddate2)

#
#as.data.frame
lseg_df <- as.data.frame(lseg_csv$PET)
mash_df <- as.data.frame(mash_up$PET)
mash_pdf <- as.data.frame(mash_up$PET)
mash_yrmo_prc <- sqldf(
  "
    select year, month, sum(PRC) from mash_df
    group by year, month
  "
)
lseg_yrmo_prc <- sqldf(
  "
    select year, month, sum(PRC) from lseg_df
    group by year, month
  "
)

met_part = "PET"
met_color <- list(
  "PET" = 'orange',
  "PRC" = 'blue',
  "TMP" = 'brown'
)
met_name <- list(
  "PET" = 'Evapotranspiration',
  "PRC" = 'Rainfall',
  "TMP" = 'Temperature'
)
for (met_part in c("PRC", "TMP", "PET")) {
  cdat <- mash_up[[met_part]]
  # generate plot
#  plot(as.Date(paste(cdat$year,cdat$month, cdat$day,sep="-")), mash_up$TMP$TMP, type = "l")
  plot(
    as.Date(paste(cdat$year,cdat$month, cdat$day,sep="-")), 
    cdat[[met_part]], 
    type = "l", 
    main = paste(met_name[[met_part]],"Mashup 2019-2022 +",year2),
    xlab = "Year",
    col = met_color[[met_part]],
    ylab = paste(met_part, "Hourly Total (inches)")
  )
}


# generate plot
plot(as.Date(paste(mash_up$TMP$year,mash_up$TMP$month, mash_up$TMP$day,sep="-")), mash_up$TMP$TMP, type = "l")
plot(
  as.Date(paste(mash_up$PRC$year,mash_up$PRC$month, mash_up$PRC$day,sep="-")), 
  mash_up$PRC$PRC, 
  type = "l", 
  main = "Mashup 2019-2022 + 2002",
  xlab = "Year",
  ylab = "Daily Total Precipitation (inches)"
)

outdir="/backup/meteorology/out/lseg_csv/mash/"
write.table(mash_up$PRC,paste0(outdir,landseg,".PRC"),col.names=FALSE,row.names=FALSE,sep=",")
write.table(mash_up$PET,paste0(outdir,landseg,".PET"),col.names=FALSE,row.names=FALSE,sep=",")
write.table(mash_up$TMP,paste0(outdir,landseg,".TMP"),col.names=FALSE,row.names=FALSE,sep=",")
write.table(mash_up$RAD,paste0(outdir,landseg,".RAD"),col.names=FALSE,row.names=FALSE,sep=",")
write.table(mash_up$DPT,paste0(outdir,landseg,".DPT"),col.names=FALSE,row.names=FALSE,sep=",")
write.table(mash_up$WND,paste0(outdir,landseg,".WND"),col.names=FALSE,row.names=FALSE,sep=",")
