#!/user/bin/env drush
<?php
$now = date('U');
$darg_hash = sha1("$gageid,$year");
$rcode = "darg_hash <- '$darg_hash';\n";
$rcode .= "[R];\n";
$rcode .= file_get_contents ('/var/www/html/files/dh/mllr/call_all_gages_mllr.R');
$rcode .= "[/R]\n";

//dpm($rcode, ' r code');;
$rout = _filter_r_process($rcode, null, null);
//dpm($rout, ' r output');
echo "Finished mllr_calc_all";
?>
