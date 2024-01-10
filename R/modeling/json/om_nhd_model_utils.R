
nhd_next_up <- function (comid, nhd_network) { 
  next_ups <- sqldf(
    paste(
      "select * from nhd_network 
       where tonode in (
         select fromnode from nhd_network 
         where comid = ", comid,
      ")"
    )
  )
  return(next_ups)
}


om_handle_wshed_area <- function(wshed_info) {
  if ("local_area_sqmi" %in% names(wshed_info)) {
    area_sqmi = wshed_info$local_area_sqmi
  } else {
    if ("area_sqmi" %in% names(wshed_info)) {
      area_sqmi = wshed_info$area_sqmi
    } else {
      if ("areasqkm" %in% names(wshed_info)) {
        area_sqmi = wshed_info$areasqkm * 0.386102
      } else {
        message("Cannot process. Watershed must have either local_area_sqmi or areasqkm")
        return(FALSE)
      }
    }
  }
  return(area_sqmi)
}

om_watershed_container <- function(wshed_info) {
  if (!("name" %in% names(wshed_info))) {
    if ("comid" %in% names(wshed_info)) {
      wshed_info$name = paste0('nhd_', wshed_info$comid)
    } else {
      message("Error: watershed info must have 'name' field")
      return(FALSE)
    }
  }
  wshed_props = list(
    name=wshed_info$name, 
    object_class = 'ModelObject'
  )
  area_sqmi = om_handle_wshed_area(wshed_info)
  if ("rchres_id" %in% names(wshed_info)) {
    rchres_id = wshed_info['rchres_id']
  } else {
    message("Error: You must include 'rchres_id' (ex: RCHRES_R001) to add container. ")
    return(FALSE)
  }
  wshed_props[['drainage_area_sqmi']] = list(
    name = 'drainage_area_sqmi', 
    object_class = 'Constant', 
    value = area_sqmi
  )
  wshed_props[['run_mode']] = list(
    name = 'run_mode', 
    object_class = 'Constant', 
    value = run_mode
  )
  wshed_props[['flow_mode']] = list(
    name = 'flow_mode', 
    object_class = 'Constant', 
    value = flow_mode
  )
  # inflow and unit area
  wshed_props[['IVOLin']] = list(
    name = 'IVOLin', 
    object_class = 'ModelLinkage',
    right_path = paste0('/STATE/', rchres_id, '/HYDR/IVOL'),
    link_type = 2
  )
  # this is a fudge, only valid for headwater segments
  # till we get DSN 10 in place
  wshed_props[['Runit']] = list(
    name = 'Runit', 
    object_class = 'Equation', 
    value='IVOLin / drainage_area_sqmi'
  )
  # Get Local & Upstream model inputs
  wshed_props[['read_from_children']] = list(
    name='read_from_children', 
    object_class = 'ModelBroadcast', 
    broadcast_type = 'read', 
    broadcast_channel = 'hydroObject', 
    broadcast_hub = 'self', 
    broadcast_params = list(
      list("Qtrib","Qtrib"),
      list("trib_area_sqmi","trib_area_sqmi"),
      list("child_wd_mgd","wd_mgd")
    )
  )
  return(wshed_props)
}



om_facility_model <- function(facility_info) {
  if (!("name" %in% names(facility_info))) {
    message("Error: Facility info must have 'name' field")
    return(FALSE)
  }
  facility_props = list(
    name=facility_info$name, 
    object_class = 'ModelObject'
  )
  facility_props[['send_to_parent']] = list(
    name='send_to_parent', 
    object_class = 'ModelBroadcast', 
    broadcast_type = 'send', 
    broadcast_channel = 'hydroObject', 
    broadcast_hub = 'parent', 
    broadcast_params = list(
      list("wd_mgd","wd_mgd"),
      list("discharge_mgd","ps_nextdown_mgd")
    )
  )
  return(facility_props)
}

om_nestable_watershed <- function(wshed_info) {
  if (!("name" %in% names(wshed_info))) {
    if ("comid" %in% names(wshed_info)) {
      wshed_info$name = paste0('nhd_', wshed_info$comid)
    } else {
      message("Error: watershed info must have 'name' field")
      return(FALSE)
    }
  }
  nested_props = list(
    name=wshed_info$name, 
    object_class = 'ModelObject'
  )
  area_sqmi = om_handle_wshed_area(wshed_info)
  nested_props[['local_area_sqmi']] = list(
    name='local_area_sqmi', 
    object_class = 'Equation', 
    value=area_sqmi
  )
  # Get Upstream model inputs
  nested_props[['read_from_children']] = list(
    name='read_from_children', 
    object_class = 'ModelBroadcast', 
    broadcast_type = 'read', 
    broadcast_channel = 'hydroObject', 
    broadcast_hub = 'self', 
    broadcast_params = list(
      list("Qtrib","Qtrib"),
      list("trib_area_sqmi","trib_area_sqmi"),
      list("child_wd_mgd","wd_mgd")
    )
  )
  # simulate flows
  nested_props[['Qlocal']] = list(
    name='Qlocal', 
    object_class = 'Equation', 
    value=paste('local_area_sqmi * Runit')
  )
  nested_props[['Qin']] = list(
    name='Qin', 
    object_class = 'Equation', 
    equation=paste('Qlocal + Qtrib')
  )
  nested_props[['Qout']] = list(
    name='Qout', 
    object_class = 'Equation', 
    equation=paste('Qin * 1.0')
  )
  # calculate secondary properties
  nested_props[['drainage_area_sqmi']] = list(
    name='drainage_area_sqmi', 
    object_class = 'Equation', 
    equation=paste('local_area_sqmi + trib_area_sqmi')
  )
  # send to parent object
  nested_props[['send_to_parent']] = list(
    name='send_to_parent', 
    object_class = 'ModelBroadcast', 
    broadcast_type = 'send', 
    broadcast_channel = 'hydroObject', 
    broadcast_hub = 'parent', 
    broadcast_params = list(
      list("Qout","Qtrib"),
      list("drainage_area_sqmi","trib_area_sqmi")
    )
  )
  return(nested_props)
}


nhd_model_network <- function (wshed_info, nhd_network, json_network) {
  comid = wshed_info$comid
  wshed_name = paste0('nhd_', comid)
  json_network[[wshed_name]] = list(
    name=wshed_name, 
    object_class = 'ModelObject'
  )
  # base attributes
  json_network[[wshed_name]][['local_area_sqmi']] = list(
    name='local_area_sqmi', 
    object_class = 'Equation', 
    value=paste(wshed_info$areasqkm,' * 0.386102')
  )
  # Get Upstream model inputs
  json_network[[wshed_name]][['read_from_children']] = list(
    name='read_from_children', 
    object_class = 'ModelBroadcast', 
    broadcast_type = 'read', 
    broadcast_channel = 'hydroObject', 
    broadcast_hub = 'self', 
    broadcast_params = list(
      list("Qtrib","Qtrib"),
      list("trib_area_sqmi","trib_area_sqmi")
    )
  )
  # simulate flows
  json_network[[wshed_name]][['Qlocal']] = list(
    name='Qlocal', 
    object_class = 'Equation', 
    value=paste('local_area_sqmi * Runit')
  )
  json_network[[wshed_name]][['Qin']] = list(
    name='Qin', 
    object_class = 'Equation', 
    equation=paste('Qlocal + Qtrib')
  )
  json_network[[wshed_name]][['Qout']] = list(
    name='Qout', 
    object_class = 'Equation', 
    equation=paste('Qin * 1.0')
  )
  # calculate secondary properties
  json_network[[wshed_name]][['drainage_area_sqmi']] = list(
    name='drainage_area_sqmi', 
    object_class = 'Equation', 
    equation=paste('local_area_sqmi + trib_area_sqmi')
  )
  # send to parent object
  json_network[[wshed_name]][['send_to_parent']] = list(
    name='send_to_parent', 
    object_class = 'ModelBroadcast', 
    broadcast_type = 'send', 
    broadcast_channel = 'hydroObject', 
    broadcast_hub = 'parent', 
    broadcast_params = list(
      list("Qout","Qtrib"),
      list("drainage_area_sqmi","trib_area_sqmi")
    )
  )
  next_ups <- nhd_next_up(comid, nhd_network)
  num_tribs = nrow(next_ups)
  if (num_tribs > 0) {
    for (n in 1:num_tribs) {
      trib_info = next_ups[n,]
      json_network[[wshed_name]] = nhd_model_network(trib_info, nhd_network, json_network[[wshed_name]])
    }
  }
  return(json_network)
}


nhd_model_network2 <- function (wshed_info, nhd_network, json_network, skip_comids) {
  comid = wshed_info$comid
  if (comid %in% skip_comids) {
    message(paste("Skipping comid", comid))
    return(json_network)
  }
  wshed_info$name = paste0('nhd_', comid)
  message(paste("Found", wshed_info$comid))
  json_network[[wshed_info$name]] = om_nestable_watershed(wshed_info)
  next_ups <- nhd_next_up(comid, nhd_network)
  num_tribs = nrow(next_ups)
  message(paste(comid,"has",num_tribs))
  if (num_tribs > 0) {
    for (n in 1:num_tribs) {
      trib_info = next_ups[n,]
      trib_info$name = paste0('nhd_', trib_info$comid)
      message(paste("Getting upstream for", trib_info$comid))
      json_network[[wshed_info$name]] = nhd_model_network2(trib_info, nhd_network, json_network[[wshed_info$name]], skip_comids)
    }
  }
  return(json_network)
}