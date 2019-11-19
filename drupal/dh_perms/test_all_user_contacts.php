<?php
module_load_include('module', 'dh_perms');

$a = arg();
dpm($a);
$user_perm_cache = array();
$entity_id_cache = array();
if (isset($a[2])) {
  $uid = $a[2];
} else {
  $uid = FALSE; // $account->uid
}
if (isset($a[3])) {
  $contact_type = $a[3];
} else {
  $contact_type = 'dh_link_admin_contact';
}
if (!$uid) {
  drupal_set_message("Usage: node/56/uid");
} else {
  dpm( "Trying  dh_perms_get_contact_entity_ids($contact_type, $uid)");
  $eids = dh_perms_get_contact_entity_ids($contact_type, $uid);
  dpm($eids,'eids');
     
     /*
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
  */
}
?>