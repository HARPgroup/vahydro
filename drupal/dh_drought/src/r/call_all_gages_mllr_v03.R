## Calculating MLLR values and saving as file -- dh compatible ##
# Should update once a year on March 1st (tstime is March 1st for last year of data)

# Load necessary libraries
library('zoo')
library('IHA')
library('stringr')
library('lubridate')
library('hydrotools')
#source("/var/www/R/config.local.private");
#source(paste(fxn_vahydro,"VAHydro-2.0/rest_functions.R", sep = "/"));

#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
save_url <- paste(str_remove(site, 'd.dh'), "data/proj3/out", sep='');
ds <- RomDataSource$new(site, 'restws_admin')
ds$get_token(rest_pw)
set_mllr_status <- FALSE

argst <- commandArgs(trailingOnly=T)
message(paste("length of argst = ", length(argst)))
gage = ""
if (length(argst) > 0) {
  calyear <- as.integer(argst[1])
  if (length(argst) > 1) {
    gage <- as.character(argst[2])
    gage <- sprintf("%08s", gage)
  }
} else {
  calyear <- as.integer(format(Sys.time(), "%Y")); # what summer year is this assessment for?
}

file_directory <- export_path;
#file_directory <- "C:\\WorkSpace\\tmp\\";
file_base <- "mllr_drought_probs"
if (gage != "") {
  file_base <- paste(file_base, gage, sep="_")
}
file_name <- paste(
  paste(
    file_base,
    calyear,
    sep="_"
  ),
  ".tsv",
  sep=""
);
file_path <- paste(file_directory, file_name, sep="");


#rm(list = ls())   # clear variables
# Initialize variables
month <- c("july", "august", "september")
percentile <- c("05", "10", "25", "50")
e <- 1
c <- 1
variables <- c()
varids <- c()

m <- 0
errors <- c()
urls <- c()
gage_probs = data.frame(
  "hydrocode" = character(),
  "tsvalue" = numeric(),
  "varkey" = character(),
  "calc_date" = integer(),
  "tstime" = integer(),
  "hcode" = character(),
  stringsAsFactors = FALSE
);

#colnames(wshed_summary_tbl) <- c("Segment Name (D. Area)", "7Q10/ALF/Min Month", "WD (mean/max)" );

# Create the variable names
for (j in 1:length(month)) {
	for (k in 1:length(percentile)) {
		variables[e] <- paste("mllr", month[j], percentile[k], sep="_")
		vardef <- ds$get_vardef(variables[e])
		varids[e] <- vardef$varid
		e <- e + 1
	}
}

# retrieve all with un-set sept 10 probabilities for the current year
uri <- paste0(site,"/usgs-mllr-sept10-gages-all")
if (gage != "") {
  uri <- paste(uri, gage, sep="/")
}
#gagelist = om_auth_read(uri, token, "text/csv")
gagelist <- ds$auth_read(uri, "text/csv", ",")
gagelist$staid <- sprintf("%08s", gagelist$staid) # insure correct usgs gage ID
# un-comment to test a small set
#gagelist <- data.frame(gagelist[which(gagelist$staid == '01626850'),])

## MLLR calculation ##

