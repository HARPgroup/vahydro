<?php

class DHVWWRSignSubmit extends EntityGroupConfiguratorPreformatted {
  // @todo:
  //  save handlers
  //  formRowDefaults
  // viewBlock method
  var $event_id = FALSE;
  var $base_entity_form_elements = FALSE;
  var $feature = FALSE;
  var $registrationid = FALSE;
  var $featureid = FALSE;
  var $startdate;
  var $base_entity_type = 'dh_adminreg_feature';
  var $groupname = 'sign_submit';
  var $group_title = 'VWWR Sign & Submit';
  var $group_description = 'Annual report form submission.';
  // $entity_tokens - a list of variables that are eligible for token substitution
  //   note: an entity property (defined as "var") must exist in order for token sub to work
  var $entity_tokens = array('adminid', 'startdate', 'featureid', 'id', 'registrationid');
  
  public function __construct($conf = array()) {
    $this->base_entity_type = 'dh_adminreg_feature';
    parent::__construct($conf);
    //$this->applyEntityTokens();
  }
  
  public function entityDefaults() {
    parent::entityDefaults();
    // HEADERS - sets before calling parent 
    $this->entity_defaults['startdate'] = $this->getDefaultYear() . '01-01';
    $this->entity_defaults['registrationid'] = FALSE;
    $this->entity_defaults['featureid'] = FALSE;
    $this->save_method = 'form_entity_map';
  }
  
  public function getData() {
    parent::getData();
    // be cool with a date and just extract the year
    list($year) = explode('-', $this->conf['startdate']);
    // get sum
    $this->startdate = $year . '-01-01';
    // @todo:
    // prevent double submissions by searching for multiples and delting older ones by modified date.
    // set a notification on the admin users timeseries feed so they know there are troubles
  }
  
  public function getRegistration() {
    // should not use this - pass all of these in as url values or in the base query
    /*
    if ($this->conf['featureid']) {
      $this->featureid = $this->conf['featureid'];
      $this->feature = entity_load_single('dh_feature', $this->conf['featureid']);
      $registrations = field_get_items('dh_feature', $this->feature, 'dh_link_admin_location');
      foreach ($registrations as $prs) {
        $efq = new EntityFieldQuery();
        $efq->entityCondition('entity_type', 'dh_adminreg_feature');
        $efq->propertyCondition('adminid', $prs['target_id', '=');
        $efq->propertyCondition('ftype', 'vdeq_vwuds', '=');
      }
    }
    */
  }
  
  public function buildBaseEntityForm($entity, $op = 'add', $fs = array()) {
    return entity_ui_get_form($this->base_entity_type, $entity, $op, $fs);
  }
  
  public function getDefaultYear() {
    $mo = date('n');
    $defyear = date('Y');
    if ($mo < 4) {
      $defyear = $defyear - 1;
    }
    return $defyear;
  }
  
  public function optionDefaults() {
    $this->property_conf_default = array(
      'adminid' => array('name'=>'adminid','hidden' => 1),
    );
  }
  
  public function propertyOptions(&$form, $form_state) {
    // this sets up properties that are to be controlled in the form
    // we override these to show only local things
    // it provides settings fields in the widget config form
    // as well as determining what gets included in the form presented to the user
    $form['entity_settings'][$this->groupname]['display']['properties'] = array();
  }  
  
