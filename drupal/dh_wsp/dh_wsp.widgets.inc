<?php

module_load_include('inc', 'dh', 'plugins/dh.display');

class EntityGroupConfiguratorPluggable extends EntityGroupConfigurator {
  var $efq;
  var $base_entity_type;
  var $base_bundle;
  var $base_form_id;
  var $property_conf_default = array();
  var $entity_defaults = array();
  var $conf;
  var $destination;
  var $headers;
  var $action = 'edit';
  var $form_columns;
  var $data;
  var $id;
  var $start = 0;
  var $limit = 25;
  var $entity_info;
  var $entity_tokens = array();
  var $row_tokens = array();
  var $query = FALSE;
  var $save_method = 'default';
  var $groupname = 'default_group';
  var $group_title = 'Grouped Entity';
  var $group_description = 'Grouped Description';
  
  function __construct($conf) {
    $this->conf = $conf;
    $this->optionDefaults();
    $this->entityDefaults();
    $this->data = array();
    $this->id = array();
    $this->base_entity_type = isset($conf['entity_type']) ? $conf['entity_type'] : $this->base_entity_type;
    $this->base_bundle = isset($conf['display']['bundle']) ? $conf['display']['bundle'] : NULL;
    $this->destination = isset($conf['destination']) ? $conf['destination'] : NULL;
    $this->base_form_id = isset($conf['form_id']) ? $conf['form_id'] : NULL;
    $this->form_columns = isset($conf['form_columns']) ? $conf['form_columns'] : $this->entity_defaults['form_columns'];
    $this->add = isset($conf['add']) ? $conf['add'] : 0;
    $this->entity_info = entity_get_info($this->base_entity_type);
    $this->applySettings();
  }
  
  function submitForm(array &$form, $form_state) {
    $this->applyEntityTokens();
    $this->applySettings();
    // identify records that this is supposed to handle
      // main form field name $this->groupname, i.e. ts_group
    // iterate through, do updates for those with PKID, inserts for those with NULL PKID
    if ($this->save_method == 'form_entity_map') {
      $this->SubmitFormEntityMap($form, $form_state);
    } else {
      $this->SubmitFormCustom($form, $form_state);
    }
  }
  function SubmitFormCustom(array &$form, $form_state) {
    foreach ($form_state['values'][$this->groupname] as $record_group) {
      //dpm($record_group,"Record Group");
    }
  }
  
  public function FormEntityMap(&$form_entity_map = array(), $row = array()) {
  }
  
  public function entity_save($entity_type, $e) {
    // children classes can do any pre-save mods here 
    entity_save($entity_type, $e);
  }
  
  function SubmitFormEntityMap(array &$form, $form_state) {
    // uses entity_map to handle all inserts and updates
    foreach ($form_state['values'][$this->groupname] as $record_group) {
      //dpm($record_group, 'handling record group');
      $form_entity_map = array();
      // set up defaults
      $this->FormEntityMap($form_entity_map, $record_group);
      foreach ($form_entity_map as $config) {
        $values = array();
        if (!isset($config['bundle'])) {
          $config['bundle'] = null;
        }
        $entity_type = $config['entity_type'];
        $bundle = $config['bundle'];
        // is this an edit or insert?
        // load the key
        $pk = $this->HandleFormMap($config['entity_key'], $record_group);
        // load the values array
        $values = array();
        foreach ($config['fields'] as $key => $map) {
          if ($map['value_src_type']) {
            $values[$key] = $this->HandleFormMap($map, $record_group);
          } else {
            // @todo - throw an error or alert about malformed entry
          }
        }
        if ($pk) {
          // PK set, so this is an update
          $e = entity_load_single($entity_type, $pk);
          foreach ($values as $key => $val) {
            $e->{$key} = $val;
          }
        } else {
          // no PK set, so this is an insert
          $values['bundle'] = $bundle;
          $e = entity_create($entity_type, $values);
        }
        if ($e) {
          //dpm($e,'entity to save');
          $this->entity_save($entity_type, $e);
        }
      }
    }
  }
    
  public function HandleFormMap($map, $data) {
    // returns value or FALSE if not handled
    //dpm($map, "Handling map");
    //dpm($data, "Data");
    switch($map['value_src_type']) {
      case 'form_key':
        $value = $this->HandleFormMap_form_key($map, $data);
      break;
      case 'constant':
        $value = $this->HandleFormMap_constant($map, $data);
      break;
      case 'env':
        $value = $this->HandleFormMap_env($map, $data);
      break;
    }
    return $value;
  }
  
  public function HandleFormMap_form_key($map, $data) {
    $key = $map['value_val_key'];
    if (isset($data[$key])) {
      if (isset($map['concat'])) {
        $value = implode($map['concat'], $data[$key]);
      } else {
        $value = $data[$key];
      }
    } else {
      return FALSE;
    }
    return $value;
  }
  
  public function HandleFormMap_constant($map, $data) {
    return $map['value_val_key'];
  }
  
  public function HandleFormMap_env($map, $data) {
    // @todo - log a message about missing env
    return $this->env[$map['value_val_key']];
  }
  
  public function validateForm(array &$form, $form_state) {
    drupal_validate_form($this->getFormId, $form, $form_state);
  }
  
  function getData() {
    if (!is_object($this->efq) and !($this->action == 'add')) {
      // throw exception un-prepared query
      return FALSE;
    }
    if ($this->action == 'add') {
      $this->data = array(
        entity_create($this->base_entity_type, array('bundle'=>$this->base_bundle))
      );
    } else {
      $result = $this->efq->execute();
      //drupal_set_message("efq: <pre>" . print_r($result ,1) . "</pre>");
      if (isset($result[$this->base_entity_type])) {
        $this->data = entity_load($this->base_entity_type, array_keys($result[$this->base_entity_type]));
      }
      //dpm($this->data, "Data");
      // now need to take this list of entity ids and return it as a proper dataset.
      // this is where certain sub-classes may want to override this method and use a straight query if it is more economical
    }
  }
  
