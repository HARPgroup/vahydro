<?php

$plugin = array(
  'label' => t('OWS - Permit Status Review'),
  'handler' =>  array(
    'class' => 'dHPermitStatusReview',
    'file' => 'dHDataAdminEvents.class.php',
  ),
  'variable' =>  array(
    'varname' => 'OWS - Permit Status Review',
    'vardesc' => 'General review for entities that may be above/below reporting or permitting thresholds.',
    'vocabulary' => 'vadeq_ows_qa',
    'varunits' => 'n/a',
    'varkey' => 'vadeq_ows_qa_status',
    'datatype' => 'boolean',
    'varcode' => 'vadeq_ows_qa_status',
    'isregular' => 0,
    'timestep' => 0,
    'timeunits' => 'n/a',
    'nodataval' => 0,
    'data_entry' => '',
    'plugin' => 'dHPermitStatusReview',
    'options' => '',
    'varabbrev' => 'Review Status',
  ),
);

?>