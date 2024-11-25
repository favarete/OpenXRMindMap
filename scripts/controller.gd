extends Node3D

@onready var controller_name = get_parent().name

func _on_interactive_element_entered(area: Area3D) -> void:
	MindMapContainer.active_controler = controller_name
	MindMapContainer.set_node_from_collison(area, global_transform.origin)

func _on_interactive_element_exited(area: Area3D) -> void:
	MindMapContainer.active_controler = null
	MindMapContainer.unset_node_from_collison(area)

func _process(delta):
	if MindMapContainer.valid_movement_action(controller_name):
		MindMapContainer.move_active_node(global_transform.origin)