  public function applySettings() {
    // add extras to fields to display
    foreach (array_keys($this->conf['display']['properties']) as $field_key) {
      if (!in_array($field_key, array('addlink','deletelink','editlink'))) {
        //dpm($this->conf['display']['properties'][$field_key], "conf for $field_key");
        if (!isset($this->conf['display']['properties'][$field_key])) {
          if (isset($this->property_conf_default[$field_key])) {
            $this->conf['display']['properties'][$field_key] = $this->property_conf_default[$field_key];
          }
        }
        //dpm($this->conf['display']['properties'][$field_key], "after default check for $field_key");
        $this->conf['display']['properties'][$field_key]['hidden'] = !isset($this->conf['display']['properties'][$field_key]['hidden']) ? FALSE : $this->conf['display']['properties'][$field_key]['hidden'];
        if (!$this->conf['display']['properties'][$field_key]['hidden'] ) {
          // add it to form_columns if it does not exist
          if (!in_array($field_key,$this->form_columns)) {
            $this->form_columns[] = $field_key;
          }
        }
      }
    }
    foreach (array_keys($this->conf['display']['fields']) as $field_key) {
      if (!$this->conf['display']['fields'][$field_key]['hidden']) {
        // add it to form_columns if it does not exist
        if (!in_array($field_key,$this->form_columns)) {
          $this->form_columns[] = $field_key;
        }
      }
    }
    // now add the special ones
    $this->form_columns[] = 'deletelink';
    $this->form_columns[] = 'editlink';
  }
  
  public function applyRowTokens($text, $row) {
    foreach ($this->row_tokens as $token) {
      if (property_exists($row, $token)) {
        $tokens["[$token]"] = $row->$token;
      }
    }
    return strtr($text, (array)$tokens);
  }
  
  public function applyEntityTokens() {
    $row_token_keys = array('default');
    // apply entity tokens
    foreach ($this->entity_tokens as $token) {
      if (property_exists($this, $token)) {
        $val = token_replace($this->conf[$token], array(), array('clear'=>TRUE));
        $this->conf[$token] = $val;
      }
    }
    // apply row tokens if requested
    foreach ($this->row_tokens as $token) {
      foreach ($row_token_keys as $key) {
        if (isset($this->conf['display']['properties'][$token][$key])) {
          $val = token_replace($this->conf['display']['properties'][$token][$key], array(), array('clear'=>TRUE));
          $this->conf['display']['properties'][$token][$key] = $val;
        }
        if (isset($this->conf['display']['fields'][$token][$key])) {
          $val = token_replace($this->conf['display']['fields'][$token][$key], array(), array('clear'=>TRUE));
          $this->conf['display']['fields'][$token][$key] = $val;
        }
      }
    }
  }
  
  function prepareQuery() {
    $this->applyEntityTokens();
    $this->applySettings();
    // children can call this parent method and then add additional
    // EFQ conditions if more sophisticated behavior is desired
    if (!strlen($this->base_entity_type)) {
      return FALSE;
    }
    $einfo = $this->entity_info;
    if (!isset($einfo['entity keys']['id'])) {
      // throw malformed entity exception and return
      return FALSE;
    }
    if ($this->conf['id'] == 'add') {
      if (empty($this->base_bundle)) {
        return FALSE;
      } else {
        $this->action = 'add';
      }
    } else { 
      $this->efq = new EntityFieldQuery;
      $this->efq->entityCondition('entity_type', $this->base_entity_type);
      $this->efq->range($this->start, $this->limit);
      if (!empty($this->conf['id'])) {
        $this->efq->propertyCondition($einfo['entity keys']['id'], $this->conf['id'], '=');
        //drupal_set_message("Arg: '$argument'");
      }
      if (!empty($this->base_bundle)) {
        $binfo = field_info_instances($this->base_entity_type, $this->base_bundle);
        foreach (array_keys((array)$binfo) as $field) {
          if (property_exists($this,$field)) {
            if (!empty($this->$field)) {
              $this->efq->fieldCondition($field,NULL,$this->$field);
            }
          }
        }
      }
      foreach ($einfo['property info'] as $prop) {
        //dpm($prop, "prop");
        if (property_exists($this,$prop)) {
          if (!empty($this->$prop)) {
            //dpm($this->$prop, "prop exists");
            $this->efq->propertyCondition($prop,$this->$prop);
          }
        }
      }
      //dpm($this->efq, "Final EFQ");
    }
    return TRUE;
  }
  
  public function buildOptionsForm(&$form, $form_state) {
    $this->entity_info = entity_get_info($this->base_entity_type);
    $this->entityOptions($form, $form_state);
    $this->propertyOptions($form, $form_state);
    $this->fieldOptions($form, $form_state);
    $this->extraOptions($form, $form_state);
  }
  
  public function extraOptions(&$form, $form_state) {
    
  }
  
  public function optionDefaults() {
    $this->property_conf_default = array();
  }
  
  public function entityDefaults() {
    // get default list and order of form columns from blank form
    // HEADERS - sets 
    $this->env = array(
      'now' => date('r'),
      'epoch' => date('U'),
    );
    $this->headerDefaults();
  }
  
  public function headerDefaults() {
    $this->entity_defaults['headers'] = array();
    // get default list and order of form columns from blank form
    $blank_form_row = array();
    $this->formRowDefaults($blank_form_row, new StdClass);
    // set form_columns - control WHAT is included (not visibility), and the ORDER
    $this->entity_defaults['form_columns'] = array_keys($blank_form_row);
    //dpm($this->entity_defaults,'defs');
    // now, we must set headers up here because we do not have a config view 
    foreach ($blank_form_row as $col => $formfield) {
      $this->conf['display']['properties'][$col]['title'] = isset($formfield['#coltitle']) ? $formfield['#coltitle'] : '';
      $this->entity_defaults['headers'][$col] = isset($formfield['#coltitle']) ? $formfield['#coltitle'] : '';
      if (isset($formfield['#type']) and $formfield['#type'] == 'hidden') {
        $this->conf['display']['properties'][$col]['hidden'] = 1;
        $this->entity_defaults['headers'][$col] = '';
      }
    }
  }
  
  public function entityOptions(&$form, $form_state) {
    if (!isset($form['entity_settings'])) {
      $form['entity_settings'] = array(
      );
    }
    if (!isset($form['entity_settings'][$this->groupname])) {
      $form['entity_settings'][$this->groupname] = array(
        '#type' => 'fieldset',
        '#tree' => TRUE,
        '#title' => $this->group_title,
        '#collapsible' => TRUE,
        '#collapsed' => FALSE,
        '#description' => $this->group_description,
      );
    }
    $form['entity_settings'][$this->groupname]['entity_type'] = array(
      '#type' => 'hidden',
      '#default_value' => $this->base_entity_type,
      '#required' => TRUE,
    );
    $form['entity_settings'][$this->groupname]['display'] = array(
      '#type' => 'fieldset',
      '#tree' => TRUE,
      '#title' => 'Entity Field & Properties Info',
      '#collapsible' => TRUE,
      '#collapsed' => FALSE,
      '#prefix' => "<div id='update-display-options'>",
      '#suffix' => "</div>",
      '#description' => 'Entity Field & Properties Info',
    );
    if ($this->base_entity_type) {
      $entity_info = $this->entity_info;
      $bundle_options = array_combine( array_keys($entity_info['bundles']) , array_keys($entity_info['bundles']) );
    } else {
      $bundle_options = array();
    }
    $form['entity_settings'][$this->groupname]['display']['bundle'] = array(
      '#title' => t('Entity bundle'),
      '#type' => 'select',
      '#options' => $bundle_options,
      '#description' => t('Entity bundle'),
      '#required' => TRUE,
    // TODO - allow certain types of bundle fields (short text, select, numeric) in table
      //'#ajax' => array(
      //  'callback' => 'entity_pane_form_fields_update',
      //  'wrapper' => 'update-field-options',
      //),
    );
    // only set this if we have a match, otherwise, we have switched entities, or are a new form
    // either of which should show an un-selected list
    if ( in_array($this->base_bundle, $bundle_options) ) {
      $form['entity_settings'][$this->groupname]['display']['bundle']['#default_value'] = $this->base_bundle;
      $form['entity_settings'][$this->groupname]['display']['bundle']['#value'];
    } else {
      unset($form['entity_settings'][$this->groupname]['display']['bundle']['#default_value']);
      unset($form['entity_settings'][$this->groupname]['display']['bundle']['#value']);
    }
  }
  
