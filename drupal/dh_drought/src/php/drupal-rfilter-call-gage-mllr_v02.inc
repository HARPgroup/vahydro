<?php
// call with: module_load_include('inc', 'dh_drought', 'src/php/drupal-rfilter-call-gage-mllr_v02');
$a = arg();
$fid = $a[1];
if (isset($a[2])) {
  $year = $a[2];
} else {
  $year = date('Y');
}
$gage = entity_load_single('dh_feature', $fid);
$gfield = field_get_items('dh_feature', $gage, 'dh_usgs_site_no');
$gageid = array_shift($gfield);
$gageid = $gageid['safe_value'];
$mllr_date = $year . "-03-01";
$call_mllr = FALSE;
// load the annual mllr timeseries event if it exists
// load the image property if it exists:
// - check the modified date, if it is after March 1st, and no force is requested, 
//   just show the image.  
// - if it is outdated, call the Rscript below 
$m_ts_info = array('featureid' => $fid, 'entity_type' => 'dh_feature', 'tstime' => $mllr_date, 'varid' => 'mllr_annual_risk10');
$mllr_annual_risk10_ts =  array_shift(dh_get_timeseries($m_ts_info, 'tstime_singular', TRUE));
dpm($m_ts_info,'m_ts_info');
dpm($mllr_annual_risk10_ts,'ts');

if (!is_object($mllr_annual_risk10_ts)) {
  // definitely need to call it.
  $call_mllr = TRUE;
} else {
  // check time on mllr timeseries and see if we need to regenerate 
  if ($mllr_annual_risk10_ts->modified < dh_handle_timestamp($mllr_date)) {
    $call_mllr = TRUE;
  }
  //dpm($m_p_info,'m_p_info');
  // check if there is a plot,if not, try calling again
  $m_p_info = array('featureid' => $mllr_annual_risk10_ts->tid,  'entity_type' => 'dh_timeseries', 'propname' => 'mllr_plot');
  $mllr_plot = dh_properties_enforce_singularity($m_p_info, 'name', FALSE);
  if (!is_object($mllr_plot)) {
    $call_mllr = TRUE;
  }
}

if ($call_mllr) {
  dsm("Trying to generate MLLR chart for USGS gage $gageid for winter $year");
  $now = date('U');
  $darg_hash = sha1("$gageid,$year");
  $rcode = "darg_hash <- '$darg_hash';\n";
  $rcode .= "[R]gage <- c(\"$gageid\");\n";
  $rcode .= "target_year <- '$year';\n";
  $rcode .= "overwrite_file <- TRUE;\n";
  $rcode .= "fid <- $fid; \n";
  //$rcode .= file_get_contents ('/var/www/html/files/dh/mllr/analyze_winter.R');
  $rcode .= file_get_contents ('/var/www/html/d.dh/modules/dh_drought/src/r/analyze_winter.R');
  $rcode .= "[/R]\n";

  //dpm($rcode, ' r code');;
  $rout = _filter_r_process($rcode, null, null);
  //dpm($rout, ' r output');;
  
  // now load the TS again 
  $mllr_annual_risk10_ts =  array_shift(dh_get_timeseries($m_ts_info, 'tstime_singular', TRUE));
  $m_p_info = array('featureid' => $mllr_annual_risk10_ts->tid,  'entity_type' => 'dh_timeseries', 'propname' => 'mllr_plot');
}
// now try to show the plot
$mllr_plot = dh_properties_enforce_singularity($m_p_info, 'name', FALSE);
//dpm($mllr_plot,'mllr_plot');
if (is_object($mllr_plot)) {
  echo "Winter Flow analysis for $gageid: <br><img src='$mllr_plot->propcode'>";
} else {
  echo "Could not locate plot for timeseries $mllr_annual_risk10_ts->tid ";
}

?>