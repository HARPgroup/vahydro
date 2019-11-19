<?php 

/**
 * @file
 * Plugin to provide access control based upon dH AdminREg Contact Record linkage.
 */

/**
 * Plugins are described by creating a $plugin array which will be used
 * by the system that includes this file.
 */
$plugin = array(
  'title' => t('dH Permissions by Contact Record'),
  'description' => t('Checks for specific permissions of a requested entity and logged in user based on a dH Contact record associated with the user account.'),
  'callback' => 'dh_perms_check_user_entity',
  'default' => array('negate' => 0, 'rids' => array()),
  'settings form' => 'dh_perms_check_user_entity_settings',
  'summary' => 'dh_perms_check_user_entity_summary',
  'required context' => new ctools_context_required(t('User'), 'user'),
);

/**
 * Settings form for the 'title hide' access plugin.
 */
function dh_perms_check_user_entity_settings($form, &$form_state, $conf) {
  //select list for all entity types
  $entities = entity_get_info();
  $form['settings']['entity_type'] = array(
    '#title' => t('Entity Type'),
    '#type' => 'select',
    '#description' => t('Type of entity to check user contact record permissions.'),
    '#default_value' => $conf['entity_type'],
    '#options' => array_combine( array_keys($entities) , array_keys($entities) ),
    '#required' => TRUE,
  );
  $form['settings']['entity_id'] = array(
    '#title' => t('Entity ID'),
    '#type' => 'textfield',
    '#description' => t('Entity ID of selected type (tokens allowed).'),
    '#default_value' => $conf['entity_id'],
    '#required' => TRUE,
  );
  $form['settings']['perm_level'] = array(
    '#title' => t('Permission Level'),
    '#type' => 'select',
    '#description' => t('Type of permissions required to access this page.'),
    '#default_value' => $conf['perm_level'],
    '#options' => dh_perms_perm_options(),
    '#required' => TRUE,
  );
  $form['settings']['rids'] = array(
    '#type' => 'checkboxes',
    '#title' => t('Over-ride permissions for the following roles'),
    '#default_value' => $conf['rids'],
    '#options' => ctools_get_roles(),
    '#description' => t('The checked roles will be granted access regardless of the presence of a contact permission.'),
  );
  return $form;
}

/**
 * Provide a summary description.
 */
function dh_perms_check_user_entity_summary($conf, $context) {
  $replacement = array('@keyword' => $conf['keyword']);
  return t('Checks if logged in user has Contact record access.', $replacement);
}

/**
 * Check for access.
 */
function dh_perms_check_user_entity($conf, $context) {
  global $user;
  $entity_id = token_replace($conf['entity_id'], array(), array('clear'=>TRUE));
  $entity_type = $conf['entity_type'];
  $perm_level = $conf['perm_level'];
  if ( intval($perm_level) == 0 ) {
    // if this has been set at full access, just return
    return TRUE;
  }
  $entity_id_cache = array();
  $user_perm_cache = array();
  $perm_text = dh_perms_perm_options($perm_level);
  dh_perms_contact_perms($user->uid, $entity_id, $entity_type, $entity_id_cache, $user_perm_cache);
  //dpm($user_perm_cache[$user->uid], "Perm req'd = $perm_text, Permissions for user $user->uid on $entity_type $entity_id");
  $p = intval($perm_level) & intval($user_perm_cache[$user->uid]['perms']);
  //dpm($p,"intval($perm_level) & intval(" . $user_perm_cache[$user->uid]['perms'] . ")");
  if (isset($user_perm_cache[$user->uid])) {
    if ( intval($perm_level) == $p ) {
      return TRUE;
    }
  }
  return dh_perms_check_role_override($conf, $context);
}

/**
 * Check for access.
 */
function dh_perms_check_role_override($conf, $context) {
  // As far as I know there should always be a context at this point, but this
  // is safe.
  if (empty($context) || empty($context->data) || !isset($context->data->roles)) {
    return FALSE;
  }

  $roles = array_keys($context->data->roles);
  $roles[] = $context->data->uid ? DRUPAL_AUTHENTICATED_RID : DRUPAL_ANONYMOUS_RID;
  
  return (bool) array_intersect($conf['rids'], $roles);
}
?>