for (i in 1:nrow(gagelist)) {
  gageinfo <- gagelist[i,]
  gage <- gageinfo$staid
	# reset variables
	z <- 1
	P_est <- c()
	winterflow <- c()
  this_gage_probs = gage_probs[0,]
	# Extract flow data for the current year from Nov - Feb
	StartDate <- as.Date(paste((calyear-1), "-11-01", sep=""))
	EndDate <- as.Date(paste(calyear, "-02-28", sep=""))
	hydrocode <- paste("usgs", gage, sep="_")

	# Extracting winter flow data
	url_base <- "https://waterservices.usgs.gov/nwis/dv/?variable=00060&format=rdb&startDT="
	url <- paste(url_base, StartDate, "&endDT=", EndDate, "&site=", gage, sep="")
  print(paste("Trying ", url, sep=''));
	winterflow <- try(read.table(url, skip = 2, comment.char = "#"))

	# No 2014 estimates if there is no 2014 winter flow data
	if (class(winterflow)=="try-error") {
		next
	}

	# No 2014 estimates for gages without a column for flow data on USGS
	if (ncol(winterflow) < 4) {
		next
	}

	# Determine the average November through February mean daily flow
	n_f_flow <- mean(na.omit(as.numeric(as.vector(winterflow[,4]))))
	### Getting Beta Values ONCE ###
	b<-0
	beta_0 <- c()
	beta_1 <- c()
	beta_table <- c()
	for (thismo in 1:length(month)) {
		for (thisp in 1:length(percentile)) {
			# Write beta variable names
			b <- b+1
			beta_0[b] <- paste("mllr_beta0", month[thismo], percentile[thisp], sep="_")
			beta_1[b] <- paste("mllr_beta1", month[thismo], percentile[thisp], sep="_")
		}
	}
	# Combine beta0s and beta1s
	varkeys <- c(beta_0, beta_1)
	# Write get_modelData URL to get ALL 24 beta values
	beta_url <- paste(site,"/?q=export-properties-om/usgs_", gage, "/drought_model", sep="");
  print(paste("getting betas: ", beta_url, sep=""));
	# Read beta values and names from URL
	#rawtable <- try(read.table(beta_url, header=TRUE, sep=","))
	rawtable <- try(om_auth_read(beta_url, token, "text/csv"))
	if (class(rawtable)=="try-error") {
		next
	} else {
	  beta_table <- cbind(as.character(rawtable$dataname), rawtable$dataval)
	}

	### End pulling in beta values ###
	for (j in 1:length(month)) {

		for (k in 1:length(percentile)) {

			## Getting the correct beta values for the month and percentile ##
			varkey_beta_0 <- paste("mllr_beta0", month[j], percentile[k], sep="_")
			varkey_beta_1 <- paste("mllr_beta1", month[j], percentile[k], sep="_")
      print(paste("Searching for varkeys ", varkey_beta_0, varkey_beta_1, sep=" "));

			b0 <- as.numeric(beta_table[beta_table[,1]==varkey_beta_0,2])
			b1 <- as.numeric(beta_table[beta_table[,1]==varkey_beta_1,2])
      print(paste("Found ", b0, b1, sep=""));

      message(paste("Recharge flow (n_f_flow))=", n_f_flow))

      if (length(b0) & length(b1)) {
        ## Calculating P_est in the given month for the given percentile ##

        P_est <- 1/(1+exp(-(b0 + b1*n_f_flow)));
        message(paste("Recharge P_est =", P_est))

        # Creating columns for file output
        c <- c + 1 # total count of how many probabilities are being calculated
        newline = data.frame(
          "hydrocode" = hydrocode,
          "tsvalue" = P_est,
          "varkey" = variables[z],
          "tstime" =  as.numeric(as.POSIXct(paste(calyear, "-03-01", sep=""),tz="America/New_York")),
          "hcode" = paste("usgs", gage, sep="_")
        );
        gage_probs <- rbind(gage_probs, newline);
        this_gage_probs <- rbind(gage_probs, newline);
        config_list = list(
          "featureid" = gageinfo$hydroid,
          "entity_type" = 'dh_feature',
          "varid" = varids[z],
          "tstime" =  as.numeric(as.POSIXct(paste(calyear, "-03-01", sep=""),tz="America/New_York")),
          "tsvalue" = P_est,
          "tscode" = P_est
        )
        message(paste("Creating TS entity in R for", varids[z]))
        ts <- RomTS$new(
          ds,
          config_list,
          TRUE
        )
        message(paste("Storing TS REST value for", varids[z]))
        ts$save(TRUE)
      } else {
        print(paste(variables[z], " = NULL for gage", gage, " varkeys ", varkey_beta_0, varkey_beta_1, sep=" "));
      }
      z <- z + 1 # count for which mllr value this gage is on
    } # Ends percentile loop
  } # Ends month loop
	# todo: put calculation for max percentile and set property too
	if (set_mllr_status) {

	}

  print(paste("Finished gage", gage, sep=" "))

} # Ends gage loop

# See results
print(gage_probs)

write(c(), file = file_path)  #create file where image will be saved
write.table(gage_probs, file = file_path,append=FALSE,quote=FALSE,row.names=FALSE,col.names=c('hydrocode','tsvalue','varkey','tstime','hcode'),sep="\t")

