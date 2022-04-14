<?php

$plugin = array(
  'label' => t('OWS - Annual Data QAed'),
  'handler' =>  array(
    'class' => 'dHDataQAed',
    'file' => 'dHDataAdminEvents.class.php',
  ),
  'variable' =>  array(
    'varname' => 'OWS - Annual Data QAed',
    'vardesc' => 'General review for entities that may be above/below reporting or permitting thresholds.',
    'vocabulary' => 'vadeq_ows_qa',
    'varunits' => 'n/a',
    'varkey' => 'vadeq_annual_data_qa',
    'datatype' => 'boolean',
    'varcode' => 'vadeq_annual_data_qa',
    'isregular' => 0,
    'timestep' => 0,
    'timeunits' => 'n/a',
    'multiplicity' => 'tstime_singular',
    'nodataval' => 0,
    'data_entry' => '',
    'plugin' => 'dHDataQAed',
    'options' => '',
    'varabbrev' => 'Review Status',
  ),
);

?>