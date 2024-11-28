extends Node

#-------------------------------------------------------------------------------

func get_main_timer() -> Node:
	const REF_POSITION = "StartXR/MainTimer"
	var root = get_tree().root
	if root.has_node(REF_POSITION):
		return root.get_node(REF_POSITION)
	else:
		return null

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

		#"7825ddcf-69aa-4ff4-b993-1867cf5bc51b": {
			#"label": "Node D",
			#"type": "common_cube",
			#"color": "#AA4A44",
			#"position": {
				#"x": -0.05,
				#"y": 0.2,
				#"z": -0.01
			#},
			#"scales": {
				#"label": 2,
				#"node": 0.05
			#},
			#"edges": [
				#"85d143e6-4567-4b53-9778-8f19946e9edc"
			#]
		#},


func update_mindmap_data(reference_node):
	var actual_mindmap = Globals.get_active_mindmap()
	var node_to_update = actual_mindmap.nodes[reference_node.name]
	
	#node_to_update.label = reference_node.label
	
	#node_to_update.type =  reference_node.type
	#node_to_update.color =  reference_node.color
	node_to_update.position = {
		"x": reference_node.position.x,
		"y": reference_node.position.y,
		"z": reference_node.position.z
		}
	#node_to_update.scales = {
		#"label": reference_node,
		#"node": 0.05
	#}

#-------------------------------------------------------------------------------

signal update_edge(edge_node, start_pos, end_pos)
func move_active_node_edge(edges: Array):
	var active_mind_map = Globals.get_active_mindmap()
	for id in edges:
		var edge_node = get_mindmap_node_by_name(id)
		var source_node = get_mindmap_node_by_name(active_mind_map.edges[id].source)
		var target_node = get_mindmap_node_by_name(active_mind_map.edges[id].target)
		update_edge.emit(edge_node, source_node.position, target_node.position)


#-------------------------------------------------------------------------------

func move_active_node(controller_name: String, controller_position: Vector3):
	var controller_ref = Globals.controllers[controller_name]
	
	controller_ref.active_node.global_transform.origin = \
	controller_position + controller_ref.offset
	
	update_mindmap_data(controller_ref.active_node)
	
	var active_node_edges = controller_ref.active_node.get_meta("edges")
	if not active_node_edges.is_empty():
		move_active_node_edge(active_node_edges)

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
	
