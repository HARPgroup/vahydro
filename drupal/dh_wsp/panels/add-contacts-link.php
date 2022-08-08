<?php
$a = arg();
$adminid = $a[1];
$l = l("Add a contact", "ows-organization-wsp_plan_region-contacts/$adminid/add", array('query'=>array('destination' => "$a[0]/$a[1]")));
echo $l;

?>