  public function formRowVisibility(&$rowform, $row) {
    // sub-classes that implement full visibility control will override this method
    parent::formRowVisibility($rowform, $row);
  }
  
  public function formRowDefaults(&$rowform, $row) {
    // load a default from the entity's own form, or other if requested
    parent::formRowDefaults($rowform, $row);
  }
  
  public function fieldOptions(&$form, $form_state) {
    $form['entity_settings'][$this->groupname]['display']['fields'] = $this->fieldElements();
  }
  
  public function fieldElements() {
    $element = array(
      '#tree' => TRUE,
      '#prefix' => "<div id='update-field-options'>",
      '#suffix' => "</div>",
    );
    $form_fields_conf = $this->conf['display']['fields'];
    $fields = array();
    $fields_conf = array();
    foreach ($form_fields_conf as $thisconf) {
      $fields_conf[$thisconf['name']] = $thisconf;
    }
    $element[] = array(
      '#markup' => "<table>",
    );
    $element[] = $this->fields_header();
    if (isset($this->base_entity_type) and isset($this->base_bundle)) {
      $fields = field_info_instances($this->base_entity_type, $this->base_bundle);
    }
    foreach ($fields as $fieldkey => $settings) {
      $field_conf = isset($fields_conf[$fieldkey]) ? $fields_conf[$fieldkey] : array(
        'name' => $fieldkey, 
        'description' => $settings['description'], 
        'default' => $settings['default_value'], 
        'title' => $settings['title'], 
        'hidden' => ($settings['display']['default']['type'] == 'hidden') ? 1 : 0,
      );
      $hidden = array(0 => t('FALSE'), 1 => t('TRUE'));
      $line = array(
        'name' =>  array(
          '#type' => 'textfield',
          '#disabled' => TRUE,
          '#value' => $field_conf['name'],
          '#size' => '12',
        ),
        'hidden' =>  array(
          '#type' => 'select',
          '#default_value' => isset($field_conf['hidden']) ? $field_conf['hidden'] : 0,
          '#options' => $hidden,
        ),
        'default' =>  array(
          '#default_value' => isset($field_conf['default']) ? $field_conf['default'] : NULL,
          '#type' => 'textfield',
          '#size' => '12',
        ),
        'title' =>  array(
          '#default_value' => isset($field_conf['title']) ? $field_conf['title'] : NULL,
          '#type' => 'textfield',
          '#size' => '12',
        ),
        'description' =>  array(
          '#type' => 'textfield',
          '#default_value' => isset($field_conf['description']) ? $field_conf['description'] : NULL,
          '#size' => '24',
        )
      );
      $this->tabularize($line);
      $element[$fieldkey] = $line;
    }
    $element[] = array(
      '#markup' => "</table>",
    );
    //drupal_set_message("element : <pre> " . print_r($element,1) . "</pre>");
    return $element;
  }
  
  public function propertyOptions(&$form, $form_state) {
    $form['entity_settings'][$this->groupname]['display']['properties'] = $this->propertyElements();
  }
  
  public function propertyElements() {
    $element = array(
      '#tree' => TRUE,
    );
    $form_prop_conf = isset($this->conf['display']['properties']) ? $this->conf['display']['properties'] : $this->property_conf_default;
    //dpm($form_prop_conf, "Props conf");
    $properties_conf = array();
    foreach ($form_prop_conf as $thisconf) {
      $properties_conf[$thisconf['name']] = $thisconf;
    }
    // add any mandated by class setting
    //dpm($this->property_conf_default, 'adding mandated');
    foreach ($this->property_conf_default as $thisconf) {
      //dpm($thisconf['name'], "adding");
      if (!isset($properties_conf[$thisconf['name']])) {
        $properties_conf[$thisconf['name']] = $thisconf;
      }
    }
    $element[] = array(
      '#markup' => "<table>",
    );
    //dpm($properties_conf, "properties to add to entity_get_property_info");
    $element[] = $this->properties_header();
    if (isset($this->base_entity_type)) {
      //$properties = array_merge($properties_conf, entity_get_property_info($this->base_entity_type)['properties']);
      $properties = $properties_conf + entity_get_property_info($this->base_entity_type)['properties'];
    } else {
      drupal_set_message("No base entity type set");
    }
    //dpm($properties, "fnal properties to config");
    foreach ($properties as $propkey => $settings) {
      //drupal_set_message("Property conf: " . print_r($settings,1));
      $property_conf = isset($properties_conf[$propkey]) ? $properties_conf[$propkey] : array('name' => $propkey, 'description' => $settings['description']);
      $hidden = array(0 => t('FALSE'), 1 => t('TRUE'));
      //dpm($property_conf, "Conf");
      if (!isset($property_conf['no_config'])) {
        $line = array(
          'name' =>  array(
            '#type' => 'textfield',
            '#disabled' => TRUE,
            '#value' => $property_conf['name'],
            '#value' => $property_conf['name'],
            '#size' => '12',
          ),
          'hidden' =>  array(
            '#type' => 'select',
            '#default_value' => isset($property_conf['hidden']) ? $property_conf['hidden'] : 0,
            '#options' => $hidden,
          ),
          'default' =>  array(
            '#default_value' => isset($property_conf['default']) ? $property_conf['default'] : NULL,
            '#type' => 'textfield',
            '#size' => '12',
          ),
          'title' =>  array(
            '#default_value' => isset($property_conf['title']) ? $property_conf['title'] : NULL,
            '#type' => 'textfield',
            '#size' => '12',
          ),
          'description' =>  array(
            '#type' => 'textfield',
            '#default_value' => isset($property_conf['description']) ? $property_conf['description'] : NULL,
            '#size' => '24',
          )
        );
        $this->tabularize($line);
        $element[$propkey] = $line;
      }
    }
    $element[] = array(
      '#markup' => "</table>",
    );
    //drupal_set_message("element : <pre> " . print_r($element,1) . "</pre>");
    return $element;
  }
  
