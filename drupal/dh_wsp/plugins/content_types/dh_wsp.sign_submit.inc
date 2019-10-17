<?php

module_load_include('inc', 'dh', 'plugins/dh.display');
module_load_include('inc', 'dh_wsp', 'dh_wsp.widgets');
module_load_include('module', 'dh');
module_load_include('module', 'dh_adminreg');
/**
 * @file
 * Pane for annualk reporting submittal.
 */

$plugin = array(
  'title' => t('VWWR Annual Reporting Sign & Submit'),
  'description' => t('Sign and submit.'),
  'module' => 'properties_form',
  'category' => t('dH Meta-Modeling'),
  'single' => TRUE,
  'defaults' => array(),
  'admin info' => 'dh_vwwr_sign_form_admin_info',
  'render callback' => 'dh_vwwr_sign_form_render',
  'edit form' => 'dh_vwwr_sign_form_edit_form',
  'all contexts' => TRUE, 
);


/**
 * Callback for page_manager admin UI information.
 */
function dh_vwwr_sign_form_admin_info($subtype, $conf, $contexts) {
  if (!empty($conf)) {
    $block = new stdClass();
    $block->title = $conf['override_title'] ? $conf['override_title_text'] : '';

    $admin_info = t('@entity_type (@formid)', array(
      '@entity_type' => $conf['dh_vwwr_sign_form_settings']['entity_type'],
      '@formid' => $conf['dh_vwwr_sign_form_settings']['formid'],
    ));
    $block->content = $admin_info;

    return $block;
  }
}

/**
 * Callback to configure options for the entity add/edit form in a pane.
 */
function dh_vwwr_sign_form_edit_form($form, &$form_state) {
  //dpm($form_state, "Form_state to dh_vwwr_sign_form_edit_form");
  $plugindefs = array(
    array('module'=>'dh', 'type' => 'dh_components', 'groupname'=>'sign_submit', 'name'=>'DHVWWRSignSubmit'),
  );
  foreach ($plugindefs as $plugindef) {
    $groupname = $plugindef['groupname'];
    $conf = isset($form_state['values']['entity_settings'][$groupname]) ? $form_state['values']['entity_settings'][$groupname] : $form_state['conf']['entity_settings'][$groupname];
    $conf['groupname'] = empty($conf['groupname']) ? $groupname : $conf['groupname'];
    ctools_include('plugins');
    $plugin = ctools_get_plugins($plugindef['module'], $plugindef['type'], $plugindef['name']);
    $class = ctools_plugin_get_class($plugin, 'handler');
    if ($class) {
      $pob = new $class($conf);
      $pob->buildOptionsForm($form, $form_state);
    } else {
      watchdog('dh_wsp', "$plugindef[name]: problem handling plugin");
    }
  }
  return $form;
}

/**
 * Submit handler just puts non-empty values into $form_state['conf'].
 */
function dh_vwwr_sign_form_edit_form_submit($form, &$form_state) {
  //dpm($form_state, "form_state to dh_vwwr_sign_form_edit_form_submit");
  $plugindefs = array(
    array('module'=>'dh', 'type' => 'dh_components', 'groupname'=>'sign_submit', 'name'=>'DHVWWRSignSubmit'),
  );
  foreach ($plugindefs as $plugindef) {
    $groupname = $plugindef['groupname'];
    if (!isset($form_state['conf']['entity_settings'][$groupname])) {
      $form_state['conf']['entity_settings'][$groupname] = array();
    }
    foreach (element_children($form['entity_settings'][$groupname]) as $key) {
      if (isset($form_state['values'][$groupname][$key])) {
        $form_state['conf']['entity_settings'][$groupname][$key] = $form_state['values'][$groupname][$key];
      }
    }
  }
  //dpm($form_state['conf'],'final form_state[conf]');
}

function dh_vwwr_sign_form($form, &$form_state, $dh_feature = null, $op = 'edit') {
  // load base form from
  ctools_include('plugins');
  //dpm($form_state, "form_state to dh_vwwr_sign_form_edit_form_submit");
  $plugindefs = array(
    array('module'=>'dh', 'type' => 'dh_components', 'groupname'=>'sign_submit', 'name'=>'DHVWWRSignSubmit'),
  );
  foreach ($plugindefs as $plugindef) {
    $groupname = $plugindef['groupname'];
    $conf = isset($form_state['values']['entity_settings'][$groupname]) ? $form_state['values']['entity_settings'][$groupname] : $form_state['conf']['entity_settings'][$groupname];
    $conf['groupname'] = empty($conf['groupname']) ? $groupname : $conf['groupname'];
    $plugin = ctools_get_plugins($plugindef['module'], $plugindef['type'], $plugindef['name']);
    $class = ctools_plugin_get_class($plugin, 'handler');
    if ($class) {
      $tsgrid = new $class($conf);
      $tsgrid->prepareQuery();
      //dpm($tsgrid,'grid');
      $tsgrid->getData();
      $tsgrid->buildForm($form, $form_state);
      // is this needed?
      $form['varkey'] = array (
        '#type' => "hidden",
        '#default_value' => $form_state['varkey'],
      );
    } else {
      $form['message'] = array (
        '#markup' => "Could not find class $class",
      );
    }
  }
  
  $form['actions'] = array('#type' => 'actions');
  $form['actions']['submit'] = array(
    '#type' => 'submit',
    '#value' => t('Save'),
    '#weight' => 40,
  );
  
  return $form;
}

function dh_vwwr_sign_form_submit(&$form, &$form_state) {
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  form_load_include($form_state, 'inc', 'dh', 'dh.admin');
  ctools_include('plugins');
  $plugindefs = array(
    array('module'=>'dh', 'type' => 'dh_components', 'groupname'=>'sign_submit', 'name'=>'DHVWWRSignSubmit'),
  );
  foreach ($plugindefs as $plugindef) {
    $groupname = $plugindef['groupname'];
    $conf = isset($form_state['values']['entity_settings'][$groupname]) ? $form_state['values']['entity_settings'][$groupname] : $form_state['conf']['entity_settings'][$groupname];
    $conf['groupname'] = empty($conf['groupname']) ? $groupname : $conf['groupname'];
    ctools_include('plugins');
    $plugin = ctools_get_plugins($plugindef['module'], $plugindef['type'], $plugindef['name']);
    $class = ctools_plugin_get_class($plugin, 'handler');
    if ($class) {  
      $tsgrid = new $class($conf);
      $tsgrid->submitForm($form, $form_state);
    }
  }
}

function dh_vwwr_sign_form_render($subtype, $conf, $panels_args, &$context) {
  $pane = new stdClass();
  $pane->module = 'ctools';
  // This title can/should be overriden in the page manager UI.
  $pane->title = 'Monthly Data Entry Form';
  if (!isset($context->form)) {
    // not really sure what to do here, if anything
  } else {
    // same as above, but perhaps it is relevant?
  }
  //dpm($conf,'conf to dh_vwwr_sign_form_render');
  switch ($conf['entity_settings']['monthly_data']['display_type']) {
    case 'table':
    /*
      $pob = new dhTimeSeriesGroup($conf['entity_settings']['monthly_data']);
      $pob->prepareQuery();
      $pob->getData();
    */
      $pane->content = 'The table view mode is currently disabled for submittal';
    break;
    case 'form':
    default:
      $form_state = array();
      $form_state['conf'] = $conf;
      $elements = drupal_build_form('dh_vwwr_sign_form', $form_state);
      $pane->content = drupal_render($elements);
    break;
  }

  return $pane;
}
?>
