extends MeshInstance3D

var left_controller = Globals.controllers["LeftController"]
var right_controller = Globals.controllers["RightController"]

var material_hovered = load("res://Materials/hovered_element.tres")
var material_selected = load("res://Materials/selected_element.tres")

var is_left_active_node = false
var is_right_active_node = false

func _process(_delta: float) -> void:
	if is_instance_valid(left_controller.active_node):
		if left_controller.active_node.name == name:
			is_left_active_node = true
		else:
			is_left_active_node = false
	else:
		is_left_active_node = false
	
	if not is_left_active_node:
		if is_instance_valid(right_controller.active_node) and name:
			if right_controller.active_node.name == name:
				is_right_active_node = true
			else:
				is_right_active_node = false
		else:
			is_right_active_node = false
 
	if is_left_active_node or is_right_active_node:
		material_overlay = material_hovered
	else:
		material_overlay = null
