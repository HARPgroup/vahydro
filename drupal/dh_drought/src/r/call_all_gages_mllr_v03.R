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
site <- "http://deq2.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
save_url <- paste(str_remove(site, 'd.dh'), "data/proj3/out", sep='');
ds <- RomDataSource$new(site)
ds$get_token()
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.R',sep='/'))
calyear <- 2021; # what summer year is this assessment for?
token <- om_vahydro_token()

file_directory <- export_path;
#file_directory <- "C:\\WorkSpace\\tmp\\";
file_name <- paste("mllr_drought_probs_", calyear, ".tsv", sep="");
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
		varids[e] <- ds$get_vardef(variables[e])
		e <- e + 1
	}
}

# retrieve all with un-set sept 10 probabilities for the current year
uri <- paste0(site,"/usgs-mllr-sept10-gages-all")
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
	for (J in 1:length(month)) {
		for (K in 1:length(percentile)) {
			# Write beta variable names
			b <- b+1
			beta_0[b] <- paste("mllr_beta0", month[J], percentile[K], sep="_")
			beta_1[b] <- paste("mllr_beta1", month[J], percentile[K], sep="_")
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
      
      if (length(b0) & length(b1)) {
        ## Calculating P_est in the given month for the given percentile ##

        P_est <- 1/(1+exp(-(b0 + b1*n_f_flow)));
        
        # Creating columns for file output
        c <- c + 1 # total count of how many probabilities are being calculated
        newline = data.frame( 
          "hydrocode" = hydrocode, 
          "tsvalue" = P_est, 
          "varkey" = variables[z], 
          "tstime" =  as.numeric(as.POSIXct(paste(paste(calyear, "-03-01", sep=""),"EST"))), 
          "hcode" = paste("usgs", gage, sep="_")
        );
        gage_probs <- rbind(gage_probs, newline);
        ts <- RomTS$new(
          ds,
          list( 
          "featureid" = gageinfo$hydroid, 
          "entity_type" = 'dh_feature', 
          "varid" = varids[z], 
          "tstime" =  as.numeric(as.POSIXct(paste(paste(calyear, "-03-01", sep=""),"EST"))), 
          "tsvalue" = P_est
          )
        )
        ts$save()
      } else {
        print(paste(variables[z], " = NULL for gage", gage, " varkeys ", varkey_beta_0, varkey_beta_1, sep=" "));
      }
      z <- z + 1 # count for which mllr value this gage is on
    } # Ends percentile loop		
  } # Ends month loop
	# todo: put calculation for max percentile and set property too
	
  print(paste("Finished gage", gage, sep=" "))

} # Ends gage loop

# See results	
print(gage_probs)

write(c(), file = file_path)  #create file where image will be saved
write.table(gage_probs, file = file_path,append=FALSE,quote=FALSE,row.names=FALSE,col.names=c('hydrocode','tsvalue','varkey','tstime','hcode'),sep="\t")

