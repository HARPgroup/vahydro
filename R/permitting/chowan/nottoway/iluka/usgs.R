basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
library('knitr')
library('dataRetrieval')

gage_number = '01633000'
startdate = '1900-01-01'
enddate = '2022-12-31'
# Get and format gage data
gage_data <- gage_import_data_cfs(gage_number, startdate, enddate)
gage_data <- as.zoo(gage_data, as.POSIXct(gage_data$date,tz="EST"))
mode(gage_data) <- 'numeric'
gage_data$month <- month(gage_data$date)
gage_data
om_flow_table(gage_data, 'flow')

available_mgd <- gage_data
available_mgd$available_mgd <- (available_mgd$flow * 0.1) / 1.547
avail_table = om_flow_table(available_mgd, 'available_mgd')
kable(avail_table, 'markdown')

# new model
rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/gage_vs_model.Rmd',
  output_file = '/Workspace/modeling/projects/chowan/nottoway_meherrin/iluka/MN3_7770_7930_02044500.docx',
  params = list(
    doc_title = "USGS Gage vs VAHydro Model",
    elid = 245459,
    runid = 400,
    gageid = '02044500',
    area_factor = 1.0
  )
)

# old model
rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/gage_vs_model.Rmd',
  output_file = '/Workspace/modeling/projects/chowan/nottoway_meherrin/iluka/cbp5-MN3_7770_7930_02044500.docx',
  params = list(
    doc_title = "USGS Gage vs VAHydro Model",
    elid = 245459,
    runid = 2,
    gageid = '02044500',
    area_factor = 1.0
  )
)