  function fields_header() {
    // for now these have the same headers
    $this->properties_header();
  }
  function properties_header() {
    $line = array(
      'name' =>  array(
        '#markup' => "Name",
      ),
      'hidden' =>  array(
        '#markup' => "Hidden",
        '#description' => t('Controls visibility - invisible fields may still use tokens to change settings.'),
      ),
      'default' =>  array(
        '#markup' => "Default (token allowed)",
      ),
      'title' =>  array(
        '#markup' => "Title",
      ),
      'description' =>  array(
        '#markup' => "Description",
      )
    );
    $this->tabularize($line);
    return $line;
  }

  
  public function buildForm(&$form, &$form_state) {
    // commenting this out since prepareQuery() should be called before this
    // which already calls applyEntityTokens and applySettings
    // and it may over-ride some of these if we have uipdated them later
    //$this->applyEntityTokens();
    //$this->applySettings();
    //dpm($this, 'buildform called');
    $element = array(
      '#tree' => TRUE,
      '#type' => '#fieldset',
    );
    $element[] = array(
      '#markup' => "<table>",
    );
    if (strlen($this->conf['destination']) > 0) {
      $form_state['redirect'] = $this->conf['destination'];
    }
    $i = 1;
    foreach ($this->data as $row) {
      $line = array();
      $this->renderFormRow($form, $form_state, $line, $row);
      if ($i == 1) {
        $header = array();
        $this->formHeader($header, $row);
        $this->tabularize($header, 'header');
        $element[] = $header;
      }
      $oe = ($i&1) ? 'odd' : 'even';
      $this->tabularize($line, $oe);
      $element[] = $line;
      $i++;
    }
    $element[] = array(
      '#markup' => "</table>",
    );
    $form[$this->groupname] = $element;
  }
  
  public function viewTable() {
    // this base class does nothing but show rows in this->data, all data pop will be done by sub-classes.
    $this->applyEntityTokens();
    $this->applySettings();
    $rows = array();
    $header = array();
    $this->renderHeader($header);
    // assemble header in the row loop
    $i = 1;
    foreach ($this->data as $row) {
      $line = array();
      $this->renderRow($line, $row);
      $rows[] = $line;
      $i++;
    }
    return theme('table', array('header' => $header, 'rows' => $rows));
  }
  
  public function addFormActions(&$form, $form_state) {
    $form['actions'] = array('#type' => 'actions');
    $form['actions']['submit'] = array(
      '#type' => 'submit',
      '#value' => t('Save '),
      '#weight' => 40,
    );
    switch ($op) {
      case 'add':
      $form['actions']['cancel'] = array(
        '#type' => 'submit',
        '#value' => t('Cancel'),
        '#weight' => 45,
        '#limit_validation_errors' => array(),
        '#submit' => array('test_formapi_form_submit_cancel')
      );
      break;
      case 'edit':
      $form['actions']['delete'] = array(
        '#type' => 'submit',
        '#value' => t('Delete type'),
        '#weight' => 45,
        '#limit_validation_errors' => array(),
        '#submit' => array('test_formapi_form_submit_delete')
      );
      break;
    }
  }
  
  /* ****************************************
  //  Render - Read Only Modes 
  //   table - all visible row properties get a column, # rows = number of visible cols
  //   2-column - variable name is in 1 column, all others in 2nd column, with delimiter
  //   unformatted - all in single column, with delimiter
  //   flex-column - formRowDefaults array has attribute #display_column for grouping output
  //     used primarily by plugin renderers, but could also be included in interface 
  // ****************************************
  */
  
  function renderHeader(&$header) {
    // header for table view (not edit)
    switch($this->render_layout) {
      case 'unformatted':
        $this->renderHeaderUnformatted($header);
      break;
      case 'table':
      default:
        $this->renderHeaderTable($header);
      break;
    }
  }
  
  function renderHeaderTable(&$header) {
    foreach ($this->form_columns as $colname) {
      if (isset($this->conf['display']['properties'][$colname])) {
        $header[$colname] = $this->conf['display']['properties'][$colname]['title'];
        if (($this->conf['display']['properties'][$colname]['hidden'] == 1)) {
          unset($header[$colname]);
        } 
      }
      if (isset($this->conf['display']['fields'][$colname])) {
        $header[$colname] = $this->conf['display']['fields'][$colname]['title'];
        if (($this->conf['display']['fields'][$colname]['hidden'] == 1)) {
          unset($header[$colname]);
        }
      }
    }
  }
  
  function renderHeaderUnformatted(&$header) {
    $headerline = '';
    $elements = array();
    foreach ($this->form_columns as $colname) {
      if (isset($this->conf['display']['properties'][$colname])) {
        $elements[$colname] = $this->conf['display']['properties'][$colname]['title'];
        if (($this->conf['display']['properties'][$colname]['hidden'] == 1)) {
          unset($elements[$colname]);
        } 
      }
      if (isset($this->conf['display']['fields'][$colname])) {
        $elements[$colname] = $this->conf['display']['fields'][$colname]['title'];
        if (($this->conf['display']['fields'][$colname]['hidden'] == 1)) {
          unset($elements[$colname]);
        }
      }
    }
    $header = array(implode($this->delimiter, $elements));
  }
  
  public function renderRow(&$line, &$row) {
    // default method to render a row simply creates a markup entry
    // we could later default to using whatever the default form element for this column is
    // form_id = entity_type + _form
    // sub-classes can choose to use the default form elements or to render their own here
    //dpm($this->form_columns,'form cols');   
        
    foreach ($this->form_columns as $colname) {
      if (isset($this->conf['display']['properties'][$colname])) {
        if (property_exists($row, $colname)) { 
          $line[$colname] = $row->$colname;
        }
        if (($this->conf['display']['properties'][$colname]['hidden'] == 1)) {
          unset($line[$colname]);
        }
      }
      
      if (isset($this->conf['display']['fields'][$colname])) {
        // @todo need to add code to handle fields properly
        //   field_info_field to get language
        //   field_info_field to get value field
        if (property_exists($row, $colname)) { 
          foreach ($row->$colname as $lang => $vals) {
            foreach ($row->$colname[$lang] as $key => $val) {
              $line[$colname] .= $row->$colname[$lang][$key]['value'] . ' ';
            }
          }
          if (($this->conf['display']['fields'][$colname]['hidden'] == 1)) {
            unset($line[$colname]);
          }
        }
      }
    }
  }
  
