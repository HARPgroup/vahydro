#!/user/bin/env drush
<?php
module_load_include('module', 'dh_wsp');

// load dh_wsp module to get access to function dh_tablefield_parse_array($data)
// returns:
//    array($formatted_tablefield, $row_count, $max_col_count);
// load csv of elements
// get OM elementid
// get WUA sub-comp name (propcode of elementid prop)
// call getData.php for OM habitat table
// format tablefield -- check land use plugin for method?
// add tablefield property or update
//  varkey = ifim_habitat_table
//  field_name = field_dh_matrix
//  class = dHVarWithTableFieldBase
// call $plugin->setCSVTableField(&$entity, $csvtable) {

$om_url_base = "http://deq1.bse.vt.edu/om/remote/get_modelData.php";
// csv of elements: 
$fname = drush_shift();
$test = drush_shift();
$file = fopen($fname, "r");
error_log("File: $fname");
$i = 0;
// pop the header line off the top
$header = fgetcsv($file, 0, "\t");
if ($header) {
  while ($rec = fgetcsv($file, 0, "\t")) {
    //dpm($rec,'rec');
    $tbl = array();
    $values = array();
    // ******************************
    // NOT FINISHED BELOW HERE
    $prop = array_combine($header, $rec);
    $varkeys = dh_varkey2varid($prop['varkey']);
    $prop['varid'] = array_shift($varkeys);
    $cols = array('varid', 'featureid', 'entity_type', 'bundle', 'propname', 'propvalue', 'propcode', 'startdate', 'enddate');
    foreach ($cols as $thiscol) {
      if (isset($prop[$thiscol])) {
        $values[$thiscol] = $prop[$thiscol];
      }
    }
    if (!$featureid) {
      // check to see if we can do a lookup
      if ($prop['entity_type'] == 'dh_feature' and isset($prop['hydrocode'])) {
		$ebundle = isset($prop['entity_bundle']) ? $prop['entity_bundle'] : FALSE;		  
        $eftype = isset($prop['entity_ftype']) ? $prop['entity_ftype'] : FALSE;
        $fid = dh_search_feature( $prop['hydrocode'], $ebundle, $eftype);
        if ($fid) {
          $values['featureid'] = $fid;
        } else {
          error_log("Could not locate hydroid for dh_feature -- cannot import.");
          continue;
        }
      } else {
        error_log("Featureid is NULL -- cannot import.");
        error_log(print_r($prop,1));
        continue;
      }
    }
    // un-comment to actually do it.
    $singularity = isset($props['singularity']) ? $props['singularity'] : 'singular';
    $pid = dh_update_properties($values, $singularity);
    error_log('values:' . print_r($values,1 ));
    if (!$pid) {
      error_log("Failed.");
    }
  }
  echo "<br>Finished. Sorted through $i records.";
}
?>