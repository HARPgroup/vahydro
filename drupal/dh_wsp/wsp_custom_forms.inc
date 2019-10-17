<?php



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
  $dh_adminreg_feature->save();
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


?>