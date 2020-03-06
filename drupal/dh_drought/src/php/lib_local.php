<?php

# lib_local.php - miscellanious local functions
function calculateNOAAMonthly($listobject, $datayear, $datamonth, $debug) {

   # process the new data
   print("Clearing Old Data from Gridded Database<br>");
   $listobject->querystring = "  delete from precip_gridded_monthly ";
   $listobject->querystring .= " where thisyear = $datayear ";
   $listobject->querystring .= "    and thismonth = $datamonth ";
   $listobject->querystring .= "    and datatype = 'obs' ";
   print("$listobject->querystring ; <br>");
   $listobject->performQuery();
   $thisdate = date('Y-m-d');
   $padmo = str_pad($datamonth, 2, '0', STR_PAD_LEFT);
   $mde = new DateTime ("$datayear-$padmo-01");
   $thisyear = $mde->format('Y');
   $thismo = $mde->format('m');
   $mostart = "$thisyear-$thismo-01";
   $lastday = $mde->format('t');
   $moend = "$thisyear-$thismo-$lastday";

   print("Inserting Data into Gridded Database<br>");
   $listobject->querystring = "  insert into precip_gridded_monthly (hrapx, hrapy, lat, lon, ";
   $listobject->querystring .= "    globvalue, entrydate, datasource, the_geom,";
   $listobject->querystring .= "    datatype, thisyear, thismonth, mo_start, src_citation ) ";
   $listobject->querystring .= " select hrapx, hrapy, avg(lat), avg(lon), sum(globvalue), ";
   $listobject->querystring .= "    '$thisdate'::timestamp, 1, ";
   # assumes that the file came in as decimal degrees
   $listobject->querystring .= "    st_setsrid(centroid(collect(the_geom)),4326) ,";
   $listobject->querystring .= "    'obs', $datayear, $datamonth, ";
   $listobject->querystring .= "    '$datayear-$padmo-01'::timestamp, 1 ";
   $listobject->querystring .= " from precip_gridded ";
   $listobject->querystring .= " where thisdate >= '$mostart' ";
   $listobject->querystring .= "    and thisdate <= '$moend' ";
   $listobject->querystring .= " GROUP BY hrapx, hrapy ";
   print("$listobject->querystring ; <br>");
   $listobject->performQuery();
   #$listobject->showList();

}

function copyNOAAMonthlyToProj($listobject, $projectid, $thisdate, $datayear, $datamonth, $datatype, $src_citation, $debug) {

   # process the new data
   print("Clearing Old Data from Gridded Database<br>");
   $listobject->querystring = "  delete from precip_gridded_monthly ";
   $listobject->querystring .= " where thisyear = $datayear ";
   $listobject->querystring .= "    and thismonth = $datamonth ";
   $listobject->querystring .= "    and datatype = '$datatype' ";
   print("$listobject->querystring ; <br>");
   $listobject->performQuery();

   print("Inserting Data into Gridded Database<br>");
   $padmo = str_pad($datamonth, 2, '0', STR_PAD_LEFT);
   $listobject->querystring = "  insert into precip_gridded_monthly (hrapx, hrapy, lat, lon, ";
   $listobject->querystring .= "    globvalue, entrydate, datasource, the_geom,";
   $listobject->querystring .= "    datatype, thisyear, thismonth, mo_start, src_citation ) ";
   $listobject->querystring .= " select hrapx, hrapy, lat, lon, globvalue, ";
   $listobject->querystring .= "    '$thisdate'::timestamp, 1, ";
   # assumes that the file came in as decimal degrees
   $listobject->querystring .= "    st_setsrid(the_geom,4326) ,";
   $listobject->querystring .= "    '$datatype', $datayear, $datamonth, ";
   $listobject->querystring .= "    '$datayear-$padmo-01'::timestamp, $src_citation";
   $listobject->querystring .= " from tmp_precipgrid ";
   $listobject->querystring .= " where the_geom && (";
   $listobject->querystring .= "    select st_extent(the_geom) ";
   $listobject->querystring .= "    from proj_seggroups ";
   $listobject->querystring .= "    where projectid = $projectid";
   $listobject->querystring .= "    ) ";
   print("$listobject->querystring ; <br>");
   $listobject->performQuery();
   #$listobject->showList();


   # clean up after ourselves
   if ($listobject->tableExists('tmp_precipgrid')) {
      $listobject->querystring = "drop table tmp_precipgrid ";
      if ($debug) { print("$listobject->querystring ; <br>"); }
      #$listobject->performQuery();
   }

}

function summarizePrecipGrid($listobject, $startdate, $enddate, $dataname, $singular, $debug) {

   # this only summarizes the observed precip
   # uses a new sub-query spatial match to improve performance
   # forget about projectid here, since we will do all data in the precip_gridded table
   $listobject->querystring = "  delete from precip_gridded_period ";
   $listobject->querystring .= " where dataname = '$dataname' ";
   # if we will allow multiple occurences of this metric with different dates, then we only try
   # to delete any copies that have the same date and name as this one, otherwise, we delete anything with a
   # matching name
   if (!$singular) {
       $listobject->querystring .= "    and startdate = '$startdate'::timestamp ";
       $listobject->querystring .= "    and enddate = '$enddate'::timestamp ";
    }
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();


   $listobject->querystring = "  insert into precip_gridded_period (hrapx, hrapy, the_geom, globvalue, ";
   $listobject->querystring .= "    dataname, startdate, enddate ) ";
   $listobject->querystring .= " select a.hrapx, a.hrapy, a.the_geom, sum(b.globvalue) as globvalue, ";
   $listobject->querystring .= "    '$dataname', min(b.thisdate), max(b.thisdate) ";
   $listobject->querystring .= " from precip_noaa_daily_grid as a, precip_gridded as b ";
   $listobject->querystring .= " where a.hrapx = b.hrapx and a.hrapy = b.hrapy ";
   $listobject->querystring .= "    and b.thisdate >= '$startdate' and b.thisdate <= '$enddate' ";
   $listobject->querystring .= " group by a.hrapx, a.hrapy, a.the_geom ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();


}


function createPeriodPrecip($listobject, $projectid, $startdate, $enddate, $datametric, $debug) {

   # start date - first month to include (refer to the first of the month)
   # end date - last month to include

   # $datametric - if blank, it will assume the existing quantities, obs, dif, and pct
   #               otherwise, it will create psuedo quantities named after the datametric

   if (strlen($datametric) > 0) {
      $obstype = $datametric . '_obs';
      $diftype = $datametric . '_dif';
      $pcttype = $datametric . '_pct';
   } else {
      $obstype = 'obs';
      $diftype = 'dif';
      $pcttype = 'pct';
   }

   $listobject->querystring = "  delete from proj_precip_period ";
   $listobject->querystring .= " where datatype in ('$obstype', '$diftype', '$pcttype' ) ";
   if (!strlen($datametric) > 0) {
       $listobject->querystring .= "    and startdate = '$startdate'::timestamp ";
       $listobject->querystring .= "    and enddate = '$enddate'::timestamp ";
    }
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # insert new records
   $listobject->querystring = "  insert into proj_precip_period (projectid, hrapx, hrapy, ";
   $listobject->querystring .= "    the_geom, globvalue, datatype, startdate, enddate,num_report ) ";
   $listobject->querystring .= " select $projectid, a.hrapx, a.hrapy, b.the_geom, sum(a.globvalue), ";
   if (strlen($datametric) > 0) {
      $listobject->querystring .= "    '$datametric' || '_' || ";
   }
   $listobject->querystring .= "a.datatype, ";
   $listobject->querystring .= "    '$startdate'::timestamp, '$enddate'::timestamp, ";
   $listobject->querystring .= "    count(a.*) as num_report ";
   $listobject->querystring .= " from precip_gridded_monthly as a, precip_noaa_grid as b ";
   $listobject->querystring .= " where a.mo_start >= '$startdate'::timestamp ";
   $listobject->querystring .= "    and a.mo_start <= '$enddate'::timestamp ";
   # only grab these two types, because the type 'pct' does not apply with a sum function
   # and nml doesn't really apply to flexible periods. We will calculate the pct later
   # as a function of the observed and the difference.  This assumes that the dif value is
   # calculated correctly when importing from NOAA ...
   $listobject->querystring .= "    and a.datatype in ('obs', 'dif', 'nml' ) ";
   # unite these data based on lat/lon not hrapx/y
   $listobject->querystring .= "    and a.hrapx = b.hrapx and a.hrapy = b.hrapy ";
   $listobject->querystring .= " group by a.hrapx, a.hrapy, b.the_geom, a.datatype ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   /*
   # insert new records for pct by calculating from dif and obs
   $listobject->querystring = "  insert into proj_precip_period (projectid, hrapx, hrapy, ";
   $listobject->querystring .= "   the_geom, globvalue, datatype, startdate, enddate, num_report)";
   $listobject->querystring .= " select $projectid, a.hrapx, a.hrapy, a.the_geom, ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "    WHEN (a.globvalue - b.globvalue) > 0 THEN ";
   $listobject->querystring .= "       (a.globvalue / (a.globvalue - b.globvalue))";
   $listobject->querystring .= "    ELSE NULL ";
   $listobject->querystring .= "    END, '$pcttype', a.startdate, a.enddate, b.num_report ";
   $listobject->querystring .= " from proj_precip_period as a, proj_precip_period as b ";
   $listobject->querystring .= " where a.startdate = '$startdate'::timestamp ";
   $listobject->querystring .= "    and a.enddate = '$enddate'::timestamp ";
   $listobject->querystring .= "    and b.startdate = '$startdate'::timestamp ";
   $listobject->querystring .= "    and b.enddate = '$enddate'::timestamp ";
   $listobject->querystring .= "    and a.datatype = '$obstype' ";
   $listobject->querystring .= "    and b.datatype = '$diftype' ";
   $listobject->querystring .= "    and a.projectid = $projectid ";
   $listobject->querystring .= "    and b.projectid = $projectid ";
   $listobject->querystring .= "    and a.hrapx = b.hrapx ";
   $listobject->querystring .= "    and a.hrapy = b.hrapy ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   */

}

function calcPoliPrecipDepart($listobject, $projectid, $startdate, $enddate, $thismetric, $debug) {

   # start date - first month to include (refer to the first of the month)
   # end date - last month to include

   if (strlen($thismetric) > 0) {
      $depmetric = $thismetric . '_dep_pct';
      $srcmetric = $thismetric . '_pct';
   } else {
      $depmetric = 'precip_dep_pct';
      $srcmetric = 'pct';
   }

   print("Deleting old records for $depmetric.<br>");
   $listobject->querystring = "  delete from proj_poli_stat ";
   $listobject->querystring .= " where projectid = $projectid ";
   # if we are passed a metric, it assumes that the metric is the defining attribute,
   # not the date range!
   if (!strlen($thismetric) > 0) {
      $listobject->querystring .= "    and startdate = '$startdate'::timestamp ";
      $listobject->querystring .= "    and enddate = '$enddate'::timestamp ";
   }
   $listobject->querystring .= "    and thismetric = '$depmetric' ";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   print("Inserting new records for $thismetric.<br>");
   # insert new records
   $listobject->querystring = "  insert into proj_poli_stat (projectid, poli1, poli2, ";
   $listobject->querystring .= "    poli3, poli4, startdate, enddate, thismetric, ";
   $listobject->querystring .= "    pct_cover, thisvalue ) ";
   $listobject->querystring .= " select $projectid, a.poli1, a.poli2, a.poli3, a.poli4, ";
   $listobject->querystring .= "    b.startdate, b.enddate,  ";
   $listobject->querystring .= "   '$depmetric',  ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
   $listobject->querystring .= "      THEN 1.0 ";
   $listobject->querystring .= "       ELSE sum(17065136.0 / a.area) ";
   $listobject->querystring .= "    END as pct_cover, ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
   $listobject->querystring .= "      THEN avg(b.globvalue) ";
   $listobject->querystring .= "       ELSE sum(17065136.0 * b.globvalue / a.area)";
   $listobject->querystring .= "    END as thisvalue, ";
   $listobject->querystring .= " from poli_bounds as a, proj_precip_period as b ";
   $listobject->querystring .= " where a.the_geom && b.the_geom ";
   $listobject->querystring .= "    and st_within(b.the_geom, a.the_geom) ";
   $listobject->querystring .= "    and a.projectid = $projectid ";
   $listobject->querystring .= "    and b.projectid = $projectid ";
   if (!strlen($thismetric) > 0) {
      $listobject->querystring .= "    and b.startdate = '$startdate'::timestamp ";
      $listobject->querystring .= "    and b.enddate = '$enddate'::timestamp ";
   }
   $listobject->querystring .= "    and b.datatype = '$srcmetric' ";
   $listobject->querystring .= " group by a.poli1, a.poli2, a.poli3, a.poli4, ";
   $listobject->querystring .= "    b.startdate, b.enddate ";
   $listobject->querystring .= "  order by a.poli1, a.poli2, a.poli3, a.poli4, ";
   $listobject->querystring .= "    b.startdate, b.enddate";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

}

function calcGroupPrecipDepart($listobject, $projectid, $startdate, $enddate, $thismetric, $debug) {

   # start date - first month to include (refer to the first of the month)
   # end date - last month to include
   if (strlen($thismetric) > 0) {
      $depmetric = $thismetric . '_dep_pct';
      $srcmetric = $thismetric . '_pct';
   } else {
      $depmetric = 'precip_dep_pct';
      $srcmetric = 'pct';
   }

   $listobject->querystring = "  delete from proj_group_stat ";
   $listobject->querystring .= " where projectid = $projectid ";
   # if we are passed a metric, it assumes that the metric is the defining attribute,
   # not the date range!
   if (!strlen($thismetric) > 0) {
      $listobject->querystring .= "    and startdate = '$startdate'::timestamp ";
      $listobject->querystring .= "    and enddate = '$enddate'::timestamp ";
   }
   $listobject->querystring .= "    and thismetric = '$depmetric' ";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # insert new records
   $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue, numrecs, agg_group ) ";
   $listobject->querystring .= " select $projectid, a.gid, a.groupname, b.startdate, b.enddate,  ";
   $listobject->querystring .= "   '$depmetric',  ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
   $listobject->querystring .= "      THEN 1.0 ";
   $listobject->querystring .= "       ELSE sum(17065136.0 / a.area) ";
   $listobject->querystring .= "    END as pct_cover, ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
   $listobject->querystring .= "      THEN avg(b.globvalue) ";
   $listobject->querystring .= "       ELSE sum(17065136.0 * b.globvalue / a.area)";
   $listobject->querystring .= "    END as thisvalue, ";
   $listobject->querystring .= "    min(b.globvalue) as minvalue, ";
   $listobject->querystring .= "    max(b.globvalue) as maxvalue,";
   $listobject->querystring .= "    avg(b.num_report) as numrecs, a.agg_group ";
   # uses proj_split_geomgroups instead of proj_seggroups to optimize for speed
   #$listobject->querystring .= " from proj_split_geomgroups as a, proj_precip_period as b ";
   $listobject->querystring .= " from proj_seggroups as a, proj_precip_period as b ";
   $listobject->querystring .= " where a.the_geom && b.the_geom ";
   $listobject->querystring .= "    and st_within(b.the_geom, a.the_geom) ";
   $listobject->querystring .= "    and a.projectid = $projectid ";
   $listobject->querystring .= "    and b.projectid = $projectid ";
   # if we are passed a metric, it assumes that the metric is the defining attribute,
   # not the date range!
   if (!strlen($thismetric) > 0) {
      $listobject->querystring .= "    and b.startdate = '$startdate'::timestamp ";
      $listobject->querystring .= "    and b.enddate = '$enddate'::timestamp ";
   }
   $listobject->querystring .= "    and b.datatype = '$srcmetric' ";
   $listobject->querystring .= "    and b.globvalue is not NULL ";
   $listobject->querystring .= " group by a.gid, a.groupname, b.startdate, b.enddate, a.agg_group ";
   $listobject->querystring .= "  order by a.gid, a.groupname, b.startdate, b.enddate ";

   if ($debug) {
      print ("$listobject->querystring ; <br>");
      }
   $listobject->performQuery();

}



