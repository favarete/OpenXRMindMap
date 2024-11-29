extends Node3D

#-------------------------------------------------------------------------------

@onready var controller_name = get_parent().name
@onready var main_timer = Utils.get_main_timer()
@onready var sphere_guide: MeshInstance3D = $MeshInstance3D
@onready var mind_map_container = Utils.get_mind_map_container()

#-------------------------------------------------------------------------------

func _on_interactive_element_entered(area: Area3D) -> void:
	Utils.set_node_from_collison(controller_name, area)

#-------------------------------------------------------------------------------

func _on_interactive_element_exited(area: Area3D) -> void:
	Utils.unset_node_from_collison(controller_name, area)

#-------------------------------------------------------------------------------

func get_local_position():
	var position_tracker = sphere_guide.global_transform.origin
	return mind_map_container.to_local(sphere_guide.global_transform.origin)

func _process(delta):
	if Utils.valid_movement_action(controller_name):
		Utils.move_active_node(controller_name, get_local_position())
		main_timer.stop()
	if Utils.valid_add_node_action(controller_name):
		Utils.add_new_node(controller_name, get_local_position())
		main_timer.stop()
	else:
		if main_timer.is_stopped():
			main_timer.start(Globals.SAVE_DELAY)
