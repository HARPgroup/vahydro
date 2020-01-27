<?php
module_load_include('module', 'dh_wsp');

function dh_vwuds_contact_form($form, &$form_state, $dh_adminreg_contact = null, $op = 'edit') {
  if ($op == 'clone') {
    $dh_adminreg_contact->name .= ' (cloned)';
    $dh_adminreg_contact->bundle = '';
  }

  if ($op == 'clone') {
    $dh_adminreg_contact->name .= ' (cloned)';
    $dh_adminreg_contact->bundle = '';
  }

  $form['name'] = array(
    '#title' => t('Contact Title'),
    '#type' => 'textfield',
    '#default_value' => $dh_adminreg_contact->name,
    '#description' => t('Title or Position of Contact'),
    '#required' => TRUE,
    '#size' => 30,
  );
  $ftype_options = array(  
    'primary' => t('Primary'),
    'secondary' => t('Secondary'),
  );
  $form['ftype'] = array(
    '#title' => t('Contact Type'),
    '#type' => 'select',
    '#options' => $ftype_options,
    '#default_value' => $dh_adminreg_contact->ftype,
    '#description' => t('Type of Contact for Facility'),
    '#required' => TRUE,
    '#multiple' => FALSE,
  );

  $form['firstname'] = array(
    '#title' => t('First Name'),
    '#type' => 'textfield',
    '#default_value' => $dh_adminreg_contact->firstname,
    '#description' => t('First Name of Contact'),
    '#required' => TRUE,
    '#size' => 30,
  );

  $form['lastname'] = array(
    '#title' => t('Last Name'),
    '#type' => 'textfield',
    '#default_value' => $dh_adminreg_contact->lastname,
    '#description' => t('Last Name of Contact'),
    '#required' => TRUE,
    '#size' => 30,
  );

  $form['phone'] = array(
    '#title' => t('Phone Number'),
    '#type' => 'textfield',
    '#default_value' => $dh_adminreg_contact->phone,
    '#description' => t('Phone Number'),
    '#required' => TRUE,
    '#size' => 30,
  );

  $form['email'] = array(
    '#title' => t('Email Address'),
    '#type' => 'textfield',
    '#default_value' => $dh_adminreg_contact->email,
    '#description' => t('Email Address of Contact'),
    '#required' => TRUE,
    '#size' => 30,
  );

  $form['address1'] = array(
    '#title' => t('Address 1'),
    '#type' => 'textfield',
    '#default_value' => $dh_adminreg_contact->address1,
    '#description' => t('If Address 1 is the same as Facility address, leave blank'),
    '#required' => FALSE,
    '#size' => 30,
  );

  $form['address2'] = array(
    '#title' => t('Address 2'),
    '#type' => 'textfield',
    '#default_value' => $dh_adminreg_contact->address2,
    '#description' => t('If Address 2 is same as Facility address, leave blank'),
    '#required' => FALSE,
    '#size' => 30,
  );

  $form['city'] = array(
    '#title' => t('City or Town'),
    '#type' => 'textfield',
    '#default_value' => $dh_adminreg_contact->city,
    '#description' => t('If City/Town is same as Facility address, leave blank'),
    '#required' => FALSE,
    '#size' => 30,
  );

  $form['state'] = array(
    '#title' => t('State'),
    '#type' => 'textfield',
    '#default_value' => $dh_adminreg_contact->state,
    '#description' => t('If State is same as Facility address, leave blank'),
    '#required' => FALSE,
    '#size' => 30,
  );

  $form['postal_code'] = array(
    '#title' => t('Zip/Postal Code'),
    '#type' => 'textfield',
    '#default_value' => $dh_adminreg_contact->postal_code,
    '#description' => t('If Zip/Postal Code is same as Facility address, leave blank'),
    '#required' => FALSE,
    '#size' => 30,
  );

  if (trim($dh_adminreg_contact->admincode) == '') {
    $dh_adminreg_contact->admincode = str_replace(' ', '_', strtolower($dh_adminreg_contact->name ));
  }
  $form['admincode'] = array(
    '#title' => t('AdminCode'),
    '#type' => 'hidden',
    '#default_value' => $dh_adminreg_contact->admincode,
    '#description' => t('The unique identifier used by the originating agency of this dH Feature type.'),
    '#required' => FALSE,
    '#size' => 30,
  );

  // Machine-readable type name.
  $form['bundle'] = array(
    '#type' => 'hidden',
    '#default_value' => 'dh_adminreg_contact',
    '#maxlength' => 32,
    '#attributes' => array('disabled' => 'disabled'),
    '#machine_name' => array(
      'exists' => 'dh_adminreg_contact_get_types',
      'source' => array('label'),
    ),
    '#description' => t('A unique machine-readable name for this model type. It must only contain lowercase letters, numbers, and underscores.'),
  );

  field_attach_form('dh_adminreg_contact', $dh_adminreg_contact, $form, $form_state);
  $hiddens = array('dh_link_admin_dhac_usafips');
  //$hiddens = array('dh_link_admin_dhac_usafips', 'dh_link_admin_contact', 'dh_link_feature_contact');
  dpm($form['dh_link_feature_contact'],"feature");
  $form['dh_link_admin_contact']['und']['#title'] = 'Link Contact Record to Organization';
  $form['dh_link_admin_contact']['und']['#description'] = 'Note: linking this Contact to an Organization gives permission to the Target User to edit ALL associated Facilities under that Organization';
  $form['dh_link_feature_contact']['und']['#title'] = 'Link Contact Record to Facility';
  foreach ($hiddens as $hidethis) {
    if (isset($form[$hidethis])) {
      $form[$hidethis]['#type'] = 'hidden';
    }
  }
  
  
  $form['data']['#tree'] = TRUE;
  $form['actions'] = array('#type' => 'actions');
  $form['actions']['submit'] = array(
    '#type' => 'submit',
    '#value' => t('Save Contact'),
    '#weight' => 40,
  );
  $form['actions']['cancel'] = array(
    '#type' => 'submit',
    '#value' => t('Cancel'),
    '#weight' => 45,
    '#limit_validation_errors' => array(),
    '#submit' => array('dh_vwuds_contact_form_submit_cancel')
  );
  if ($op <> 'add') {
    $form['actions']['delete'] = array(
      '#type' => 'submit',
      '#value' => t('Delete Contact'),
      '#weight' => 45,
      '#limit_validation_errors' => array(),
      '#submit' => array('dh_vwuds_contact_form_submit_delete')
    );
  }
  return $form;
}

