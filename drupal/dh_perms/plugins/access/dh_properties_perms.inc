<?php 

$plugin = array(
  'title' => t('dH Properties'),
  'description' => t('Loads a specified property for an entity (if it exists) and tests visibility based on propcode or propvalue.'),
  'callback' => 'dh_properties_prop_check',
  'default' => array('negate' => 0),
  'summary' => 'dh_properties_prop_check_summary',
  'settings form' => 'dh_properties_prop_check_settings',
  'required context' => array(),
);

/**
 * Settings form for the 'title hide' access plugin.
 */
function dh_properties_prop_check_settings($form, &$form_state, $conf) {
  //error_log("Showing the entity selector");
  $entities = entity_get_info();
  $form['settings']['entity_type'] = array(
    '#title' => t('Entity Type'),
    '#type' => 'select',
    '#options' => array_combine( array_keys($entities) , array_keys($entities) ),
    '#default_value' => !empty($conf['entity_type']) ? $conf['entity_type'] : '',
    '#description' => t('Entity Type'),
    '#required' => TRUE,
  );
  $form['settings']['featureid'] = array(
    '#title' => t('Feature IDs'),
    '#type' => 'textfield',
    '#default_value' => (strlen($conf['featureid']) > 0) ? $conf['featureid'] : NULL,
    '#description' => t('What entity id to retrieve TS values for.'),
    '#size' => 30,
    '#required' => FALSE,
  );  
  $conditions = array();
  $options = dh_vardef_vocab_options(TRUE);
  $form['settings']['vocabulary'] = array(
    '#title' => t('Vocabulary'),
    '#type' => 'select',
    '#options' => $options,
    '#default_value' => (count($conf['vocabulary']) > 0) ? $conf['vocabulary'] : NULL,
    '#description' => t('What vocabulary to retrieve variables for - must save and re-open to update variable list.'),
    '#size' => 5,
    '#multiple' => TRUE,
    '#required' => FALSE,
  );
  $conditions = array();
  if (count($conf['vocabulary']) > 0) {
    $vocab_clause = "vocabulary in ( '" . implode("', '", $conf['vocabulary']) . "')";
    //dpm($vocab_clause, "Vocab Clause");
    $conditions = array($vocab_clause);
  }
  $options = dh_vardef_varselect_options($conditions, 'varkey');
  $form['settings']['varkey'] = array(
    '#title' => t('Variable'),
    '#type' => 'select',
    '#options' => $options,
    '#default_value' => (count($conf['varkey']) > 0) ? $conf['varkey'] : NULL,
    '#description' => t('What varkey to retrieve TS values for.'),
    '#size' => 1,
    '#multiple' => FALSE,
    '#required' => FALSE,
    '#prefix' => "<div id='update-varkey-options'>",
    '#suffix' => '</div>',
  );
  $form['settings']['enable_propvalue'] = array(
    '#title' => t('Check'),
    '#prefix' => '<table><tr><td>',
    '#type' => 'checkbox',
    '#default_value' => $conf['enable_propvalue'],
    '#required' => FALSE,
    '#suffix' => '</td>',
  );
  $form['settings']['propvalue'] = array(
    '#prefix' => '<td>',
    '#title' => t('Propvalue'),
    '#type' => 'textfield',
    '#description' => t('Propvalue field will be searched for entered number.'),
    '#default_value' => $conf['propvalue'],
    '#required' => FALSE,
    '#suffix' => '</td></tr></table>',
  );
  $form['settings']['enable_propcode'] = array(
    '#title' => t('Check'),
    '#prefix' => '<table><tr><td>',
    '#type' => 'checkbox',
    '#default_value' => $conf['enable_propcode'],
    '#required' => FALSE,
    '#suffix' => '</td>',
  );
  $form['settings']['propcode'] = array(
    '#title' => t('Propcode'),
    '#type' => 'textfield',
    '#prefix' => '<td>',
    '#description' => t('Propcode field will be searched for entered string.'),
    '#default_value' => $conf['propcode'],
    '#required' => FALSE,
    '#suffix' => '</td></tr></table>',
  );

  return $form;
}

/**
 * Provide a summary description.
 */
function dh_properties_prop_check_summary($conf, $context) {
  $replacement = array(
    '@propvalue' => $conf['propvalue'],
    '@propcode' => $conf['propcode'],
  );
  return t('Checks if propvalue = "@propvalue, propcode = @propcode".', $replacement);
}

/**
 * Check for access.
 */
function dh_properties_prop_check($conf, $context) {
  $a = arg();
  // replace tokens
  // query for a matching property
  // check the criteria if it exists
  $conf['featureid'] = token_replace($conf['featureid']);
  $conf['propvalue'] = token_replace($conf['propvalue']);
  $conf['propcode'] = token_replace($conf['propcode']);
  if (!$conf['enable_propcode']) {
    unset($conf['propcode']);
  }
  if (!$conf['enable_propvalue']) {
    unset($conf['propvalue']);
  }
  $pids = dh_get_properties($conf, 'props_singular');
  if (count($pids) > 0) {
    if (count($pids) > 1) {
      watchdog('dh', 'dh_properties_prop_check returned multiple matches. Using first one.', WATCHDOG_WARNING);
    }
    return TRUE;
  }
  return FALSE;
}
?>