<?php
module_load_include('module', 'dh_perms');
   global $user;
   if (!isset($account)) {
     $account = $user;
   }
   $a = arg();
   $user_perm_cache = array();
   $entity_id_cache = array();
   if (isset($a[2])) {
     $entity_id = $a[2];
   } else {
     $entity_id = 67290;
   }
   if (isset($a[3])) {
     $entity_type = $a[3];
   } else {
     $entity_type = 'dh_feature';
   }
   if (isset($a[4])) {
     $uid = $a[4];
   } else {
     $uid = FALSE; // $account->uid
   }
   
  //dpm( "Trying  dh_perms_contact_perms($uid, $entity_id, $entity_type ... ");
   dh_perms_contact_perms($uid, $entity_id, $entity_type, $entity_id_cache, $user_perm_cache);
   
$entity = entity_load_single($entity_type, $entity_id);
echo "Entity" . render(entity_view($entity_type, array($entity)));

if (count($user_perm_cache) > 0) {
  $formatted = array();
  foreach ($user_perm_cache as $line) {
    $formatted[] = array_values($line);
  }
  echo "User Permissions" . theme_table(
    array(
      'header' => array_keys($user_perm_cache[array_shift(array_keys($user_perm_cache))]),
      'rows' => $formatted,
      'attributes' => array(),
    )
  );
}

if (count($entity_id_cache) > 0) {
  echo "Entities In Contact/Permission Tree" . theme_table(
    array(
      'header' => array_keys($entity_id_cache[array_shift(array_keys($entity_id_cache))]),
      'rows' => $entity_id_cache,
      'attributes' => array(),
    )
  );
}


?>