  function formHeader(&$header, $row) {
    //dpm($this->form_columns,'form cols at row header format');
    // renders tabular form headers in same order as colnames
    foreach ($this->form_columns as $colname) {
      if (isset($this->conf['display']['properties'][$colname])) {
        $header[$colname] = array(
          '#markup' => $this->conf['display']['properties'][$colname]['title']
        );
        if (($this->conf['display']['properties'][$colname]['hidden'] == 1)) {
          $header[$colname]['#hidden'] = TRUE;
          unset($header[$colname]['#markup']);
          //dpm(1,"hiding $colname");
        }
      }
      if (isset($this->conf['display']['fields'][$colname])) {
        $header[$colname] = array(
          '#markup' => $this->conf['display']['fields'][$colname]['title']
        );
        if (($this->conf['display']['fields'][$colname]['hidden'] == 1)) {
          $header[$colname]['#hidden'] = TRUE;
          unset($header[$colname]['#markup']);
        }
      }
    }
  }
  
  function tabularize(&$line, $oe = 'odd') {
    if ($oe == 'header') {
      $oe = 'even';
      $tr_pre = '<thead>';
      $tr_suf = '</thead>';
      $tag = 'th';
    } else {
      $tag = 'td';
      $tr_pre = '';
      $tr_suf = '';
    }
    // works only for a form entity
    $i = 0;
    foreach (array_keys($line) as $key) {
      if (isset($line[$key]['#type']) and ($line[$key]['#type'] == 'hidden') ) {
        $style = 'style=\"display:none;\"';
      } else {
        $style = '';
      }
      $line[$key]['#suffix'] = isset($line[$key]['#suffix']) ? $line[$key]['#suffix'] : '';
      $line[$key]['#prefix'] = isset($line[$key]['#prefix']) ? $line[$key]['#prefix'] : '';
      switch ($i) {
        case 0:
          $line[$key]['#prefix'] = "$tr_pre<tr class='tablefield-row-0 $oe'><$tag $style>" . $line[$key]['#prefix'];
          $line[$key]['#suffix'] .= "</$tag>";
        break;
        case (count($line) - 1):
          $line[$key]['#prefix'] = "<$tag $style>" . $line[$key]['#prefix'];
          $line[$key]['#suffix'] .= "</$tag></tr>$tr_suf";
        break;
        default:
          $line[$key]['#prefix'] = "<$tag $style>" . $line[$key]['#prefix'];
          $line[$key]['#suffix'] .= "</$tag>";
        break;
      }
      $i++;
    }
  }
}

class EntityGroupConfiguratorPluggableNew extends EntityGroupConfigurator {
  var $action = 'edit';
  var $groupname = 'default_group';
  var $group_title = 'Grouped Entity';
  var $group_description = 'Grouped Description';

  
  public function buildForm(&$form, &$form_state) {
    // commenting this out since prepareQuery() should be called before this
    // which already calls applyEntityTokens and applySettings
    // and it may over-ride some of these if we have uipdated them later
    //$this->applyEntityTokens();
    //$this->applySettings();
    //dpm($this, 'buildform called');
    $element = array(
      '#tree' => TRUE,
      '#type' => '#fieldset',
    );
    $element[] = array(
      '#markup' => "<table>",
    );
    if (strlen($this->conf['destination']) > 0) {
      $form_state['redirect'] = $this->conf['destination'];
    }
    $i = 1;
    foreach ($this->data as $row) {
      $line = array();
      $this->renderFormRow($form, $form_state, $line, $row);
      if ($i == 1) {
        $header = array();
        $this->formHeader($header, $row);
        $this->tabularize($header, 'header');
        $element[] = $header;
      }
      $oe = ($i&1) ? 'odd' : 'even';
      $this->tabularize($line, $oe);
      $element[] = $line;
      $i++;
    }
    $element[] = array(
      '#markup' => "</table>",
    );
    $form[$this->groupname] = $element;
  }
  
  public function entityOptions(&$form, $form_state) {
    if (!isset($form['entity_settings'])) {
      $form['entity_settings'] = array(
      );
    }
    if (!isset($form['entity_settings'][$this->groupname])) {
      $form['entity_settings'][$this->groupname] = array(
        '#type' => 'fieldset',
        '#tree' => TRUE,
        '#title' => $this->group_title,
        '#collapsible' => TRUE,
        '#collapsed' => FALSE,
        '#description' => $this->group_description,
      );
    }
    $form['entity_settings'][$this->groupname]['entity_type'] = array(
      '#type' => 'hidden',
      '#default_value' => $this->base_entity_type,
      '#required' => TRUE,
    );
    $form['entity_settings'][$this->groupname]['display'] = array(
      '#type' => 'fieldset',
      '#tree' => TRUE,
      '#title' => 'Entity Field & Properties Info',
      '#collapsible' => TRUE,
      '#collapsed' => FALSE,
      '#prefix' => "<div id='update-display-options'>",
      '#suffix' => "</div>",
      '#description' => 'Entity Field & Properties Info',
    );
    if ($this->base_entity_type) {
      $entity_info = $this->entity_info;
      $bundle_options = array_combine( array_keys($entity_info['bundles']) , array_keys($entity_info['bundles']) );
    } else {
      $bundle_options = array();
    }
    $form['entity_settings'][$this->groupname]['display']['bundle'] = array(
      '#title' => t('Entity bundle'),
      '#type' => 'select',
      '#options' => $bundle_options,
      '#description' => t('Entity bundle'),
      '#required' => TRUE,
    // TODO - allow certain types of bundle fields (short text, select, numeric) in table
      //'#ajax' => array(
      //  'callback' => 'entity_pane_form_fields_update',
      //  'wrapper' => 'update-field-options',
      //),
    );
    // only set this if we have a match, otherwise, we have switched entities, or are a new form
    // either of which should show an un-selected list
    if ( in_array($this->base_bundle, $bundle_options) ) {
      $form['entity_settings'][$this->groupname]['display']['bundle']['#default_value'] = $this->base_bundle;
      $form['entity_settings'][$this->groupname]['display']['bundle']['#value'];
    } else {
      unset($form['entity_settings'][$this->groupname]['display']['bundle']['#default_value']);
      unset($form['entity_settings'][$this->groupname]['display']['bundle']['#value']);
    }
  }
  public function fieldOptions(&$form, $form_state) {
    $form['entity_settings'][$this->groupname]['display']['fields'] = $this->fieldElements();
  }
  
  public function propertyOptions(&$form, $form_state) {
    $form['entity_settings'][$this->groupname]['display']['properties'] = $this->propertyElements();
  }
  