function calcPoliPrecipObservedMonthly($listobject, $projectid, $startdate, $enddate, $thismetric, $debug) {

   # start date - first month to include (refer to the first of the month)
   # end date - last month to include
   if (strlen($thismetric) > 0) {
      $obsmetric = $thismetric . '_obs';
      $srcmetric = $thismetric . '_obs';
      $nmlmetric = $thismetric . '_nml';
      $depmetric = $thismetric . '_dep_pct';
   } else {
      $obsmetric = 'obs';
      $srcmetric = 'obs';
      $nmlmetric = 'nml';
      $depmetric = 'dep';
   }

   # need to extract starting and ending months, since this is an exclusively month-based query
   # will have to do some fancy query clauses to get the values that I need
   # when making the normal queries to insure that partial monthly summaries are used if they
   # are present
   $sd = new DateTime($startdate);
   $ed = new DateTime($enddate);

   $sm = $sd->format('n');
   $em = $ed->format('n');
   $sy = $sd->format('Y');
   $ey = $ed->format('Y');
   $eday = $ed->format('j');
   $lastday = $ed->format('t');

   $listobject->querystring = "  delete from proj_poli_stat ";
   $listobject->querystring .= " where projectid = $projectid ";
   # if we are passed a metric, it assumes that the metric is the defining attribute,
   # not the date range!
   if (!strlen($thismetric) > 0) {
      $listobject->querystring .= "    and startdate = '$startdate'::timestamp ";
      $listobject->querystring .= "    and enddate = '$enddate'::timestamp ";
   }
   $listobject->querystring .= "    and thismetric in ( '$obsmetric', '$nmlmetric', '$depmetric') ";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # now insert records for monthly normals, create temp table of months to map
   if ($listobject->tableExists('tmp_poli_stat')) {
      $listobject->querystring = "drop table tmp_poli_stat";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();
   }


   $listobject->querystring = "create temp table tmp_poli_stat (projectid integer, ";
   $listobject->querystring .= "    poli1 varchar(48),";
   $listobject->querystring .= "    poli2 varchar(48),";
   $listobject->querystring .= "    poli3 varchar(48),";
   $listobject->querystring .= "    poli4 varchar(48),";
   $listobject->querystring .= "    startdate timestamp, enddate timestamp, ";
   $listobject->querystring .= "    thismetric varchar(24), pct_cover float8, ";
   $listobject->querystring .= "    thisvalue float8, minvalue float8, maxvalue float8 ) ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # insert new observed records
   $listobject->querystring = "  insert into tmp_poli_stat (projectid, ";
   $listobject->querystring .= "    poli1, poli2, poli3, poli4, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue ) ";
   $listobject->querystring .= " select $projectid, a.poli1, a.poli2, a.poli3, a.poli4, ";
   $listobject->querystring .= "    '$startdate'::timestamp, '$enddate'::timestamp,  ";
   $listobject->querystring .= "   '$obsmetric',  ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
   $listobject->querystring .= "      THEN 1.0 ";
   $listobject->querystring .= "       ELSE sum(17065136.0 / a.area) ";
   $listobject->querystring .= "    END as pct_cover, ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
   $listobject->querystring .= "      THEN avg(b.globvalue) ";
   $listobject->querystring .= "      ELSE sum(17065136.0 * b.globvalue / a.area)";
   $listobject->querystring .= "    END as thisvalue, ";
   $listobject->querystring .= "    min(b.globvalue) as minvalue, ";
   $listobject->querystring .= "    max(b.globvalue) as maxvalue ";
   # uses proj_split_geomgroups instead of proj_seggroups to optimize for speed
   #$listobject->querystring .= " from proj_split_geomgroups as a, proj_precip_period as b ";
   $listobject->querystring .= " from poli_bounds as a, precip_gridded_monthly as b ";
   $listobject->querystring .= " where a.the_geom && b.the_geom ";
   $listobject->querystring .= "    and st_within(b.the_geom, a.the_geom) ";
   $listobject->querystring .= "    and a.projectid = $projectid ";
   $listobject->querystring .= "    and b.mo_start >= '$startdate'::timestamp ";
   $listobject->querystring .= "    and b.mo_start <= '$enddate'::timestamp ";
   # no longer used since this is a monthly summary only!
   #$listobject->querystring .= "    and b.datatype = '$srcmetric' ";
   $listobject->querystring .= "    and b.datatype = 'obs' ";
   $listobject->querystring .= "    and b.globvalue is not NULL ";
   $listobject->querystring .= " group by a.poli1, a.poli2, a.poli3, a.poli4, b.mo_start ";
   $listobject->querystring .= " order by a.poli1, a.poli2, a.poli3, a.poli4 ";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   $nextmo = $sm;
   $nextyear = $sy;

   while ( ($nextyear < $ey) or ( ($nextyear == $ey) and ($nextmo <= $em) ) ) {

      if ($nextmo > 12) {
         $nextmo = 1;
         $nextyear++;
      }

      $listobject->querystring = "  insert into tmp_poli_stat (projectid, ";
      $listobject->querystring .= "    poli1, poli2, poli3, poli4, ";
      $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
      $listobject->querystring .= "    thisvalue, minvalue, maxvalue ) ";
      $listobject->querystring .= " select $projectid, a.poli1, a.poli2, a.poli3, a.poli4, ";
      $listobject->querystring .= "    '$startdate'::timestamp, '$enddate'::timestamp,  ";
      $listobject->querystring .= "   '$nmlmetric',  ";
      $listobject->querystring .= "    CASE ";
      $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
      $listobject->querystring .= "      THEN 1.0 ";
      $listobject->querystring .= "       ELSE sum(17065136.0 / a.area) ";
      $listobject->querystring .= "    END as pct_cover, ";
      $listobject->querystring .= "    CASE ";
      $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
      $listobject->querystring .= "      THEN avg(b.globvalue) ";
      $listobject->querystring .= "       ELSE sum(17065136.0 * b.globvalue / a.area)";
      $listobject->querystring .= "    END as thisvalue, ";
      $listobject->querystring .= "    min(b.globvalue) as minvalue, ";
      $listobject->querystring .= "    max(b.globvalue) as maxvalue ";
      # uses proj_split_geomgroups instead of proj_seggroups to optimize for speed
      #$listobject->querystring .= " from proj_split_geomgroups as a, proj_precip_period as b ";
      $listobject->querystring .= " from poli_bounds as a, precip_gridded_monthly as b ";
      $listobject->querystring .= " where a.the_geom && b.the_geom ";
      $listobject->querystring .= "    and st_within(b.the_geom, a.the_geom) ";
      $listobject->querystring .= "    and a.projectid = $projectid ";
      # match a value for every normal monthly reading in the database to every
      # month in the query summary range
      $listobject->querystring .= "    and b.thismonth = $nextmo ";
      # no longer used since this is a monthly summaries only!
      #$listobject->querystring .= "    and b.datatype = '$srcmetric' ";
      # if we are asking for a partial month summary, we must look for the
      # partial month datatype.  We assume that there is only one partial month
      # summary, and it corresponds to the date range requested
      if ( (($nextmo == $em) and ($nextyear == $ey)) and ($eday < $lastday)) {
         $listobject->querystring .= "    and b.datatype = 'mtdnml' ";
      } else {
         $listobject->querystring .= "    and b.datatype = 'nml' ";
      }
      $listobject->querystring .= "    and b.globvalue is not NULL ";
      $listobject->querystring .= " group by a.poli1, a.poli2, a.poli3, a.poli4, b.mo_start ";
      $listobject->querystring .= " order by a.poli1, a.poli2, a.poli3, a.poli4 ";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();

      $nextmo++;
   }

   # now summarize and insert into proj_group_stat
   $listobject->querystring = "  insert into proj_poli_stat (projectid, ";
   $listobject->querystring .= "    poli1, poli2, poli3, poli4, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue ) ";
   $listobject->querystring .= " select projectid, poli1, poli2, poli3, poli4, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, avg(pct_cover), ";
   $listobject->querystring .= "    sum(thisvalue), sum(minvalue), sum(maxvalue) ";
   $listobject->querystring .= " from tmp_poli_stat ";
   $listobject->querystring .= " group by projectid, poli1, poli2, poli3, poli4, ";
   $listobject->querystring .= "    startdate, enddate, thismetric ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # now calculate the departure value
   $listobject->querystring = "  insert into proj_poli_stat (projectid, ";
   $listobject->querystring .= "    poli1, poli2, poli3, poli4, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, retrievaldate, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue ) ";
   $listobject->querystring .= " select b.projectid, b.poli1, b.poli2, b.poli3, b.poli4, ";
   $listobject->querystring .= "    b.startdate, b.enddate, '$depmetric', ";
   $listobject->querystring .= "    b.retrievaldate, b.pct_cover, ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "       WHEN b.thisvalue <> 0 ";
   $listobject->querystring .= "          THEN c.thisvalue / b.thisvalue ";
   $listobject->querystring .= "    ELSE NULL ";
   $listobject->querystring .= "    END as pct, ";
   $listobject->querystring .= "    c.minvalue, c.maxvalue";
   $listobject->querystring .= " from proj_poli_stat as b, ";
   $listobject->querystring .= "    proj_poli_stat as c  ";
   $listobject->querystring .= " where c.projectid = $projectid  ";
   $listobject->querystring .= "    and b.projectid = $projectid  ";
   $listobject->querystring .= "    and b.poli1 = c.poli1  ";
   $listobject->querystring .= "    and b.poli2 = c.poli2  ";
   $listobject->querystring .= "    and b.poli3 = c.poli3  ";
   $listobject->querystring .= "    and b.poli4 = c.poli4  ";
   $listobject->querystring .= "    and b.thismetric = '$nmlmetric'  ";
   $listobject->querystring .= "    and c.thismetric = '$obsmetric'  ";
   $listobject->querystring .= " order by b.thismetric ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

}

function calcGroupPrecipObservedMonthly($listobject, $projectid, $startdate, $enddate, $thismetric, $debug) {

   # start date - first month to include (refer to the first of the month)
   # end date - last month to include
   if (strlen($thismetric) > 0) {
      $obsmetric = $thismetric . '_obs';
      $srcmetric = $thismetric . '_obs';
      $nmlmetric = $thismetric . '_nml';
      $depmetric = $thismetric . '_dep_pct';
   } else {
      $obsmetric = 'obs';
      $srcmetric = 'obs';
      $nmlmetric = 'nml';
      $depmetric = 'dep';
   }

   # need to extract starting and ending months, since this is an exclusively month-based query
   # will have to do some fancy query clauses to get the values that I need
   # when making the normal queries to insure that partial monthly summaries are used if they
   # are present
   $sd = new DateTime($startdate);
   $ed = new DateTime($enddate);

   $sm = $sd->format('n');
   $em = $ed->format('n');
   $sy = $sd->format('Y');
   $ey = $ed->format('Y');
   $eday = $ed->format('j');
   $lastday = $ed->format('t');

   $listobject->querystring = "  delete from proj_group_stat ";
   $listobject->querystring .= " where projectid = $projectid ";
   # if we are passed a metric, it assumes that the metric is the defining attribute,
   # not the date range!
   if (!strlen($thismetric) > 0) {
      $listobject->querystring .= "    and startdate = '$startdate'::timestamp ";
      $listobject->querystring .= "    and enddate = '$enddate'::timestamp ";
   }
   $listobject->querystring .= "    and thismetric in ( '$obsmetric', '$nmlmetric', '$depmetric') ";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # now insert records for monthly normals, create temp table of months to map
   if ($listobject->tableExists('tmp_group_stat')) {
      $listobject->querystring = "drop table tmp_group_stat";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();
   }


   $listobject->querystring = "create temp table tmp_group_stat (projectid integer, gid integer,";
   $listobject->querystring .= "    groupname varchar(64), ";
   $listobject->querystring .= "    startdate timestamp, enddate timestamp, ";
   $listobject->querystring .= "    thismetric varchar(24), pct_cover float8, ";
   $listobject->querystring .= "    thisvalue float8, minvalue float8, maxvalue float8, agg_group integer ) ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # insert new observed records
   $listobject->querystring = "  insert into tmp_group_stat (projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
   $listobject->querystring .= " select $projectid, a.gid, a.groupname, ";
   $listobject->querystring .= "    '$startdate'::timestamp, '$enddate'::timestamp,  ";
   $listobject->querystring .= "   '$obsmetric',  ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
   $listobject->querystring .= "      THEN 1.0 ";
   $listobject->querystring .= "       ELSE sum(17065136.0 / a.area) ";
   $listobject->querystring .= "    END as pct_cover, ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
   $listobject->querystring .= "      THEN avg(b.globvalue) ";
   $listobject->querystring .= "      ELSE sum(17065136.0 * b.globvalue / a.area)";
   $listobject->querystring .= "    END as thisvalue, ";
   $listobject->querystring .= "    min(b.globvalue) as minvalue, ";
   $listobject->querystring .= "    max(b.globvalue) as maxvalue, a.agg_group ";
   # uses proj_split_geomgroups instead of proj_seggroups to optimize for speed
   #$listobject->querystring .= " from proj_split_geomgroups as a, proj_precip_period as b ";
   $listobject->querystring .= " from proj_seggroups as a, precip_gridded_monthly as b ";
   $listobject->querystring .= " where a.the_geom && b.the_geom ";
   $listobject->querystring .= "    and st_within(b.the_geom, a.the_geom) ";
   $listobject->querystring .= "    and a.projectid = $projectid ";
   $listobject->querystring .= "    and b.mo_start >= '$startdate'::timestamp ";
   $listobject->querystring .= "    and b.mo_start <= '$enddate'::timestamp ";
   # no longer used since this is a monthly summary only!
   #$listobject->querystring .= "    and b.datatype = '$srcmetric' ";
   $listobject->querystring .= "    and b.datatype = 'obs' ";
   $listobject->querystring .= "    and b.globvalue is not NULL ";
   $listobject->querystring .= " group by a.gid, a.groupname, b.mo_start, a.agg_group ";
   $listobject->querystring .= " order by a.gid, a.groupname ";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   $nextmo = $sm;
   $nextyear = $sy;

   while ( ($nextyear < $ey) or ( ($nextyear == $ey) and ($nextmo <= $em) ) ) {

      if ($nextmo > 12) {
         $nextmo = 1;
         $nextyear++;
      }

      # now insert records for normal precip values
      $listobject->querystring = "  insert into tmp_group_stat (projectid, gid, groupname, ";
      $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
      $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
      $listobject->querystring .= " select $projectid, a.gid, a.groupname, ";
      $listobject->querystring .= "    '$startdate'::timestamp, '$enddate'::timestamp,  ";
      $listobject->querystring .= "   '$nmlmetric',  ";
      $listobject->querystring .= "    CASE ";
      $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
      $listobject->querystring .= "      THEN 1.0 ";
      $listobject->querystring .= "       ELSE sum(17065136.0 / a.area) ";
      $listobject->querystring .= "    END as pct_cover, ";
      $listobject->querystring .= "    CASE ";
      $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
      $listobject->querystring .= "      THEN avg(b.globvalue) ";
      $listobject->querystring .= "       ELSE sum(17065136.0 * b.globvalue / a.area)";
      $listobject->querystring .= "    END as thisvalue, ";
      $listobject->querystring .= "    min(b.globvalue) as minvalue, ";
      $listobject->querystring .= "    max(b.globvalue) as maxvalue, a.agg_group ";
      # uses proj_split_geomgroups instead of proj_seggroups to optimize for speed
      #$listobject->querystring .= " from proj_split_geomgroups as a, proj_precip_period as b ";
      $listobject->querystring .= " from proj_seggroups as a, precip_gridded_monthly as b ";
      $listobject->querystring .= " where a.the_geom && b.the_geom ";
      $listobject->querystring .= "    and st_within(b.the_geom, a.the_geom) ";
      $listobject->querystring .= "    and a.projectid = $projectid ";
      # match a value for every normal monthly reading in the database to every
      # month in the query summary range
      $listobject->querystring .= "    and b.thismonth = $nextmo ";
      # no longer used since this is a monthly summaries only!
      #$listobject->querystring .= "    and b.datatype = '$srcmetric' ";
      # if we are asking for a partial month summary, we must look for the
      # partial month datatype.  We assume that there is only one partial month
      # summary, and it corresponds to the date range requested
      if ( (($nextmo == $em) and ($nextyear == $ey)) and ($eday < $lastday)) {
         $listobject->querystring .= "    and b.datatype = 'mtdnml' ";
      } else {
         $listobject->querystring .= "    and b.datatype = 'nml' ";
      }
      $listobject->querystring .= "    and b.globvalue is not NULL ";
      $listobject->querystring .= " group by a.gid, a.groupname, a.agg_group ";
      $listobject->querystring .= " order by a.gid, a.groupname ";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();

      $nextmo++;
   }

   # now summarize and insert into proj_group_stat
   $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
   $listobject->querystring .= " select projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, avg(pct_cover), ";
   $listobject->querystring .= "    sum(thisvalue), sum(minvalue), sum(maxvalue), agg_group ";
   $listobject->querystring .= " from tmp_group_stat ";
   $listobject->querystring .= " group by projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, agg_group ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # now calculate the departure value
   $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, retrievaldate, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
   $listobject->querystring .= " select b.projectid, b.gid, b.groupname,  ";
   $listobject->querystring .= "    b.startdate, b.enddate, '$depmetric', ";
   $listobject->querystring .= "    b.retrievaldate, b.pct_cover, ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "       WHEN b.thisvalue <> 0 ";
   $listobject->querystring .= "          THEN c.thisvalue / b.thisvalue ";
   $listobject->querystring .= "    ELSE NULL ";
   $listobject->querystring .= "    END as pct, ";
   $listobject->querystring .= "    c.minvalue, c.maxvalue, b.agg_group";
   $listobject->querystring .= " from proj_group_stat as b, ";
   $listobject->querystring .= "    proj_group_stat as c  ";
   $listobject->querystring .= " where c.projectid = $projectid  ";
   $listobject->querystring .= "    and b.projectid = $projectid  ";
   $listobject->querystring .= "    and b.gid = c.gid  ";
   $listobject->querystring .= "    and b.thismetric = '$nmlmetric'  ";
   $listobject->querystring .= "    and c.thismetric = '$obsmetric'  ";
   $listobject->querystring .= "    and c.agg_group = b.agg_group  ";
   $listobject->querystring .= " order by b.thismetric ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

}

