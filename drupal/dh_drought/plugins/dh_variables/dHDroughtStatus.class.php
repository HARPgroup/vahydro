<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHDroughtStatusBase extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
  }
  
  public function hiddenFields() {
    return array('pid', 'varid', 'featureid', 'entity_type', 'bundle', 'propcode', 'dh_link_admin_pr_condition');
  }
  
  public function droughtOptions() {
    return array(
      '' => 'Not Set',
      0 => 'Normal',
      1 => 'Watch',
      2 => 'Warning',
      3 => 'Emergency',
    );
  }
  
  public function droughtCodeToIndex($ci) {
    $map = array(
      'normal' => 0,
      'watch' => 1,
      'warning' => 2,
      'emergency' => 3,
    );
    if (is_numeric($ci)) {
      return array_search($ci, $map);
    }
    return $map[$ci];
  }
  
  public function renderDroughtCode($ci) {
    if (!is_numeric($ci)) {
      $ci = $this->droughtCodeToIndex($ci);
    }
    $droughtkey = $this->droughtOptions();
    return $droughtkey[$ci];
  }
  
  public function formRowRender(&$form_values, &$entity) {
    // this will alter appearances in the properties gridded edit form and timeseriers gridded forms
    $entity->propcode = $this->renderDroughtCode($entity->propcode); 
  }
  
  public function buildContent(&$content, &$entity) {
    // for a timeseries entity the $entity will have all the normal TS props:
    // $entity->tid = unique id
    // $entity->tstime = timestamp
    // $entity->tstime = end timestamp
    // $entity->tsvalue = the value
    // $entity->tscode = code
    // $entity->field_ts_text = this is the text field attached which has a different format
    // this will alter content called with drupal_render (views)
    //dpm($content, 'content values');
    //dpm($entity, 'entity ');
    $content['propcode']['#markup'] = $this->renderDroughtCode($entity->propcode); 
    //dpm($content, 'after formRowRender ');
  }
  
  public function formRowEdit(&$form, $entity) {
    parent::formRowEdit($form, $entity);
    // apply custom settings here
    $opts = $this->droughtOptions();
    // note: when using '+' to combine arrays, the key-value pairs in the 1st will
    //       take priority over the 2nd, so this is essentially a UNION, with only new info
    //       added by the keys in the 2nd and no over-write of values.
    $form['propcode'] = array(
      '#title' => 'Drought Status',
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $entity->propcode,
      '#size' => 1,
    ) + $form['propcode'];
    $form['propvalue'] = array(
      '#title' => t('Metric Value'),
      '#type' => 'textfield',
      '#default_value' => $entity->propvalue,
      '#attributes' => array('maxlength' => 6, 'size' => 6), 
    ) + $form['propvalue'];
    $form['pid'] = array(
      '#type' => 'hidden',
      '#default_value' => $entity->pid,
    );
    $form['varid'] = array(
      '#type' => 'hidden',
      '#default_value' => $entity->varid,
    );
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    foreach ($this->hiddenFields as $hide_this) {
      $form[$hide_this]['#type'] = 'hidden';
      unset($form[$hide_this]['#input']);
    }
  }
  public function formRowSave(&$form_values, &$entity) {
    if ( ($entity->propcode <> '0') and empty($entity->propcode)) {
      $entity->propvalue = NULL;
      $entity->propcode = NULL;
    }
  }
}

class dHDroughtStatus extends dHDroughtStatusBase{
  public function formRowEdit(&$form, $entity) {
    parent::formRowEdit($form, $entity);
    $form['propvalue']['#type'] = 'hidden';
    $form['propvalue']['#prefix'] = 'n/a';
  }
  public function formRowSave(&$form_values, &$entity) {
    $entity->propvalue = $this->droughtCodeToIndex($entity->propcode);
  }
} 

class dHDroughtStatusStream extends dHDroughtStatusBase{
  public function formRowEdit(&$form, $entity) {
    parent::formRowEdit($form, $entity);
    $form['propvalue']['#title'] = t('7-day Mean Flow');
  }  
}

