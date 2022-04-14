<?php
module_load_include('inc', 'dh', 'plugins/dh.display');

class dHRedundancyReview extends dHVariablePluginDefault {
  
  public function optionDefaults($conf = array()) {
    parent::optionDefaults($conf);
    $hidden = array('tid', 'varid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $this->property_conf_default[$hide_this]['hidden'] = 1;
    }
    //          tscode           | count
    // ---------------------------+-------
    //  closed_duplicate_verified |    91 - N/A
    //  needs_review              |   180 - N/A
    //  closed_not_duplicate      |     1 - N/A
    //  closed_duplicate_apriori      |     1 - N/A
    // (6 rows)
    // update dh_timeseries set tscode = 'closed_duplicate_verified' where varid = 1039 and tscode = 'closed_fixed';
    // update dh_timeseries set tscode = 'needs_review' where varid = 1039 and tscode = 'need_review';
    // update dh_timeseries set tscode = 'closed_not_duplicate' where varid = 1039 and tscode = 'closed_not_fixed';

  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $opts = array(
      'needs_review' => 'Needs Review',
      'closed_not_duplicate' => 'Closed (marked as not duplicate)',
      'closed_duplicate_verified' => 'Closed (duplicate verified)',
      'closed_duplicate_apriori' => 'Closed (duplicate assumed due to data match)',
    );
    $rowform['tscode'] = array(
      '#title' => 'Review Case Status',
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->tscode,
      '#size' => 1,
      '#weight' => 1,
    );
    $rowform['tid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->tid,
    );
    $rowform['varid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->varid,
    );
    $rowform['entity_type'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->entity_type,
    );
    $rowform['tstime']['#description'] = t('Date that this event was logged.');
    $rowform['tstime']['#weight'] = 2;
    $rowform['tsendtime']['#description'] = t('Date that this issue was resolved.');
    $rowform['tsendtime']['#weight'] = 3;
    $rowform['tsendtime']['#title'] = 'Date of Resolution';
    //dpm($row->tsendtime);
    $rowform['tsendtime']['#tsendtime'] = !empty($row->tsendtime) ? $row->tsendtime : strtotime(date('Y-m-d'));
    $rowform['featureid']['#title'] = 'Possible Duplicate Feature';
    $rowform['featureid']['#disabled'] = TRUE;
    $rowform['featureid']['#weight'] = 4;
    $rowform['featureid']['#type'] = 'textfield';
    $rowform['tsvalue']['#size'] = 1;
    //$rowform['tsvalue']['#disabled'] = TRUE;
    $rowform['tsvalue']['#title'] = 'Valid Feature';
    $rowform['tsvalue']['#weight'] = 5;
      
    // @todo: figure this visibility into one single place
    // thse should automatically be hidden by the optionDefaults setting but for some reason...
    $hidden = array('tid', 'varid', 'entity_type', 'bundle');
    foreach ($hidden as $hide_this) {
      $rowform[$hide_this]['#type'] = 'hidden';
      unset($rowform[$hide_this]['#input']);
    }
  }
  
  public function formRowSave(&$rowvalues, &$row) {
    // may call dh_move_timeseries_events
    if (in_array($row->tscode, array('closed_duplicate_verified','closed_duplicate_apriori'))){
      dh_move_timeseries_events ($row->featureid, $row->tsvalue, $row->entity_type, $row->entity_type, $mindate = FALSE, $maxdate = FALSE);
    }
  }
}

// @todo: move_boreholelog, move_entity_references
function dh_move_boreholelogs ($src_entity_id, $dest_entity_id, $src_type = 'dh_feature', $dest_type = 'dh_feature') {
  
}

function dh_move_timeseries_events ($src_entity_id, $dest_entity_id, $src_type = 'dh_feature', $dest_type = 'dh_feature', $mindate = FALSE, $maxdate = FALSE) {
  $src_info = entity_get_info($src_type);
  if (!$src_info) {
    watchdog('dh', "Invalid source entity_type to dh_move_timeseries_events ($src_entity_id, $dest_entity_id, $src_type, $dest_type , $mindate, $maxdate)" );
    return FALSE;
  }
  $dest_info = entity_get_info($dest_type);
  if (!$dest_info) {
    watchdog('dh', "Invalid dest entity_type to dh_move_timeseries_events ($src_entity_id, $dest_entity_id, $src_type, $dest_type , $mindate, $maxdate)" );
    return FALSE;
  }
  $src_table = $src_info['base table'];
  $dest_table = $dest_info['base table'];
  $src_pk_col = $src_info['entity keys']['id'];
  $dest_pk_col = $dest_info['entity keys']['id'];
  $q = "  update dh_timeseries set featureid = $dest_entity_id, entity_type = '$dest_type' ";
  $q .= " from ( ";
  $q .= "   select bar.tstime, bar.tid, bar.tsvalue, baz.tsvalue, bar.varid, baz.varid  ";
  $q .= "   from dh_timeseries as bar  ";
  $q .= "   left outer join dh_timeseries as baz  ";
  $q .= "   on ( ";
  $q .= "     baz.featureid = $dest_entity_id ";
  $q .= "     and baz.entity_type = '$dest_type' ";
  $q .= "     and baz.tstime = bar.tstime  ";
  $q .= "     and baz.varid = bar.varid ";
  $q .= "   ) ";
  $q .= "   where bar.tid is not null  ";
  $q .= "   and baz.tid is null  ";
  $q .= "   and bar.entity_type = '$src_type' ";
  $q .= "   and bar.featureid = $src_entity_id ";
  $q .= " ) as bing  ";
  $q .= " where dh_timeseries.tid = bing.tid  ";
  $q .= "  and dh_timeseries.featureid = $src_entity_id  ";
  $q .= "  and dh_timeseries.entity_type = '$src_type'  ";
  db_query($q);
  dpm($q,"dh_move_timeseries_events ($src_entity_id, $dest_entity_id, $src_type, $dest_type , $mindate, $maxdate)");
}