  public function formRowDefaults(&$rowform, $row) {
    $rowform['adminid'] = array(
      '#type' => 'hidden',
      '#default_value' => (property_exists($row, 'adminid') and !empty($row->adminid)) ? $row->adminid : NULL,
    );
    // shared by method and meterloc
    // date-time
    $rowform['startdate'] = array(
      '#default_value' => (property_exists($row, 'startdate') and !empty($row->startdate)) ? dh_handletimestamp($row->startdate) : $this->startdate,
      '#type' => 'hidden',
    );
    dpm($row, '$row');
    dpm($row->startdate, '$row->startdate');
    dpm(strtotime($row->startdate), 'strtotime($row->startdate)');
    dpm(dh_handletimestamp($row->startdate), 'dh_handletimestamp($row->startdate)');
    dpm($this->startdate, '$this->startdate');
    dpm($rowform['startdate'], 'rowform[startdate]');
    $fstatus = array(
      'needs_review' => 'Needs Review',
      'submitted' => 'Submitted',
    );
    $rowform['ftype'] = array(
      '#field_prefix' => t('Submission Status'),
      '#type' => 'hidden',
      '#default_value' => (property_exists($row, 'ftype') and !empty($row->ftype)) ? $row->ftype : 'vwuds_submittal_certification',
    );
    $rowform['fstatus'] = array(
      '#field_prefix' => t('Submission Status'),
      '#type' => 'select',
      '#options' => $fstatus,
      '#default_value' => (property_exists($row, 'fstatus') and !empty($row->fstatus)) ? $row->fstatus : 'submitted',
    );
    $rowform['name'] = array(
      '#field_prefix' => "Signatory Name",
      '#field_suffix' => (property_exists($row, 'name') and !empty($row->name)) ? $row->name : '',
      '#type' => 'textfield',
      //'#attributes' => array('disabled' => 'disabled'),
      '#default_value' => (property_exists($row, 'name') and !empty($row->name)) ? $row->name : '',
      '#required' => TRUE,
      '#size' => 8,
    );
    
    // attach fields if we are in actual add/edit mode
    if (get_class($row) == $this->entity_info['entity class']) {
      // this loads the models normal form but doesn't seem to work?
      //$op = ($row->adminid) ? 'edit' : 'add';
      //$base_entity_form_elements = $this->buildBaseEntityForm($row, $op = 'add', array());
      //$rowform['field_submittal_certification'] = $base_entity_form_elements['field_submittal_certification'];
      
      $fstemp = array();
      field_attach_form($this->base_entity_type, $row, $rowform, $fstemp, NULL, array('field_name'=> 'field_submittal_certification'));
      
      //@todo: figure out why this doesn't make it to the form_state['values'] array
      //       I was pretty sure that it worked, then broke?
      /*
      field_attach_form($this->base_entity_type, $row, $rowform, $fstemp, NULL, array('field_name'=> 'dh_link_feature_submittal'));
      
      if (!$rowform['dh_link_admin_submittal_pr']['und'][0]['target_id']['#default_value']) {
        $rowform['dh_link_admin_submittal_pr']['und'][0]['target_id']['#default_value'] = $this->conf['registrationid'];
      }
      
      field_attach_form($this->base_entity_type, $row, $rowform, $fstemp, NULL, array('field_name'=> 'dh_link_admin_submittal_pr'));
      if (!$rowform['dh_link_feature_submittal']['und'][0]['target_id']['#default_value']) {
        $rowform['dh_link_feature_submittal']['und'][0]['target_id']['#default_value'] = $this->conf['featureid'];
        $rowform['dh_link_feature_submittal']['und'][0]['target_id']['#value'] = $this->conf['featureid'];
      }
      */
    }
    $rowform['field_submittal_certification']['und']['#field_prefix'] = 'Certify';
    $this->formRowVisibility($rowform, $row);
    
  }
  
  public function buildOptionsForm(&$form, $form_state) {
    // Form for configuration when adding to interface
    //   public function buildOptionsForm(&$form, FormStateInterface $form_state) {
    // when we go to D8 this will be relevant
    // until then, we use the old school method
    parent::buildOptionsForm($form, $form_state);
    $val = token_replace($this->conf['display']['properties'][$token][$key], array(), array('clear'=>TRUE));
    // we may total over-ride this, but use some of the other guts to do querying
  }
  
