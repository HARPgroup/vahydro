<?php
// Example: http://deq1.bse.vt.edu:81/d.dh/?q=ows-watershed-dash-met/74542

$args = arg();
$fid = $args[1];
$today = date("Y-m-d");
$enddate = $today;
$thisyear = date("Y");
$thismo = date("m");
if ($thismo < 10) {
  $wystart = $thisyear - 1;
} else {
  $wystart = $thisyear;
}
$startdate = $wystart . "-10-01"; 
if (count($args) > 2) {
  $startdate = $args[2];
}
if (count($args) > 3) {
  $enddate = $args[3];
}

print("Meteorology from $start to $end (calculated today $today)");

$q = "select to_timestamp(c.tstime)::date pd_start, to_timestamp(c.tsendtime)::date as pd_end, ";
$q .= "    extract(month from to_timestamp(c.tstime)) as mo, ";
$q .= "    (ST_summarystats(st_clip(c.rast, b.dh_geofield_geom), 1, TRUE)).mean as obs, ";
$q .= "    (ST_summarystats(st_clip(c.rast, b.dh_geofield_geom), 2, TRUE)).mean as nml, ";
$q .= "    (ST_summarystats(st_clip(c.rast, b.dh_geofield_geom), 2, TRUE)).count as num ";
$q .= "from dh_feature as a ";
$q .= "left outer join field_data_dh_geofield as b ";
$q .= "  on ( ";
$q .= "    entity_id = a.hydroid ";
$q .= "        and b.entity_type = 'dh_feature' ";
$q .= "  ) ";
$q .= "left outer join dh_timeseries_weather as c ";
$q .= "    on ( ";
$q .= "      c.varid in (select hydroid from dh_variabledefinition where varkey = 'noaa_precip_raster' ) ";
$q .= ") ";
$q .= "where a.hydroid = $fid ";
$q .= "and c.tstime >= extract(epoch from '$startdate'::timestamp) ";
$q .= " and c.tsendtime <= extract(epoch from '$enddate'::timestamp) ";
$q .= " order by c.tsendtime";

$sq = "select min(pd_start) as pd_start, max(pd_end) as pd_end, sum(obs) as obs, sum(nml) as nml, avg(num) as num from ($q) as foo ";

foreach (array($sq, $q) as $thisq) {
  dpm($thisq,'query');

  $res = db_query($thisq);
  $rows = array();
  while ($row = $res->fetchAssoc()) {
    if (count($rows) == 0) {
      $header = array_keys($row);
    }
    $rows[] = $row;
  }
  $table_out = theme('table', array('header' => $header, 'rows' => $rows));
  echo $table_out;
}
?>