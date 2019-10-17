<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHWSPComplianceStatus extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    foreach ($this->hiddenFields as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
  }
  
  function complianceOpts() {
    $opts = array(
      'incomplete' => 'Incomplete',
      'submitted' => 'Submitted',
      'complete' => 'Complete',
    );
  }
  
  public function codeToText($ci) {
    $map = $this->complianceOpts();
    if (!(strtolower($ci) == $ci)) {
      return array_search($ci, $map);
    }
    return $map[$ci];
  }
  
  public function hiddenFields() {
    return array('pid', 'varid', 'featureid', 'entity_type', 'bundle', 'propcode', 'dh_link_admin_pr_condition');
  }
  
  public function formRowRender(&$rowvalues, &$row) {
    // this will alter appearances in the properties gridded edit form and timeseriers gridded forms
    $row->propcode = $this->codeToText($row->propcode); 
  }
  
  public function buildContent(&$content, &$entity, $view_mode) {
    // this will alter content called with drupal_render
    // loads the entity that this prop or timeseries is attached to so that we have access to it's properties
    $feature = $this->getParentEntity($entity);
    $hidden = array_keys($content);
    foreach ($hidden as $col) {
      $content[$col]['#type'] = 'hidden';
    }
    switch ($entity->entity_type) {
      case 'dh_timeseries':
        $content['message']['#markup'] = $feature->name . ' status changed to ' . $this->codeToText($entity->propcode); 
      break;
      
      case 'dh_properties':
        $content['message']['#markup'] = $feature->name . ' status = ' . $this->codeToText($entity->propcode); 
      break;
    }
    
  }
  
  public function formRowEdit(&$rowform, $row) {
    global $user;
    // apply custom settings here
    $opts = $this->droughtOptions();
    $codename = $this->row_map['code'];
    // note: when using '+' to combine arrays, the key-value pairs in the 1st will
    //       take priority over the 2nd, so this is essentially a UNION, with only new info
    //       added by the keys in the 2nd and no over-write of values.
    $rowform['pid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->pid,
    );
    $rowform['varid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->varid,
    );
    $rowform[$codename]['#type'] = 'select';
    // if user is not admin, planner, or other internal role, 
    // we may want to restrict opts from marking complete, unless it is already complete
    // for now, we show them all.
    $rowform[$codename]['#options'] = $opts;
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    foreach ($this->hiddenFields as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
      unset($rowform[$hide_this]['#input']);
    }
  }
  public function formRowSave(&$rowvalues, &$row) {
  }
  
  public function update(&$entity) {
    
  }
  
  public function insert(&$entity) {
    // add a ts event for this if this is a property
  }
  
  public function save(&$entity) {
    // we load the linked projection source 
    // and the base demand source 
    // and then multiply the factor from the linked projection by this base demand value
    
    // load all projections that are linked to this parent projection
    // this only can happen if this is an established projection with a valid ID,
    // otherwise, if it is an initial insert, we can skip this (since nothing can have been linked to it)
    $code = $this->row_map['code'];
    $start = $this->row_map['start'];
    $end = $this->row_map['code'];
  }
}

?>