<?php

$plugin = array(
  'label' => t('Monthly Event Reporting'),
  'handler' =>  array(
    'class' => 'DHGWPermitMonthlyReportingEvent',
    'file' => 'DHMonthlyReportingEvent.class.php',
  ),
);

?>