  /* ****************************************
  //  Render - Read Only Modes 
  //   table - all visible row properties get a column, # rows = number of visible cols
  //   2-column - variable name is in 1 column, all others in 2nd column, with delimiter
  //   unformatted - all in single column, with delimiter
  //   flex-column - formRowDefaults array has attribute #display_column for grouping output
  //     used primarily by plugin renderers, but could also be included in interface 
  // ****************************************
  */
 
}

// * This class provides a handler that can be plugged into any field and 
// will co-exist with multiple copies of the same handler type.
// @todo: move to dh.display.inc an update include at top of implementing plugins
class dhTimeSeriesGroupPluggable extends EntityGroupConfiguratorPluggable {
  var $groupname;
  var $varid;
  var $id;
  var $starttime;
  var $endtime;
  var $featureid;
  var $erefs;
  var $ts_entity_type; // the type of entity that is storing ts data
  var $limit = 25;
  var $entity_tokens = array('featureid', 'starttime', 'endtime', 'varid', 'dh_link_admin_timeseries');
  var $row_tokens = array('tstext', 'tscode', 'tsvalue', 'tid', 'featureid', 'tstime', 'tsendtime', 'varname');
  
  public function __construct($conf) {
    parent::__construct($conf);
    $this->base_entity_type = 'dh_timeseries';
  }
  
  function applySettings() {
    $csv2array = array('featureid', 'entity_type', 'varid', 'dh_link_admin_timeseries');
    foreach ($this->entity_defaults as $key => $def) {
      $this->$key = isset($this->conf[$key]) ? $this->conf[$key] : $def;
      if (in_array($key, $csv2array)) {
        if (!is_array($this->$key)) {
          $this->$key = explode(',', $this->$key);
        }
      }
    }
    parent::applySettings();
  }
  
  public function entityDefaults() {
    parent::entityDefaults();
    $this->entity_defaults['groupname'] = 'ts_group';
    $this->entity_defaults['varid'] = array();
    $this->entity_defaults['id'] = array();
    $this->entity_defaults['starttime'] = FALSE;
    $this->entity_defaults['endtime'] = FALSE;
    $this->entity_defaults['ts_entity_type'] = 'dh_feature';
    $this->entity_defaults['featureid'] = array();
    $this->entity_defaults['dh_link_admin_timeseries'] = array();
    $this->entity_defaults['maxrecords'] = 25;
  }
  
  public function optionDefaults() {
    $this->property_conf_default = array(
      'tid' => array('name'=>'tid','hidden' => 1),
      'utcoffset' => array('name'=>'utcoffset','hidden' => 1, 'no_config' => TRUE),
      'entity_type' => array('name'=>'entity_type','hidden' => 1),
      'featureid' => array('name'=>'featureid','hidden' => 1),
      'timeline' => array('name'=>'timeline','hidden' => 1),
      'status' => array('name'=>'status','hidden' => 1, 'no_config' => TRUE),
      'module' => array('name'=>'module','hidden' => 1, 'no_config' => TRUE),
      'url' => array('name'=>'url','hidden' => 1, 'no_config' => TRUE),
      'feed_nid' => array('name'=>'feed_nid','hidden' => 1, 'no_config' => TRUE),
      'varname' => array('name'=>'varname','hidden' => 0),
      'varunits' => array('name'=>'varunits','hidden' => 0),
      'editlink' => array('name'=>'editlink','hidden' => 1),
      'addlink' => array('name'=>'addlink','hidden' => 1),
      'deletelink' => array('name'=>'deletelink','hidden' => 1),
    );
  }
  
  public function getFormId() {
    return 'timeseries_panel_form';
  }
  
  function getTSEntityInfo() {
    // get ts data parent entity type table name
    $ei = entity_get_info($this->ts_entity_type);
    if (!isset($ei['entity keys']['id']) or !isset($ei['base table'])) {
      // fail with malformed entity exception
      //dpm($ei,"Problem with entity info from entity_get_info($this->ts_entity_type)");
      return FALSE;
    }
    // insure only numeric
    return $ei;
  }
  
  function prepareQuery() {
    $this->applyEntityTokens();
    $this->applySettings();
    //parent::prepareQuery();
    // get ts data parent entity type table name
    $ei = $this->getTSEntityInfo();
    if (!isset($ei['entity keys']['id']) or !isset($ei['base table'])) {
      // fail with malformed entity exception
      //dpm($ei,"Problem with entity info from entity_get_info($this->ts_entity_type)");
      return FALSE;
    }
    $this->featureid = array_filter($this->featureid, 'is_numeric');
    $eidcol = $ei['entity keys']['id'];
    $ts_entity_table = $ei['base table'];
    // get varid
    // create a query that outer joins if insert ability is requested
    $q = "  select ent.$eidcol as featureid, ts.tid, ";
    $q .= " var.hydroid as varid, var.varname, ";
    $q .= " var.varkey, var.varunits ";
    $q .= " from {$ts_entity_table} as ent ";
    $q .= " left outer join {dh_variabledefinition} as var ";
    if (count($this->varid) > 0) {
      $varids = implode(", ", $this->varid);
      $q .= " on (var.hydroid in ($varids)) ";
    } else {
      // fail with malformed query exception - 
      //dpm($ei,"malformed query - no varid specified");
      return FALSE;
    }
    $q .= " left outer join {dh_timeseries} as ts ";
    $q .= " on ( ";
    $q .= "   ts.featureid = ent.$eidcol ";
    $q .= "   AND var.hydroid = ts.varid ";
    $q .= " ) ";
    // we must have a match in the TS table
    $q .= " WHERE var.hydroid IS NOT NULL ";
    if (count($this->featureid) > 0) {
      $features = implode(", ", $this->featureid);
      $q .= " AND (ent.$eidcol in ($features)) ";
    }
    if (strlen($this->starttime) > 0) {
      $starttime = (intval($this->starttime) == $this->starttime) ? $this->starttime : strtotime($this->starttime);
      $q .= " AND (ts.tstime >= $starttime) ";
    }
    if (strlen($this->endtime) > 0) {
      $endtime = (intval($this->endtime) == $this->endtime) ? $this->endtime : strtotime($this->endtime);
      $q .= " AND (ts.tstime <= $endtime) ";
    }
    if (count($this->tstime) > 0) {
      $tstime = implode(", ", $this->tstime);
      $q .= " AND (ts.tstime in ($tstime)) ";
    }
    if (count($this->tsendtime) > 0) {
      $tsendtime = implode(", ", $this->tsendtime);
      $q .= " AND (ts.tsendtime in ($tsendtime)) ";
    }
//    if (count($this->dh_link_admin_timeseries) > 0) {
//      $dh_link_admin_timeseries = implode(", ", $this->dh_link_admin_timeseries);
//      $q .= " AND (ts.tid in (select dh_link_admin_timeseries_target_id from field_data_dh_link_admin_timeseries where entity_id in ($dh_link_admin_timeseries))) ";
//    }
    if (!$this->add) {
      $q .= " AND ts.featureid IS NOT NULL ";
    }
    $q .= " LIMIT $this->limit ";
    $this->query = $q;
    //dpm($q, "Query");
    return TRUE;
  }
  
