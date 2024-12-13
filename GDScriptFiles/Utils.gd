extends Node

func get_main_timer() -> Timer:
	var path_to_node: String = "StartXRContainer/MainTimer"
	var root: Window = get_root()
	return root.get_node(path_to_node) if root.has_node(path_to_node) else null

func get_mind_map_container() -> Node3D:
	var path_to_node: String = "StartXRContainer/XROrigin3D/MindMapContainer"
	var root: Window = get_root()
	return root.get_node(path_to_node) if root.has_node(path_to_node) else null

func get_mindmap_node_by_name(node_name: String) -> MeshInstance3D:
	var path_to_node: String = "StartXRContainer/XROrigin3D/MindMapContainer/" + node_name
	var root: Window = get_root()
	return root.get_node(path_to_node) if root.has_node(path_to_node) else null

func get_controller_node_by_name(controller_name: String) -> XRController3D:
	var path_to_node: String = "StartXRContainer/XROrigin3D/" + controller_name
	var root: Window = get_root()
	return root.get_node(path_to_node) if root.has_node(path_to_node) else null
		
func get_root() -> Window:
	return get_tree().root

#-------------------------------------------------------------------------------

func get_node_name_from_collider(area: Area3D) -> String:
	return area.get_parent().name
	
#-------------------------------------------------------------------------------

func set_active_node(controller_name: String, node_instance: MeshInstance3D) -> void:
	var controller_ref: Dictionary = Globals.controllers[controller_name]
	controller_ref.active_node = node_instance

func set_node_from_collison(controller_name: String, area: Area3D) -> void:
	var controller_ref: Dictionary = Globals.controllers[controller_name]
	var new_collision: MeshInstance3D = get_mindmap_node_by_name(get_node_name_from_collider(area))
	
	var local_collisions: Array = controller_ref.group_collision.collisions
	if not local_collisions.has(new_collision):
		local_collisions.append(new_collision)

func unset_node_from_collison(controller_name: String, area: Area3D) -> void:
	var controller_ref: Dictionary = Globals.controllers[controller_name]
	
	var node_ref: MeshInstance3D = get_mindmap_node_by_name(get_node_name_from_collider(area))
	
	var local_collisions: Array = controller_ref.group_collision.collisions
	if local_collisions.has(node_ref):
		local_collisions.erase(node_ref)

#-------------------------------------------------------------------------------

signal update_edge(edge_node: MeshInstance3D, start_pos: MeshInstance3D, end_pos: MeshInstance3D)
func move_active_node_edge(edges: Array) -> void:
	var active_mind_map: Dictionary = Globals.get_active_mindmap()
	for id: String in edges:
		var edge_node: MeshInstance3D = get_mindmap_node_by_name(id)
		
		var source_node_name: String = active_mind_map.edges[id].source
		var source_node: MeshInstance3D = get_mindmap_node_by_name(source_node_name)
		
		var target_node_name: String = active_mind_map.edges[id].target
		var target_node: MeshInstance3D = get_mindmap_node_by_name(target_node_name)
		update_edge.emit(edge_node, source_node.position, target_node.position)


func move_active_node(controller_name: String, controller_position: Vector3) -> void:
	var controller_ref: Dictionary = Globals.controllers[controller_name]
	var active_node: MeshInstance3D = controller_ref.active_node
	
	active_node.position = controller_position + controller_ref.offset
	update_mindmap_data({"node_instance": active_node}, "update-node")
	
	var active_node_edges: Array = active_node.get_meta("edges")
	if not active_node_edges.is_empty():
		move_active_node_edge(active_node_edges)

#-------------------------------------------------------------------------------

