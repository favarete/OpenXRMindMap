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

const material_hovered = preload("res://Materials/hovered_element.tres")
const material_selected = preload("res://Materials/selected_element.tres")

func set_node_from_collison(controller_name: String, area: Area3D):
	var controller_ref = Globals.controllers[controller_name]
	
	if not controller_ref.active_node:
		var active_node = get_mindmap_node_by_name(get_node_name_from_collider(area))
		active_node.material_overlay = material_hovered
		controller_ref.active_node = active_node

func unset_node_from_collison(controller_name: String, area: Area3D):
	var controller_ref = Globals.controllers[controller_name]
	
	var active_node_name = get_node_name_from_collider(area)
	
	if controller_ref.active_node \
	and controller_ref.active_node.name == active_node_name:
		controller_ref.active_node = null
		var active_node = get_mindmap_node_by_name(active_node_name)
		active_node.material_overlay = null

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
	
	update_mindmap_data(controller_ref.active_node, "update-node")
	
	var active_node_edges = controller_ref.active_node.get_meta("edges")
	if not active_node_edges.is_empty():
		move_active_node_edge(active_node_edges)

#-------------------------------------------------------------------------------

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
	
	update_mindmap_data({"key": new_node_key, "value": new_node_value}, "add-node")

func remove_active_node(controller_name: String):
	var node_name = Globals.controllers[controller_name].active_node.name
	var node_instance = get_mindmap_node_by_name(node_name)
	if node_instance:
		var tween = create_tween().bind_node(node_instance)
		var scale_in_vector = node_instance.scale * (Vector3.ONE * 1.1)
		tween.tween_property(node_instance, "scale", scale_in_vector, 
			Globals.TWEEN_CONSTRUCTION_DELAY).set_ease(Tween.EASE_IN)
		tween.tween_property(node_instance, "scale", Vector3.ONE * 0.001, 
			Globals.TWEEN_CONSTRUCTION_DELAY).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func (): node_instance.queue_free())
		Globals.controllers[controller_name].active_node = null
	
	var actual_mindmap = Globals.get_active_mindmap()
	var edges_to_remove = actual_mindmap.nodes[node_name].edges
	
	for edge_id in edges_to_remove:
		var edges_instance = get_mindmap_node_by_name(edge_id)
		if edges_instance: edges_instance.queue_free()
	
	update_mindmap_data({
		"node_to_remove": node_name,
		"edges_to_remove": edges_to_remove
	}, "remove-node")

#-------------------------------------------------------------------------------

func update_node_connection(new_edge_data: Dictionary):
	var start_node_instance = get_mindmap_node_by_name(new_edge_data.source)
	var end_node_instance = get_mindmap_node_by_name(new_edge_data.target)
	var edge_id = new_edge_data.key
	
	var start_node_edges = start_node_instance.get_meta("edges")
	if not start_node_edges.has(edge_id):
		start_node_edges.append(edge_id)
		start_node_instance.set_meta("edges", start_node_edges)
		
	var end_node_edges = end_node_instance.get_meta("edges")
	if not end_node_edges.has(edge_id):
		end_node_edges.append(edge_id)
		end_node_instance.set_meta("edges", end_node_edges)
		
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

func update_mindmap_data(reference_data, action_name):
	var actual_mindmap = Globals.get_active_mindmap()
	
	match action_name:
		"update-node":
			var node_to_update = actual_mindmap.nodes[reference_data.name]
	
			#node_to_update.label = reference_node.label
	
			#node_to_update.type =  reference_node.type
			#node_to_update.color =  reference_node.color
			node_to_update.position = {
				"x": reference_data.position.x,
				"y": reference_data.position.y,
				"z": reference_data.position.z
				}
			#node_to_update.scales = {
				#"label": reference_node,
				#"node": 0.05
			#}
		"add-node":
			actual_mindmap.nodes[reference_data.key] = reference_data.value
		"add-edge":
			actual_mindmap.edges[reference_data.key] = {
				"source": reference_data.source,
				"target": reference_data.target
			}
		"remove-node":
			if actual_mindmap.nodes.has(reference_data.node_to_remove):
				actual_mindmap.nodes.erase(reference_data.node_to_remove)
			for edge_id in reference_data.edges_to_remove:
				if actual_mindmap.edges.has(edge_id):
					actual_mindmap.edges.erase(edge_id)

#-------------------------------------------------------------------------------

signal add_edge(key, value)
func verify_edge_action(controller_name: String, collision_guide: Array[Area3D]):
	var controller_ref = Globals.controllers[controller_name]
	var start_connection = controller_ref.node_connection.start.name

	for collision in collision_guide:
		var end_connection = get_node_name_from_collider(collision)
		if start_connection != end_connection:
			unset_button_pressed(controller_name, "trigger_click")
			if Globals.connection_is_new(start_connection, end_connection):
				var new_edge_key = uuid_util.v4()
				
				var new_edge_data = {
					"source": start_connection, 
					"target": end_connection
				}
				
				add_edge.emit(new_edge_key, new_edge_data)
				
				new_edge_data["key"] = new_edge_key
				
				update_node_connection(new_edge_data)
				update_mindmap_data(new_edge_data, "add-edge")
			break

#-------------------------------------------------------------------------------

func set_controller_offset(controller_name: String):
	var controller_ref = Globals.controllers[controller_name]
	if controller_ref.active_node:
		var node_position = controller_ref.active_node.global_transform.origin
		var controller_instance = get_controller_node_by_name(controller_name)
		var controller_collider = controller_instance.get_node("Controller/Guide/MainSphere")
	
		controller_ref.offset = node_position  - controller_collider.global_transform.origin
		
#-------------------------------------------------------------------------------

func set_button_pressed(controller_name: String, action: String):
	var controller_ref = Globals.controllers[controller_name]

	set_controller_offset(controller_name)
	if not controller_ref.active_actions.has(action):
		if action == "trigger_click" and \
		not controller_ref.active_actions.has("thumbstick_backward"):
			if controller_ref.active_node:
				controller_ref.node_connection.is_adding_edge = true
				controller_ref.node_connection.start = controller_ref.active_node
			else:
				controller_ref.node_connection.is_adding_edge = false
				controller_ref.node_connection.start = null
			controller_ref.node_connection.end = null
				
		controller_ref.active_actions.append(action)

func unset_button_pressed(controller_name: String, action: String):
	var controller_ref = Globals.controllers[controller_name]
	
	if controller_ref.active_actions.has(action):
		if controller_ref.active_actions.has("trigger_click"):
			controller_ref.node_connection.is_adding_edge = false
			controller_ref.node_connection.start = null
			controller_ref.node_connection.end = null
		
		controller_ref.active_actions.erase(action)
		controller_ref.offset = Vector3.ZERO
