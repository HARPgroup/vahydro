<?php
module_load_include('module', 'dh');
module_load_include('module', 'om');

$a = array();
while ($arg = drush_shift()) {
  $a[] = $arg;
}
$fid = $a[0];
if (isset($a[1])) {
  $year = $a[1];
} else {
  $year = date('Y');
}
if ($fid == 'all') {
  // query all gages
  $q = db_query("select hydroid from dh_feature where bundle = 'usgsgage'");
  $fids = $q->fetchCol();
} else {
  // just grab the gage in question
  $fids = array($fid);
}

//error_log("FIDS " . print_r($fids,1));
foreach ($fids as $fid) {
  error_log("Running MLLR for $year hydroid $fid ");
  $gage = entity_load_single('dh_feature', $fid);
  $gfield = field_get_items('dh_feature', $gage, 'dh_usgs_site_no');
  $gageid = array_shift($gfield);
  $gageid = $gageid['safe_value'];
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
}

?>