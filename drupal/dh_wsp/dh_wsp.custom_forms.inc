<?php

function dh_cwsserviceareamap_form($form, &$form_state, $dh_adminreg_feature = null, $op = 'edit') {
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }
  
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }

  $form['name'] = array(
    '#title' => t('Document Name'),
    '#type' => 'hidden',
    '#default_value' => 'Community Water System Service Area Map',
    '#description' => t('Name of Document'),
    '#required' => TRUE,
    '#size' => 50,
    '#weight' => 1,
  );

  $form['ftype'] = array(
    '#title' => t('Document Type'),
    '#type' => 'hidden',
    '#default_value' => 'wsp_upload_cws_service_area_map',
    '#description' => t('The type of document being uploaded'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 2,
  );

  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  $form['admincode'] = array(
    '#title' => t('admincode'),
    '#type' => 'hidden',
    '#default_value' => $dh_adminreg_feature->admincode,
    '#description' => t('The unique identifier used by the originating agency of this dH Feature type.'),
    '#required' => FALSE,
    '#size' => 30,
  );
  $form['fstatus'] = array(
    '#title' => t('Status'),
    '#type' => 'hidden',
    '#options' => array(
      'active' => t('Active'),
      'abandoned' => t('Abandoned'),
      'alternative' => t('Alternative Source'),
      'inactive' => t('Out of Service/Temporarily Inactive'),
      'proposed' => t('Proposed/Unknown/Other'),
    ),
    '#default_value' => 'active',
    '#description' => t('The current status of this System. Please select Active if still in operation.'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 3,
  );

  // Machine-readable type name.
  $form['bundle'] = array(
    '#type' => 'hidden',
    '#default_value' => 'submittal',
    '#maxlength' => 32,
    '#attributes' => array('disabled' => 'disabled'),
    '#machine_name' => array(
      'exists' => 'dh_adminreg_feature_get_types',
      'source' => array('label'),
    ),
    '#description' => t('A unique machine-readable name for this model type. It must only contain lowercase letters, numbers, and underscores.'),
  );

  field_attach_form('dh_adminreg_feature', $dh_adminreg_feature, $form, $form_state);
  // now show attached properties that we need to edit
  // how to add attached props
  // this works except will not yet support ajax requests because the form 
  // function is defined locally, so the rebuild fails - must use other means if ajax is needed
  /*
  module_load_include('inc', 'dh', 'plugins/dh.display');
  $facprop_conf = array(
    'featureid' => $dh_adminreg_feature->adminid,
    'varid' => array('sic_code'),
    'prop_entity_type' => 'dh_adminreg_feature',
    'render_layout' => 'unformatted',
    'add' => TRUE,
    'entity_type' => 'dh_properties',
    'display' => array(
      'bundle' => 'dh_properties'
    ),
  );
  if (!$facprop_conf) {
    return FALSE;
  }
  $fac_props = new dhPropertiesGroup($facprop_conf);
  $fac_props->prepareQuery();
  $fac_props->getData();
  $fac_props->buildForm($form, $form_state);
  dpm($fac_props,'fac prop grid');
  */
  // , 'dh_link_admin_submittal_pr'
  $hiddens = array('dh_link_admin_timeseries', 'formtype', 'formid', 'dh_link_webform_submittal', 'dh_link_admin_submittal_pr', 'dh_link_feature_submittal', 'field_dha_link_modification');
  //$hiddens = array();
  foreach ($hiddens as $hidethis) {
    if (isset($form[$hidethis])) {
      $form[$hidethis]['#type'] = 'hidden';
    }
  }


  // set weights on other fields:
 //$form['dh_link_feature_submittal']['#title'] = 'Connect WSP System to VA Hydro Facility'; 
 $form['field_dha_submittal_document']['und']['#title'] = 'Upload Community Water System Service Area Map';
 //$form['dh_link_feature_submittal']['#weight'] = 9;
 $form['dh_link_feature_submittal']['und']['#weight'] = 9;
  $form['description']['und'][0]['value']['#title'] = 'Notes/Comments';
  $form['description']['#weight'] = 11;
  
  $form['data']['#tree'] = TRUE;
  $form['actions'] = array('#type' => 'actions');
  $form['actions']['submit'] = array(
    '#type' => 'submit',
    '#value' => t('Save'),
    '#weight' => 40,
  );
  $form['actions']['cancel'] = array(
    '#type' => 'submit',
    '#value' => t('Cancel'),
    '#weight' => 45,
    '#limit_validation_errors' => array(),
    '#submit' => array('dh_cwsserviceareamap_form_submit_cancel')
  );
  //dpm($form,'form');
  return $form;
}

function dh_cwsserviceareamap_form_submit_cancel($form, &$form_state) {
  // just hoor the destination parameter
}

/**
 * Form API submit callback for the type form.
 */
function dh_cwsserviceareamap_form_submit(&$form, &$form_state) {
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  form_load_include($form_state, 'inc', 'dh', 'dh.admin');
  $dh_adminreg_feature = entity_ui_form_submit_build_entity($form, $form_state);
  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  //dpm($dh_adminreg_feature,'saving feature');
  $dh_adminreg_feature->save();
  //dpm($dh_adminreg_feature,'saved feature');
}

/**
 * Form API submit callback for the delete button.
 */
function dh_cwsserviceareamap_form_submit_delete(&$form, &$form_state) {
  list($pg, $us, $id) = explode('/', $_GET['destination']);
  unset($_GET['destination']);
  drupal_goto(
    'admin/content/dh_adminreg_feature/manage/' . $form_state['dh_adminreg_feature']->fid . '/delete',
    array('query' => array(
      'destination' => $pg
      )
    )  
  );
}

/**
 *****************************************************
 * Existing Resource Info
 ***************************************************** 
*/
function dh_existingresourceupload_form($form, &$form_state, $dh_adminreg_feature = null, $op = 'edit') {
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }
  
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }

  $form['name'] = array(
    '#title' => t('Document Name'),
    '#type' => 'hidden',
    '#default_value' => 'WSP Existing Resources Information',
    '#description' => t('Name of Document'),
    '#required' => TRUE,
    '#size' => 50,
    '#weight' => 1,
  );

  $form['ftype'] = array(
    '#title' => t('Document Type'),
    '#type' => 'hidden',
    '#default_value' => 'wsp_upload_existing_resource_info',
    '#description' => t('The type of document being uploaded'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 2,
  );

  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  $form['admincode'] = array(
    '#title' => t('admincode'),
    '#type' => 'hidden',
    '#default_value' => $dh_adminreg_feature->admincode,
    '#description' => t('The unique identifier used by the originating agency of this dH Feature type.'),
    '#required' => FALSE,
    '#size' => 30,
  );
  $form['fstatus'] = array(
    '#title' => t('Status'),
    '#type' => 'hidden',
    '#default_value' => 'active',
    '#description' => t('The current status of this System. Please select Active if still in operation.'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 3,
  );

  // Machine-readable type name.
  $form['bundle'] = array(
    '#type' => 'hidden',
    '#default_value' => 'submittal',
    '#maxlength' => 32,
    '#attributes' => array('disabled' => 'disabled'),
    '#machine_name' => array(
      'exists' => 'dh_adminreg_feature_get_types',
      'source' => array('label'),
    ),
    '#description' => t('A unique machine-readable name for this model type. It must only contain lowercase letters, numbers, and underscores.'),
  );

  field_attach_form('dh_adminreg_feature', $dh_adminreg_feature, $form, $form_state);
  // now show attached properties that we need to edit
  // how to add attached props
  // this works except will not yet support ajax requests because the form 
  // function is defined locally, so the rebuild fails - must use other means if ajax is needed
  /*
  module_load_include('inc', 'dh', 'plugins/dh.display');
  $facprop_conf = array(
    'featureid' => $dh_adminreg_feature->adminid,
    'varid' => array('sic_code'),
    'prop_entity_type' => 'dh_adminreg_feature',
    'render_layout' => 'unformatted',
    'add' => TRUE,
    'entity_type' => 'dh_properties',
    'display' => array(
      'bundle' => 'dh_properties'
    ),
  );
  if (!$facprop_conf) {
    return FALSE;
  }
  $fac_props = new dhPropertiesGroup($facprop_conf);
  $fac_props->prepareQuery();
  $fac_props->getData();
  $fac_props->buildForm($form, $form_state);
  dpm($fac_props,'fac prop grid');
  */
  // , 'dh_link_admin_submittal_pr'
  $hiddens = array('dh_link_admin_timeseries', 'formtype', 'dh_link_webform_submittal', 'formid', 'dh_link_admin_submittal_pr', 'dh_link_feature_submittal', 'field_dha_link_modification');
  //$hiddens = array();
  foreach ($hiddens as $hidethis) {
    if (isset($form[$hidethis])) {
      $form[$hidethis]['#type'] = 'hidden';
    }
  }


  // set weights on other fields:
 //$form['dh_link_feature_submittal']['#title'] = 'Connect WSP System to VA Hydro Facility'; 
 $form['field_dha_submittal_document']['und']['#title'] = 'Upload Community Water System Service Area Map';
 //$form['dh_link_feature_submittal']['#weight'] = 9;
 $form['dh_link_feature_submittal']['und']['#weight'] = 9;
  $form['description']['und'][0]['value']['#title'] = 'Notes/Comments';
  $form['description']['#weight'] = 11;
  
  $form['data']['#tree'] = TRUE;
  $form['actions'] = array('#type' => 'actions');
  $form['actions']['submit'] = array(
    '#type' => 'submit',
    '#value' => t('Save'),
    '#weight' => 40,
  );
  $form['actions']['cancel'] = array(
    '#type' => 'submit',
    '#value' => t('Cancel'),
    '#weight' => 45,
    '#limit_validation_errors' => array(),
    '#submit' => array('dh_existingresourceupload_form_submit_cancel')
  );
  //dpm($form,'form');
  return $form;
}

function dh_existingresourceupload_form_submit_cancel($form, &$form_state) {
  // just hoor the destination parameter
}

/**
 * Form API submit callback for the type form.
 */
function dh_existingresourceupload_form_submit(&$form, &$form_state) {
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  form_load_include($form_state, 'inc', 'dh', 'dh.admin');
  $dh_adminreg_feature = entity_ui_form_submit_build_entity($form, $form_state);
  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  $dh_adminreg_feature->save();
  //dpm($dh_adminreg_feature,'post save');
}

/**
 * Form API submit callback for the delete button.
 */
function dh_existingresourceupload_form_submit_delete(&$form, &$form_state) {
  list($pg, $us, $id) = explode('/', $_GET['destination']);
  unset($_GET['destination']);
  drupal_goto(
    'admin/content/dh_adminreg_feature/manage/' . $form_state['dh_adminreg_feature']->fid . '/delete',
    array('query' => array(
      'destination' => $pg
      )
    )  
  );
}

/**
 *****************************************************
 * Plan Adoption
 ***************************************************** 
*/
function dh_wspadoption_form($form, &$form_state, $dh_adminreg_feature = null, $op = 'edit') {
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }
  
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }

  $form['name'] = array(
    '#title' => t('Document Name'),
    '#type' => 'hidden',
    '#default_value' => 'Water Supply Plan Adoption Information',
    '#description' => t('Name of Document'),
    '#required' => TRUE,
    '#size' => 50,
    '#weight' => 1,
  );

  $form['ftype'] = array(
    '#title' => t('Document Type'),
    '#type' => 'hidden',
    '#default_value' => 'wsp_upload_wsp_adoption_document',
    '#description' => t('The type of document being uploaded'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 2,
  );

  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  $form['admincode'] = array(
    '#title' => t('admincode'),
    '#type' => 'hidden',
    '#default_value' => $dh_adminreg_feature->admincode,
    '#description' => t('The unique identifier used by the originating agency of this dH Feature type.'),
    '#required' => FALSE,
    '#size' => 30,
  );
  $form['fstatus'] = array(
    '#title' => t('Status'),
    '#type' => 'hidden',
    '#default_value' => 'active',
    '#description' => t('The current status of this System. Please select Active if still in operation.'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 3,
  );

  // Machine-readable type name.
  $form['bundle'] = array(
    '#type' => 'hidden',
    '#default_value' => 'submittal',
    '#maxlength' => 32,
    '#attributes' => array('disabled' => 'disabled'),
    '#machine_name' => array(
      'exists' => 'dh_adminreg_feature_get_types',
      'source' => array('label'),
    ),
    '#description' => t('A unique machine-readable name for this model type. It must only contain lowercase letters, numbers, and underscores.'),
  );

  field_attach_form('dh_adminreg_feature', $dh_adminreg_feature, $form, $form_state);
  // now show attached properties that we need to edit
  // how to add attached props
  // this works except will not yet support ajax requests because the form 
  // function is defined locally, so the rebuild fails - must use other means if ajax is needed
  /*
  module_load_include('inc', 'dh', 'plugins/dh.display');
  $facprop_conf = array(
    'featureid' => $dh_adminreg_feature->adminid,
    'varid' => array('sic_code'),
    'prop_entity_type' => 'dh_adminreg_feature',
    'render_layout' => 'unformatted',
    'add' => TRUE,
    'entity_type' => 'dh_properties',
    'display' => array(
      'bundle' => 'dh_properties'
    ),
  );
  if (!$facprop_conf) {
    return FALSE;
  }
  $fac_props = new dhPropertiesGroup($facprop_conf);
  $fac_props->prepareQuery();
  $fac_props->getData();
  $fac_props->buildForm($form, $form_state);
  dpm($fac_props,'fac prop grid');
  */
  // , 'dh_link_admin_submittal_pr'
  $hiddens = array('dh_link_admin_timeseries', 'formtype', 'dh_link_webform_submittal', 'formid', 'dh_link_admin_submittal_pr', 'dh_link_feature_submittal', 'field_dha_link_modification');
  //$hiddens = array();
  foreach ($hiddens as $hidethis) {
    if (isset($form[$hidethis])) {
      $form[$hidethis]['#type'] = 'hidden';
    }
  }


  // set weights on other fields:
 //$form['dh_link_feature_submittal']['#title'] = 'Connect WSP System to VA Hydro Facility'; 
 $form['field_dha_submittal_document']['und']['#title'] = 'Upload Community Water System Service Area Map';
 //$form['dh_link_feature_submittal']['#weight'] = 9;
 $form['dh_link_feature_submittal']['und']['#weight'] = 9;
  $form['description']['und'][0]['value']['#title'] = 'Notes/Comments';
  $form['description']['#weight'] = 11;
  
  $form['data']['#tree'] = TRUE;
  $form['actions'] = array('#type' => 'actions');
  $form['actions']['submit'] = array(
    '#type' => 'submit',
    '#value' => t('Save'),
    '#weight' => 40,
  );
  $form['actions']['cancel'] = array(
    '#type' => 'submit',
    '#value' => t('Cancel'),
    '#weight' => 45,
    '#limit_validation_errors' => array(),
    '#submit' => array('dh_wspadoption_form_submit_cancel')
  );
  //dpm($form,'form');
  return $form;
}

function dh_wspadoption_form_submit_cancel($form, &$form_state) {
  // just hoor the destination parameter
}

/**
 * Form API submit callback for the type form.
 */
function dh_wspadoption_form_submit(&$form, &$form_state) {
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  form_load_include($form_state, 'inc', 'dh', 'dh.admin');
  $dh_adminreg_feature = entity_ui_form_submit_build_entity($form, $form_state);
  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  $dh_adminreg_feature->save();
}

/**
 * Form API submit callback for the delete button.
 */
function dh_wspadoption_form_submit_delete(&$form, &$form_state) {
  list($pg, $us, $id) = explode('/', $_GET['destination']);
  unset($_GET['destination']);
  drupal_goto(
    'admin/content/dh_adminreg_feature/manage/' . $form_state['dh_adminreg_feature']->fid . '/delete',
    array('query' => array(
      'destination' => $pg
      )
    )  
  );
}


/**
 *****************************************************
 * Demand Management
 ***************************************************** 
*/
function dh_waterdemandmgmt_form($form, &$form_state, $dh_adminreg_feature = null, $op = 'edit') {
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }
  
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }

  $form['name'] = array(
    '#title' => t('Document Name'),
    '#type' => 'hidden',
    '#default_value' => 'Water Demand Management Information',
    '#description' => t('Name of Document'),
    '#required' => TRUE,
    '#size' => 50,
    '#weight' => 1,
  );

  $form['ftype'] = array(
    '#title' => t('Document Type'),
    '#type' => 'hidden',
    '#default_value' => 'wsp_upload_water_demand_mgmt_info',
    '#description' => t('The type of document being uploaded'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 2,
  );

  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  $form['admincode'] = array(
    '#title' => t('admincode'),
    '#type' => 'hidden',
    '#default_value' => $dh_adminreg_feature->admincode,
    '#description' => t('The unique identifier used by the originating agency of this dH Feature type.'),
    '#required' => FALSE,
    '#size' => 30,
  );
  $form['fstatus'] = array(
    '#title' => t('Status'),
    '#type' => 'hidden',
    '#default_value' => 'active',
    '#description' => t('The current status of this System. Please select Active if still in operation.'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 3,
  );

  // Machine-readable type name.
  $form['bundle'] = array(
    '#type' => 'hidden',
    '#default_value' => 'submittal',
    '#maxlength' => 32,
    '#attributes' => array('disabled' => 'disabled'),
    '#machine_name' => array(
      'exists' => 'dh_adminreg_feature_get_types',
      'source' => array('label'),
    ),
    '#description' => t('A unique machine-readable name for this model type. It must only contain lowercase letters, numbers, and underscores.'),
  );

  field_attach_form('dh_adminreg_feature', $dh_adminreg_feature, $form, $form_state);
  // now show attached properties that we need to edit
  // how to add attached props
  // this works except will not yet support ajax requests because the form 
  // function is defined locally, so the rebuild fails - must use other means if ajax is needed
  /*
  module_load_include('inc', 'dh', 'plugins/dh.display');
  $facprop_conf = array(
    'featureid' => $dh_adminreg_feature->adminid,
    'varid' => array('sic_code'),
    'prop_entity_type' => 'dh_adminreg_feature',
    'render_layout' => 'unformatted',
    'add' => TRUE,
    'entity_type' => 'dh_properties',
    'display' => array(
      'bundle' => 'dh_properties'
    ),
  );
  if (!$facprop_conf) {
    return FALSE;
  }
  $fac_props = new dhPropertiesGroup($facprop_conf);
  $fac_props->prepareQuery();
  $fac_props->getData();
  $fac_props->buildForm($form, $form_state);
  dpm($fac_props,'fac prop grid');
  */
  // , 'dh_link_admin_submittal_pr'
  $hiddens = array('dh_link_admin_timeseries', 'formtype', 'dh_link_webform_submittal', 'formid', 'dh_link_admin_submittal_pr', 'dh_link_feature_submittal', 'field_dha_link_modification');
  //$hiddens = array();
  foreach ($hiddens as $hidethis) {
    if (isset($form[$hidethis])) {
      $form[$hidethis]['#type'] = 'hidden';
    }
  }


  // set weights on other fields:
 //$form['dh_link_feature_submittal']['#title'] = 'Connect WSP System to VA Hydro Facility'; 
 $form['field_dha_submittal_document']['und']['#title'] = 'Upload Community Water System Service Area Map';
 //$form['dh_link_feature_submittal']['#weight'] = 9;
 $form['dh_link_feature_submittal']['und']['#weight'] = 9;
  $form['description']['und'][0]['value']['#title'] = 'Notes/Comments';
  $form['description']['#weight'] = 11;
  
  $form['data']['#tree'] = TRUE;
  $form['actions'] = array('#type' => 'actions');
  $form['actions']['submit'] = array(
    '#type' => 'submit',
    '#value' => t('Save'),
    '#weight' => 40,
  );
  $form['actions']['cancel'] = array(
    '#type' => 'submit',
    '#value' => t('Cancel'),
    '#weight' => 45,
    '#limit_validation_errors' => array(),
    '#submit' => array('dh_waterdemandmgmt_form_submit_cancel')
  );
  //dpm($form,'form');
  return $form;
}

function dh_waterdemandmgmt_form_submit_cancel($form, &$form_state) {
  // just hoor the destination parameter
}

/**
 * Form API submit callback for the type form.
 */
function dh_waterdemandmgmt_form_submit(&$form, &$form_state) {
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  form_load_include($form_state, 'inc', 'dh', 'dh.admin');
  $dh_adminreg_feature = entity_ui_form_submit_build_entity($form, $form_state);
  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  $dh_adminreg_feature->save();
}

/**
 * Form API submit callback for the delete button.
 */
function dh_waterdemandmgmt_form_submit_delete(&$form, &$form_state) {
  list($pg, $us, $id) = explode('/', $_GET['destination']);
  unset($_GET['destination']);
  drupal_goto(
    'admin/content/dh_adminreg_feature/manage/' . $form_state['dh_adminreg_feature']->fid . '/delete',
    array('query' => array(
      'destination' => $pg
      )
    )  
  );
}


/**
 *****************************************************
 * Alternatives
 ***************************************************** 
*/
function dh_needstatement_form($form, &$form_state, $dh_adminreg_feature = null, $op = 'edit') {
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }
  
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }

  $form['name'] = array(
    '#title' => t('Document Name'),
    '#type' => 'hidden',
    '#default_value' => 'Statement of Need and Alternatives Document',
    '#description' => t('Name of Document'),
    '#required' => TRUE,
    '#size' => 50,
    '#weight' => 1,
  );

  $form['ftype'] = array(
    '#title' => t('Document Type'),
    '#type' => 'hidden',
    '#default_value' => 'wsp_upload_need_statement_alternatives',
    '#description' => t('The type of document being uploaded'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 2,
  );

  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  $form['admincode'] = array(
    '#title' => t('admincode'),
    '#type' => 'hidden',
    '#default_value' => $dh_adminreg_feature->admincode,
    '#description' => t('The unique identifier used by the originating agency of this dH Feature type.'),
    '#required' => FALSE,
    '#size' => 30,
  );
  $form['fstatus'] = array(
    '#title' => t('Status'),
    '#type' => 'hidden',
    '#default_value' => 'active',
    '#description' => t('The current status of this System. Please select Active if still in operation.'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 3,
  );

  // Machine-readable type name.
  $form['bundle'] = array(
    '#type' => 'hidden',
    '#default_value' => 'submittal',
    '#maxlength' => 32,
    '#attributes' => array('disabled' => 'disabled'),
    '#machine_name' => array(
      'exists' => 'dh_adminreg_feature_get_types',
      'source' => array('label'),
    ),
    '#description' => t('A unique machine-readable name for this model type. It must only contain lowercase letters, numbers, and underscores.'),
  );

  field_attach_form('dh_adminreg_feature', $dh_adminreg_feature, $form, $form_state);
  // now show attached properties that we need to edit
  // how to add attached props
  // this works except will not yet support ajax requests because the form 
  // function is defined locally, so the rebuild fails - must use other means if ajax is needed
  /*
  module_load_include('inc', 'dh', 'plugins/dh.display');
  $facprop_conf = array(
    'featureid' => $dh_adminreg_feature->adminid,
    'varid' => array('sic_code'),
    'prop_entity_type' => 'dh_adminreg_feature',
    'render_layout' => 'unformatted',
    'add' => TRUE,
    'entity_type' => 'dh_properties',
    'display' => array(
      'bundle' => 'dh_properties'
    ),
  );
  if (!$facprop_conf) {
    return FALSE;
  }
  $fac_props = new dhPropertiesGroup($facprop_conf);
  $fac_props->prepareQuery();
  $fac_props->getData();
  $fac_props->buildForm($form, $form_state);
  dpm($fac_props,'fac prop grid');
  */
  // , 'dh_link_admin_submittal_pr'
  $hiddens = array('dh_link_admin_timeseries', 'formtype', 'dh_link_webform_submittal', 'formid', 'dh_link_admin_submittal_pr', 'dh_link_feature_submittal', 'field_dha_link_modification');
  //$hiddens = array();
  foreach ($hiddens as $hidethis) {
    if (isset($form[$hidethis])) {
      $form[$hidethis]['#type'] = 'hidden';
    }
  }


  // set weights on other fields:
 //$form['dh_link_feature_submittal']['#title'] = 'Connect WSP System to VA Hydro Facility'; 
 $form['field_dha_submittal_document']['und']['#title'] = 'Upload Community Water System Service Area Map';
 //$form['dh_link_feature_submittal']['#weight'] = 9;
 $form['dh_link_feature_submittal']['und']['#weight'] = 9;
  $form['description']['und'][0]['value']['#title'] = 'Notes/Comments';
  $form['description']['#weight'] = 11;
  
  $form['data']['#tree'] = TRUE;
  $form['actions'] = array('#type' => 'actions');
  $form['actions']['submit'] = array(
    '#type' => 'submit',
    '#value' => t('Save'),
    '#weight' => 40,
  );
  $form['actions']['cancel'] = array(
    '#type' => 'submit',
    '#value' => t('Cancel'),
    '#weight' => 45,
    '#limit_validation_errors' => array(),
    '#submit' => array('dh_needstatement_form_submit_cancel')
  );
  //dpm($form,'form');
  return $form;
}

function dh_needstatement_form_submit_cancel($form, &$form_state) {
  // just hoor the destination parameter
}

/**
 * Form API submit callback for the type form.
 */
function dh_needstatement_form_submit(&$form, &$form_state) {
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  form_load_include($form_state, 'inc', 'dh', 'dh.admin');
  $dh_adminreg_feature = entity_ui_form_submit_build_entity($form, $form_state);
  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  $dh_adminreg_feature->save();
}

/**
 * Form API submit callback for the delete button.
 */
function dh_needstatement_form_submit_delete(&$form, &$form_state) {
  list($pg, $us, $id) = explode('/', $_GET['destination']);
  unset($_GET['destination']);
  drupal_goto(
    'admin/content/dh_adminreg_feature/manage/' . $form_state['dh_adminreg_feature']->fid . '/delete',
    array('query' => array(
      'destination' => $pg
      )
    )  
  );
}


/**
 *****************************************************
 * Drought Plan
 ***************************************************** 
*/

function dh_droughtplanupload_form($form, &$form_state, $dh_adminreg_feature = null, $op = 'edit') {
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }
  
  if ($op == 'clone') {
    $dh_adminreg_feature->name .= ' (cloned)';
    $dh_adminreg_feature->bundle = '';
  }

  $form['name'] = array(
    '#title' => t('Document Name'),
    '#type' => 'hidden',
    '#default_value' => 'WSP Drought Response and Contingency Plan',
    '#description' => t('Name of Document'),
    '#required' => TRUE,
    '#size' => 50,
    '#weight' => 1,
  );

  $form['ftype'] = array(
    '#title' => t('Document Type'),
    '#type' => 'hidden',
    '#default_value' => 'wsp_upload_drought_plan',
    '#description' => t('The type of document being uploaded'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 2,
  );

  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  $form['admincode'] = array(
    '#title' => t('admincode'),
    '#type' => 'hidden',
    '#default_value' => $dh_adminreg_feature->admincode,
    '#description' => t('The unique identifier used by the originating agency of this dH Feature type.'),
    '#required' => FALSE,
    '#size' => 30,
  );
  $form['fstatus'] = array(
    '#title' => t('Status'),
    '#type' => 'hidden',
    '#options' => array(
      'active' => t('Active'),
      'abandoned' => t('Abandoned'),
      'alternative' => t('Alternative Source'),
      'inactive' => t('Out of Service/Temporarily Inactive'),
      'proposed' => t('Proposed/Unknown/Other'),
    ),
    '#default_value' => 'active',
    '#description' => t('The current status of this System. Please select Active if still in operation.'),
    '#required' => FALSE,
    '#multiple' => FALSE,
    '#weight' => 3,
  );

  // Machine-readable type name.
  $form['bundle'] = array(
    '#type' => 'hidden',
    '#default_value' => 'submittal',
    '#maxlength' => 32,
    '#attributes' => array('disabled' => 'disabled'),
    '#machine_name' => array(
      'exists' => 'dh_adminreg_feature_get_types',
      'source' => array('label'),
    ),
    '#description' => t('A unique machine-readable name for this model type. It must only contain lowercase letters, numbers, and underscores.'),
  );

  field_attach_form('dh_adminreg_feature', $dh_adminreg_feature, $form, $form_state);
  // now show attached properties that we need to edit
  // how to add attached props
  // this works except will not yet support ajax requests because the form 
  // function is defined locally, so the rebuild fails - must use other means if ajax is needed
  /*
  module_load_include('inc', 'dh', 'plugins/dh.display');
  $facprop_conf = array(
    'featureid' => $dh_adminreg_feature->adminid,
    'varid' => array('sic_code'),
    'prop_entity_type' => 'dh_adminreg_feature',
    'render_layout' => 'unformatted',
    'add' => TRUE,
    'entity_type' => 'dh_properties',
    'display' => array(
      'bundle' => 'dh_properties'
    ),
  );
  if (!$facprop_conf) {
    return FALSE;
  }
  $fac_props = new dhPropertiesGroup($facprop_conf);
  $fac_props->prepareQuery();
  $fac_props->getData();
  $fac_props->buildForm($form, $form_state);
  dpm($fac_props,'fac prop grid');
  */
  // , 'dh_link_admin_submittal_pr'
  $hiddens = array('dh_link_admin_timeseries', 'formtype', 'dh_link_webform_submittal', 'formid', 'dh_link_admin_submittal_pr', 'dh_link_feature_submittal', 'field_dha_link_modification');
  //$hiddens = array();
  foreach ($hiddens as $hidethis) {
    if (isset($form[$hidethis])) {
      $form[$hidethis]['#type'] = 'hidden';
    }
  }


  // set weights on other fields:
 //$form['dh_link_feature_submittal']['#title'] = 'Connect WSP System to VA Hydro Facility'; 
 $form['field_dha_submittal_document']['und']['#title'] = 'Upload Community Water System Service Area Map';
 //$form['dh_link_feature_submittal']['#weight'] = 9;
 $form['dh_link_feature_submittal']['und']['#weight'] = 9;
  $form['description']['und'][0]['value']['#title'] = 'Notes/Comments';
  $form['description']['#weight'] = 11;
  
  $form['data']['#tree'] = TRUE;
  $form['actions'] = array('#type' => 'actions');
  $form['actions']['submit'] = array(
    '#type' => 'submit',
    '#value' => t('Save'),
    '#weight' => 40,
  );
  $form['actions']['cancel'] = array(
    '#type' => 'submit',
    '#value' => t('Cancel'),
    '#weight' => 45,
    '#limit_validation_errors' => array(),
    '#submit' => array('dh_droughtplanupload_form_submit_cancel')
  );
  return $form;
}

function dh_droughtplanupload_form_submit_cancel($form, &$form_state) {
  // just hoor the destination parameter
}

/**
 * Form API submit callback for the type form.
 */
function dh_droughtplanupload_form_submit(&$form, &$form_state) {
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  form_load_include($form_state, 'inc', 'dh', 'dh.admin');
  $dh_adminreg_feature = entity_ui_form_submit_build_entity($form, $form_state);
  if (trim($dh_adminreg_feature->admincode) == '') {
    $dh_adminreg_feature->admincode = str_replace(' ', '_', strtolower($dh_adminreg_feature->name ));
  }
  $dh_adminreg_feature->save();
}

/**
 * Form API submit callback for the delete button.
 */
function dh_droughtplanupload_form_submit_delete(&$form, &$form_state) {
  list($pg, $us, $id) = explode('/', $_GET['destination']);
  unset($_GET['destination']);
  drupal_goto(
    'admin/content/dh_adminreg_feature/manage/' . $form_state['dh_adminreg_feature']->fid . '/delete',
    array('query' => array(
      'destination' => $pg
      )
    )  
  );
}


function dh_wsp_gwp_monthly_form($form, &$form_state, $annual_ts = null, $op = 'edit') {
  // load base form from
  ctools_include('plugins');
  $plugins = ctools_get_plugins('dh', 'dh_components');
  //dpm($plugins,'all plug');
  //dpm($annual_ts,'annual_ts');
  if (!is_object($annual_ts)) {
    $annual_ts = drupal_array_get_nested_value($form_state['build_info'], array('args',0));
  }
  error_log(" FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ");
  error_log("Called: dh_wsp_gwp_monthly_form ");
  error_log(" FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ");
  $plugin = ctools_get_plugins('dh', 'dh_components', 'DHGWPermitMonthlyReportingEvent');
  $class = ctools_plugin_get_class($plugin, 'handler');
  //dpm($plugin,'plug');
  $config = array();
  if ($class) {
    $src = new $class($config);
    $src->year = date('Y', dh_handletimestamp($annual_ts->tstime));
    $src->quarter = $annual_ts->quarter;
    $src->varkey = 'wd_meter_reading';
    $src->featureid = array($annual_ts->featureid);
    $src->ann_varkey = $annual_ts->varkey;
    $src->save_method = 'form_entity_map';
    //dpm($src,'app plugin object');
    $hiddens = array('tid', 'varname', 'tsendtime', 'featureid', 'entity_type');
    $src->hidePropCols($hiddens);
    $src->prepareQuery();
    $src->getData();
    $src->buildForm($form, $form_state);
    $form['annual_tid'] = array(
      '#type' => 'hidden',
      '#default_value' => $annual_ts->tid
    );
  } else {
    dsm("Could not load $class for plugin $plugin");
  }
  //dpm($annual_ts,"passed in annual_ts");
  $form['permit_id'] = array(
    '#type' => 'hidden',
    '#default_value' => $annual_ts->permit_id
  );
  
  $form['actions'] = array('#type' => 'actions');
  $next = dh_monthly_get_next_mp($annual_ts->featureid, 'active', 'well');
  if ($next) {
    $form['actions']['save_and_next'] = array(
      '#type' => 'submit',
      '#value' => t("Next Well ($next->name)"),
      '#weight' => 25,
    );
  }  
  $form['actions']['save_and_submit'] = array(
    '#type' => 'submit',
    '#value' => t("Save & Submit to DEQ"),
    '#weight' => 25,
 #   '#submit' => array('dh_wsp_gwp_monthly_submit_final')
  );
  /*
  $form['actions']['submit'] = array(
    '#type' => 'submit',
    '#value' => t('Update Totals'),
    '#weight' => 35,
    '#submit' => array('dh_wsp_gwp_monthly_form_refresh')
  );
  */
  switch ($op) {
    case 'add':
    break;
    case 'edit':
    break;
  }
  $form['actions']['cancel'] = array(
    '#type' => 'submit',
    '#value' => t('Cancel'),
    '#weight' => 45,
    '#limit_validation_errors' => array(),
    '#submit' => array('dh_wsp_gwp_monthly_form_cancel')
  );
  $form['actions']['save'] = array(
    '#type' => 'submit',
    '#value' => t('Save & Reload'),
    '#weight' => 40,
    //'#submit' => array('dh_wsp_gwp_monthly_form_rebuild')
  );
  $form['#prefix'] = "<div id='dh-wsp-gwp-monthly-form-block'>" ;
  $form['#suffix'] = "</div>";
  return $form;
}

// this is not used here, but it is a good example of how to do it
/**
 * Form API submit callback for the delete button.
 */
function dh_wsp_gwp_monthly_form_submit_delete(&$form, &$form_state) {
  /*
  $parms = drupal_get_query_parameters();
  if (isset($parms['finaldest'])) {
    $extras['query']['destination'] = $parms['finaldest'];
  }
  $url = implode('/', array('admin/content/dh_adminreg_feature/manage/' . $form_state['dh_adminreg_feature']->adminid . '/delete'));
  drupal_goto($url, $extras);
  */
}

function dh_wsp_gwp_monthly_form_save(&$form, &$form_state) {
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  form_load_include($form_state, 'inc', 'dh', 'dh.admin');
  // load the object
  $dh_timeseries = entity_ui_form_submit_build_entity($form, $form_state);
  $dh_timeseries->save();
  ctools_include('plugins');
  $class = ctools_plugin_load_class('dh', 'dh_components', 'DHGWPermitMonthlyReportingEvent', 'handler');
  $config = array();
  $src = new $class($config);
  $options = array();
  // handle all the attached stuff
  $src->submitForm($form, $form_state);
  // We do NOT call the save() of the annual here because the 
  // monthly children already push their values to the annual total
  // $dh_timeseries->save();
  //dpm($dh_timeseries,'saved timeseries');
  return $dh_timeseries;
  
}

function dh_wsp_gwp_monthly_form_refresh(&$form, &$form_state) {
  // save but show the form again
  error_log("!!!!!!!!!!!!!!!!! Called dh_wsp_gwp_monthly_form_refresh !!!!!!!!!!!");
  $args = arg();
  $parms = drupal_get_query_parameters();
  $dh_timeseries = dh_wsp_gwp_monthly_form_save($form, $form_state);
  $url = implode('/', $args);
  drupal_goto($url, array('query' => $parms));
}

function dh_wsp_gwp_monthly_form_rebuild(&$form, &$form_state) {
  // no longer used.
  //return $form;
  // save but show the form again
  //error_log("!!!!!!!!!!!!!!!!! Called dh_wsp_gwp_monthly_form_rebuild !!!!!!!!!!!");
  //return dh_wsp_gwp_monthly_form_submit($form, $form_state);
  $dh_timeseries = dh_wsp_gwp_monthly_form_save($form, $form_state);
  $year = date('Y', $dh_timeseries->tstime);
  $dh_timeseries->quarter = ceil(date('n', $dh_timeseries->tstime) / 4);
  /*
  $form_state = array();
  $form_state['wrapper_callback'] = 'entity_ui_main_form_defaults';
  $form_state['entity_type'] = 'dh_timeseries';
  $form_state['bundle'] = 'agchem_app';
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  // does this do anything in this context?
  $form_state['build_info']['args'] = array($dh_timeseries, 'edit', 'dh_timeseries', $year, $dh_timeseries->featureid);
  */

  // **********************
  // Load the form
  // **********************
  //error_log("Returning Form" . print_r($elements['ts_group'],1));
  $elements = drupal_build_form('dh_wsp_gwp_monthly_form', $form_state);
  //error_log("dh_wsp_gwp_monthly_form_rebuild calling drupal_build_form('dh_wsp_gwp_monthly_form', form_state)");
  //dpm($elements,'FORM elements');
  //$form = drupal_render($elements);
  return $elements;
}

function dh_wsp_gwp_monthly_form_submit(&$form, &$form_state) {
  //error_log("$$$$$$$$$$$$$$$$$$$$$$$ Called dh_wsp_gwp_monthly_form_submit ");
  #error_log('form state:' . print_r($form_state,1));
  //dpm($form_state,'form_state');
  $dh_timeseries = dh_wsp_gwp_monthly_form_save($form, $form_state);
  $parms = drupal_get_query_parameters();
  $wellid = $dh_timeseries->featureid;
  // can't do this automatically with arg() because when submitting with ajax it breaks the URL args
  $args = arg();
  //$args = array('ows-wwpr-well-monthly', $wellid);
  $finaldest = FALSE;
  if (isset($parms['finaldest'])) {
    $finaldest = $parms['finaldest'];
  }
  // get GWP adminreg id to insure we have the right program
  // gwp admincode = vdeq_gwp 
  $authid = dh_adminreg_get_adminreg_entity('vdeq_gwp');
  $gwpid = array_shift($authid);
  $facilityid = dh_getMpFacilityHydroId($wellid);
  if ($form_state['values']['permit_id'] == NULL) {
    $permit_id = dh_adminreg_get_admin_location($facilityid, FALSE, FALSE, $gwpid);
  } else {
    // we were called with the a permit id 
    $permit_id = $form_state['values']['permit_id'];
    //dpm($permit_id,"passed in permitid");
  }
  //dpm($permit_id, "permit_id for well $wellid fac $facilityid");
  // now set a vadeq_report_wd on the permit-info
  // due date = 
  $year = date('Y', $dh_timeseries->tstime);
  $year = ($dh_timeseries->quarter == 4) ? $year + 1 : $year;
  $mo = ($dh_timeseries->quarter == 4) ? 1 : $dh_timeseries->quarter * 3 + 1;
  $day = 10;
  $info = array(
    'varkey' => 'vadeq_report_wd',
    'tsendtime' => dh_handletimestamp(date('Y-m-d')),
    'tstime' => dh_handletimestamp("$year-$mo-$day"),
    'featureid' => $permit_id,
    'tsvalue' => 0,
    'entity_type' => 'dh_adminreg_feature',
    'tscode' => 'submitted',
  );
  // we should only save this if it does *not* exist, otherwise, the initial receipt will be overwritten
  // but since the requirements ask for this audit trail every time we save, se la vie

  $receipt = dh_get_timeseries($info , 'tstime_singular', TRUE);
  $receipt = array_shift($receipt);
  if (!is_object($receipt)) {
    dsm("Adding receipt record.");
    $receipt = dh_update_timeseries($info, 'tsendtime_singular');
  } else {
    dsm("Receipt record already exists.");
  }
  //dpm($info,'receipt info');
  //dpm($receipt,'created receipt');
  // ****************
  // Now handle the specific save type requested.
  // handle save_and_next if requested
  // if add, we route to set properties, then to monthly data entry
  // if edit we just honor the destination that already is set
  if ($form_state['triggering_element']['#id'] == 'edit-save-and-next') {
    $next_feature = dh_monthly_get_next_mp($wellid, 'active', 'well');
    $args[0] = 'ows-wwpr-well-monthly'; # defaults to this page
    if ($next_feature) {
      // we have what we need so lets go to the next one
      $args[1] = $next_feature->hydroid;
      $url = implode('/', $args);
    }
  } else {
    if ($form_state['triggering_element']['#id'] == 'edit-save-and-submit') {
      // regular save here, and if we have a finaldest param we use it as our destination
      // the default should be the save page
      if ($finaldest) {
        $url = $finaldest;
        unset($parms);
      } else {
        $url = implode('/', array('ows-wwpr-permit-info', $permit_id));
        if (!$permit_id) {
          // not a permit, try a vwuds registration, else bail.
          $url = implode('/', array('ows-vwuds-facility-info', $facilityid));
        }
        $fac = entity_load_single('dh_feature', $facilityid);
        drupal_set_message("Withdrawal Report for $fac->name.");
      }
    } else {
      // regular save here and we should reload this same form page
      $args[0] = 'ows-wwpr-well-monthly'; # defaults to this page
      $url = implode('/', $args);
      drupal_set_message("Updating Withdrawal Form Calculations.");
      /*
      if ($finaldest) {
        $url = $finaldest;
        unset($parms);
      } else {
        $url = implode('/', array('ows-wwpr-well-info', $wellid));
      }
      */
    }
  }
  drupal_goto($url, array('query' => $parms));
}

function dh_wsp_gwp_monthly_form_cancel($form, &$form_state) {
  $parms = drupal_get_query_parameters();
  $args = arg();
  $wellid = $args[1];
  if (isset($parms['finaldest'])) {
    $url = $parms['finaldest'];
  } else {
    $url = implode('/', array('ows-vwuds-well-info', $wellid));
  }
  drupal_goto($url);
}
?>