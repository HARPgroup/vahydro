<?php
// call with: module_load_include('inc', 'dh_drought', 'src/php/drupal-rfilter-call-gage-mllr');
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
// load the annual mllr timeseries event if it exists
// load the image property if it exists:
// - check the modified date, if it is after March 1st, and no force is requested, 
//   just show the image.  
// - if it is outdated, call the Rscript below 
$m_ts_info = array('featureid' => $fid, 'entity_type' => 'dh_feature', 'tstime' => $year . "-03-01", 'varid' => 'mllr_annual_risk10');
$mllr_annual_risk10_ts =  array_shift(dh_get_timeseries($m_ts_info, 'tstime_singular', TRUE));
dpm($mllr_annual_risk10_ts,'ts');
if (is_object($mllr_annual_risk10_ts)) {
  $m_p_info = array('featureid' => $mllr_annual_risk10_ts->tid,  'entity_type' => 'dh_timeseries', 'propname' => 'mllr_plot');
  //dpm($m_p_info,'m_p_info');
  $mllr_plot = dh_properties_enforce_singularity($m_p_info, 'name', FALSE);
  //dpm($mllr_plot,'mllr_plot');
  echo "Winter Flow analysis for $gageid: <br><img src='$mllr_plot->propcode'>";
}
  
$now = date('U');
$darg_hash = sha1("$gageid,$year");
$rcode = "darg_hash <- '$darg_hash';\n";
$rcode .= "[R]gage <- c($gageid);\n";
$rcode .= "target_year <- '$year';\n";
$rcode .= "fid <- $fid; \n";
//$rcode .= file_get_contents ('/var/www/html/files/dh/mllr/analyze_winter.R');
$rcode .= file_get_contents ('/var/www/html/d.dh/modules/dh_drought/src/r/analyze_winter.R');
$rcode .= "[/R]\n";

//dpm($rcode, ' r code');;
$rout = _filter_r_process($rcode, null, null);
//dpm($rout, ' r output');;

?>