signal add_node(key: String, value: Dictionary)
func add_new_node(controller_name: String, controller_position: Vector3) -> void:	
	var new_node_key: String = UUID.v4()

	var new_node_value: Dictionary = {
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

func remove_active_node(controller_name: String) -> void:
	if is_instance_valid(Globals.controllers[controller_name].active_node):
		var node_name: String = Globals.controllers[controller_name].active_node.name
		var node_instance: MeshInstance3D = get_mindmap_node_by_name(node_name)
		if node_instance:
			var tween: Tween = create_tween().bind_node(node_instance)
			var scale_in_vector: Vector3 = node_instance.scale * (Vector3.ONE * 1.1)
			var _in: PropertyTweener = tween.tween_property(node_instance, "scale", scale_in_vector, 
				Globals.TWEEN_CONSTRUCTION_DELAY).set_ease(Tween.EASE_IN)
			var _out: PropertyTweener = tween.tween_property(node_instance, "scale", Vector3.ONE * 0.001, 
				Globals.TWEEN_CONSTRUCTION_DELAY).set_ease(Tween.EASE_OUT)
			var _cb: CallbackTweener = tween.tween_callback(func () -> void: node_instance.queue_free())
			Globals.controllers[controller_name].active_node = null
		
		var actual_mindmap: Dictionary = Globals.get_active_mindmap()
		var edges_to_remove: Array = actual_mindmap.nodes[node_name].edges
		
		for edge_id: String in edges_to_remove:
			var edges_instance: MeshInstance3D = get_mindmap_node_by_name(edge_id)
			if edges_instance: edges_instance.queue_free()
		
		update_mindmap_data({
			"node_to_remove": node_name,
			"edges_to_remove": edges_to_remove
		}, "remove-node")

#-------------------------------------------------------------------------------

func update_node_connection(new_edge_data: Dictionary) -> void:
	var source_name: String = new_edge_data.source
	var target_name: String = new_edge_data.target
	var start_node_instance: MeshInstance3D = get_mindmap_node_by_name(source_name)
	var end_node_instance: MeshInstance3D = get_mindmap_node_by_name(target_name)
	var edge_id: String = new_edge_data.key
	
	var start_node_edges: Array = start_node_instance.get_meta("edges")
	if not start_node_edges.has(edge_id):
		start_node_edges.append(edge_id)
		start_node_instance.set_meta("edges", start_node_edges)
		
	var end_node_edges: Array = end_node_instance.get_meta("edges")
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

func update_mindmap_data(reference_data: Dictionary, action_name: String) -> void:
	var actual_mindmap: Dictionary = Globals.get_active_mindmap()
	
	match action_name:
		"update-node":
			var node_to_update: Dictionary = actual_mindmap.nodes[reference_data.node_instance.name]
	
			#node_to_update.label = reference_node.label
	
			#node_to_update.type =  reference_node.type
			#node_to_update.color =  reference_node.color
			node_to_update.position = {
				"x": reference_data.node_instance.position.x,
				"y": reference_data.node_instance.position.y,
				"z": reference_data.node_instance.position.z
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
			var node_data: Dictionary = actual_mindmap.nodes
			if node_data.has(reference_data.node_to_remove):
				var _nl: bool = node_data.erase(reference_data.node_to_remove)
			for edge_id: String in reference_data.edges_to_remove:
				var map_edges_data: Dictionary = actual_mindmap.edges
				if map_edges_data.has(edge_id):
					var source_node_id: String = actual_mindmap.edges[edge_id].source
					var target_node_id: String = actual_mindmap.edges[edge_id].target
					
					var node_to_clean_id: String = source_node_id \
						if reference_data.node_to_remove == target_node_id else target_node_id
					if node_data.has(node_to_clean_id):
						var node_to_clean: Array = node_data[node_to_clean_id].edges
						node_to_clean.erase(edge_id)
					var _er: bool = map_edges_data.erase(edge_id)

#-------------------------------------------------------------------------------

signal add_edge(key: String, value: Dictionary)
func verify_edge_action(controller_name: String, collision_guide: Array) -> void:
	var controller_ref: Dictionary = Globals.controllers[controller_name]
	var start_connection: String = controller_ref.node_connection.start.name

	for collision: Area3D in collision_guide:
		var end_connection: String = get_node_name_from_collider(collision)
		if start_connection != end_connection:
			unset_button_pressed(controller_name, "trigger_click")
			if Globals.connection_is_new(start_connection, end_connection):
				var new_edge_key: String = UUID.v4()
				
				var new_edge_data: Dictionary = {
					"source": start_connection, 
					"target": end_connection
				}
				
				add_edge.emit(new_edge_key, new_edge_data)
				
				new_edge_data["key"] = new_edge_key
				
				update_node_connection(new_edge_data)
				update_mindmap_data(new_edge_data, "add-edge")
			break

#-------------------------------------------------------------------------------

func set_controller_offset(controller_name: String) -> void:
	var controller_ref: Dictionary = Globals.controllers[controller_name]
	if is_instance_valid(controller_ref.active_node):
		var node_position: Vector3 = controller_ref.active_node.global_transform.origin
		var controller_instance: XRController3D = get_controller_node_by_name(controller_name)
		var controller_collider: MeshInstance3D = controller_instance.get_node("Controller/Guide/MainSphere")
	
		controller_ref.offset = node_position - controller_collider.global_transform.origin
		
#-------------------------------------------------------------------------------

func set_button_pressed(controller_name: String, action: String) -> void:
	var controller_ref: Dictionary = Globals.controllers[controller_name]
	var active_actions: Array = controller_ref.active_actions

	set_controller_offset(controller_name)
	if not active_actions.has(action):
		if action == "trigger_click" and \
		not active_actions.has("thumbstick_backward"):
			if controller_ref.active_node:
				controller_ref.node_connection.is_adding_edge = true
				controller_ref.node_connection.start = controller_ref.active_node
			else:
				controller_ref.node_connection.is_adding_edge = false
				controller_ref.node_connection.start = null
			controller_ref.node_connection.end = null
				
		active_actions.append(action)

func unset_button_pressed(controller_name: String, action: String) -> void:
	var controller_ref: Dictionary = Globals.controllers[controller_name]
	var active_actions: Array = controller_ref.active_actions

	if active_actions.has(action):
		if active_actions.has("trigger_click"):
			controller_ref.node_connection.is_adding_edge = false
			controller_ref.node_connection.start = null
			controller_ref.node_connection.end = null
		
		active_actions.erase(action)
		controller_ref.offset = Vector3.ZERO