function calcGroupDailyPrecip($listobject, $projectid, $ownerid, $thisdate, $prefix, $debug, $overwrite = 1) {

   # note, that using this routine with a date span GREATER THAN 1 DAY, causes the date index to be ignored
   # which seriously impacts performance.  Also, calculating fractional monthly values is much harder than
   # a single day form a month, so for now, this routine will only do a single day at a time

   if (!(strlen($prefix) > 0)) {
      $prefix = 'daily_precip';
   }

   $grid_size = '17065136.0';

   $depmetric = $prefix . '_dep';
   $obsmetric = $prefix . '_obs';
   $nmlmetric = $prefix . '_nml';

   # check for duplicates if we do not overwrite:
   if (!$overwrite) {
      $listobject->querystring = "  select count(*) as numrecs from proj_group_stat ";
      $listobject->querystring .= " where projectid = $projectid ";
      $listobject->querystring .= "    and startdate = '$thisdate'::timestamp ";
      $listobject->querystring .= "    and enddate = '$thisdate'::timestamp ";
      $listobject->querystring .= "    and gid in (";
      $listobject->querystring .= "       select gid  ";
      $listobject->querystring .= "       from proj_seggroups ";
      $listobject->querystring .= "       where projectid = $projectid ";
      $listobject->querystring .= "       and ( ( ownerid = $ownerid ) or ( $ownerid = -1) ) ";
      $listobject->querystring .= "    ) ";
      $listobject->querystring .= "    and thismetric in ( '$depmetric', '$obsmetric', '$nmlmetric') ";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();
      $numexisting = $listobject->getRecordValue(1,'numrecs');
   }

   if ($overwrite or ($numexisting < 3) ) {
      $listobject->querystring = "  delete from proj_group_stat ";
      $listobject->querystring .= " where projectid = $projectid ";
      $listobject->querystring .= "    and startdate = '$thisdate'::timestamp ";
      $listobject->querystring .= "    and enddate = '$thisdate'::timestamp ";
      $listobject->querystring .= "    and gid in (";
      $listobject->querystring .= "       select gid  ";
      $listobject->querystring .= "       from proj_seggroups ";
      $listobject->querystring .= "       where projectid = $projectid ";
      $listobject->querystring .= "       and ( ( ownerid = $ownerid ) or ( $ownerid = -1) ) ";
      $listobject->querystring .= "    ) ";
      $listobject->querystring .= "    and thismetric in ( '$depmetric', '$obsmetric', '$nmlmetric') ";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();

      $listobject->querystring = "  INSERT INTO proj_group_stat (projectid, gid, groupname, ";
      $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
      $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
      $listobject->querystring .= " SELECT $projectid, a.gid, a.groupname, ";
      $listobject->querystring .= "    '$thisdate', '$thisdate', '$obsmetric', ";
      # this modification introduced to eliminate problems with the normal grid differing from the daily grid
      # now, we scale the observed grid cells by the total density of grid cells overlapping each individual
      # grouping.  This is much better.
      $listobject->querystring .= "    CASE WHEN b.gid is NULL THEN 0.0 ELSE (b.precip_cells / a.max_cells) END AS pct_cover, ";
      $listobject->querystring .= "    CASE WHEN b.gid is NULL THEN 0.0 ELSE (b.area_wgtd / max_area) END AS thisvalue, ";
      $listobject->querystring .= "    CASE WHEN b.gid is NULL THEN 0.0 ELSE b.minvalue END AS minvalue, ";
      $listobject->querystring .= "    CASE WHEN b.gid is NULL THEN 0.0 ELSE b.maxvalue END AS maxvalue, ";
      $listobject->querystring .= "    a.agg_group ";
      $listobject->querystring .= " FROM ";
      $listobject->querystring .= "    ( select a.gid, a.groupname, a.agg_group, count(c.hrapx)::float8 * $grid_size as max_area, ";
      $listobject->querystring .= "         count(c.hrapx)::float8 as max_cells ";
      $listobject->querystring .= "      FROM proj_seggroups as a, precip_noaa_daily_grid as c ";
      $listobject->querystring .= "      WHERE a.projectid = $projectid  ";
      $listobject->querystring .= "         AND ( ( a.ownerid = $ownerid ) or ( $ownerid = -1) ) ";
      $listobject->querystring .= "         AND a.gid in (select gid from proj_seggroups where projectid = $projectid) ";
      $listobject->querystring .= "         AND a.the_geom && c.the_geom ";
      $listobject->querystring .= "         AND st_within(c.the_geom, a.the_geom) ";
      $listobject->querystring .= "      GROUP BY a.gid, a.groupname, a.agg_group ";
      $listobject->querystring .= "    ) as a ";
      $listobject->querystring .= " LEFT OUTER JOIN ( ";
      $listobject->querystring .= "    SELECT a.gid, ";
      $listobject->querystring .= "       count(b.hrapx)::float8 AS precip_cells, ";
      $listobject->querystring .= "       avg(b.globvalue) as mean_value, ";
      $listobject->querystring .= "       sum($grid_size * b.globvalue) as area_wgtd, ";
      $listobject->querystring .= "       min(b.globvalue) as minvalue, max(b.globvalue) as maxvalue ";
      $listobject->querystring .= "    FROM proj_seggroups as a, precip_gridded as b ";
      $listobject->querystring .= "    WHERE b.thisdate = '$thisdate' ";
      $listobject->querystring .= "       AND a.projectid = $projectid  ";
      $listobject->querystring .= "       and ( ( a.ownerid = $ownerid ) or ( $ownerid = -1) ) ";
      $listobject->querystring .= "       AND a.gid in (select gid from proj_seggroups where projectid = $projectid) ";
      $listobject->querystring .= "       AND a.the_geom && b.the_geom ";
      $listobject->querystring .= "       AND st_within(b.the_geom, a.the_geom) ";
      $listobject->querystring .= "       AND b.globvalue is not NULL ";
      $listobject->querystring .= "    GROUP BY a.gid ";
      $listobject->querystring .= " ) as b ";
      $listobject->querystring .= " ON (a.gid = b.gid)";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();


      # insert new records for normal
      $mde = new DateTime ($thisdate);
      $thisyear = $mde->format('Y');
      $thismo = $mde->format('m');
      $mostart = "$thisyear-$thismo-01";
      # check for the existence of the first of the month record, if it is there, then we can copy it,
      # otherwise, we generate an entirely new one
      $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
      $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
      $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
      $listobject->querystring .= " select projectid, gid, groupname, ";
      $listobject->querystring .= "    '$thisdate', '$thisdate', thismetric, pct_cover, ";
      $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ";
      $listobject->querystring .= " from proj_group_stat ";
      $listobject->querystring .= " where projectid = $projectid ";
      $listobject->querystring .= "    and startdate = '$mostart'::timestamp ";
      $listobject->querystring .= "    and enddate = '$mostart'::timestamp ";
      $listobject->querystring .= "    and gid in (";
      $listobject->querystring .= "       select gid from proj_seggroups where ";
      $listobject->querystring .= "          ( ( ownerid = $ownerid ) or ( $ownerid = -1) ) ";
      $listobject->querystring .= "          and projectid = $projectid  ";
      $listobject->querystring .= "       ) ";
      $listobject->querystring .= "    and thismetric = '$nmlmetric' ";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();


      # this is done without a static grid, so shifts in the data grid over time will goof up the calcs for
      # small watersheds

      #################################
      ### START WITHOUT STATIC GRID ###
      #################################
      # will use CASE statement to multiply the fractional value of the current month
      $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
      $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
      $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
      $listobject->querystring .= " select $projectid, gid, groupname, '$thisdate', '$thisdate', '$nmlmetric', ";
      $listobject->querystring .= "    avg(pct_cover) as pct_cover, ";
      $listobject->querystring .= "    sum(thisvalue) as thisvalue, ";
      $listobject->querystring .= "    sum(minvalue) as minvalue, ";
      $listobject->querystring .= "    sum(maxvalue) as maxvalue, ";
      $listobject->querystring .= "    agg_group ";
      $listobject->querystring .= " from ( ";
      # creates a query of monthly average values by shape area and month, including a partial record for hte current month
      $listobject->querystring .= "    select a.gid, a.groupname, b.thismonth, ";
      $listobject->querystring .= "       CASE WHEN sum($grid_size / a.area) >= 1 ";
      $listobject->querystring .= "          THEN 1.0 ELSE sum($grid_size / a.area) ";
      $listobject->querystring .= "       END as pct_cover,  ";
      # no need to area weight this, since it assumes total coverage, and even if we DIDN'T have total coverage
      # we would still opt to use a mean value as an estimate for the points that were NOT represented in the data
      $listobject->querystring .= "       avg(b.globvalue * 1.0 / c.num_days) as thisvalue, ";
      $listobject->querystring .= "       min(b.globvalue * 1.0 / c.num_days) as minvalue, ";
      $listobject->querystring .= "       max(b.globvalue * 1.0 / c.num_days) as maxvalue, ";
      $listobject->querystring .= "       a.agg_group ";
      $listobject->querystring .= "    from proj_seggroups as a, precip_gridded_monthly as b, def_month_days as c ";
      $listobject->querystring .= "    where b.datatype = 'nml' ";
      $listobject->querystring .= "       and b.thismonth = $thismo ";
      $listobject->querystring .= "       and c.month_no = $thismo  ";
      $listobject->querystring .= "       and a.projectid = $projectid  ";
      $listobject->querystring .= "       and ( ( a.ownerid = $ownerid ) or ( $ownerid = -1) ) ";
      # screen for summaries that have already been entered in the previous query
      $listobject->querystring .= "       and a.gid not in ( ";
      $listobject->querystring .= "          select gid ";
      $listobject->querystring .= "          from proj_group_stat ";
      $listobject->querystring .= "          where thismetric = '$nmlmetric' ";
      $listobject->querystring .= "             and startdate = '$thisdate'::timestamp ";
      $listobject->querystring .= "             and enddate = '$thisdate'::timestamp ";
      $listobject->querystring .= "             and gid in (";
      $listobject->querystring .= "                select gid from proj_seggroups where ";
      $listobject->querystring .= "                   ( ( ownerid = $ownerid ) or ( $ownerid = -1) ) ";
      $listobject->querystring .= "                   and projectid = $projectid  ";
      $listobject->querystring .= "             ) ";
      $listobject->querystring .= "             and projectid = $projectid ";
      $listobject->querystring .= "       ) ";
      $listobject->querystring .= "       and a.the_geom && b.the_geom ";
      $listobject->querystring .= "       and st_within(b.the_geom, a.the_geom) ";
      $listobject->querystring .= "       and b.globvalue is not NULL ";
      $listobject->querystring .= "    group by a.gid, a.groupname, b.thismonth, a.agg_group ";
      $listobject->querystring .= " ) as foo ";
      $listobject->querystring .= " group by gid, groupname, agg_group ";
      $listobject->querystring .= " order by gid, groupname ";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();

      ###############################
      ### END WITHOUT STATIC GRID ###
      ###############################
   }

}




function calcSingleGroupDailyPrecip($listobject, $projectid, $gid, $ownerid, $thisdate, $prefix, $debug, $overwrite = 1) {

   # note, that using this routine with a date span GREATER THAN 1 DAY, causes the date index to be ignored
   # which seriously impacts performance.  Also, calculating fractional monthly values is much harder than
   # a single day form a month, so for now, this routine will only do a single day at a time

   if (!(strlen($prefix) > 0)) {
      $prefix = 'daily_precip';
   }

   $grid_size = '17065136.0';

   $depmetric = $prefix . '_dep';
   $obsmetric = $prefix . '_obs';
   $nmlmetric = $prefix . '_nml';

   # check for duplicates if we do not overwrite:
   if (!$overwrite) {
      $listobject->querystring = "  select count(*) as numrecs from proj_group_stat ";
      $listobject->querystring .= " where projectid = $projectid ";
      $listobject->querystring .= "    and startdate = '$thisdate'::timestamp ";
      $listobject->querystring .= "    and enddate = '$thisdate'::timestamp ";
      $listobject->querystring .= "    and ( (gid = $gid) or ($gid = -1) )";
      $listobject->querystring .= "    and thismetric in ( '$depmetric', '$obsmetric', '$nmlmetric') ";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();
      $numexisting = $listobject->getRecordValue(1,'numrecs');
   }

   if ($overwrite or ($numexisting < 3) ) {
      $listobject->querystring = "  delete from proj_group_stat ";
      $listobject->querystring .= " where projectid = $projectid ";
      $listobject->querystring .= "    and startdate = '$thisdate'::timestamp ";
      $listobject->querystring .= "    and enddate = '$thisdate'::timestamp ";
      $listobject->querystring .= "    and ( (gid = $gid) or ($gid = -1) )";
      $listobject->querystring .= "    and thismetric in ( '$depmetric', '$obsmetric', '$nmlmetric') ";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();

      $listobject->querystring = "  INSERT INTO proj_group_stat (projectid, gid, groupname, ";
      $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
      $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
      $listobject->querystring .= " SELECT $projectid, a.gid, a.groupname, ";
      $listobject->querystring .= "    '$thisdate', '$thisdate', '$obsmetric', ";
      # this modification introduced to eliminate problems with the normal grid differing from the daily grid
      # now, we scale the observed grid cells by the total density of grid cells overlapping each individual
      # grouping.  This is much better.
      $listobject->querystring .= "    CASE WHEN b.gid is NULL THEN 0.0 ELSE (b.precip_cells / a.max_cells) END AS pct_cover, ";
      $listobject->querystring .= "    CASE WHEN b.gid is NULL THEN 0.0 ELSE (b.area_wgtd / max_area) END AS thisvalue, ";
      $listobject->querystring .= "    CASE WHEN b.gid is NULL THEN 0.0 ELSE b.minvalue END AS minvalue, ";
      $listobject->querystring .= "    CASE WHEN b.gid is NULL THEN 0.0 ELSE b.maxvalue END AS maxvalue, ";
      $listobject->querystring .= "    a.agg_group ";
      $listobject->querystring .= " FROM ";
      $listobject->querystring .= "    ( select a.gid, a.groupname, a.agg_group, count(c.hrapx)::float8 * $grid_size as max_area, ";
      $listobject->querystring .= "         count(c.hrapx)::float8 as max_cells ";
      $listobject->querystring .= "      FROM proj_seggroups as a, precip_noaa_daily_grid as c ";
      $listobject->querystring .= "      WHERE a.projectid = $projectid  ";
      $listobject->querystring .= "         AND ( ( a.ownerid = $ownerid ) or ( $ownerid = -1) ) ";
      $listobject->querystring .= "         AND a.the_geom && c.the_geom ";
      $listobject->querystring .= "         AND ( (a.gid = $gid) or ($gid = -1) )";
      $listobject->querystring .= "         AND st_within(c.the_geom, a.the_geom) ";
      $listobject->querystring .= "      GROUP BY a.gid, a.groupname, a.agg_group ";
      $listobject->querystring .= "    ) as a ";
      $listobject->querystring .= " LEFT OUTER JOIN ( ";
      $listobject->querystring .= "    SELECT a.gid, ";
      $listobject->querystring .= "       count(b.hrapx)::float8 AS precip_cells, ";
      $listobject->querystring .= "       avg(b.globvalue) as mean_value, ";
      $listobject->querystring .= "       sum($grid_size * b.globvalue) as area_wgtd, ";
      $listobject->querystring .= "       min(b.globvalue) as minvalue, max(b.globvalue) as maxvalue ";
      $listobject->querystring .= "    FROM proj_seggroups as a, precip_gridded as b ";
      $listobject->querystring .= "    WHERE b.thisdate = '$thisdate' ";
      $listobject->querystring .= "       AND a.projectid = $projectid  ";
      $listobject->querystring .= "       and ( ( a.ownerid = $ownerid ) or ( $ownerid = -1) ) ";
      $listobject->querystring .= "       AND ( (a.gid = $gid) or ($gid = -1) )";
      $listobject->querystring .= "       AND a.the_geom && b.the_geom ";
      $listobject->querystring .= "       AND st_within(b.the_geom, a.the_geom) ";
      $listobject->querystring .= "       AND b.globvalue is not NULL ";
      $listobject->querystring .= "    GROUP BY a.gid ";
      $listobject->querystring .= " ) as b ";
      $listobject->querystring .= " ON (a.gid = b.gid)";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();


      # insert new records for normal
      $mde = new DateTime ($thisdate);
      $thisyear = $mde->format('Y');
      $thismo = $mde->format('m');
      $mostart = "$thisyear-$thismo-01";
      # check for the existence of the first of the month record, if it is there, then we can copy it,
      # otherwise, we generate an entirely new one
      $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
      $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
      $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
      $listobject->querystring .= " select projectid, gid, groupname, ";
      $listobject->querystring .= "    '$thisdate', '$thisdate', thismetric, pct_cover, ";
      $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ";
      $listobject->querystring .= " from proj_group_stat ";
      $listobject->querystring .= " where projectid = $projectid ";
      $listobject->querystring .= "    and startdate = '$mostart'::timestamp ";
      $listobject->querystring .= "    and enddate = '$mostart'::timestamp ";
      $listobject->querystring .= "    AND ( (gid = $gid) or ($gid = -1) )";
      $listobject->querystring .= "    and thismetric = '$nmlmetric' ";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();


      # this is done without a static grid, so shifts in the data grid over time will goof up the calcs for
      # small watersheds

      #################################
      ### START WITHOUT STATIC GRID ###
      #################################
      # will use CASE statement to multiply the fractional value of the current month
      $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
      $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
      $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
      $listobject->querystring .= " select $projectid, gid, groupname, '$thisdate', '$thisdate', '$nmlmetric', ";
      $listobject->querystring .= "    avg(pct_cover) as pct_cover, ";
      $listobject->querystring .= "    sum(thisvalue) as thisvalue, ";
      $listobject->querystring .= "    sum(minvalue) as minvalue, ";
      $listobject->querystring .= "    sum(maxvalue) as maxvalue, ";
      $listobject->querystring .= "    agg_group ";
      $listobject->querystring .= " from ( ";
      # creates a query of monthly average values by shape area and month, including a partial record for hte current month
      $listobject->querystring .= "    select a.gid, a.groupname, b.thismonth, ";
      $listobject->querystring .= "       CASE WHEN sum($grid_size / a.area) >= 1 ";
      $listobject->querystring .= "          THEN 1.0 ELSE sum($grid_size / a.area) ";
      $listobject->querystring .= "       END as pct_cover,  ";
      # no need to area weight this, since it assumes total coverage, and even if we DIDN'T have total coverage
      # we would still opt to use a mean value as an estimate for the points that were NOT represented in the data
      $listobject->querystring .= "       avg(b.globvalue * 1.0 / c.num_days) as thisvalue, ";
      $listobject->querystring .= "       min(b.globvalue * 1.0 / c.num_days) as minvalue, ";
      $listobject->querystring .= "       max(b.globvalue * 1.0 / c.num_days) as maxvalue, ";
      $listobject->querystring .= "       a.agg_group ";
      $listobject->querystring .= "    from proj_seggroups as a, precip_gridded_monthly as b, def_month_days as c ";
      $listobject->querystring .= "    where b.datatype = 'nml' ";
      $listobject->querystring .= "       and b.thismonth = $thismo ";
      $listobject->querystring .= "       and c.month_no = $thismo  ";
      $listobject->querystring .= "       and a.projectid = $projectid  ";
      $listobject->querystring .= "       and ( ( a.ownerid = $ownerid ) or ( $ownerid = -1) ) ";
      # screen for summaries that have already been entered in the previous query
      $listobject->querystring .= "       AND ( (a.gid = $gid) or ($gid = -1) )";
      $listobject->querystring .= "       and a.gid not in ( ";
      $listobject->querystring .= "          select gid ";
      $listobject->querystring .= "          from proj_group_stat ";
      $listobject->querystring .= "          where thismetric = '$nmlmetric' ";
      $listobject->querystring .= "             and startdate = '$thisdate'::timestamp ";
      $listobject->querystring .= "             and enddate = '$thisdate'::timestamp ";
      $listobject->querystring .= "             AND ( (gid = $gid) or ($gid = -1) )";
      $listobject->querystring .= "             and projectid = $projectid ";
      $listobject->querystring .= "       ) ";
      $listobject->querystring .= "       and a.the_geom && b.the_geom ";
      $listobject->querystring .= "       and st_within(b.the_geom, a.the_geom) ";
      $listobject->querystring .= "       and b.globvalue is not NULL ";
      $listobject->querystring .= "    group by a.gid, a.groupname, b.thismonth, a.agg_group ";
      $listobject->querystring .= " ) as foo ";
      $listobject->querystring .= " group by gid, groupname, agg_group ";
      $listobject->querystring .= " order by gid, groupname ";
      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();

      ###############################
      ### END WITHOUT STATIC GRID ###
      ###############################
   }

}