class dHDroughtResponse extends dHDroughtStatusBase{
  public function formRowEdit(&$form, $entity) {
    parent::formRowEdit($form, $entity);
    $form['propvalue']['#title'] = t('Target reduction %');
    $opts = array(
     'none' => 'None',
     'voluntary' => 'Voluntary',
     'mandatory' => 'Mandatory',
    );
    $form['propcode'] = array(
      '#title' => 'Reduction Type',
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $entity->propcode,
      '#size' => 1,
    ) + $form['propcode'];
  }  
}
class dHDroughtStatusPalmer extends dHDroughtStatusBase{
  public function formRowEdit(&$form, $entity) {
    parent::formRowEdit($form, $entity);
    $form['propvalue']['#title'] = t('Palmer Index (in)');
  }  
}

class dHDroughtStatusReservoir extends dHDroughtStatusBase{
  public function formRowEdit(&$form, $entity) {
    parent::formRowEdit($form, $entity);
    $form['propvalue']['#title'] = t('Reservoir Surface Level');
  }  
}

class dHDroughtStatusMLLR extends dHDroughtStatusBase {
  public function formRowEdit(&$form, $entity) {
    parent::formRowEdit($form, $entity);
    $form['propvalue']['#title'] = t('Highest Probability of Drought Warning Flow (10%)');
  }  
  
  public function save(&$entity) {
    $code = $this->entity_map['code'];
    
    if ( ($entity->propcode == '-1') or ($entity->propcode == '') or empty($entity->propcode) ) {
      $level = NULL;
      switch (TRUE) {
        // <=Dec
        case $entity->propvalue <= 0.15:
          $level = 0;
        break;
        case ($entity->propvalue <= 0.25):
          $level = 1;
        break;
        case $entity->propvalue <= 0.35:
          $level = 2;
        break;
        case $entity->propvalue > 0.35:
          $level = 3;
        break;
      }
      $entity->propcode = $level;
    }
  }
}

class dHDroughtStatusWell extends dHDroughtStatusBase{
  public function formRowEdit(&$form, $entity) {
    parent::formRowEdit($form, $entity);
    $form['propvalue']['#title'] = t('7-day Mean Depth to Surface');
  }
}

class dHDroughtStatusPrecip extends dHDroughtStatusBase{
  public function formRowEdit(&$form, $entity) {
    parent::formRowEdit($form, $entity);
    $form['propvalue']['#title'] = t('Water Year % of Normal.');
    // adds auto-calculation directive on saving
    // if we import the percent of normal as a feed
    // all we need to do is to set propcode = -1 
    // and the save routine will handle it for us
    $form['propcode']['#options'][-1] = 'Auto-Calculate on Save';
    ksort($form['propcode']['#options']);
  }  
  
  public function getStatus($entity) {
    
  }
  
  public function save(&$entity) {
    $code = $this->entity_map['code'];
    $start = $this->entity_map['start'];
    $end = $this->entity_map['code'];
    // propcode is status, automatically calculated for date range
    if (!isset($entity->$start) and isset($entity->$end)) {
      return;
    }
    //dpm($entity);
    if ( !($entity->propcode === '0') and (($entity->propcode == '-1') or ($entity->propcode == '') or empty($entity->propcode)) ) {
      $level = 0;
      $days = (dh_handletimestamp($entity->enddate) - dh_handletimestamp($entity->startdate) ) / 86400.0;
      $bounds = array();
      switch (TRUE) {
        // <=Dec
        case $days <= 91:
          $bounds = array(75.0, 65.0, 55.0, 0.0);
        break;
        // Jan-March
        case $days <= 182:
          $bounds = array(80.0, 70.0, 60.0, 0.0);
        break;
        // Apr
        case $days <= 212:
          $bounds = array(81.5, 71.5, 61.5, 0.0);
        break;
        // May
        case $days <= 243:
          $bounds = array(82.5, 72.5, 62.5, 0.0);
        break;
        // June
        case $days <= 273:
          $bounds = array(83.5, 73.5, 63.5, 0.0);
        break;
        // July+
        default:
          $bounds = array(85.0, 75.0, 65.0, 0.0);
        break;
      }
      $pct = $entity->propvalue;
      foreach ($bounds as $bound) {
        if ($pct < $bound) {
          $level++;
        }
      }
      $entity->propcode = $level;
    }
  }
}
?>