  public function entityOptions(&$form, $form_state) {
    parent::entityOptions($form, $form_state);
    
    $form['entity_settings'][$this->groupname]['id'] = array(
      '#title' => t('Submittal Admin ID'),
      '#type' => 'textfield',
      '#default_value' => (strlen($this->conf['id']) > 0) ? $this->conf['id'] : NULL,
      '#description' => t('What adminid to use for edit requests.'),
      '#size' => 30,
      '#required' => FALSE,
    );  
    $form['entity_settings'][$this->groupname]['featureid'] = array(
      '#title' => t('Facility that this submittal attaches to.'),
      '#type' => 'textfield',
      '#default_value' => (strlen($this->conf['featureid']) > 0) ? $this->conf['featureid'] : NULL,
      '#description' => t('What adminid to use for edit requests.'),
      '#size' => 30,
      '#required' => FALSE,
    );  
    $form['entity_settings'][$this->groupname]['registrationid'] = array(
      '#title' => t('VWWR Registration Entity Admin ID.'),
      '#type' => 'textfield',
      '#default_value' => (strlen($this->conf['registrationid']) > 0) ? $this->conf['registrationid'] : NULL,
      '#description' => t('VWWR Registration Entity Admin ID for insert requests.'),
      '#size' => 30,
      '#required' => FALSE,
    );  
    $form['entity_settings'][$this->groupname]['startdate'] = array(
      '#title' => t('Reporting Period Start Date'),
      '#type' => 'textfield',
      '#default_value' => (count($this->conf['startdate']) > 0) ? $this->conf['startdate'] : NULL,
      '#description' => t('Reporting Period Start Date (tokens ok).'),
      '#size' => 12,
      '#required' => FALSE,
    );
  }
  
  public function FormEntityMap(&$form_entity_map = array(), $row = array()) {
    // @todo - create stub for this in parent class
    // the rate
    $form_entity_map['Submittal'] = array(
      'entity_type' => 'dh_adminreg_feature',
      'entity_class' => 'entity', // entity, entityreference, field
      'description' => 'Submittal.',
      'bundle' => 'submittal',
      'debug' => FALSE,
      'notnull_fields' => array('adminid'),
      'entity_key' => array(
        'fieldname'=> 'tid',
        'value_src_type' => 'form_key', 
        'value_val_key' => 'adminid', 
      ),
      'handler' => '', // NOT USED YET - could later add custom functions
      'fields' => array(
        // field_name - name in the destination entity 
        // field_type - type of data - valid values are property and field  
        // value_src_type - type of  
        // value_src_type - form_field, EntityFieldQuery, 
          // token, constant, env (environment var)
        'name' => array(
          'fieldname'=> 'name',
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'name', 
        ),
        'startdate' => array(
          'fieldname'=> 'startdate',
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'startdate', 
        ),
        'field_submittal_certification' => array(
          'fieldname'=> 'field_submittal_certification', 
          'field_type'=> 'field', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'field_submittal_certification', 
        ),
        'dh_link_feature_submittal' => array(
          'fieldname'=> 'dh_link_feature_submittal', 
          'field_type'=> 'field', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'dh_link_feature_submittal', 
        ),
        'dh_link_admin_submittal_pr' => array(
          'fieldname'=> 'dh_link_admin_submittal_pr', 
          'field_type'=> 'field', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'dh_link_admin_submittal_pr', 
        ),
        'fstatus' => array(
          'fieldname'=> 'fstatus', 
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'fstatus', 
        ),
        'ftype' => array(
          'fieldname'=> 'ftype', 
          'field_type'=> 'property', 
          'value_src_type' => 'form_key', 
          'value_val_key' => 'ftype', 
        ),
      ),
      'resultid' => 'submittal_id',
    );
  }
  
  public function entity_save($entity_type, $e) {
    // do any pre-save mods here 
    $e->fstatus = 'submitted'; // by definition, if they submitted this, they submitted
    // @todo: hack entity reference fields
    // because of the way we assemble forms, the entity references don't yet come through
    // although, other fields such as selec t boxes seem to be OK.
    // for now we have to hack this
    $f_link = array(
      'und' => array(
        0 => array(
          'target_id' => $this->conf['featureid']
        ),
      ),
    );
    $e->dh_link_feature_submittal = $f_link;
    $r_link = array(
      'und' => array(
        0 => array(
          'target_id' => $this->conf['registrationid']
        ),
      ),
    );
    $e->dh_link_admin_submittal_pr = $r_link;
    //dpm($e,'entity to save');
    parent::entity_save($entity_type, $e);
  }
    
  public function HandleFormMap($map, $data) {
    $value = parent::HandleFormMap($map, $data);
    return $value;
  }
  function SubmitFormEntityMap(array &$form, $form_state) {
    //dpm($form_state,'form state');
    parent::SubmitFormEntityMap($form, $form_state);
  }
}

?>