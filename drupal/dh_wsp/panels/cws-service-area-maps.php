<?php

global $user;
$op = 'add';
$a = arg();
$sysid = $a[1]; // either a valid adminid for a system or "add"
$locid = $a[2]; // either a valid adminid for locality or "edit"
$facid = $a[3]; // either a valid facility hydroid or empty

if ($sysid <> 'add') {
  $submittal = entity_load_single('dh_adminreg_feature', $sysid);
  $op = 'edit';
} else {
  if ($locid) {
    $config = array(
      'bundle' => 'submittal',
      'dh_link_admin_submittal_pr' => array('und' => array( 0 => array('target_id' => $locid) )),
    );
    if (is_numeric($facid) and ($facid > 0) ) {
      $config['dh_link_feature_submittal'] = array('und' => array( 0 => array('target_id' => $facid) ));
    }
    $submittal = entity_create('dh_adminreg_feature', $config);
  } else {
    $error = TRUE;
    $msg = 'You must provide a valid locality to add a new system.';
  }
}
if ($error) {
  drupal_set_message($msg);
} else {
  $form_state = array();
  $form_state['wrapper_callback'] = 'entity_ui_main_form_defaults';
  $form_state['entity_type'] = 'dh_adminreg_feature';
  $form_state['bundle'] = 'submittal';
  $form_state['values']['name'] = 'New System';
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  form_load_include($form_state, 'module', 'dh_wsp');
  form_load_include($form_state, 'inc', 'dh_wsp', 'dh_wsp.custom_forms');
  // set things before initial form_state build
  $form_state['build_info']['args'] = array($submittal, $op, 'dh_adminreg_feature');

  // **********************
  // Load the form
  // **********************
  $elements = drupal_build_form('dh_cwsserviceareamap_form', $form_state);
  $form = drupal_render($elements);
  echo $form;
}
?>