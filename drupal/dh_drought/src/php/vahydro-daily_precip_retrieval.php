<?php

include('./config.php');

$projectid = 1;
$ownerid = 1;
$debug = 1;
$indicator_sites = 1; # use only indicator sites?? (indicator_site are marked as 1 in map_group_sites)
$overwrite = 0; # replace if already there?
$scratchdir = './data';

$dateranges = array();

# choose water year boundaries based on the beginning of the current water year, 
# through the current date (convention is to handle the end date as the begining of the month)
$today = date('Y-m-d');
$today_obj = new DateTime($today);
$today_obj->modify("-1 days");
$today = $today_obj->format('Y-m-d');
$single = FALSE;
$overwrite = FALSE;
print("Called with" . print_r($argv,1) . "\n");
if (count($argv) > 1) {
   if (isset($argv[1])) {
      $today = $argv[1];
      if ($today == 'today') {
        $today_obj = new DateTime();
        $today = $today_obj->format('Y-m-d');
      }
   }
   if (isset($argv[2])) {
      $single = filter_var($argv[2], FILTER_VALIDATE_BOOLEAN);
   }
   if (isset($argv[3])) {
      $overwrite = filter_var($argv[3], FILTER_VALIDATE_BOOLEAN);
   }
} else {
  echo "Usage: vahydro-daily_precip_retrieval.php date (yyyy-mm-dd or today) [single = FALSE] [overwrite = FALSE]\n";
  echo "Example: Retrieve data for all days since last entry up till today, no overwrite.  \n";
  echo "  php vahydro-daily_precip_retrieval.php today \n";
  echo "Example: Refresh data from Jan 1, 2015  \n";
  echo "  php vahydro-daily_precip_retrieval.php 2015-01-01 TRUE TRUE \n";
  die;
}

# set the flag to NOT calculate a partial monthly normal value since we no longer use these, opting to perform the partial value 
# on the fly in the summary by shape routine
$dopartial = 0;

print("Retrieving Precip for $today single = $single overwrite = $overwrite .\n");

# get precip till today
# monthly totals if they exist
# temporarily disabled because there are errors with the NOAA server.
#$monthurl = 'http://water.weather.gov/p_download_new';
#getMonthlyPrecipToDate($listobject, $projectid, $monthurl, $today, $scratchdir, $debug);
# then daily values
// disabled 4/5/2011 - server failure
//$basedataurl = "http://www.srh.noaa.gov/rfcshare/p_download_new";
// re-enabled on 4/5/2011 due to outage in the above URL/server
//$basedataurl = "http://water.weather.gov/precip/p_download_new";
// changed 6/28/2017
$basedataurl = "http://water.weather.gov/precip/downloads";
getPrecipToDateVAHydro($vahydro, $projectid, $basedataurl, $today, $scratchdir, $debug, $single, $overwrite);

cleanUp();
session_destroy();
?>
