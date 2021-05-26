<?php
$lu = NULL;
module_load_include('module', 'dh');
module_load_include('module', 'dh_adminreg');
module_load_include('module', 'dh_wsp');
module_load_include('inc', 'dh_wsp', 'dh_wsp.custom_forms');
$ann_varkey = 'wd_gpy';
$a = arg();
$params = drupal_get_query_parameters();
if (isset($a[1])) {
  $wellid = $a[1];
  //dpm($a,'args');
  if (isset($a[2])) {
    $year = $a[2];
  } else {
    $year = date('Y');
  }
  if (isset($a[3])) {
    $quarter = $a[3];
  } else {
    $quarter = date('n');
    $quarter = ceil($quarter / 4);
  }
  $permit_id = isset($params['permit_id']) ? $params['permit_id'] : NULL;
    
  $tstime = dh_handletimestamp("$year-01-01");
  $values = array(
    'varkey' => dh_varkey2varid($ann_varkey, TRUE),
    //'varkey' => $ann_varkey,
    'tstime' => $tstime,
    'featureid' => $wellid,
    'entity_type' => 'dh_feature',
  );
  //dpm($values,'var vals');
  // creates or fetches
  $annual_tid = dh_update_timeseries($values, 'tstime_singular');
  $annual_ts = entity_load_single('dh_timeseries', $annual_tid);
  //dpm($annual_ts,'ts returned');
  if (is_object($annual_ts)) {
    $annual_ts->varkey = $ann_varkey;
    $annual_ts->quarter = $quarter;
    $annual_ts->permit_id = $permit_id;
    $form_state = array();
    $form_state['wrapper_callback'] = 'entity_ui_main_form_defaults';
    $form_state['entity_type'] = 'dh_timeseries';
    $form_state['bundle'] = 'agchem_app';
    form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
    // does this do anything in this context?
    $form_state['build_info']['args'] = array($annual_ts, 'edit', 'dh_timeseries', $year, $wellid);

    // **********************
    // Load the form
    // **********************
    $elements = drupal_build_form('dh_wsp_gwp_monthly_form', $form_state);
    $form = drupal_render($elements);
    echo $form;
  } else {
    echo "Problem creating/loading object $annual_tid";
  }
} else {
  echo "There was a problem, no well loaded.";
}

?>