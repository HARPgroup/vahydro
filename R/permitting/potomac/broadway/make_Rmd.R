# make Rmd



# generate
rmarkdown::render(
  'C:/usr/local/home/git/vahydro/R/examples/VWP_CIA_Summary.Rmd', 
  output_file = '/usr/local/home/git/vahydro/R/permitting/broadway/te_broadway_v03.docx', 
  params = list( 
    doc_title = 'VWP 17-0513: Town of Broadway, North Fork Shenandoah River',
    rseg.hydroid = 67830, 
    fac.hydroid = 74345, 
    runid.list = c("runid_11", "runid_400","runid_600"), 
    intake_stats_runid = 400,
    upstream_rseg_ids=c(469965) 
  )
)