class dHPermitStatusReview extends dHVariablePluginDefault {
  
  public function hiddenFields() {
    $hidden = array('tid', 'tsvalue') + parent::hiddenFields();
    return $hidden;
  }
  
  public function formRowEdit(&$rowform, $row) {
    // apply custom settings here
    $rowform['featureid']['#title'] = 'Hydroid/Adminid of Entity needing review';
    $rowform['featureid']['#disabled'] = TRUE;
    $rowform['featureid']['#weight'] = 1;
    $rowform['featureid']['#type'] = 'textfield';
    $opts = array(
      'needs_review' => 'Needs Review',
      'closed_no_action' => 'Status Un-Changed (closed)',
      'closed_status_changed' => 'Status Changed (closed)',
    );
    $rowform['tscode'] = array(
      '#title' => 'Review Case Status',
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $row->tscode,
      '#size' => 1,
      '#weight' => 2,
    );
    $rowform['tid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->tid,
    );
    $rowform['varid'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->varid,
    );
    $rowform['entity_type'] = array(
      '#type' => 'hidden',
      '#default_value' => $row->entity_type,
    );
    $rowform['tstime']['#description'] = t('Date that this event was logged.');
    $rowform['tstime']['#weight'] = 3;
    $rowform['tsendtime']['#description'] = t('Date that this issue was resolved.');
    $rowform['tsendtime']['#weight'] = 4;
    $rowform['tsendtime']['#title'] = 'Date of Resolution';
    //dpm($row->tsendtime);
    $rowform['tsendtime']['#tsendtime'] = !empty($row->tsendtime) ? $row->tsendtime : strtotime(date('Y-m-d'));
  }
  
}


class dHDataQAed extends dHVariablePluginDefault {
  
  public function hiddenFields() {
    $hidden = array('tid', 'varid', 'tsvalue', 'tsendtime', 'tsvalue');
    return $hidden;
  }
  
  public function formRowEdit(&$form, $entity) {
    parent::formRowEdit($form, $entity);
    // apply custom settings here
    $params = drupal_get_query_parameters();
    if ($entity->is_new === TRUE) {
      if (isset($params['tstime'])) {
        $year = $params['tstime'];
        $entity->tstime = dh_handletimestamp("$year-01-01");
      }
    }
    $form['tstime']['#title'] = t('Year of Withdrawal.');
    $form['tstime']['#type'] = 'date_select';
    $form['tstime']['#date_format'] = 'Y';
    $form['tstime']['#default_value'] = date('Y',$entity->tstime);
    $form['tstime']['#weight'] = 1;
    $form['tstime']['#description'] = t('The water withdrawal for which QA should be performed.');
    $form['featureid']['#title'] = 'Hydroid of Well or Intake needing review';
    $form['featureid']['#disabled'] = TRUE;
    $form['featureid']['#weight'] = 2;
    $form['featureid']['#type'] = 'textfield';
    $opts = array(
      'needs_review' => 'Needs QA',
      'closed_no_action' => 'QA Complete, Un-Changed',
      'closed_status_changed' => 'QA Complete, Changed',
    );
    $form['tscode'] = array(
      '#title' => 'QA Status',
      '#type' => 'select',
      '#options' => $opts,
      '#default_value' => $entity->tscode,
      '#size' => 1,
      '#weight' => 3,
    );
    $form['tid'] = array(
      '#type' => 'hidden',
      '#default_value' => $entity->tid,
    );
    $form['varid'] = array(
      '#type' => 'hidden',
      '#default_value' => $entity->varid,
    );
    $form['entity_type'] = array(
      '#type' => 'hidden',
      '#default_value' => $entity->entity_type,
    );
  }
  
  public function formRowSave(&$form_values, &$entity) {
    // handle the year selector
    if (!($form_values['tstime'] == NULL)) {
      $year = $form_values['tstime'];
      $form_values['tstime'] = $year . "-01-01";
      $form_values['tsendtime'] = $year . "-01-01";
      $entity->tstime = dh_handletimestamp($form_values['tstime']);
      $entity->tsendtime = dh_handletimestamp($form_values['tsendtime']);
    }
    parent::formRowSave($form_values, $entity);
  }

  
}

?>