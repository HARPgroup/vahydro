#!/user/bin/env drush
<?php
module_load_include('module', 'dh_wsp');
module_load_include('module', 'dh');

// load dh_wsp module to get access to function dh_tablefield_parse_array($data)
// returns:
//    array($formatted_tablefield, $row_count, $max_col_count);

// get parameters if any
$pid = trim(drush_shift());
$test = ($pid == 'all');
echo "First param " . $pid . " test == 'all' = $test \n";

if (($pid == 'all')) {
  $q = "  select pid from {dh_properties} ";
  $q .= " where varid in (select hydroid from dh_variabledefinition where varkey = 'wsp_rate_table') ";
  $q .= "   and entity_type = 'dh_adminreg_feature' ";
  //$q .= " limit 20 ";
  $pids = db_query($q)->fetchCol();
} else {
  $pids = array($pid); // 
}

//echo "Pids: " . print_r($pids,1) . "\n";

foreach ($pids as $pid) {
  //dpm($rec,'rec');
  $proj = entity_load_single('dh_properties', $pid);
  if (!$proj) {
    error_log("Failed loading $pid .");
  }else {
    echo "Found $proj->propname with pid = $pid " . "\n";
  }
  // get all the rows that could be
  $plugin = dh_variables_getPlugins($proj);
  $default = $plugin->tableDefault($proj);
  list($master, $row_count, $max_col_count) = dh_tablefield_parse_array($default);
  $master = dh_tablefield_to_associative($master);
  $mm_matrix = matrix_field_to_assoc('field_matrix', $proj->field_matrix['und']);
  foreach ($mm_matrix as $rowkey => $row) {
    foreach ($row as $key => $val) {
      if (isset($master[$rowkey][$key])) {
        $master[$rowkey][$key] = $val;
      }
    }
  }
  # Now add back the header
  $cats = array_keys($master);
  $row1 = current($master);
  $years = array_keys($row1);
  array_unshift($years,'Category');
  foreach($cats as $key) {
    array_unshift($master[$key], $key);
  }
  array_unshift($master, $years);
  //error_log('reformatted master:' . print_r($master,1 ));
  error_log('Header:' . print_r($years,1 ));
  //error_log('final values:' . print_r((array)$mm_matrix,1 ));
  //list($lutable, $row_count, $max_col_count) = tablefield_parse_assoc($mm_matrix);
  dh_tablefield_array_to_field($proj, $master, 'field_projection_table');
  
  //$proj->field_projection_table['und'][0] = $master;
  $proj->save();
  //$this->setLUTableField($entity, $lutable);
  $i++;
}
echo "<br>Finished. Sorted through $i records.";
?>