extends Node3D

#-------------------------------------------------------------------------------

@onready var controller_name = get_parent().name
@onready var main_timer = Utils.get_main_timer()
@onready var sphere_guide := $MeshInstance3D
@onready var collision_guide := $Area3D
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
	if Utils.performing_creation(controller_name):
		main_timer.stop()
		if Globals.controllers[controller_name].node_connection.is_adding_edge:
			var all_collisions = collision_guide.get_overlapping_areas()
			if Utils.verify_edge_action(controller_name, all_collisions):
				print("CONNECT!")
		else:
			if Utils.valid_add_node_action(controller_name):
				Utils.add_new_node(controller_name, get_local_position())
	else:
		if Utils.valid_movement_action(controller_name):
			main_timer.stop()
			Utils.move_active_node(controller_name, get_local_position())
		else:
			if main_timer.is_stopped():
				main_timer.start(Globals.SAVE_DELAY)
