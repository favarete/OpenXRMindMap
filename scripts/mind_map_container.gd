extends Node

var active_node: Node3D = null
var active_controler = null
var initial_offset: Vector3 = Vector3.ZERO

var button_pressed = {
	"LeftController": [],
	"RightController": []
}

const REF_POSITION = "Main/XROrigin3D/MindMapContainer"

const TYPE_MAP_EDGE = "edge"
const TYPE_MAP_NODE = "node"
const TYPE_MAP_LABEL = "label"

func get_element_id(source_id, type, target_id = null):
	match type:
		TYPE_MAP_NODE:
			return "NODE<{0}>".format([source_id])
		TYPE_MAP_LABEL:
			return "LABEL<{0}>".format([source_id])
		TYPE_MAP_EDGE:
			var node_ids = [source_id, target_id]
			node_ids.sort()
			return "EDGE<{0}><to><{1}>".format(node_ids)
		_:
			return source_id


func get_collider_id(node_name):
	return "COLLIDER<{0}>".format([node_name])


func process_collider_string(input: String) -> String:
	if input.begins_with("COLLIDER"):
		var stripped = input.substr(9)
		var end_index = stripped.find(">") + 1
		if end_index != -1:
			return stripped.substr(0, end_index)
	return input


func get_node_by_name(node_name: String) -> Node:
	var root = get_tree().root
	var node_path = REF_POSITION + "/" + node_name
	if root.has_node(node_path):
		return root.get_node(node_path)
	else:
		return null


func set_node_from_collison(area: Area3D, controller_position: Vector3):
	var node_name = process_collider_string(area.name)
	active_node = get_node_by_name(node_name)
	if active_node:
		initial_offset = active_node.global_transform.origin - controller_position


func unset_node_from_collison(area: Area3D):
	var node_name = process_collider_string(area.name)
	if active_node and active_node.name == node_name:
		active_node = null
		initial_offset = Vector3.ZERO


func move_active_node(controller_position: Vector3):
	active_node.global_transform.origin = controller_position + initial_offset


func valid_movement_action(controller_name: String):
	return active_node \
	and active_controler == controller_name \
	and button_pressed[controller_name].has("grip_click")


func set_button_pressed(controller: String, action: String):
	var controller_ref = button_pressed[controller]
	if not controller_ref.has(action):
		controller_ref.append(action)


func unset_button_pressed(controller: String, action: String):
	var controller_ref = button_pressed[controller]
	if controller_ref.has(action):
		controller_ref.erase(action)
	
