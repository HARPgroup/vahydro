<?php

$plugin = array(
  'label' => t('VDH - Pump Capacity'),
  'handler' =>  array(
    'class' => 'dHVDHPumpCapacity',
    'file' => 'dHWaterWorksPermit.class.php',
  ),
  'variable' =>  array(
    'varname' => 'VDH - Pump Capacity',
    'vardesc' => 'Pump capacity or limiting intake capacity as per VDH waterworks documentation.',
    'vocabulary' => 'vdh',
    'varunits' => 'mgd',
    'varkey' => 'vdh_pump_capacity_mgd',
    'datatype' => 'numeric',
    'varcode' => 'vdh_pump_capacity_mgd',
    'isregular' => 0,
    'timestep' => 0,
    'timeunits' => 'n/a',
    'nodataval' => 0,
    'data_entry' => '',
    'plugin' => 'dHVDHPumpCapacity',
    'options' => '',
    'varabbrev' => 'Pump Cap.',
  ),
);

?>