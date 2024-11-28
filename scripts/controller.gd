extends Node3D

#-------------------------------------------------------------------------------

@onready var controller_name = get_parent().name
@onready var main_timer = Utils.get_main_timer()

#-------------------------------------------------------------------------------

func _on_interactive_element_entered(area: Area3D) -> void:
	Utils.set_node_from_collison(controller_name, area)

#-------------------------------------------------------------------------------

func _on_interactive_element_exited(area: Area3D) -> void:
	Utils.unset_node_from_collison(controller_name, area)

#-------------------------------------------------------------------------------
	
func _process(delta):
	if Utils.valid_movement_action(controller_name):
		Utils.move_active_node(controller_name, global_transform.origin)
		main_timer.stop()
	else:
		if main_timer.is_stopped():
			main_timer.start(Globals.SAVE_DELAY)