function calcGroupNormalMonthlyPrecip($listobject, $projectid, $ownerid, $startmonth, $endmonth, $metricname, $debug) {

   # note, that using this routine with a date span GREATER THAN 1 DAY, causes the date index to be ignored
   # which seriously impacts performance.  Also, calculating fractional monthly values is much harder than
   # a single day form a month, so for now, this routine will only do a single day at a time

   if (!(strlen($metricname) > 0)) {
      $metricname = 'monthly_precip_nml';
   }

   $grid_size = '17065136.0';

   $thisyear = date('Y');
   $dateobj = new DateTime("$thisyear-$endmonth-01");
   $endday = $dateobj->format('t');

   $listobject->querystring = "  delete from proj_group_stat ";
   $listobject->querystring .= " where projectid = $projectid ";
   $listobject->querystring .= "    and startdate = '$thisyear-$startmonth-01'::timestamp ";
   $listobject->querystring .= "    and enddate = '$thisyear-$endmonth-$endday'::timestamp ";
   $listobject->querystring .= "    and gid in (";
   $listobject->querystring .= "       select gid  ";
   $listobject->querystring .= "       from proj_seggroups ";
   $listobject->querystring .= "       where projectid = $projectid ";
   $listobject->querystring .= "       and ( ( ownerid = $ownerid ) or ( $ownerid = -1) ) ";
   $listobject->querystring .= "    ) ";
   $listobject->querystring .= "    and thismetric in ( '$metricname') ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # this is done without a static grid, so shifts in the data grid over time will goof up the calcs for
   # small watersheds

   #################################
   ### START WITHOUT STATIC GRID ###
   #################################
   # will use CASE statement to multiply the fractional value of the current month
   $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
   $listobject->querystring .= " select $projectid, gid, groupname, '$thisyear-$startmonth-01', '$thisyear-$endmonth-$endday', ";
   $listobject->querystring .= "    '$metricname', ";
   $listobject->querystring .= "    avg(pct_cover) as pct_cover, ";
   $listobject->querystring .= "    sum(thisvalue) as thisvalue, ";
   $listobject->querystring .= "    sum(minvalue) as minvalue, ";
   $listobject->querystring .= "    sum(maxvalue) as maxvalue, ";
   $listobject->querystring .= "    agg_group ";
   $listobject->querystring .= " from ( ";
   # creates a query of monthly average values by shape area and month, including a partial record for hte current month
   $listobject->querystring .= "    select a.gid, a.groupname, b.thismonth, ";
   $listobject->querystring .= "       CASE WHEN sum($grid_size / a.area) >= 1 ";
   $listobject->querystring .= "          THEN 1.0 ELSE sum($grid_size / a.area) ";
   $listobject->querystring .= "       END as pct_cover,  ";
   # no need to area weight this, since it assumes total coverage, and even if we DIDN'T have total coverage
   # we would still opt to use a mean value as an estimate for the points that were NOT represented in the data
   $listobject->querystring .= "       avg(b.globvalue) as thisvalue, ";
   $listobject->querystring .= "       min(b.globvalue) as minvalue, ";
   $listobject->querystring .= "       max(b.globvalue) as maxvalue, ";
   $listobject->querystring .= "       a.agg_group ";
   $listobject->querystring .= "    from proj_seggroups as a, precip_gridded_monthly as b ";
   $listobject->querystring .= "    where b.datatype = 'nml' ";
   $listobject->querystring .= "       and b.thismonth >= $startmonth ";
   $listobject->querystring .= "       and b.thismonth <= $endmonth ";
   $listobject->querystring .= "       and a.projectid = $projectid  ";
   $listobject->querystring .= "       and ( ( a.ownerid = $ownerid ) or ( $ownerid = -1) ) ";
   $listobject->querystring .= "       and a.the_geom && b.the_geom ";
   $listobject->querystring .= "       and st_within(b.the_geom, a.the_geom) ";
   $listobject->querystring .= "       and b.globvalue is not NULL ";
   $listobject->querystring .= "    group by a.gid, a.groupname, b.thismonth, a.agg_group ";
   $listobject->querystring .= " ) as foo ";
   $listobject->querystring .= " group by gid, groupname, agg_group ";
   $listobject->querystring .= " order by gid, groupname ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   ###############################
   ### END WITHOUT STATIC GRID ###
   ###############################

}


function calcGroupMonthlyPrecip($listobject, $projectid, $ownerid, $thismonth, $thisyear, $prefix, $debug) {

   # note, that using this routine with a date span GREATER THAN 1 DAY, causes the date index to be ignored
   # which seriously impacts performance.  Also, calculating fractional monthly values is much harder than
   # a single day form a month, so for now, this routine will only do a single day at a time

   if (!(strlen($prefix) > 0)) {
      $prefix = 'monthly_precip';
   }

   $grid_size = '17065136.0';

   $depmetric = $prefix . '_dep';
   $obsmetric = $prefix . '_obs';
   $nmlmetric = $prefix . '_nml';

   $dateobj = new DateTime("$thisyear-$thismonth-01");
   $endday = $dateobj->format('t');

   $listobject->querystring = "  delete from proj_group_stat ";
   $listobject->querystring .= " where projectid = $projectid ";
   $listobject->querystring .= "    and startdate = '$thisyear-$thismonth-01'::timestamp ";
   $listobject->querystring .= "    and enddate = '$thisyear-$thismonth-$endday'::timestamp ";
   $listobject->querystring .= "    and gid in (";
   $listobject->querystring .= "       select gid  ";
   $listobject->querystring .= "       from proj_seggroups ";
   $listobject->querystring .= "       where projectid = $projectid ";
   $listobject->querystring .= "       and ( ( ownerid = $ownerid ) or ( $ownerid = -1) ) ";
   $listobject->querystring .= "    ) ";
   $listobject->querystring .= "    and thismetric in ( '$depmetric', '$obsmetric', '$nmlmetric') ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # get the observed total for this month
   # will use CASE statement to multiply the fractional value of the current month
   $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
   $listobject->querystring .= " select $projectid, gid, groupname, '$thisyear-$thismonth-01', '$thisyear-$thismonth-$endday', ";
   $listobject->querystring .= "    '$obsmetric', ";
   $listobject->querystring .= "    avg(pct_cover) as pct_cover, ";
   $listobject->querystring .= "    sum(thisvalue) as thisvalue, ";
   $listobject->querystring .= "    sum(minvalue) as minvalue, ";
   $listobject->querystring .= "    sum(maxvalue) as maxvalue, ";
   $listobject->querystring .= "    agg_group ";
   $listobject->querystring .= " from ( ";
   # creates a query of monthly average values by shape area and month, including a partial record for hte current month
   $listobject->querystring .= "    select a.gid, a.groupname, b.thismonth, ";
   $listobject->querystring .= "       CASE WHEN sum($grid_size / a.area) >= 1 ";
   $listobject->querystring .= "          THEN 1.0 ELSE sum($grid_size / a.area) ";
   $listobject->querystring .= "       END as pct_cover,  ";
   # no need to area weight this, since it assumes total coverage, and even if we DIDN'T have total coverage
   # we would still opt to use a mean value as an estimate for the points that were NOT represented in the data
   $listobject->querystring .= "       avg(b.globvalue) as thisvalue, ";
   $listobject->querystring .= "       min(b.globvalue) as minvalue, ";
   $listobject->querystring .= "       max(b.globvalue) as maxvalue, ";
   $listobject->querystring .= "       a.agg_group ";
   $listobject->querystring .= "    from proj_seggroups as a, precip_gridded_monthly as b ";
   $listobject->querystring .= "    where b.datatype = 'obs' ";
   $listobject->querystring .= "       and b.thismonth = $thismonth ";
   $listobject->querystring .= "       and b.thisyear = $thisyear ";
   $listobject->querystring .= "       and a.projectid = $projectid  ";
   $listobject->querystring .= "       and ( ( a.ownerid = $ownerid ) or ( $ownerid = -1) ) ";
   $listobject->querystring .= "       and a.the_geom && b.the_geom ";
   $listobject->querystring .= "       and st_within(b.the_geom, a.the_geom) ";
   $listobject->querystring .= "       and b.globvalue is not NULL ";
   $listobject->querystring .= "    group by a.gid, a.groupname, b.thismonth, a.agg_group ";
   $listobject->querystring .= " ) as foo ";
   $listobject->querystring .= " group by gid, groupname, agg_group ";
   $listobject->querystring .= " order by gid, groupname ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # this is done without a static grid, so shifts in the data grid over time will goof up the calcs for
   # small watersheds

   #################################
   ### START WITHOUT STATIC GRID ###
   #################################
   # will use CASE statement to multiply the fractional value of the current month
   $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
   $listobject->querystring .= " select $projectid, gid, groupname, '$thisyear-$thismonth-01', '$thisyear-$thismonth-$endday', ";
   $listobject->querystring .= "    '$nmlmetric', ";
   $listobject->querystring .= "    avg(pct_cover) as pct_cover, ";
   $listobject->querystring .= "    sum(thisvalue) as thisvalue, ";
   $listobject->querystring .= "    sum(minvalue) as minvalue, ";
   $listobject->querystring .= "    sum(maxvalue) as maxvalue, ";
   $listobject->querystring .= "    agg_group ";
   $listobject->querystring .= " from ( ";
   # creates a query of monthly average values by shape area and month, including a partial record for hte current month
   $listobject->querystring .= "    select a.gid, a.groupname, b.thismonth, ";
   $listobject->querystring .= "       CASE WHEN sum($grid_size / a.area) >= 1 ";
   $listobject->querystring .= "          THEN 1.0 ELSE sum($grid_size / a.area) ";
   $listobject->querystring .= "       END as pct_cover,  ";
   # no need to area weight this, since it assumes total coverage, and even if we DIDN'T have total coverage
   # we would still opt to use a mean value as an estimate for the points that were NOT represented in the data
   $listobject->querystring .= "       avg(b.globvalue) as thisvalue, ";
   $listobject->querystring .= "       min(b.globvalue) as minvalue, ";
   $listobject->querystring .= "       max(b.globvalue) as maxvalue, ";
   $listobject->querystring .= "       a.agg_group ";
   $listobject->querystring .= "    from proj_seggroups as a, precip_gridded_monthly as b ";
   $listobject->querystring .= "    where b.datatype = 'nml' ";
   $listobject->querystring .= "       and b.thismonth = $thismonth ";
   $listobject->querystring .= "       and a.projectid = $projectid  ";
   $listobject->querystring .= "       and ( ( a.ownerid = $ownerid ) or ( $ownerid = -1) ) ";
   $listobject->querystring .= "       and a.the_geom && b.the_geom ";
   $listobject->querystring .= "       and st_within(b.the_geom, a.the_geom) ";
   $listobject->querystring .= "       and b.globvalue is not NULL ";
   $listobject->querystring .= "    group by a.gid, a.groupname, b.thismonth, a.agg_group ";
   $listobject->querystring .= " ) as foo ";
   $listobject->querystring .= " group by gid, groupname, agg_group ";
   $listobject->querystring .= " order by gid, groupname ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   ###############################
   ### END WITHOUT STATIC GRID ###
   ###############################

}

function calcGroupPrecipFromGroup($listobject, $projectid, $startdate, $enddate, $thismetric, $debug) {

   # start date - first month to include (refer to the first of the month)
   # end date - last month to include
   if (strlen($thismetric) > 0) {
      $obsmetric = $thismetric . '_obs';
      $srcmetric = $thismetric . '_obs';
      $nmlmetric = $thismetric . '_nml';
      $depmetric = $thismetric . '_dep_pct';
   } else {
      $obsmetric = 'obs';
      $srcmetric = 'obs';
      $nmlmetric = 'nml';
      $depmetric = 'dep';
   }
   $dailyobs = 'daily_precip_obs';
   $dailynml = 'daily_precip_nml';

   # need to extract starting and ending months, since this is an exclusively month-based query
   # will have to do some fancy query clauses to get the values that I need
   # when making the normal queries to insure that partial monthly summaries are used if they
   # are present
   $sd = new DateTime($startdate);
   $ed = new DateTime($enddate);

   $sm = $sd->format('n');
   $em = $ed->format('n');
   $sy = $sd->format('Y');
   $ey = $ed->format('Y');
   $eday = $ed->format('j');
   $lastday = $ed->format('t');

   $listobject->querystring = "  delete from proj_group_stat ";
   $listobject->querystring .= " where projectid = $projectid ";
   # if we are passed a metric, it assumes that the metric is the defining attribute,
   # not the date range!
   if (!strlen($thismetric) > 0) {
      $listobject->querystring .= "    and startdate = '$startdate'::timestamp ";
      $listobject->querystring .= "    and enddate = '$enddate'::timestamp ";
   }
   $listobject->querystring .= "    and thismetric in ( '$obsmetric', '$nmlmetric', '$depmetric') ";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # now summarize and insert into proj_group_stat
   # do observed first
   $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
   $listobject->querystring .= " select projectid, gid, groupname, ";
   $listobject->querystring .= "    min(startdate), max(enddate), '$obsmetric', avg(pct_cover), ";
   $listobject->querystring .= "    sum(thisvalue), sum(minvalue), sum(maxvalue), agg_group ";
   $listobject->querystring .= " from proj_group_stat ";
   $listobject->querystring .= " where thismetric = '$dailyobs'";
   $listobject->querystring .= "    and projectid = $projectid ";
   $listobject->querystring .= "    and startdate >= '$startdate'::timestamp ";
   $listobject->querystring .= "    and enddate <= '$enddate'::timestamp ";
   $listobject->querystring .= " group by projectid, gid, groupname, agg_group ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # now summarize and insert into proj_group_stat
   # do normal
   $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
   $listobject->querystring .= " select projectid, gid, groupname, ";
   $listobject->querystring .= "    min(startdate), max(enddate), '$nmlmetric', avg(pct_cover), ";
   $listobject->querystring .= "    sum(thisvalue), sum(minvalue), sum(maxvalue), agg_group ";
   $listobject->querystring .= " from proj_group_stat ";
   $listobject->querystring .= " where thismetric = '$dailynml'";
   $listobject->querystring .= "    and projectid = $projectid ";
   $listobject->querystring .= "    and startdate >= '$startdate'::timestamp ";
   $listobject->querystring .= "    and enddate <= '$enddate'::timestamp ";
   $listobject->querystring .= " group by projectid, gid, groupname, agg_group ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # now calculate the departure value
   $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, retrievaldate, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
   $listobject->querystring .= " select b.projectid, b.gid, b.groupname,  ";
   $listobject->querystring .= "    b.startdate, b.enddate, '$depmetric', ";
   $listobject->querystring .= "    b.retrievaldate, b.pct_cover, ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "       WHEN b.thisvalue <> 0 ";
   $listobject->querystring .= "          THEN c.thisvalue / b.thisvalue ";
   $listobject->querystring .= "    ELSE NULL ";
   $listobject->querystring .= "    END as pct, ";
   $listobject->querystring .= "    c.minvalue, c.maxvalue, b.agg_group";
   $listobject->querystring .= " from proj_group_stat as b, ";
   $listobject->querystring .= "    proj_group_stat as c  ";
   $listobject->querystring .= " where c.projectid = $projectid  ";
   $listobject->querystring .= "    and b.projectid = $projectid  ";
   $listobject->querystring .= "    and b.gid = c.gid  ";
   $listobject->querystring .= "    and b.thismetric = '$nmlmetric'  ";
   $listobject->querystring .= "    and c.thismetric = '$obsmetric'  ";
   $listobject->querystring .= "    and c.agg_group = b.agg_group  ";
   $listobject->querystring .= " order by b.thismetric ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

}


function calcGroupPrecipObserved($listobject, $projectid, $startdate, $enddate, $thismetric, $debug) {

   # start date - first month to include (refer to the first of the month)
   # end date - last month to include
   if (strlen($thismetric) > 0) {
      $depmetric = $thismetric . '_obs';
      $srcmetric = $thismetric . '_obs';
   } else {
      $depmetric = 'obs';
      $srcmetric = 'obs';
   }

   $listobject->querystring = "  delete from proj_group_stat ";
   $listobject->querystring .= " where projectid = $projectid ";
   # if we are passed a metric, it assumes that the metric is the defining attribute,
   # not the date range!
   if (!strlen($thismetric) > 0) {
      $listobject->querystring .= "    and startdate = '$startdate'::timestamp ";
      $listobject->querystring .= "    and enddate = '$enddate'::timestamp ";
   }
   $listobject->querystring .= "    and thismetric = '$depmetric' ";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # insert new records
   $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, pct_cover, ";
   $listobject->querystring .= "    thisvalue, minvalue, maxvalue, agg_group ) ";
   $listobject->querystring .= " select $projectid, a.gid, a.groupname, b.startdate, b.enddate,  ";
   $listobject->querystring .= "   '$depmetric',  ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
   $listobject->querystring .= "      THEN 1.0 ";
   $listobject->querystring .= "       ELSE sum(17065136.0 / a.area) ";
   $listobject->querystring .= "    END as pct_cover, ";
   $listobject->querystring .= "    CASE ";
   $listobject->querystring .= "      WHEN sum(17065136.0 / a.area) > 1 ";
   $listobject->querystring .= "      THEN avg(b.globvalue) ";
   $listobject->querystring .= "       ELSE sum(17065136.0 * b.globvalue / a.area)";
   $listobject->querystring .= "    END as thisvalue, ";
   $listobject->querystring .= "    min(b.globvalue) as minvalue, ";
   $listobject->querystring .= "    max(b.globvalue) as maxvalue, a.agg_group ";
   # uses proj_split_geomgroups instead of proj_seggroups to optimize for speed
   #$listobject->querystring .= " from proj_split_geomgroups as a, proj_precip_period as b ";
   $listobject->querystring .= " from proj_seggroups as a, proj_precip_period as b ";
   $listobject->querystring .= " where a.the_geom && b.the_geom ";
   $listobject->querystring .= "    and st_within(b.the_geom, a.the_geom) ";
   $listobject->querystring .= "    and a.projectid = $projectid ";
   $listobject->querystring .= "    and b.projectid = $projectid ";
   # if we are passed a metric, it assumes that the metric is the defining attribute,
   # not the date range!
   if (strlen($thismetric) > 0) {
      $listobject->querystring .= "    and b.startdate = '$startdate'::timestamp ";
      $listobject->querystring .= "    and b.enddate = '$enddate'::timestamp ";
   }
   $listobject->querystring .= "    and b.datatype = '$srcmetric' ";
   $listobject->querystring .= "    and b.globvalue is not NULL ";
   $listobject->querystring .= " group by a.gid, a.groupname, b.startdate, b.enddate, a.agg_group ";
   $listobject->querystring .= " order by a.gid, a.groupname, b.startdate, b.enddate ";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

}

