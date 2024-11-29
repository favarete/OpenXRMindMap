extends Node

const uuid_util = preload('res://Scripts/uuid.gd')

#-------------------------------------------------------------------------------

func get_main_timer() -> Node:
	var path_to_node = "StartXR/MainTimer"
	return get_node_by_path(path_to_node)

func get_mind_map_container() -> Node:
	var path_to_node = "StartXR/XROrigin3D/MindMapContainer"
	return get_node_by_path(path_to_node)

func get_mindmap_node_by_name(node_name: String) -> Node:
	var path_to_node = "StartXR/XROrigin3D/MindMapContainer/" + node_name
	return get_node_by_path(path_to_node)

func get_controller_node_by_name(controller_name: String) -> Node:
	var path_to_node = "StartXR/XROrigin3D/" + controller_name
	return get_node_by_path(path_to_node)
		
func get_node_by_path(path_to_node):
	var root = get_tree().root
	if root.has_node(path_to_node):
		return root.get_node(path_to_node)
	else:
		return null

#-------------------------------------------------------------------------------

func get_node_name_from_collider(area: Area3D):
	return area.get_parent().name
	
#-------------------------------------------------------------------------------

func set_node_from_collison(controller_name: String, area: Area3D):
	var controller_ref = Globals.controllers[controller_name]
	
	if not controller_ref.active_node:
		controller_ref.active_node = get_mindmap_node_by_name(get_node_name_from_collider(area))

#-------------------------------------------------------------------------------

func unset_node_from_collison(controller_name: String, area: Area3D):
	var controller_ref = Globals.controllers[controller_name]
	
	if controller_ref.active_node \
	and controller_ref.active_node.name == get_node_name_from_collider(area):
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


func update_mindmap_data(reference_node, action_name):
	var actual_mindmap = Globals.get_active_mindmap()
	
	match action_name:
		"update":
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
		"add":
			actual_mindmap.nodes[reference_node.key] = reference_node.value
			pass

#-------------------------------------------------------------------------------

signal update_edge(edge_node, start_pos, end_pos)
func move_active_node_edge(edges: Array):
	var active_mind_map = Globals.get_active_mindmap()
	for id in edges:
		var edge_node = get_mindmap_node_by_name(id)
		var source_node = get_mindmap_node_by_name(active_mind_map.edges[id].source)
		var target_node = get_mindmap_node_by_name(active_mind_map.edges[id].target)
		update_edge.emit(edge_node, source_node.position, target_node.position)


func move_active_node(controller_name: String, controller_position: Vector3):
	var controller_ref = Globals.controllers[controller_name]
	
	controller_ref.active_node.position = controller_position + controller_ref.offset
	
	update_mindmap_data(controller_ref.active_node, "update")
	
	var active_node_edges = controller_ref.active_node.get_meta("edges")
	if not active_node_edges.is_empty():
		move_active_node_edge(active_node_edges)


signal add_node(key, value)
func add_new_node(controller_name: String, controller_position: Vector3):
	var controller_ref = Globals.controllers[controller_name]
	
	var new_node_key = uuid_util.v4()
	var adjusted_controller_position = controller_position + controller_ref.offset
	var new_node_value = {
		"label": Globals.DEFAULT_LABEL_TEXT,
		"type": Globals.DEFAULT_NODE_TYPE,
		"color": Globals.DEFAULT_NODE_COLOR,
		"position": {
			"x": controller_position.x,
			"y": controller_position.y,
			"z": controller_position.z
		},
		"scales": {
			"label": Globals.DEFAULT_LABEL_SCALE,
			"node": Globals.DEFAULT_NODE_SCALE
		},
		"edges": []
	}
	
	unset_button_pressed(controller_name, "trigger_click")
	add_node.emit(new_node_key, new_node_value)
	
	update_mindmap_data({"key": new_node_key, "value": new_node_value}, "add")


#-------------------------------------------------------------------------------

func valid_movement_action(controller_name: String):
	var controller_ref = Globals.controllers[controller_name]
	
	var check_conditions = controller_ref.active_node \
	and controller_ref.active_actions.has("grip_click")
	
	return check_conditions


func valid_add_node_action(controller_name: String):
	var controller_ref = Globals.controllers[controller_name]
	
	var check_conditions = not controller_ref.active_node \
	and controller_ref.active_actions.has("trigger_click")
	
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
	