  function getData() {
    if (!isset($this->query)) {
      // malformed or non existent query
      return FALSE;
    }
    $this->data = array();
    //get the info linked to this event
    $q = db_query($this->query);
    //dpm($q, "initial data");
    foreach ($q as $tsrow) {
      if ($tsrow->tid == NULL) {
        // this is an insert request
        //dpm((array)$tsrow, "Creating blank");
        $this->data[] = entity_create($this->base_entity_type, (array)$tsrow);
      } else {
        $entities = entity_load($this->base_entity_type, array($tsrow->tid));
        $this->data[] = array_shift($entities);
      }
    }
    //dpm($this->data, "Final data");
    // now, go through the returned data and if we have "show_blank" property set
    // we append new object form entries for these
    // create a matrix of entity_type, property_conditions & field_conditions?
    // a better approach would be to use a query that would return prefilled null records like an outer join
  }
  
  function buildOptionsForm(&$form, $form_state) {
    parent::buildOptionsForm($form, $form_state);
  }
  
  public function entityOptions(&$form, $form_state) {
    parent::entityOptions($form, $form_state);
    
    $form['entity_settings'][$this->groupname]['featureid'] = array(
      '#title' => t('Feature IDs'),
      '#type' => 'textfield',
      '#default_value' => (strlen($this->conf['featureid']) > 0) ? $this->conf['featureid'] : NULL,
      '#description' => t('What entity id to retrieve TS values for.'),
      '#size' => 30,
      '#required' => FALSE,
    );  
    $conditions = array();
    $options = dh_vardef_vocab_options(TRUE);
    $form['entity_settings'][$this->groupname]['vocabulary'] = array(
      '#title' => t('Vocabulary'),
      '#type' => 'select',
      '#options' => $options,
      '#default_value' => (count($this->conf['vocabulary']) > 0) ? $this->conf['vocabulary'] : NULL,
      '#description' => t('What vocabulary to retrieve variables for - must save and re-open to update variable list.'),
      '#size' => 5,
      '#multiple' => TRUE,
      '#required' => FALSE,
    );
    $conditions = array();
    if (count($this->conf['vocabulary']) > 0) {
      $vocab_clause = "vocabulary in ( '" . implode("', '", $this->conf['vocabulary']) . "')";
      //dpm($vocab_clause, "Vocab Clause");
      $conditions = array($vocab_clause);
    }
    $options = dh_vardef_varselect_options($conditions);
    $form['entity_settings'][$this->groupname]['varid'] = array(
      '#title' => t('Variables'),
      '#type' => 'select',
      '#options' => $options,
      '#default_value' => (count($this->conf['varid']) > 0) ? $this->conf['varid'] : NULL,
      '#description' => t('What varid to retrieve TS values for.'),
      '#size' => 12,
      '#multiple' => TRUE,
      '#required' => FALSE,
      '#prefix' => "<div id='update-varid-options'>",
      '#suffix' => '</div>',
    );
    $entities = entity_get_info();
    $form['entity_settings'][$this->groupname]['ts_entity_type'] = array(
      '#title' => t('Entity Type'),
      '#type' => 'select',
      '#options' => array_combine( array_keys($entities) , array_keys($entities) ),
      '#default_value' => isset($this->ts_entity_type) ? $this->ts_entity_type : 'dh_feature',
      '#description' => t('Entity Type'),
      '#required' => TRUE,
    );
    $form['entity_settings'][$this->groupname]['id'] = array(
      '#title' => t('TimeSeries IDs'),
      '#type' => 'textfield',
      '#default_value' => (strlen($this->conf['id']) > 0) ? $this->conf['id'] : NULL,
      '#description' => t('What tid to retrieve TS values for.'),
      '#size' => 30,
      '#required' => FALSE,
    );  
    $form['entity_settings'][$this->groupname]['starttime'] = array(
      '#title' => t('Beginning of TimeSpan'),
      '#type' => 'textfield',
      '#default_value' => (strlen($this->conf['starttime']) > 0) ? $this->conf['starttime'] : NULL,
      '#description' => t('Will select events whose tstime >= this value (unix timestamp of yyy-mm-dd).'),
      '#size' => 24,
      '#required' => FALSE,
    );  
    $form['entity_settings'][$this->groupname]['endtime'] = array(
      '#title' => t('End of TimeSpan'),
      '#type' => 'textfield',
      '#default_value' => (strlen($this->conf['endtime']) > 0) ? $this->conf['endtime'] : NULL,
      '#description' => t('Will select events whose tstime <= this value (unix timestamp of yyy-mm-dd).'),
      '#size' => 24,
      '#required' => FALSE,
    );  
    $form['entity_settings'][$this->groupname]['dh_link_admin_timeseries'] = array(
      '#title' => t('TimeSeries Admin Submittal EREFs'),
      '#type' => 'textfield',
      '#default_value' => (strlen($this->conf['dh_link_admin_timeseries']) > 0) ? $this->conf['dh_link_admin_timeseries'] : NULL,
      '#description' => t('What dh_link_admin_timeseries to retrieve TS values for.'),
      '#size' => 30,
      '#required' => FALSE,
    );  
  }
  
