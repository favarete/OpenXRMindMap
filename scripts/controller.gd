extends Node3D

#-------------------------------------------------------------------------------

const MIN_SIZE: float = 0.001
const MAX_SIZE = 0.05
const GROWTH_SPEED: float = 0.002

@onready var controller_name = get_parent().name
@onready var main_timer = Utils.get_main_timer()
@onready var sphere_guide := $Guide/MainSphere
@onready var visual_feedback := $Guide/VisualFeedback
@onready var collision_guide := $Area3D
@onready var mind_map_container = Utils.get_mind_map_container()

var scale_value: float = 0.0

#-------------------------------------------------------------------------------

func _on_interactive_element_entered(area: Area3D) -> void:
	Utils.set_node_from_collison(controller_name, area)

func _on_interactive_element_exited(area: Area3D) -> void:
	Utils.unset_node_from_collison(controller_name, area)

#-------------------------------------------------------------------------------

func get_local_position():
	var position_tracker = sphere_guide.global_transform.origin
	return mind_map_container.to_local(sphere_guide.global_transform.origin)

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

func performing_creation(controller_name: String):
	var controller_ref = Globals.controllers[controller_name]
	return controller_ref.active_actions.has("trigger_click")

#-------------------------------------------------------------------------------

func reset_visual_feedback():
	visual_feedback.scale = Vector3(MIN_SIZE, MIN_SIZE, MIN_SIZE)
	scale_value = MIN_SIZE
#-------------------------------------------------------------------------------

func _process(delta):
	if performing_creation(controller_name):
		main_timer.stop()
		if Globals.controllers[controller_name].node_connection.is_adding_edge:
			reset_visual_feedback()
			var all_collisions = collision_guide.get_overlapping_areas()
			Utils.verify_edge_action(controller_name, all_collisions)
		else:
			if valid_add_node_action(controller_name):
				scale_value += GROWTH_SPEED
				visual_feedback.scale = Vector3(scale_value, scale_value, scale_value)
				if scale_value >= MAX_SIZE:
					Utils.add_new_node(controller_name, get_local_position())
	else:
		reset_visual_feedback()
		if valid_movement_action(controller_name):
			main_timer.stop()
			Utils.move_active_node(controller_name, get_local_position())
		else:
			if main_timer.is_stopped():
				main_timer.start(Globals.SAVE_DELAY)
