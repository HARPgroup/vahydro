library('zoo')
elid = 347370
run.id = 125
cbp6_link <- paste0(github_link, "/cbp6/code");
source(paste0(cbp6_link,"/cbp6_functions.R"))
source(paste(cbp6_link, "/fn_vahydro-1.0.R", sep = ''))

bechtel <- fn_get_runfile(elid, run.id, site = omsite,  cached = TRUE);

breg <- lm(as.numeric(bechtel$wd12_mgd) ~ as.numeric(bechtel$cbp_et_in))

plot(bechtel$cbp_et_in, bechtel$wd12_mgd, ylim=c(0,110))
abline(breg)
loess.smooth(
  x, y, span = 2/3, degree = 1,
  family = c("symmetric", "gaussian"),
  evaluation = 50
)
lines(bechtel$cbp_et_in, bechtel$whtf_natevap_mgd)