function quantileInterpolate($quantiles, $thisvalue, $debug, $floordefault=0.0) {
   # $quantiles must be in the form
   # array( 0.05 => 12.5, 0.10 => 13.8, ... 0.9 => 78.9)
   # with the quantile percents as keys (0.0 - 1.0)
   # and the values equal to the corresponding values
   # the routine will assume 0.0 as absolute bottom
   # if it is not explicitly passed in
   # it will not make ANY inference about a ceiling if
   # no 1.0 key is given, it will simply mark it as the highest
   # value input

   # sort this by the bounding values, so that goofy quantities such as depth to
   # groundwater, which increase as the percent decreases, will be calculated properly
   if ($debug) {
      print_r($quantiles);
      print("<br>");
   }
   asort($quantiles);
   if ($debug) {
      print_r($quantiles);
      print("<br>");
   }
   $quans = array_keys($quantiles);
   $vals = array_values($quantiles);
   $quantile = -1;

   if (!(count($quans) > 1))  {
      $out['error'] = 1;
      $out['message'] = 'You must pass at least 2 values in for quantile assignment to work';
      return $out;
   }

   # assume that a zero value is included in the given quantiles
   $floor = $vals[0];
   $qlo = $quans[0];
   $st = 1;
   $c = count($quans);

   for ($i = $st; $i <= ($c - 1); $i++) {
      $qhi = $quans[$i];
      $ciel = $vals[$i];
      if ($debug) { print("[$i / $c]: Checking $thisvalue against $floor ($qlo) and $ciel ($qhi) <br>"); }
      if ( ($thisvalue <= $ciel) and ($thisvalue > $floor) ) {
         # we have a match, interpolate here
         if ($ceil == $floor) {
            $out['message'] = 'You have matching quantile values.  Returned quantile is estimated as midway.';
            $pct = 0.5;
         } else {
            $pct = ($thisvalue - $floor) / ($ciel - $floor);
         }
         if ($debug) {
            print(" quantile = $pct * ($qhi - $qlo) + $qlo <br>");
         }
         $quantile = $pct * ($qhi - $qlo) + $qlo;
         break;
      }
      $qlo = $qhi;
      $floor = $ciel;
   }

   if ($quantile == -1) {
      # see it it is above the max or below min, i.e. the last and first values in the array
      if ($thisvalue > $vals[$c-1]) {
         $quantile = $quans[$c-1];
      }
      if ($thisvalue < $vals[0]) {
         $quantile = $quans[0];
      }
   }

   if ($quantile == -1) {
      $out['error'] = 1;
   }

   $out['quantile'] = $quantile;

   return $out;
}

function calcGroupNDayStreamStage($listobject, $projectid, $sitelist, $thisdate, $period, $thisdatacode, $thismetric, $datatype, $indicator_sites, $overwrite, $debug) {

   $sd = new DateTime($thisdate);
   $pdminusone = -1 * ($period - 1);
   $sd->modify("$pdminusone day");
   $startdate = $sd->format('Y-m-d');
   calcGroupPeriodStreamStage($listobject, $projectid, $sitelist, $thisdate, $startdate, $thisdatacode, $thismetric, $datatype, $indicator_sites, $overwrite, $debug);
}

function calcGroupPeriodStreamStage($listobject, $projectid, $sitelist, $thisdate, $startdate, $thisdatacode, $thismetric, $datatype, $indicator_sites, $overwrite, $debug) {

   $ldebug = $debug;

   if (strlen(ltrim(rtrim($sitelist))) > 0) {
      # specific sites requested
      $sitewhere = " site_no in ( '" . join("','", split(',', $sitelist)) . "' ) ";
   } else {
      $sitewhere = " ( 1 = 1 ) ";
   }

   if (strlen(ltrim(rtrim($startdate))) > 0) {
      $sclause = "startdate >= '$startdate'";
      $eclause = "enddate <= '$thisdate'";
   } else {
      $sclause = "(1 = 1)";
      $eclause = "(1 = 1)";
   }

   $retrievaldate = date('Y-m-d');

   # looks for most recent N days report
   # set enddate = $thisdate in report (date requested)
   # set startdate = $thisdate in report
   # will try to get a period that matches the requested, but will accept the longest
   # period that is less than or equal to the requested period

   # now, default to deleting, $overwrite variable is deprecated, assumes metric is
   # descriptive enough to handle all contingencies
   $listobject->querystring = "  delete from proj_group_stat ";
   $listobject->querystring .= " where projectid = $projectid ";
   $listobject->querystring .= "    and ( (thismetric = '$thismetric') ";
   $listobject->querystring .= "          or ( thismetric = '$thismetric' || '_value' ) ";
   $listobject->querystring .= "    ) ";
   $listobject->querystring .= "    and gid in ( ";
   $listobject->querystring .= "       select gid from map_group_site ";
   $listobject->querystring .= "       where $sitewhere ) ";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # get stations and flows
   $listobject->querystring = "  select a.site_no, c.gid, d.startdate, b.enddate, b.mean_val, b.min_val, b.max_val,";
   $listobject->querystring .= "    b.retrievaldate, b.num_recs ";
   $listobject->querystring .= " from ";
   $listobject->querystring .= " (";
   $listobject->querystring .= "    select site_no, max(enddate) as enddate ";
   $listobject->querystring .= "    from stats_site_period ";
   $listobject->querystring .= "    where $eclause ";
   $listobject->querystring .= "       and datatype = '$datatype' ";
   $listobject->querystring .= "       and $sitewhere ";
   $listobject->querystring .= "    group by site_no ";
   $listobject->querystring .= " ) as a, ";
   $listobject->querystring .= " (";
   $listobject->querystring .= "    select site_no, min(startdate) as startdate, enddate ";
   $listobject->querystring .= "    from stats_site_period ";
   $listobject->querystring .= "    where $eclause ";
   $listobject->querystring .= "       and $sclause ";
   $listobject->querystring .= "       and datatype = '$datatype' ";
   $listobject->querystring .= "       and $sitewhere ";
   $listobject->querystring .= "    group by site_no, enddate ";
   $listobject->querystring .= " ) as d, ";
   $listobject->querystring .= " stats_site_period as b, map_group_site as c, proj_seggroups as e ";
   $listobject->querystring .= " where a.site_no = b.site_no ";
   $listobject->querystring .= "    and a.site_no = c.site_no ";
   $listobject->querystring .= "    and a.site_no = d.site_no ";
   $listobject->querystring .= "    and d.startdate = b.startdate ";
   $listobject->querystring .= "    and a.enddate = b.enddate ";
   $listobject->querystring .= "    and a.enddate = d.enddate ";
   $listobject->querystring .= "    and b.datatype = '$datatype' ";
   # make sure that we do not get duplicate entries is projects share a station.
   # thus, we include link to proj_seggroups, and screen for projectid on it
   $listobject->querystring .= "    and e.projectid = $projectid ";
   $listobject->querystring .= "    and c.gid = e.gid ";
   if ($indicator_sites) {
      # use only sites signified as indicator sites in the map_group_site table
      $listobject->querystring .= "    and c.indicator_site = 1 ";
   }

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   $siterecs = $listobject->queryrecords;

   foreach($siterecs as $thissite) {

      $sdate = $thissite['startdate'];
      $edate = $thissite['enddate'];
      $site_no = $thissite['site_no'];
      $numrecs = $thissite['num_recs'];
      # custom debug
      if ($site_no == '') {
         $debug = 1;
      } else {
         $debug = $ldebug;
      }
      $mean_val = $thissite['mean_val'];
      $min_val = $thissite['min_val'];
      $max_val = $thissite['max_val'];
      $gid = $thissite['gid'];

      $syear = date('Y', strtotime($sdate));
      $eyear = date('Y', strtotime($edate));
      $sday = date('d', strtotime($sdate));
      $eday = date('d', strtotime($edate));

 
      # get stations and flows
      $listobject->querystring = "  select site_no, avg(min_va) as min_va, avg(max_va) as max_va, ";
      $listobject->querystring .= "    avg(p05_va) as p05_va, avg(p10_va) as p10_va, ";
      $listobject->querystring .= "    avg(p20_va) as p20_va, avg(p25_va) as p25_va, ";
      $listobject->querystring .= "    avg(p50_va) as p50_va, avg(p75_va) as p75_va, ";
      $listobject->querystring .= "    avg(p80_va) as p80_va, avg(p90_va) as p90_va, ";
      $listobject->querystring .= "    avg(p95_va) as p95_va ";
      $listobject->querystring .= " from  ";
      $listobject->querystring .= " ( select date_series.dates, a.* from site_daily_stats as a,  ";
      $listobject->querystring .= "      ( select '$sdate'::date + s.a as dates ";
      $listobject->querystring .= "        from generate_series(0,extract(days from ('$edate'::timestamp - ";
      $listobject->querystring .= "           '$sdate'::timestamp))::integer,1) as s(a) ";
      $listobject->querystring .= "   ) as date_series ";
      $listobject->querystring .= "   where a.site_no = '$site_no' ";
      $listobject->querystring .= "      and a.month_nu = extract(month from dates) ";
      $listobject->querystring .= "      and a.day_nu = extract(day from dates) ";
      $listobject->querystring .= " ) as foo ";
      $listobject->querystring .= " where parameter_cd = '$thisdatacode' ";
      $listobject->querystring .= " group by site_no ";

      if ($debug) { print ("$listobject->querystring ; <br>"); }
      
      $listobject->performQuery();
      $listobject->showList();

      $theserecs = $listobject->queryrecords;
      $k = 0;
      $minq = '';
      $maxq = '';
      $qaccum = 0;

      foreach ($theserecs as $thisrec) {
         $k++;
         $min_va = $thisrec['min_va'];
         $p05 = $thisrec['p05_va'];
         $p10 = $thisrec['p10_va'];
         $p20 = $thisrec['p20_va'];
         $p25 = $thisrec['p25_va'];
         $p50 = $thisrec['p50_va'];
         $p75 = $thisrec['p75_va'];
         $p80 = $thisrec['p80_va'];
         $p90 = $thisrec['p90_va'];
         $p95 = $thisrec['p95_va'];
         $max_va = $thisrec['max_va'];

         if (strlen($min_va) > 0) {
            $quantiles['0.0'] = $thisrec['min_va'];
         }
         if (strlen($p05) > 0) {
            $quantiles['0.05'] = $thisrec['p05_va'];
         }
         if (strlen($p10) > 0) {
            $quantiles['0.10'] = $thisrec['p10_va'];
         }
         if (strlen($p20) > 0) {
            $quantiles['0.20'] = $thisrec['p20_va'];
         }
         if (strlen($p25) > 0) {
            $quantiles['0.25'] = $thisrec['p25_va'];
         }
         if (strlen($p50) > 0) {
            $quantiles['0.5'] = $thisrec['p50_va'];
         }
         if (strlen($p75) > 0) {
            $quantiles['0.75'] = $thisrec['p75_va'];
         }
         if (strlen($p80) > 0) {
            $quantiles['0.8'] = $thisrec['p80_va'];
         }
         if (strlen($p90) > 0) {
            $quantiles['0.9'] = $thisrec['p90_va'];
         }
         if (strlen($p95) > 0) {
            $quantiles['0.95'] = $thisrec['p95_va'];
         }
         if (strlen($max_va) > 0) {
            $quantiles['1.0'] = $thisrec['max_va'];
         }

         #print_r($quantiles);
         $qout = quantileInterpolate($quantiles, $mean_val, $debug, 0.0);
         $q = $qout['error'];
         $q = $qout['quantile'];
         $qhundred = number_format($q * 100.0,2);
         $mf = number_format($mean_val,2);
         $qm = $qout['message'];
         print("Analyzing data from site: <b>$site_no</b> for period closest to $startdate - $thisdate.<br>");
         if (strlen($qm) > 0) {
            print("$qm<br>");
         }
         if (strlen($q) > 0) {
            $qaccum += $q;
            if ( ($maxq == '') or ($q > $maxq) ) {
               $maxq = $q;
            }
            if ( ($minq == '') or ($q < $minq) ) {
               $minq = $q;
            }
         }
         print("Mean Value of site $k $mean_val estimated to <b>$qhundred</b> percentile .<br>");
      }

      if ($k > 0) {
         $meanq = $qaccum / $k;
         # insert new records
         $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
         $listobject->querystring .= "    startdate, enddate, retrievaldate, thismetric, ";
         $listobject->querystring .= "    pct_cover, thisvalue, minvalue, maxvalue, numrecs, agg_group ) ";
         $listobject->querystring .= " select $projectid, a.gid, b.groupname, ";
         $listobject->querystring .= "    '$sdate', '$edate', '$retrievaldate', '$thismetric', ";
         $listobject->querystring .= "    1.0, $meanq, $minq, $maxq, $numrecs, b.agg_group ";
         $listobject->querystring .= " from map_group_site as a, proj_seggroups as b ";
         $listobject->querystring .= " where a.site_no = '$site_no' ";
         $listobject->querystring .= "    and a.gid = b.gid ";
         $listobject->querystring .= "    and a.gid = $gid ";
         $listobject->querystring .= "    and b.projectid = $projectid ";

         if ($debug) { print ("$listobject->querystring ; <br>"); }
         $listobject->performQuery();
         # insert new records for mean observed
         $omet = $thismetric . '_value';
         $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
         $listobject->querystring .= "    startdate, enddate, retrievaldate, thismetric, ";
         $listobject->querystring .= "    pct_cover, thisvalue, minvalue, maxvalue, numrecs, agg_group ) ";
         $listobject->querystring .= " select $projectid, a.gid, b.groupname, ";
         $listobject->querystring .= "    '$sdate', '$edate', '$retrievaldate', '$omet' , ";
         $listobject->querystring .= "    1.0, $mean_val, $min_val, $max_val, $numrecs, b.agg_group ";
         $listobject->querystring .= " from map_group_site as a, proj_seggroups as b ";
         $listobject->querystring .= " where a.site_no = '$site_no' ";
         $listobject->querystring .= "    and a.gid = b.gid ";
         $listobject->querystring .= "    and a.gid = $gid ";
         $listobject->querystring .= "    and b.projectid = $projectid ";

         if ($debug) { print ("$listobject->querystring ; <br>"); }
         $listobject->performQuery();
         print("Group stats recorded for $k sites with mean: $meanq, min: $minq, and max: $maxq .<br>");
      }
   }

}


function calcGroupPeriodStreamFlow($listobject, $projectid, $sitelist, $thisdate, $startdate, $thisdatacode, $thismetric, $datatype, $indicator_sites, $overwrite, $debug) {

   $ldebug = $debug;

   if (strlen(ltrim(rtrim($sitelist))) > 0) {
      # specific sites requested
      $sitewhere = " site_no in ( '" . join("','", split(',', $sitelist)) . "' ) ";
   } else {
      $sitewhere = " ( 1 = 1 ) ";
   }

   if (strlen(ltrim(rtrim($startdate))) > 0) {
      $sclause = "startdate >= '$startdate'";
      $eclause = "enddate <= '$thisdate'";
   } else {
      $sclause = "(1 = 1)";
      $eclause = "(1 = 1)";
   }

   $retrievaldate = date('Y-m-d');

   # looks for most recent N days report
   # set enddate = $thisdate in report (date requested)
   # set startdate = $thisdate in report
   # will try to get a period that matches the requested, but will accept the longest
   # period that is less than or equal to the requested period

   # now, default to deleting, $overwrite variable is deprecated, assumes metric is
   # descriptive enough to handle all contingencies
   $listobject->querystring = "  delete from proj_group_stat ";
   $listobject->querystring .= " where projectid = $projectid ";
   $listobject->querystring .= "    and thismetric = '$thismetric' ";
   $listobject->querystring .= "    and gid in ( ";
   $listobject->querystring .= "       select gid from map_group_site ";
   $listobject->querystring .= "       where $sitewhere ) ";

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   # get stations and flows
   $listobject->querystring = "  select a.site_no, c.gid, d.startdate, b.enddate, b.mean_val,";
   $listobject->querystring .= "    b.min_val, b.max_val, b.retrievaldate, b.num_recs ";
   $listobject->querystring .= " from ";
   $listobject->querystring .= " (";
   $listobject->querystring .= "    select site_no, max(enddate) as enddate ";
   $listobject->querystring .= "    from stats_site_period ";
   $listobject->querystring .= "    where $eclause ";
   $listobject->querystring .= "       and datatype = '$datatype' ";
   $listobject->querystring .= "       and $sitewhere ";
   $listobject->querystring .= "    group by site_no ";
   $listobject->querystring .= " ) as a, ";
   $listobject->querystring .= " (";
   $listobject->querystring .= "    select site_no, min(startdate) as startdate, enddate ";
   $listobject->querystring .= "    from stats_site_period ";
   $listobject->querystring .= "    where $eclause ";
   $listobject->querystring .= "       and $sclause ";
   $listobject->querystring .= "       and datatype = '$datatype' ";
   $listobject->querystring .= "       and $sitewhere ";
   $listobject->querystring .= "    group by site_no, enddate ";
   $listobject->querystring .= " ) as d, ";
   $listobject->querystring .= " stats_site_period as b, map_group_site as c, proj_seggroups as e ";
   $listobject->querystring .= " where a.site_no = b.site_no ";
   $listobject->querystring .= "    and a.site_no = c.site_no ";
   $listobject->querystring .= "    and a.site_no = d.site_no ";
   $listobject->querystring .= "    and d.startdate = b.startdate ";
   $listobject->querystring .= "    and a.enddate = b.enddate ";
   $listobject->querystring .= "    and a.enddate = d.enddate ";
   $listobject->querystring .= "    and b.datatype = '$datatype' ";
   # make sure that we do not get duplicate entries is projects share a station.
   # thus, we include link to proj_seggroups, and screen for projectid on it
   $listobject->querystring .= "    and e.projectid = $projectid ";
   $listobject->querystring .= "    and c.gid = e.gid ";
   if ($indicator_sites) {
      # use only sites signified as indicator sites in the map_group_site table
      $listobject->querystring .= "    and c.indicator_site = 1 ";
   }

   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   $siterecs = $listobject->queryrecords;

   foreach($siterecs as $thissite) {

      $sdate = $thissite['startdate'];
      $edate = $thissite['enddate'];
      $site_no = $thissite['site_no'];
      $numrecs = $thissite['num_recs'];
      # custom debug
      if ($site_no == '') {
         $debug = 1;
      } else {
         $debug = $ldebug;
      }
      $mean_val = $thissite['mean_val'];
      $min_val = $thissite['min_val'];
      $max_val = $thissite['max_val'];
      if ( (strlen($mean_val) == 0) or (strlen($mean_val) == 'NULL')) {
         $mean_val = 'NULL';
         $max_val = 'NULL';
         $min_val = 'NULL';
      }
      $gid = $thissite['gid'];

      $syear = date('Y', strtotime($sdate));
      $eyear = date('Y', strtotime($edate));
      $sday = date('d', strtotime($sdate));
      $eday = date('d', strtotime($edate));

      # insert new records
      $listobject->querystring = "  insert into proj_group_stat (projectid, gid, groupname, ";
      $listobject->querystring .= "    startdate, enddate, retrievaldate, thismetric, ";
      $listobject->querystring .= "    pct_cover, thisvalue, minvalue, maxvalue, numrecs, agg_group ) ";
      $listobject->querystring .= " select $projectid, a.gid, b.groupname, ";
      $listobject->querystring .= "    '$sdate', '$edate', '$retrievaldate', '$thismetric', ";
      $listobject->querystring .= "    1.0, $mean_val, $min_val, $max_val, $numrecs, b.agg_group ";
      $listobject->querystring .= " from map_group_site as a, proj_seggroups as b ";
      $listobject->querystring .= " where a.site_no = '$site_no' ";
      $listobject->querystring .= "    and a.gid = b.gid ";
      $listobject->querystring .= "    and b.projectid = $projectid ";

      if ($debug) { print ("$listobject->querystring ; <br>"); }
      $listobject->performQuery();
      print("Group stats recorded for $k sites with mean: $meanq, min: $minq, and max: $maxq .<br>");
   }

}