  public function formRowDefaults(&$rowform, $row) {
    $pc = $this->conf['display']['properties'];
    //dpm($pc, "Prop conf");
    $fc = $this->conf['display']['fields'];
    $rowform['tid'] = array(
      '#type' => ($pc['tid']['hidden'] == 1) ? 'hidden' : 'textfield',
      '#default_value' => $row->tid,
   //   '#required' => TRUE,
      '#size' => 8,
      '#coltitle' => 'Event ID (tid)', 
    );
    $rowform['varname'] = array(
      '#coltitle' => 'Var Name',
      '#markup' => $row->varname,
    );

    $date_format = 'Y-m-d';
    $rowform['tstime'] = array(
      '#coltitle' => 'Event Time (tstime)', 
      '#default_value' => empty($row->tstime) ? $this->conf['display']['properties']['tstime']['default'] : date($date_format,$row->tstime),
      '#date_format' => $date_format,
      '#type' => 'date_select',
      '#date_year_range' => '-100:+5',
      '#required' => TRUE,
    );
    $rowform['tsendtime'] = array(
      '#coltitle' => 'Event End Time (tsendtime)', 
      '#default_value' => empty($row->tsendtime) ? $this->conf['display']['properties']['tsendtime']['default'] : date($date_format,$row->tsendtime),
      '#date_format' => $date_format,
      '#type' => 'date_select',
      '#date_year_range' => '-100:+5',
      '#required' => FALSE,
    );
    
    $rowform['tsvalue'] = array(
      '#coltitle' => 'Value (tsvalue)',
      '#type' => 'textfield',
      '#default_value' => empty($row->tsvalue) ? $this->conf['display']['properties']['tsvalue']['default'] : $row->tsvalue,
      '#required' => TRUE,
      '#size' => 8,
    );    
    
    $rowform['featureid'] = array(
      '#type' => 'textfield',
      '#default_value' => empty($row->featureid) ? $this->conf['display']['properties']['featureid']['default'] : $row->featureid,
      '#required' => TRUE,
      '#size' => 8,
    ); 
    $rowform['entity_type'] = array(
      '#type' => 'textfield',
      '#default_value' => empty($row->entity_type) ? $this->conf['display']['properties']['entity_type']['default'] : $row->entity_type,
      '#required' => FALSE,
      '#size' => 32,
    );
    if ($row->varid > 0) {
      $conditions = array();
      $conditions[] = 'hydroid = ' . $row->varid;
      $options = dh_vardef_varselect_options($conditions);
    } else {
      $options = array();
    } 
    //dpm($options,"options");
    if (count($options) > 1) {
      $rowform['varid'] = array(
        '#coltitle' => 'Varid',
        '#type' => 'select',
        '#default_value' => empty($row->varid) ? $this->conf['display']['properties']['varid']['default'] : $row->varid,
        '#options' => $options,
        '#required' => TRUE,
      );
    } else {
      $label = array_shift($options);
      $rowform['varid'] = array(
        '#coltitle' => 'Varid',
        '#type' => 'hidden',
        '#attributes' => array('disabled' => 'disabled'),
        '#default_value' => empty($row->varid) ? $this->conf['display']['properties']['varid']['default'] : $row->varid,
        '#required' => TRUE,
      );
      if (!($this->conf['display']['properties']['varid']['hidden'] == 1)) {
        // add a text label in here if we are requesting to show (should use 
        // varname instead, but this adds flexibility
        $rowform['varid']['#prefix'] = $label;
      }
    }
    parent::formRowDefaults($rowform, $row);
    
    // need to spoof a form_state for the row to properly load attached fields
    
  }

}

class DHTimeseriesGroupPreformatted extends dhTimeSeriesGroupPluggable {
  
  public function buildForm(&$form, &$form_state) {
    // commenting this out since prepareQuery() should be called before this
    // which already calls applyEntityTokens and applySettings
    // and it may over-ride some of these if we have uipdated them later
    //$this->applyEntityTokens();
    //$this->applySettings();
    $element = array(
      '#tree' => TRUE,
      '#type' => '#fieldset',
    );
    if (strlen($this->conf['destination']) > 0) {
      $form_state['redirect'] = $this->conf['destination'];
    }
    $i = 1;
    foreach ($this->data as $row) {
      $line = array();
      $this->renderFormRow($form, $form_state, $line, $row);
      $element[] = $line;
      $i++;
    }
    $form[$this->groupname] = $element;
  }
}

class EntityGroupConfiguratorPreformatted extends EntityGroupConfiguratorPluggable {
  
  function prepareQuery() {
    $this->applyEntityTokens();
    $this->applySettings();
    // children can call this parent method and then add additional
    // EFQ conditions if more sophisticated behavior is desired
    if (!strlen($this->base_entity_type)) {
      return FALSE;
    }
    $einfo = $this->entity_info;
    if (!isset($einfo['entity keys']['id'])) {
      // throw malformed entity exception and return
      return FALSE;
    }
    if ($this->conf['id'] == 'add') {
      if (empty($this->base_bundle)) {
        return FALSE;
      } else {
        $this->action = 'add';
      }
    } else { 
      $this->efq = new EntityFieldQuery;
      $this->efq->entityCondition('entity_type', $this->base_entity_type);
      $this->efq->range($this->start, $this->limit);
      if (!empty($this->conf['id'])) {
        $this->efq->propertyCondition($einfo['entity keys']['id'], $this->conf['id'], '=');
        //drupal_set_message("Arg: '$argument'");
      }
      if (!empty($this->base_bundle)) {
        $binfo = field_info_instances($this->base_entity_type, $this->base_bundle);
        foreach (array_keys((array)$binfo) as $field) {
          if (property_exists($this,$field)) {
            if (!empty($this->$field)) {
              $this->efq->fieldCondition($field,NULL,$this->$field);
            }
          }
        }
      }
      foreach ($einfo['property info'] as $prop) {
        //dpm($prop, "prop");
        if (property_exists($this,$prop)) {
          if (!empty($this->$prop)) {
            //dpm($this->$prop, "prop exists");
            $this->efq->propertyCondition($prop,$this->$prop);
          }
        }
      }
      //dpm($this->efq, "Final EFQ");
    }
    return TRUE;
  }
  
  function getData() {
    if (!is_object($this->efq) and !($this->action == 'add')) {
      // throw exception un-prepared query
      return FALSE;
    }
    if ($this->action == 'add') {
      $this->data = array(
        entity_create($this->base_entity_type, array('bundle'=>$this->base_bundle))
      );
    } else {
      $result = $this->efq->execute();
      //drupal_set_message("efq: <pre>" . print_r($result ,1) . "</pre>");
      if (isset($result[$this->base_entity_type])) {
        $this->data = entity_load($this->base_entity_type, array_keys($result[$this->base_entity_type]));
      }
      //dpm($this->data, "Data");
      // now need to take this list of entity ids and return it as a proper dataset.
      // this is where certain sub-classes may want to override this method and use a straight query if it is more economical
    }
  }
  
  public function buildForm(&$form, &$form_state) {
    // commenting this out since prepareQuery() should be called before this
    // which already calls applyEntityTokens and applySettings
    // and it may over-ride some of these if we have uipdated them later
    //$this->applyEntityTokens();
    //$this->applySettings();
    $element = array(
      '#tree' => TRUE,
      '#type' => '#fieldset',
    );
    if (strlen($this->conf['destination']) > 0) {
      $form_state['redirect'] = $this->conf['destination'];
    }
    $i = 1;
    foreach ($this->data as $row) {
      $line = array();
      $this->renderFormRow($form, $form_state, $line, $row);
      $element[] = $line;
      $i++;
    }
    $form[$this->groupname] = $element;
  }
}

?>