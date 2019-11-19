<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHPermsAuthProp extends dHVariablePluginDefault {
  
  public function generateAuthCode() {
    if (function_exists('random_bytes')) {
      return random_bytes(16);
    } else {
      return md5(mt_rand(0,32768));
    }
    
  }
  
  public function hiddenFields() {
    $hidden = array('dh_link_admin_pr_condition') + parent::hiddenFields();
    return $hidden;
  }
  
  public function formRowEdit(&$form, $entity) {
    parent::formRowEdit($form, $entity);
    $entity->propcode = !strlen($entity->propcode) ? $this->generateAuthCode() : $entity->propcode;
    $form['propcode']['#title'] = t('Private Authorization Code');
    $form['propcode']['#default_value'] = $entity->propcode;
    $form['propcode']['#type'] = 'hidden';
    $form['propcode']['#prefix'] = t('Private Authorization Code:');
    $form['propcode']['#suffix'] = $entity->propcode;
    $tf = array(
      0 => 'No',
      1 => 'Yes'
    );
    $form['propname']['#default_value'] = 'Authorization Code';
    $form['regenerate'] = array(
      '#title' => t('Regenerate Code?'),
      '#type' => 'select',
      '#options' => $tf,
      '#size' => 1,
      '#multiple' => FALSE,
    );
  }
  
  public function save(&$entity) {
    parent::save($entity);
    $entity->propname = 'Authorization Code';
    if (property_exists($entity, 'regenerate') and (intval($entity->regenerate) == 1)) {
      $entity->propcode = $this->generateAuthCode();
    }
  }
  
  public function formRowSave(&$rowvalues, &$row) {
    // special form save handlers
    parent::formRowSave($rowvalues, $row);
    if (intval($rowvalues['regenerate']) == 1) {
      $row->propcode = $this->generateAuthCode();
    }
  }
}