function createSyntheticDailyFromMonthly($listobject, $thisparam, $debug) {

   # clean up
   $listobject->querystring = "  delete from site_daily_stats ";
   $listobject->querystring .= " where site_daily_stats.site_no in ";
   $listobject->querystring .= "    (select site_no from site_monthly_stats ";
   $listobject->querystring .= "     where parameter_cd = '$thisparam' ";
   $listobject->querystring .= "     group by site_no ";
   $listobject->querystring .= "    )";
   $listobject->querystring .= "    and parameter_cd = '$thisparam' ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   for ($mon = 1; $mon <= 12; $mon++) {
      $pmon = str_pad($mon, 2, '0', STR_PAD_LEFT);
      $dateobj = new DateTime("2005-$pmon-01");
      $numdays = $dateobj->format('t');
      if ($mon == 2) {
         $numdays = 29; # manually set for February
      }
      $textmo = $dateobj->format('M');

      print("Creating synthetic $thisparam values for $textmo .<br>");

      for ($day = 1; $day <= $numdays; $day++) {

         $listobject->querystring = "  insert into site_daily_stats (site_no, parameter_cd, ";
         $listobject->querystring .= "    agency_cd, month_nu, day_nu, min_va, max_va, ";
         $listobject->querystring .= "    p05_va, p10_va, p25_va, p50_va, p75_va, p90_va, p95_va, count_nu ) ";
         $listobject->querystring .= " select site_no, parameter_cd, ";
         $listobject->querystring .= "    agency_cd, $mon, $day, min_va, max_va, ";
         $listobject->querystring .= "    p05_va, p10_va, p25_va, p50_va, p75_va, p90_va, p95_va, count_nu ";
         $listobject->querystring .= " from site_monthly_stats ";
         $listobject->querystring .= " where parameter_cd = '$thisparam' ";
         $listobject->querystring .= "    and month = '$textmo' ";

         if ($debug) { print ("$listobject->querystring ; <br>"); }
         $listobject->performQuery();
      }
   }
}


