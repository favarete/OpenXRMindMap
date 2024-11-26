extends Node

#-------------------------------------------------------------------------------

func get_mindmap_node_by_name(node_name: String) -> Node:
	const REF_POSITION = "StartXR/XROrigin3D/MindMapContainer"
	
	var root = get_tree().root
	var node_path = REF_POSITION + "/" + node_name
	if root.has_node(node_path):
		return root.get_node(node_path)
	else:
		return null

func get_controller_node_by_name(controller_name: String) -> Node:
	const REF_POSITION = "StartXR/XROrigin3D"
	
	var root = get_tree().root
	var node_path = REF_POSITION + "/" + controller_name
	if root.has_node(node_path):
		return root.get_node(node_path)
	else:
		return null

#-------------------------------------------------------------------------------

func get_node_name_from_collider(area: Area3D):
	return area.get_parent().name
	
#-------------------------------------------------------------------------------

func set_node_from_collison(controller_name: String, area: Area3D):
	var controller_ref = Globals.controllers[controller_name]
	
	if not controller_ref.is_interacting:
		controller_ref.is_interacting = true
		controller_ref.active_node = get_mindmap_node_by_name(get_node_name_from_collider(area))

#-------------------------------------------------------------------------------

func unset_node_from_collison(controller_name: String, area: Area3D):
	var controller_ref = Globals.controllers[controller_name]
	
	if controller_ref.active_node \
	and controller_ref.active_node.name == get_node_name_from_collider(area):
		controller_ref.is_interacting = false
		controller_ref.active_node = null

#-------------------------------------------------------------------------------

func move_active_node(controller_name: String, controller_position: Vector3):
	var controller_ref = Globals.controllers[controller_name]
	
	controller_ref.active_node.global_transform.origin = \
	controller_position + controller_ref.offset

#-------------------------------------------------------------------------------

func valid_movement_action(controller_name: String):
	var controller_ref = Globals.controllers[controller_name]
	
	var check_conditions = controller_ref.active_node \
	and controller_ref.is_interacting  \
	and controller_ref.active_actions.has("grip_click")
	
	return check_conditions

#-------------------------------------------------------------------------------

func set_controller_offset(controller_name: String):
	var controller_ref = Globals.controllers[controller_name]
	if controller_ref.active_node:
		var node_position = controller_ref.active_node.global_transform.origin
		var controller_instance = get_controller_node_by_name(controller_name)
		var controller_collider = controller_instance.get_node("Controller/MeshInstance3D")
	
		controller_ref.offset = node_position  - controller_collider.global_transform.origin
		
#-------------------------------------------------------------------------------

func set_button_pressed(controller_name: String, action: String):
	var controller_ref = Globals.controllers[controller_name]
	set_controller_offset(controller_name)
	if not controller_ref.active_actions.has(action):
		controller_ref.active_actions.append(action)

#-------------------------------------------------------------------------------

func unset_button_pressed(controller_name: String, action: String):
	var controller_ref = Globals.controllers[controller_name]
	
	if controller_ref.active_actions.has(action):
		controller_ref.active_actions.erase(action)
		controller_ref.offset = Vector3.ZERO
	