function dh_vwuds_contact_form_submit_cancel($form, &$form_state) {
  // just hoor the destination parameter
}

/**
 * Form API submit callback for the type form.
 */
function dh_vwuds_contact_form_submit(&$form, &$form_state) {
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  form_load_include($form_state, 'inc', 'dh', 'dh.admin');
  $dh_adminreg_contact = entity_ui_form_submit_build_entity($form, $form_state);
  $dh_adminreg_contact->save();
}

/**
 * Form API submit callback for the delete button.
 */

function dh_vwuds_contact_form_submit_delete(&$form, &$form_state) {
  $dh_adminreg_contact = entity_ui_form_submit_build_entity($form, $form_state);
  $pg = $_GET['destination'];
  unset($_GET['destination']);
  drupal_goto(
    'admin/content/dh_adminreg_contact/manage/' . $dh_adminreg_contact->contactid . '/delete',
    array('query' => array(
      'destination' => $pg
      )
    )  
  );
}

global $user;
$op = 'add';
$a = arg();
$facid = $a[1];
$cid = $a[2];
if (($cid <> 'add') and ($cid > 0)) {
  $result = entity_load('dh_adminreg_contact', array($cid));
  $dh_adminreg_contact = $result[$cid];
  $op = 'edit';
} else {
  $dh_adminreg_contact = entity_create('dh_adminreg_contact', 
    array(
      'bundle' => 'dh_adminreg_contact',
      'dh_link_feature_contact' => array('und' => array( 0 => array('target_id' => $facid) )),
    )
  );
}
if (is_object($dh_adminreg_contact)) {
  $form_state = array();
  $form_state['wrapper_callback'] = 'entity_ui_main_form_defaults';
  $form_state['entity_type'] = 'dh_adminreg_contact';
  $form_state['bundle'] = 'dh_adminreg_contact';
  $form_state['values']['name'] = 'New Contact';
  form_load_include($form_state, 'inc', 'entity', 'includes/entity.ui');
  // set things before initial form_state build
  $form_state['build_info']['args'] = array($dh_adminreg_contact, $op, 'dh_adminreg_contact');

  // **********************
  // Load the form
  // **********************
  $elements = drupal_build_form('dh_vwuds_contact_form', $form_state);
  $form = drupal_render($elements);
  echo $form;
}
?>