function importSiteDailyStats($listobject, $thisparam, $debug) {

   # clean up
   $listobject->querystring = "  delete from site_daily_stats ";
   $listobject->querystring .= " where site_daily_stats.site_no in ";
   $listobject->querystring .= "    (select site_no from site_monthly_stats ";
   $listobject->querystring .= "     where parameter_cd = '$thisparam' ";
   $listobject->querystring .= "     group by site_no ";
   $listobject->querystring .= "    )";
   $listobject->querystring .= "    and parameter_cd = '$thisparam' ";
   if ($debug) { print ("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   for ($mon = 1; $mon <= 12; $mon++) {
      $pmon = str_pad($mon, 2, '0', STR_PAD_LEFT);
      $dateobj = new DateTime("2005-$pmon-01");
      $numdays = $dateobj->format('t');
      if ($mon == 2) {
         $numdays = 29; # manually set for February
      }
      $textmo = $dateobj->format('M');

      print("Creating synthetic $thisparam values for $textmo .<br>");

      for ($day = 1; $day <= $numdays; $day++) {

         $listobject->querystring = "  insert into site_daily_stats (site_no, parameter_cd, ";
         $listobject->querystring .= "    agency_cd, month_nu, day_nu, min_va, max_va, ";
         $listobject->querystring .= "    p10_va, p25_va, p50_va, p75_va, p90_va, count_nu ) ";
         $listobject->querystring .= " select site_no, parameter_cd, ";
         $listobject->querystring .= "    agency_cd, $mon, $day, min_va, max_va, ";
         $listobject->querystring .= "    p10_va, p25_va, p50_va, p75_va, p90_va, count_nu ";
         $listobject->querystring .= " from site_monthly_stats ";
         $listobject->querystring .= " where parameter_cd = '$thisparam' ";
         $listobject->querystring .= "    and month = '$textmo' ";

         if ($debug) { print ("$listobject->querystring ; <br>"); }
         $listobject->performQuery();
      }
   }
}



function createUSGSPeriodSummary($listobject, $sd, $ed, $sitelist, $siteinfocode, $stype, $replace, $thisdatacode, $datatype, $debug, $period = '') {

   $today = date("Y-m-d");

   $usgs_result = retrieveUSGSData($sitelist, '', $debug, '', '', $siteinfocode, '', '', '', '');
   $sitedata = $usgs_result['row_array'];
   $numrecs = $usgs_result['numrecs'];
   print("Found information for $numrecs stations.  Debug switch= $debug<br>");


   foreach ($sitedata as $thisdata) {
      $siteno = $thisdata['site_no'];
      $site_id = $thisdata['site_id'];
      $dec_lat_va = $thisdata['dec_lat_va'];
      $dec_long_va = $thisdata['dec_long_va'];
      $state_cd = $thisdata['state_cd'];
      $alt_va = $thisdata['alt_va'];

      # check for point in site db
      $listobject->querystring = "  select count(*) as numsites from monitoring_sites ";
      $listobject->querystring .= " where site_no = '$siteno' ";
      $listobject->querystring .= "    and site_type = $stype ";
      $listobject->performQuery();
      $numsites = $listobject->getRecordValue(1,'numsites');
      if (!($numsites > 0)) {
         print("Adding record for site $siteno, LAT: $dec_lat_va, LON: $dec_long_va.<br>");
         if (ltrim(rtrim($alt_va)) == '') {
            $alt_va = 'NULL';
         }
         $listobject->querystring = "  insert into monitoring_sites(site_no, site_id, dec_lat_va, dec_long_va, ";
         $listobject->querystring .= "    state_cd, alt_va, site_type, the_geom ) ";
         $listobject->querystring .= " values ('$siteno', '$site_id', $dec_lat_va, $dec_long_va, ";
         $listobject->querystring .= "    '$state_cd', $alt_va, $stype, ";
         $listobject->querystring .= "    PointFromText('POINT($dec_long_va $dec_lat_va)',4326) ";
         $listobject->querystring .= " ) ";
         if ($debug) { print("$listobject->querystring ; <br>"); }
         $listobject->performQuery();
      }

      $listobject->querystring = "  select count(*) as numrecs from stats_site_period ";
      $listobject->querystring .= " where site_no = '$siteno' ";
      if (strlen($ed) > 0) {
         $listobject->querystring .= "    and enddate = '$ed' ";
      }
      if (strlen($sd) > 0) {
         $listobject->querystring .= "    and startdate = '$sd' ";
      }
      $listobject->querystring .= "    and datatype = '$datatype' ";
      if ($debug) { print("$listobject->querystring ; <br>"); }
      $listobject->performQuery();
      $numrecs = $listobject->getRecordValue(1,'numrecs');
      if (!($replace) and ($numrecs > 0)) {
         print("Station statistics already in database for site: $siteno. Skipping. <br>");
      } else {
         print("Retrieving daily flow stats for $siteno.<br>");
         if (strlen($sd) > 0) {
            $period = '';
         }
         # gets daily flow values for indicated period
         $site_result = retrieveUSGSData($siteno, $period, $debug, $sd, $ed, 1, '', 'rdb', $thisdatacode);
         $gagedata = $site_result['row_array'];
         if ($debug) {
            print('USGS Debug INfo: ' . $site_result['debug'] . '<br>');
         }

         $numstats = count($gagedata);

         $thisno = $gagedata[0]['site_no'];
         $thiscomment = "<b>USGS Site:</b> $thisno<br>\n";
         $thiscomment .= "<b>Retrieved:</b> $today<br>\n";
         $thisdatatable = "array[";
         $flowaccum = 0;
         $nr = 0;
         $mindate = '';
         $maxdate = '';
         if (count($gagedata) > 0) {
            $mindate = $gagedata[0]['datetime'];
            $maxdate = $gagedata[count($gagedata)-1]['datetime'];
         }

         print("Clearing old stats from local database for $siteno.<br>");
         $listobject->querystring = "  delete from stats_site_period ";
         $listobject->querystring .= " where site_no = '$siteno' ";
         if (strlen($ed) > 0) {
            $listobject->querystring .= "    and enddate = '$maxdate' ";
         }
         if (strlen($sd) > 0) {
            $listobject->querystring .= "    and startdate = '$mindate' ";
         }
         $listobject->querystring .= "    and datatype = '$datatype' ";
         if ($debug) { print("$listobject->querystring ; <br>"); }
         $listobject->performQuery();

         print("Inserting $numstats new daily flow stats for $siteno (ID: $siteid).<br>");
         if ($numstats > 0) {
            $j++;
         }
         
         if ($stype == 2) {
            $gagedata = array();
            // groundwater, use a USGSGageObject for the data
            $gobj = new USGSGageObject;
            $gobj->debug = 1;
            $gobj->debugmode = 2;
            $gobj->staid = $siteno;
            $gobj->startdate = $sd;
            $gobj->enddate = $ed;
            $gobj->sitetype = 2;
            $gobj->wake();
            $gobj->init();
            foreach ($gobj->tsvalues as $thisval) {
               $gagedata[] = array('datetime' => $thisval['thisdate'], $thisdatacode => $thisval['tabledepth']);
            }
            //print_r($gobj->tsvalues);
            //die;
         }
         

         $flows = array();
         $rdel = '';
         if (count($gagedata) == 0) {
            # postgresql will throw an error if it receives an empty array
            $thisdatatable .= "0,0,0";
         }
         foreach ($gagedata as $thisdata) {

            $thisdate = $thisdata['datetime'];
            $thisflag = '';
            # default to missing
            $thisflow = 'N/A';
            foreach (array_keys($thisdata) as $thiscol) {

               if (substr_count($thiscol, $thisdatacode)) {
                  # this is a flow related column, check if it is a flag or data
                  if (substr_count($thiscol, 'cd')) {
                     # this is a flag
                     $thisflag = $thisdata[$thiscol];
                  } else {
                     # must be a flow value
                     if ($thisflow <> '') {
                        $thisflow = $thisdata[$thiscol];
                     } else {
                        $thisflow = 'N/A';
                     }
                  }
               }
            }
            if ( ($thisflow <> 'N/A') and (ltrim(rtrim($thisflow)) <> '') ) {
               array_push($flows, $thisflow);
               $flowaccum += $thisflow;
               $nr++;
            }
            $thisdatatable .= $rdel . "['$thisdate','$thisflow','$thisflag']";
            $rdel = ',';
         }
         $thisdatatable .= "]";
         if ($nr > 0) {
            $mean_val = $flowaccum / $nr;
            sort($flows);
            $min_val = $flows[0];
            $max_val = $flows[count($flows)-1];
         } else {
            $mean_val = 'NULL';
            $min_val = 'NULL';
            $max_val = 'NULL';
         }
         #print_r($flows);
         $thiscomment .= "<b>Records:</b> $nr<br>\n";
         $thiscomment .= "<b>Mean Value:</b> $meanflow<br>\n";
         $thiscomment .= $thisdatatable;
         $listobject->querystring = "  insert into stats_site_period ( site_no, retrievaldate, ";
         $listobject->querystring .= "    startdate, enddate, dataflag, num_recs, ";
         $listobject->querystring .= "    mean_val, min_val, max_val, datatable, datatype ) ";
         $listobject->querystring .= " values ( '$thisno', '$today', ";
         $listobject->querystring .= "    '$mindate', '$maxdate', '$thisflag', $nr, ";
         $listobject->querystring .= "    $mean_val, $min_val, $max_val, $thisdatatable, '$datatype' ) ";
         if ($debug) { print("$listobject->querystring ; <br>"); }
         $listobject->performQuery();
         #print("$listobject->querystring ; <br>");

      }
   }
   print("Inserted flow stats for $j stations.<br>");

}



function updateUSGSSiteInfo($listobject, $siteinfocode, $stype, $debug) {

/*
   $today = date("Y-m-d");

   $listobject->querystring = "  select site_no from monitoring_sites ";
   $listobject->querystring .= " where site_type = $stype ";
   $listobject->performQuery();

   $sdel = '';
   foreach($listobject->queryrecords as $thisrec) {
      $sitelist .= $sdel . $thisrec['site_no'];
      $sdel = ',';
   }
*/

   $usgs_result = retrieveUSGSData($sitelist, '', $debug, '', '', $siteinfocode, '', '', '', '');
   $sitedata = $usgs_result['row_array'];
   $numrecs = $usgs_result['numrecs'];
   print("Found information for $numrecs stations.<br>");


   foreach ($sitedata as $thisdata) {
      $siteno = $thisdata['site_no'];
      $site_id = $thisdata['site_id'];
      $dec_lat_va = $thisdata['dec_lat_va'];
      $dec_long_va = $thisdata['dec_long_va'];
      $state_cd = $thisdata['state_cd'];
      $alt_va = $thisdata['alt_va'];
      $dav = $thisdata['drain_area_va'];

      # check for point in site db
      $listobject->querystring = "  select count(*) as numsites from monitoring_sites ";
      $listobject->querystring .= " where site_no = '$siteno' ";
      $listobject->querystring .= "    and site_type = $stype ";
      $listobject->performQuery();
      $numsites = $listobject->getRecordValue(1,'numsites');
      if (!($numsites > 0)) {
         print("Adding record for site $siteno, LAT: $dec_lat_va, LON: $dec_long_va.<br>");
         if (ltrim(rtrim($alt_va)) == '') {
            $alt_va = 'NULL';
         }
         $listobject->querystring = "  insert into monitoring_sites(site_no, site_id, dec_lat_va, dec_long_va, ";
         $listobject->querystring .= "    state_cd, alt_va, site_type, drain_area_va, the_geom ) ";
         $listobject->querystring .= " values ('$siteno', '$site_id', $dec_lat_va, $dec_long_va, ";
         $listobject->querystring .= "    '$state_cd', $alt_va, $stype, $dav, ";
         $listobject->querystring .= "    PointFromText('POINT($dec_long_va $dec_lat_va)',4326) ";
         $listobject->querystring .= " ) ";
         if ($debug) { print("$listobject->querystring ; <br>"); }
         $listobject->performQuery();
      } else {
         print("Updating record for site $siteno, LAT: $dec_lat_va, LON: $dec_long_va.<br>");
         if (ltrim(rtrim($alt_va)) == '') {
            $alt_va = 'NULL';
         }
         $listobject->querystring = "  update monitoring_sites set dec_lat_va = $dec_lat_va, ";
         $listobject->querystring .= "    dec_long_va = $dec_long_va, ";
         $listobject->querystring .= "    state_cd = '$state_cd', ";
         $listobject->querystring .= "    alt_va = $alt_va, ";
         $listobject->querystring .= "    drain_area_va = $dav, ";
         $listobject->querystring .= "    the_geom = ";
         $listobject->querystring .= "       st_PointFromText('POINT($dec_long_va $dec_lat_va)',4326) ";
         $listobject->querystring .= " where site_no = '$siteno' ";
         if ($debug) { print("$listobject->querystring ; <br>"); }
         $listobject->performQuery();
      }
   }
   print("Inserted/Updated station information for $j stations.<br>");

}


function getPrecipDateRange($listobject, $projectid, $basedataurl, $startdate, $enddate, $scratchdir, $debug, $overwrite = 1) {

   # Or, get all data from most recent entry in database forward till today
   $datear = array();
   $thisdate = new DateTime(date($today));
   $tds = $thisdate->format('Y-m-d');
   $listobject->querystring = "  select max(thisdate) as maxdate from precip_gridded ";
   $listobject->querystring .= " where thisdate <= '$tds'::timestamp ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   $md = $listobject->getRecordValue(1,'maxdate');

   if (strlen($md) == 0) {
      $md = "$year-$month-01";
   }
   $nextdate = new DateTime($md);

   if (!($nextdate->format('Y-m-d') == $today)) {
      # nothing to do if we have the data current

      if ($nextdate->format('Y-m-d') <> $tds) {
         $nds = '';
         for ($i = 1; $tds <> $nds; $i++) {
            $nextdate->modify("+1 day");
            $day = $nextdate->format('d');
            $month = $nextdate->format('m');
            $year = $nextdate->format('Y');
            array_push($datear, array($year,$month,$day) );
            $nds = $nextdate->format('Y-m-d');
         }
      } else {
         $day = $thisdate->format('d');
         $month = $thisdate->format('m');
         $year = $thisdate->format('Y');
         array_push($datear, array($year,$month,$day) );
         if ($debug) { print("Adding $year-$month-$day <br>"); }
      }

      # add in manual date
      #array_push($datear, array('2007','06','22'));

      foreach ($datear as $thisdate) {
         $thisyear = $thisdate[0];
         $thismo = $thisdate[1];
         $thisday = $thisdate[2];
         #$debug = 1;
         importNOAAGriddedPrecip ($listobject, $projectid, $thisyear, $thismo, $thisday, $scratchdir, $basedataurl, $debug, $overwrite);
         print("$message <br>");
      }

      $padmo = str_pad($thismo, 2, '0', STR_PAD_LEFT);
      $startdate = "$thisyear-$padmo-01";
      $dateobj = new DateTime("$startdate");
      $maxday = $dateobj->format('t');
      $enddate = "$thisyear-$padmo-$maxday";
   } else {
      $thisyear = $nextdate->format('Y');
      $thismo = $nextdate->format('m');
      $startdate = "$thisyear-$thismo-01";
   }
}


function getPrecipToDate($listobject, $projectid, $basedataurl, $today, $scratchdir, $debug, $overwrite = 1, $dopartial = 1, $db = 'noaa') {

   # Or, get all data from most recent entry in database forward till today
   $datear = array();
   $thisdate = new DateTime(date($today));
   $tds = $thisdate->format('Y-m-d');
   $month = $thisdate->format('m');
   $year = $thisdate->format('Y');
   switch ($db) {
     case 'vahydro':
     $listobject->querystring = "  select to_timestamp(max(tstime)) as maxdate from dh_timeseries_weather ";
     $listobject->querystring .= " where tstime <= extract(epoch from '$tds'::timestamptz) ";
     break;
     default:
     $listobject->querystring = "  select max(thisdate) as maxdate from precip_gridded ";
     $listobject->querystring .= " where thisdate <= '$tds'::timestamp ";
   }
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   $md = $listobject->getRecordValue(1,'maxdate');

   if (strlen($md) == 0) {
      $md = "$year-$month-01";
   }
   $nextdate = new DateTime($md);
   $nd = $nextdate->format('Y-m-d');
   
   print ("Next Date: $nd - Today: $today \n<br>");

   if ( (!($nextdate->format('Y-m-d') == $today)) or ($overwrite)) {
      # nothing to do if we have the data current

      if ($nextdate->format('Y-m-d') <> $tds) {
         $nds = '';
         for ($i = 1; $tds <> $nds; $i++) {
            $nextdate->modify("+1 day");
            $day = $nextdate->format('d');
            $month = $nextdate->format('m');
            $year = $nextdate->format('Y');
            array_push($datear, array($year,$month,$day) );
            $nds = $nextdate->format('Y-m-d');
         }
      } else {
         $day = $thisdate->format('d');
         $month = $thisdate->format('m');
         $year = $thisdate->format('Y');
         array_push($datear, array($year,$month,$day) );
         if ($debug) { print("Adding $year-$month-$day <br>"); }
      }

      # add in manual date
      #array_push($datear, array('2007','06','22'));

      foreach ($datear as $thisdate) {
         $thisyear = $thisdate[0];
         $thismo = $thisdate[1];
         $thisday = $thisdate[2];
         #$debug = 1;
         switch ($db) {
           case 'vahydro':
           importNOAAGriddedPrecipVAHydro($listobject, $projectid, $thisyear, $thismo, $thisday, $scratchdir, $basedataurl, $debug, $overwrite);
           break;
           default:
           importNOAAGriddedPrecip ($listobject, $projectid, $thisyear, $thismo, $thisday, $scratchdir, $basedataurl, $debug, $overwrite);
           break;
         }
         print("$message <br>");
      }

      $padmo = str_pad($thismo, 2, '0', STR_PAD_LEFT);
      $startdate = "$thisyear-$padmo-01";
      $dateobj = new DateTime("$startdate");
      $maxday = $dateobj->format('t');
      $enddate = "$thisyear-$padmo-$maxday";
   } else {
      $thisyear = $nextdate->format('Y');
      $thismo = $nextdate->format('m');
      $startdate = "$thisyear-$thismo-01";
   }

   #$debug = 1;

   # do a partial month summary ONLY if there is no monthly data for this time period
   $listobject->querystring = "  select count(*) as numrecs from precip_gridded_monthly ";
   $listobject->querystring .= " where mo_start = '$startdate'::timestamp ";
   $listobject->querystring .= "    and src_citation = 1 ";
   $listobject->querystring .= "    and datatype in ('obs') ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   $numrecs = $listobject->getRecordValue(1,'numrecs');

   if (!($numrecs > 0) and ($dopartial)) {
      # if no src_citation = 1 (NOAA official) records exist, create synthetic ones
      calculatePartialMonthlyDeparture($listobject, $projectid, $thisyear, $thismo, 1);
   }
}

function getPrecipToDateVAHydro($listobject, $projectid, $basedataurl, $enddate, $scratchdir, $debug, $oneday = FALSE, $overwrite = TRUE) {
  
  $today = date('Y-m-d');
  $bases = array(
    'nws_precip_1day_observed_shape_' => array(
      'filebase' => 'nws_precip_1day_observed_shape_',
      'varkey' => 'precip_obs_daily',
    ), 
    'nws_precip_wateryear2date_departure_shape_' => array(
      'filebase' => 'nws_precip_wateryear2date_departure_shape_',
      'varkey' => 'precip_depart_wy2date',
    ), 
    'nws_precip_wateryear2date_observed_shape_' => array(
      'filebase' => 'nws_precip_wateryear2date_observed_shape_',
      'varkey' => 'precip_obs_wy2date',
    ), 
    'nws_precip_wateryear2date_percent_shape_' => array(
      'filebase' => 'nws_precip_wateryear2date_percent_shape_',
      'varkey' => 'precip_pct_wy2date',
    ), 
    'nws_precip_wateryear2date_normal_shape_' => array(
      'filebase' => 'nws_precip_wateryear2date_normal_shape_',
      'varkey' => 'precip_nml_wy2date',
    ), 
  );
  $varkeys = array();
  foreach ($bases as $config) {
    $varkeys[] = $config['varkey'];
  }
  $datear = array();
  $thisdate = new DateTime(date($enddate));
  $tds = $thisdate->format('Y-m-d');
  $month = $thisdate->format('m');
  $year = $thisdate->format('Y');
  $endts = $thisdate->format('u');
  if ($oneday) {
    $md = $enddate;
  } else {
    # Or, get all data from most recent entry in database forward till today
    // makes sure that we get all variables, and re-import all vars for a given time period if any failed
    $listobject->querystring = "  select to_timestamp(min(tstime)) as maxdate ";
    $listobject->querystring .= " from ( ";
    $listobject->querystring .= "   select CASE ";
    $listobject->querystring .= "     WHEN tstime < tsendtime THEN tsendtime ";
    $listobject->querystring .= "     ELSE tstime ";
    $listobject->querystring .= "     END as tstime ";
    $listobject->querystring .= "   from ( ";
    $listobject->querystring .= "     select varid, max(tstime) as tstime, max(tsendtime) as tsendtime ";
    $listobject->querystring .= "     from dh_timeseries_weather ";
    $listobject->querystring .= "     where tstime <= extract (epoch from '$tds'::timestamptz) ";
    $listobject->querystring .= "     and varid in (";
    $listobject->querystring .= "       select hydroid from dh_variabledefinition ";
    $listobject->querystring .= "       where varkey in ( '" . implode("','", $varkeys) . "')";
    $listobject->querystring .= "     )";
    $listobject->querystring .= "     group by varid ";
    $listobject->querystring .= "   ) as foo ";
    $listobject->querystring .= " ) as bar ";

    //if ($debug) { 
      print("$listobject->querystring ; <br>"); 
    //}
    $listobject->performQuery();
    $md = $listobject->getRecordValue(1,'maxdate');

    if (strlen($md) == 0) {
      $md = "$year-$month-01";
    }
  }
  $nextdate = new DateTime($md);
  $nd = $nextdate->format('Y-m-d');

  print ("Next Date: $nd - end date: $enddate - overwrite = $overwrite \n<br>");

  if ( (!($nextdate->format('u') > $endts)) or ($overwrite)) {
    # nothing to do if we have the data current

    if ($nextdate->format('Y-m-d') <> $tds) {
      $nds = '';
      for ($i = 1; $tds <> $nds; $i++) {
        $nextdate->modify("+1 day");
        $day = $nextdate->format('d');
        $month = $nextdate->format('m');
        $year = $nextdate->format('Y');
        array_push($datear, array($year,$month,$day) );
        $nds = $nextdate->format('Y-m-d');
      }
    } else {
      $day = $thisdate->format('d');
      $month = $thisdate->format('m');
      $year = $thisdate->format('Y');
      array_push($datear, array($year,$month,$day) );
      if ($debug) { print("Adding $year-$month-$day <br>"); }
    }

    # add in manual date
    #array_push($datear, array('2007','06','22'));

    foreach ($datear as $thisdate) {
      $thisyear = $thisdate[0];
      $thismo = $thisdate[1];
      $thisday = $thisdate[2];
      #$debug = 1;
      foreach ($bases as $config) {
        importNOAAGriddedPrecipVAHydro($listobject, $projectid, $thisyear, $thismo, $thisday, $scratchdir, $basedataurl, $debug, $overwrite, $config);
      }
      print("$message <br>");
    }

    $padmo = str_pad($thismo, 2, '0', STR_PAD_LEFT);
    $startdate = "$thisyear-$padmo-01";
    $dateobj = new DateTime("$startdate");
    $maxday = $dateobj->format('t');
    $enddate = "$thisyear-$padmo-$maxday";
  }
}


function getMonthlyPrecipToDate($listobject, $projectid, $basedataurl, $today, $scratchdir, $debug, $overwrite=1) {
   ###############################################################################
   # Import Monthly historical normal values
   ###############################################################################

   # get todays info
   $date = new DateTime($today);
   $day = $date->format('d');
   $month = $date->format('m');
   $year = $date->format('Y');

   # get max month/year with real NOAA summary data
   $listobject->querystring = "  select max(mo_start) as maxdate ";
   $listobject->querystring .= " from precip_gridded_monthly ";
   $listobject->querystring .= " where mo_start <= '$today'::timestamp ";
   $listobject->querystring .= "    and datatype = 'obs' and src_citation = 1 ";
   if ($debug) { print(" $listobject->querystring ; <br>"); }
   $listobject->performQuery();
   $md = $listobject->getRecordValue(1,'maxdate');

   if (strlen($md) == 0) {
      $md = "$year-$month-01";
   }
   $nextdate = new DateTime($md);
   $nextmo = $nextdate->format('n') + 1;
   $nextyear = $nextdate->format('Y');

   # old school, there was a problem with the retrieval server, such that it returned the january (01),
   # files, when requesting the October (10) files.
#   while ( ($nextyear < $year) or ( ($nextyear == $year) and ($nextmo <= $month) ) ) {
   # new school, does NOT look for monthly summary if this is the current month and year
   while ( ($nextyear < $year) or ( ($nextyear == $year) and ($nextmo < $month) ) ) {

      if ($nextmo > 12) {
         $nextmo = 1;
         $nextyear++;
      }
      $mopad = str_pad($nextmo, 2, '0', STR_PAD_LEFT);
      # no data exists for this month, so go get it!
      $thisdate = "$year-$month-$day";
      $baseurl = $basedataurl . '/' . $nextyear;
      $filename = 'nws_precip_';
      $filename .= $nextyear . $mopad;
      $filename .= '_obs.tar.gz';
      print("Retrieving data for month $nextmo from $baseurl/$filename <br>");
      $results = getNOAAGriddedPrecipHTTP ($listobject, $scratchdir, $baseurl, $filename, $debug);
      # now, stash the data into our table
      if ($results['numrecs'] > 0) {
         copyNOAAMonthlyToProj($listobject, $projectid, $thisdate, $nextyear, $nextmo, 'obs', 1, $debug);
      }

      $filename = 'nws_precip_';
      $filename .= $nextyear . $mopad;
      $filename .= '_dif.tar.gz';
      print("Retrieving obs data for month $nextmo from $baseurl/$filename <br>");
      $results = getNOAAGriddedPrecipHTTP ($listobject, $scratchdir, $baseurl, $filename, $debug);
      # now, stash the data into our table
      if ($results['numrecs'] > 0) {
         copyNOAAMonthlyToProj($listobject, $projectid, $thisdate, $nextyear, $nextmo, 'dif', 1, $debug);
      }

      $filename = 'nws_precip_';
      $filename .= $nextyear . $mopad;
      $filename .= '_pct.tar.gz';
      print("Retrieving pct data for month $nextmo from $baseurl/$filename <br>");
      $results = getNOAAGriddedPrecipHTTP ($listobject, $scratchdir, $baseurl, $filename, $debug);
      # now, stash the data into our table
      if ($results['numrecs'] > 0) {
         copyNOAAMonthlyToProj($listobject, $projectid, $thisdate, $nextyear, $nextmo, 'pct', 1, $debug);
      }

      $nextmo++;
   }

}

function calculatePartialMonthlyDeparture($listobject, $projectid, $thisyear, $thismo, $debug) {

   $padmo = str_pad($thismo, 2, '0', STR_PAD_LEFT);
   $startdate = "$thisyear-$padmo-01";
   $dateobj = new DateTime("$startdate");
   $maxday = $dateobj->format('t');
   $enddate = "$thisyear-$padmo-$maxday";
   $thisdate = date('Y-m-d');

   print("Checking for full monthly observed value.<br>");
   $listobject->querystring = "  select count(*) as numrecs from precip_gridded_monthly ";
   $listobject->querystring .= " where mo_start = '$startdate'::timestamp ";
   $listobject->querystring .= "    and src_citation = 1 ";
   $listobject->querystring .= "    and datatype = 'obs' ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   $numrecs = $listobject->getRecordValue(1,'numrecs');
   if ($numrecs > 0) {
      print("Offical observed record already exists for $startdate, exiting.<br>");
      return;
   }

   print("Clearing previous partial observed estimates.<br>");
   $listobject->querystring = "  delete from precip_gridded_monthly ";
   $listobject->querystring .= " where mo_start = '$startdate'::timestamp ";
   # delete all records for this, since we have only a partial obs, assume the others, if they exist, to be invalid
   #$listobject->querystring .= "    and src_citation = 3 ";
   $listobject->querystring .= "    and datatype in ( 'obs', 'mtdnml', 'dif', 'pct' ) ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   print("Getting max reported data.<br>");
   $listobject->querystring = " select max(thisdate) as maxdate from precip_gridded ";
   $listobject->querystring .= " where thisdate >= '$startdate'::timestamp ";
   $listobject->querystring .= "    and thisdate <= '$enddate' ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   $maxdate = $listobject->getRecordValue(1,'maxdate');
   $mdo = new DateTime($maxdate);
   $numdays = $mdo->format('j');
   $mofrac = $numdays / $maxday;

   print("Inserting Partial Monthly Observed Data into Gridded Monthly Database<br>");
   $listobject->querystring = "  insert into precip_gridded_monthly (hrapx, hrapy, lat, lon, ";
   $listobject->querystring .= "    globvalue, entrydate, datasource, the_geom,";
   $listobject->querystring .= "    datatype, thisyear, thismonth, mo_start, src_citation ) ";
   $listobject->querystring .= " select hrapx, hrapy, lat, lon, sum(globvalue), ";
   # datasource = 3 - estimated monthly departure
   $listobject->querystring .= "    '$thisdate'::timestamp, 3, ";
   # assumes that the file came in as decimal degrees
   $listobject->querystring .= "    the_geom,";
   $listobject->querystring .= "    'obs', $thisyear, $thismo, ";
   $listobject->querystring .= "    '$startdate'::timestamp, 3 ";
   $listobject->querystring .= " from precip_gridded ";
   $listobject->querystring .= " where thisdate >= '$startdate'::timestamp ";
   $listobject->querystring .= "    and thisdate <= '$enddate' ";
   $listobject->querystring .= " group by hrapx, hrapy, lat, lon, the_geom ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   #$listobject->showList();


   print("Inserting Partial Monthly Observed Data into Gridded Monthly Database<br>");
   $listobject->querystring = "  insert into precip_gridded_monthly (hrapx, hrapy, lat, lon, ";
   $listobject->querystring .= "    globvalue, entrydate, datasource, the_geom,";
   $listobject->querystring .= "    datatype, thisyear, thismonth, mo_start, src_citation ) ";
   $listobject->querystring .= " select hrapx, hrapy, lat, lon, $mofrac * globvalue, ";
   # datasource = 3 - estimated monthly departure
   $listobject->querystring .= "    '$thisdate'::timestamp, 3, ";
   # assumes that the file came in as decimal degrees
   $listobject->querystring .= "    the_geom,";
   $listobject->querystring .= "    'mtdnml', $thisyear, $thismo, ";
   $listobject->querystring .= "    '$startdate'::timestamp, 3 ";
   $listobject->querystring .= " from precip_gridded_monthly ";
   $listobject->querystring .= " where thismonth = $thismo ";
   $listobject->querystring .= "    and datatype = 'nml' ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   #$listobject->showList();

   print("Inserting Estimated Partial Monthly Departure Data into Gridded Monthly Database<br>");
   $listobject->querystring = "  insert into precip_gridded_monthly (hrapx, hrapy, lat, lon, ";
   $listobject->querystring .= "    globvalue, entrydate, datasource, the_geom,";
   $listobject->querystring .= "    datatype, thisyear, thismonth, mo_start, src_citation ) ";
   $listobject->querystring .= " select b.hrapx, b.hrapy, b.lat, b.lon,  ";
   $listobject->querystring .= "    CASE  ";
   $listobject->querystring .= "       WHEN a.numdays is null THEN (0.0 - $mofrac * b.globvalue) ";
   $listobject->querystring .= "       ELSE ( a.total_p - (($mofrac::float8) * b.globvalue) ) ";
   $listobject->querystring .= "    END as dif, '$thisdate'::timestamp, 3, b.the_geom, ";
   $listobject->querystring .= "    'dif', $thisyear, $thismo, '$startdate'::timestamp, 3 ";
   $listobject->querystring .= " from precip_gridded_monthly as b left outer join ( ";
   $listobject->querystring .= "    select a.hrapx, a.hrapy, a.lat, a.lon, ";
   $listobject->querystring .= "       sum(a.globvalue) as total_p, count(a.*) as numdays ";
   $listobject->querystring .= "    from precip_gridded as a ";
   $listobject->querystring .= "    where a.thisdate >= '$startdate'::timestamp  ";
   $listobject->querystring .= "       and a.thisdate <= '$enddate'::timestamp  ";
   $listobject->querystring .= "    group by a.hrapx, a.hrapy, a.lat, a.lon  ";
   $listobject->querystring .= " ) as a   ";
   # join on lat lon / causes problems because of issues with monthly versus daily NOAA data
   $listobject->querystring .= " on a.hrapx = b.hrapx and a.hrapy = b.hrapy  ";
   #$listobject->querystring .= " on a.lat = b.lat and a.lon = b.lon  ";
   $listobject->querystring .= " where b.thismonth = $thismo and b.datatype = 'nml'  ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   #$listobject->showList();

   /*
   print("Cleaning up data in Gridded Monthly Database<br>");
   $listobject->querystring = "  vacuum analyze precip_gridded_monthly ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   #$listobject->showList();
   */
}


function showGridPartialMonthlyDeparture($listobject, $projectid, $thisyear, $thismo, $hrapx, $hrapy, $debug) {

   $padmo = str_pad($thismo, 2, '0', STR_PAD_LEFT);
   $startdate = "$thisyear-$padmo-01";
   $dateobj = new DateTime("$startdate");
   $maxday = $dateobj->format('t');
   $enddate = "$thisyear-$padmo-$maxday";
   $thisdate = date('Y-m-d');

   print("Getting max reported data.<br>");
   $listobject->querystring = " select max(thisdate) as maxdate from precip_gridded ";
   $listobject->querystring .= " where thisdate >= '$startdate'::timestamp ";
   $listobject->querystring .= "    and thisdate <= '$enddate' ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   $maxdate = $listobject->getRecordValue(1,'maxdate');
   $mdo = new DateTime($maxdate);
   $numdays = $mdo->format('j');
   $mofrac = $numdays / $maxday;

   print("Monthly fraction, $numdays of $maxday = $mofrac <br>");

   print("Inserting Partial Monthly Observed Data into Gridded Monthly Database<br>");
   $listobject->querystring = "  select hrapx, hrapy, lat, lon, sum(globvalue) as globvalue, ";
   # datasource = 3 - estimated monthly departure
   $listobject->querystring .= "    '$thisdate'::timestamp as entrydate, ";
   $listobject->querystring .= "    '$thisdate'::timestamp as thisdate, 3 as datasource, ";
   # assumes that the file came in as decimal degrees
   $listobject->querystring .= "    the_geom,";
   $listobject->querystring .= "    'obs'::varchar(6) as datatype, $thisyear as thisyear, $thismo as thismonth, ";
   $listobject->querystring .= "    '$startdate'::timestamp as mo_start, 3 as src_citation ";
   $listobject->querystring .= " into temp table tmp_pgm ";
   $listobject->querystring .= " from precip_gridded ";
   $listobject->querystring .= " where thisdate >= '$startdate'::timestamp ";
   $listobject->querystring .= "    and thisdate <= '$enddate' ";
   $listobject->querystring .= "    and hrapx = $hrapx ";
   $listobject->querystring .= "    and hrapy = $hrapy ";
   $listobject->querystring .= " group by hrapx, hrapy, lat, lon, the_geom ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   #$listobject->showList();

   print("Inserting Partial Monthly Observed Data into Gridded Monthly Database<br>");
   $listobject->querystring = "  insert into tmp_pgm (hrapx, hrapy, lat, lon, ";
   $listobject->querystring .= "    globvalue, entrydate, datasource, the_geom,";
   $listobject->querystring .= "    datatype, thisyear, thismonth, mo_start, src_citation ) ";
   $listobject->querystring .= " select hrapx, hrapy, lat, lon, $mofrac * globvalue, ";
   # datasource = 3 - estimated monthly departure
   $listobject->querystring .= "    '$thisdate'::timestamp, 3, ";
   # assumes that the file came in as decimal degrees
   $listobject->querystring .= "    the_geom,";
   $listobject->querystring .= "    'mtdnml', $thisyear, $thismo, ";
   $listobject->querystring .= "    '$startdate'::timestamp, 3 ";
   $listobject->querystring .= " from precip_gridded_monthly ";
   $listobject->querystring .= " where thismonth = $thismo ";
   $listobject->querystring .= "    and datatype = 'nml' ";
   $listobject->querystring .= "    and hrapx = $hrapx ";
   $listobject->querystring .= "    and hrapy = $hrapy ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();
   #$listobject->showList();

   print("Inserting Estimated Partial Monthly Departure Data into Gridded Monthly Database<br>");
   $listobject->querystring = "  insert into tmp_pgm (hrapx, hrapy, lat, lon, ";
   $listobject->querystring .= "    globvalue, entrydate, datasource, the_geom,";
   $listobject->querystring .= "    datatype, thisyear, thismonth, mo_start, src_citation ) ";
   $listobject->querystring .= " select b.hrapx, b.hrapy, b.lat, b.lon,  ";
   $listobject->querystring .= "    CASE  ";
   $listobject->querystring .= "       WHEN a.numdays is null THEN (0.0 - $mofrac * b.globvalue) ";
   $listobject->querystring .= "       ELSE ( a.total_p - (($mofrac::float8) * b.globvalue) ) ";
   $listobject->querystring .= "    END as dif, '$thisdate'::timestamp, 3, b.the_geom, ";
   $listobject->querystring .= "    'dif', $thisyear, $thismo, '$startdate'::timestamp, 3 ";
   $listobject->querystring .= " from precip_gridded_monthly as b left outer join ( ";
   $listobject->querystring .= "    select a.hrapx, a.hrapy, a.lat, a.lon, ";
   $listobject->querystring .= "       sum(a.globvalue) as total_p, count(a.*) as numdays ";
   $listobject->querystring .= "    from precip_gridded as a ";
   $listobject->querystring .= "    where a.thisdate >= '$startdate'::timestamp  ";
   $listobject->querystring .= "       and a.thisdate <= '$enddate'::timestamp  ";
   $listobject->querystring .= "    group by a.hrapx, a.hrapy, a.lat, a.lon  ";
   $listobject->querystring .= " ) as a   ";
   $listobject->querystring .= " on a.hrapx = b.hrapx and a.hrapy = b.hrapy  ";
   $listobject->querystring .= " where b.thismonth = $thismo and b.datatype = 'nml'  ";
   $listobject->querystring .= "    and b.hrapx = $hrapx ";
   $listobject->querystring .= "    and b.hrapy = $hrapy ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();


   $listobject->querystring = "  select * from tmp_pgm order by hrapx, hrapy, datatype ";
   $listobject->performQuery();
   $listobject->showList();

}

function importNOAAGriddedPrecip ($listobject, $projectid, $thisyear, $thismo, $thisday, $scratchdir, $basedataurl, $debug, $overwrite = 1) {

   $year = $thisyear;
   $month = str_pad($thismo, 2, '0', STR_PAD_LEFT);
   $day = str_pad($thisday, 2, '0', STR_PAD_LEFT);

   print("Downloading Data for $year-$month-$day<br>");
   # old school, gets most recent real-time
   #getNOAAGriddedPrecip ($listobject, $scratchdir, $year, $month, $day, $debug);
   # new school - daily format:
   # http://www.srh.noaa.gov/rfcshare/p_download_new/2007/200706/nws_precip_20070601.tar.gz
   // file structure for this format
   // $thisbase = $basedataurl . '/' . $year . '/' . $year . $month;
   //$filename = 'nws_precip_';
   //$filename .= $year;
   //$filename .= $month;
   //$filename .= $day;
   //$filename .= '.tar.gz';
   // http://water.weather.gov/precip/p_download_new 
   // New file name structure: nws_precip_1day_observed_shape_20110304.tar.gz
   $thisbase = $basedataurl . '/' . $year . '/' . $month . '/' . $day;
   $filename = 'nws_precip_1day_observed_shape_';
   $filename .= $year;
   $filename .= $month;
   $filename .= $day;
   $filename .= '.tar.gz';
   
   // creates and populates tmp_precipgrid
   $results = getNOAAGriddedPrecipHTTP ($listobject, $scratchdir, $thisbase, $filename, $overwrite, $debug);
   if ($results['numrecs'] == 0) {
      return $results['error'];
   }
   # process the new data
   $thisdate = "$year-$month-$day";
   print("Clearing Old Data from Gridded Database<br>");
   $listobject->querystring = "  delete from precip_gridded ";
   $listobject->querystring .= " where thisdate = '$thisdate'::timestamp ";
   print("$listobject->querystring ; <br>");
   $listobject->performQuery();

   print("Inserting Data into Gridded Database<br>");
   // updated 3/10/2016 - see new query below
/*
   $listobject->querystring = "  insert into precip_gridded (hrapx, hrapy, lat, lon, ";
   $listobject->querystring .= "    globvalue, thisdate, datasource, the_geom ) ";
   $listobject->querystring .= " select hrapx, hrapy, lat, lon, globvalue, ";
   $listobject->querystring .= "    '$thisdate'::timestamp, 1, ";
   # assumes that the file came in as decimal degrees
   $listobject->querystring .= "    st_setsrid(the_geom,4326) ";
   $listobject->querystring .= " from tmp_precipgrid as a ";
   $listobject->querystring .= " left outer join proj_seggroups as b ";
   $listobject->querystring .= " where the_geom && (";
   $listobject->querystring .= "    select st_extent(the_geom) ";
   $listobject->querystring .= "    from proj_seggroups ";
   $listobject->querystring .= "    WHERE projectid = $projectid ";
   $listobject->querystring .= "    ) ";
   print("$listobject->querystring ; <br>");
   $listobject->performQuery();
   #$listobject->showList();
*/
   $listobject->querystring = "  insert into precip_gridded (hrapx, hrapy, lat, lon,  ";
   $listobject->querystring .= "     globvalue, thisdate, datasource, the_geom )  ";
   $listobject->querystring .= "  select hrapx, hrapy, lat, lon, globvalue,  ";
   $listobject->querystring .= "     '$thisdate'::timestamp, 1,  ";
   $listobject->querystring .= "     st_setsrid(geom,4326)  ";
   $listobject->querystring .= "  from tmp_precipgrid as a  ";
   $listobject->querystring .= "  left outer join ( ";
   $listobject->querystring .= "    select st_extent(the_geom) as geom_extent  ";
   $listobject->querystring .= "    from proj_seggroups ";
   $listobject->querystring .= "    WHERE projectid = $projectid ";
   $listobject->querystring .= "  ) as b  ";
   $listobject->querystring .= "  on ( a.geom && b.geom_extent)  ";
   $listobject->querystring .= "  where geom_extent is not null ";
   print("$listobject->querystring ; <br>");
   $listobject->performQuery();
   #$listobject->showList();
 
   
   
   # clean up after ourselves
   if ($listobject->tableExists('tmp_precipgrid')) {
      $listobject->querystring = "drop table tmp_precipgrid ";
      if ($debug) { print("$listobject->querystring ; <br>"); }
      $listobject->performQuery();
   }

   return $message;
   #mxcl_mail( $subject, $message, 'robert.burgholzer@deq.virginia.gov' );
   #mailIMAP($mailobj, $mail_headers, 'robert.burgholzer@deq.virginia.gov', 'robert.burgholzer@deq.virginia.gov' , $message, $debug);
}

function importNOAAGriddedPrecipVAHydro ($listobject, $projectid, $thisyear, $thismo, $thisday, $scratchdir, $basedataurl, $debug, $overwrite = 1, $config = array()) {

  $year = $thisyear;
  $month = str_pad($thismo, 2, '0', STR_PAD_LEFT);
  $day = str_pad($thisday, 2, '0', STR_PAD_LEFT);
  $wateryear = $thisyear;
  if ($thismo < 10) {
   $wateryear = $wateryear - 1;
  }

  if (empty($config)) {
    $config = array(
      'filebase' => 'nws_precip_1day_observed_shape_',
      'varkey' => 'precip_obs_daily',
    );
  }

  print("Downloading Data for $year-$month-$day<br>");
  $filebase = $config['filebase'];
  $varkey = $config['varkey'];

  // New file name structure: nws_precip_1day_observed_shape_20110304.tar.gz
  $thisbase = $basedataurl . '/' . $year . '/' . $month . '/' . $day;
  $filename = $filebase;
  $filename .= $year;
  $filename .= $month;
  $filename .= $day;
  $filename .= '.tar.gz';

  // creates and populates tmp_precipgrid
  $results = getNOAAGriddedPrecipHTTP ($listobject, $scratchdir, $thisbase, $filename, $overwrite, $debug);
  if ($results['numrecs'] == 0) {
    return $results['error'];
  }

  # process the new data
  $thisdate = "$year-$month-$day";
  $tstime = $thisdate;
  $tsendtime = FALSE;
  if (!(strpos($varkey, 'wy2') === FALSE)) {
    $tsendtime = $tstime;
    $tstime = "$wateryear-10-01";
  }
  
  print("Clearing Old Data from Gridded Database<br>");
  $listobject->querystring = "  delete from dh_timeseries_weather ";
  //$listobject->querystring .= " where tstime = extract(epoch from '$thisdate'::timestamp) ";
  // uses timestamptz now since local postgres install has timezone set 
  // select 
  $listobject->querystring .= " where tstime = extract(epoch from '$tstime'::timestamptz) ";
  if (!($tsendtime === FALSE)) {
    $listobject->querystring .= " and tsendtime = extract(epoch from '$tsendtime'::timestamptz) ";
  }
  $listobject->querystring .= " and varid in (select hydroid from dh_variabledefinition  ";
  $listobject->querystring .= "   WHERE varkey = '$varkey'";
  $listobject->querystring .= " ) ";
  print("$listobject->querystring ; <br>");
  $listobject->performQuery();

  print("Inserting Data into Gridded Database<br>");
  $listobject->querystring = "  insert into dh_timeseries_weather (tstime, tsendtime, rain, featureid, entity_type, varid) ";
  $listobject->querystring .= "  select extract(epoch from '$tstime'::timestamptz), ";
  if (!($tsendtime === FALSE)) {
    $listobject->querystring .= " extract(epoch from '$tsendtime'::timestamptz), ";
  } else {
  $listobject->querystring .= "  NULL, ";
  }
  $listobject->querystring .= "  a.globvalue, b.hydroid, 'dh_feature', c.hydroid ";
  $listobject->querystring .= "  from tmp_precipgrid as a  ";
  $listobject->querystring .= "  left outer join dh_variabledefinition as c  ";
  $listobject->querystring .= "  on ( ";
  $listobject->querystring .= "    c.varkey = '$varkey' ";
  $listobject->querystring .= "  ) ";
  $listobject->querystring .= "  left outer join dh_feature as b  ";
  $listobject->querystring .= "  on ( ";
  $listobject->querystring .= "    (a.hrapx || '-' || a.hrapy) = b.hydrocode ";
  $listobject->querystring .= "    and b.bundle = 'weather_sensor' ";
  $listobject->querystring .= "    and b.ftype = 'nws_precip' ";
  $listobject->querystring .= "  ) ";
  $listobject->querystring .= "  where b.hydroid is not null ";
  print("$listobject->querystring ; <br>");
  $listobject->performQuery();
  #$listobject->showList();



  # clean up after ourselves
  if ($listobject->tableExists('tmp_precipgrid')) {
    $listobject->querystring = "drop table tmp_precipgrid ";
    if ($debug) { print("$listobject->querystring ; <br>"); }
    $listobject->performQuery();
  }
  return $message;
}

function removeTempSummary($listobject, $projectid, $sitelist, $stype, $thismetric, $datatype, $debug) {

   if (strlen(ltrim(rtrim($sitelist))) > 0) {
      # specific sites requested
      $sitewhere = " site_no in ( '" . join("','", split(',', $sitelist)) . "' ) ";
   } else {
      $sitewhere = " ( 1 = 1 ) ";
   }
   $listobject->querystring = "  delete from stats_site_period ";
   $listobject->querystring .= " where site_no in ( ";
   $listobject->querystring .= "    select site_no ";
   $listobject->querystring .= "    from monitoring_sites ";
   $listobject->querystring .= "    where site_type = $stype ";
   $listobject->querystring .= "       and $sitewhere ";
   $listobject->querystring .= "    ) ";
   $listobject->querystring .= "    and datatype = '$thismetric' ";
   $listobject->performQuery();
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   $listobject->querystring = "  delete from proj_group_stat ";
   $listobject->querystring .= " where thismetric like '$thismetric' ";
   $listobject->querystring .= "    and gid in ( ";
   $listobject->querystring .= "       select gid from map_group_site ";
   $listobject->querystring .= "       where $sitewhere ) ";
   $listobject->querystring .= " and projectid = $projectid ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   return;
}

function copyStatSummary($listobject, $projectid, $from_metric, $to_metric, $debug) {

   # Create a copy of a previously created summary
   # check first for the summary to copy FROM ($from_metric)
   # then, if it exists, delete any old copies of the summary to copy TO ($to_metric)
   $listobject->querystring = "  delete from proj_group_stat as a USING proj_group_stat as b ";
   $listobject->querystring .= " where a.thismetric = '$to_metric' ";
   $listobject->querystring .= "    and b.thismetric = '$from_metric' ";
   $listobject->querystring .= "    and a.gid = b.gid ";
   $listobject->querystring .= "    and a.projectid = $projectid ";
   $listobject->querystring .= "    and b.projectid = $projectid ";
   $listobject->performQuery();
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   $listobject->querystring = "  insert into proj_group_stat ( projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, thismetric, thisvalue, ";
   $listobject->querystring .= "    pct_cover, retrievaldate, minvalue, maxvalue, ";
   $listobject->querystring .= "    numrecs ) ";
   $listobject->querystring .= " select projectid, gid, groupname, ";
   $listobject->querystring .= "    startdate, enddate, '$to_metric', thisvalue, ";
   $listobject->querystring .= "    pct_cover, retrievaldate, minvalue, maxvalue, ";
   $listobject->querystring .= "    numrecs ";
   $listobject->querystring .= " from proj_group_stat ";
   $listobject->querystring .= " where thismetric = '$from_metric' ";
   if ($debug) { print("$listobject->querystring ; <br>"); }
   $listobject->performQuery();

   return;
}



function createUSGSTimeSeries($wbname, $staid, $startdate, $enddate, $period, $debug) {

   # part of modeling widgets, expects lib_hydrology,php, and lib_usgs.php to be included
   # creates a time series object, and returns it
   $flow2 = new timeSeriesInput;
   $flow2->init();
   $flow2->name = $wbname;
   $flow2->maxflow = 0;
   $dataitems = '00060,00010';
   $code_name = array('00060'=>'Qout', '00010'=>'Temp');

   print("Obtaining Physical Data for station: $staid <br>");
   $usgs_result = retrieveUSGSData($staid, $period, $debug, '', '', 3, '', '', '');
   $sitedata = $usgs_result['row_array'][0];
   #print_r($sitedata);
   $dav = $sitedata['drain_area_va'];
   #print("<br>Area = $dav<br>");
   $flow2->state['area'] = $dav;

   # gets daily flow values for indicated period
   print("Obtaining Flow Data for station: $staid $startdate to $enddate<br>");
   $site_result = retrieveUSGSData($staid, $period, 0, $startdate, $enddate, 1, '', 'rdb', $dataitems);
   $gagedata = $site_result['row_array'];
   $thisno = $gagedata[0]['site_no'];
   print($site_result['uri'] . "<br>");
   foreach ($gagedata as $thisdata) {
      if ($debug) {
         print_r($thisdata);
      }
      $thisdate = new DateTime($thisdata['datetime']);
      $ts = $thisdate->format('r');
      $thisflag = '';
      # default to missing
      $thisval = 0.0;
      foreach (split(',', $dataitems) as $dataitem) {

         foreach (array_keys($thisdata) as $thiscol) {
            if (substr_count($thiscol, $dataitem)) {
               # this is a flow related column, check if it is a flag or data
               if (!substr_count($thiscol, 'cd')) {
                  # must be a valid value
                  if ($thisdata[$thiscol] <> '') {
                     $thisval = $thisdata[$thiscol];
                  } else {
                     $thisval = '0.0';
                  }
               }
            }
         }
         $dataname = $code_name[$dataitem];
         # multiply by area factor to adjust for area factor at inlet
         $flow2->addValue($ts, $dataname, floatval($thisval));
         if ($dataname == 'Qout') {
            if ($thisval > $flow2->maxflow) {
               $flow2->maxflow = $thisval;
            }
         }
      }
      $flow2->addValue($ts, 'timestamp', $ts);
      $flow2->addValue($ts, 'thisdate', $thisdate->format('m-d-Y'));
   }

   return $flow2;
}

?>