extends Node3D

#-------------------------------------------------------------------------------

@onready var controller_name = get_parent().name
@onready var controller_ref = Globals.controllers[get_parent().name]
@onready var main_timer = Utils.get_main_timer()
@onready var sphere_guide := $Guide/MainSphere
@onready var visual_feedback := $Guide/VisualFeedback
@onready var collision_guide := $Area3D
@onready var mind_map_container = Utils.get_mind_map_container()

#-------------------------------------------------------------------------------

func _on_interactive_element_entered(area: Area3D) -> void:
	Utils.set_node_from_collison(controller_name, area)

func _on_interactive_element_exited(area: Area3D) -> void:
	Utils.unset_node_from_collison(controller_name, area)

#-------------------------------------------------------------------------------

func get_local_position():
#	var position_tracker = sphere_guide.global_transform.origin
	return mind_map_container.to_local(sphere_guide.global_transform.origin)

#-------------------------------------------------------------------------------

func valid_movement_action():
	var check_conditions = controller_ref.active_node \
	and controller_ref.active_actions.has("grip_click")
	
	return check_conditions

func valid_add_node_action():
	var check_conditions = not controller_ref.active_node \
	and controller_ref.active_actions.has("trigger_click")
	
	return check_conditions
	
func in_delete_position() -> bool:
	var check_conditions = controller_ref.active_node \
	and controller_ref.active_actions.has("thumbstick_backward")
	
	return check_conditions
	
func valid_delete_node_action() -> bool:
	var check_conditions = controller_ref.active_node \
	and controller_ref.active_actions.has("thumbstick_backward") \
	and controller_ref.active_actions.has("trigger_click")
	
	return check_conditions

func performing_creation():
	return controller_ref.active_actions.has("trigger_click")

#-------------------------------------------------------------------------------

const MIN_SIZE: float = 0.001
const MAX_SIZE = 0.05
const GROWTH_SPEED: float = 0.002
var scale_value: float = 0.0

func reset_visual_feedback():
	visual_feedback.scale = Vector3(MIN_SIZE, MIN_SIZE, MIN_SIZE)
	visual_feedback.visible = false
	scale_value = MIN_SIZE

#-------------------------------------------------------------------------------

func _process(_delta):
	if in_delete_position():
		if valid_delete_node_action():
			Utils.remove_active_node(controller_name)
	elif performing_creation():
		main_timer.stop()
		if Globals.controllers[controller_name].node_connection.is_adding_edge:
			reset_visual_feedback()
			var all_collisions = collision_guide.get_overlapping_areas()
			Utils.verify_edge_action(controller_name, all_collisions)
		else:
			if valid_add_node_action():
				if not visual_feedback.visible:
					visual_feedback.visible = true
				scale_value += GROWTH_SPEED
				visual_feedback.scale = Vector3(scale_value, scale_value, scale_value)
				if scale_value >= MAX_SIZE:
					Utils.add_new_node(controller_name, get_local_position())
	else:
		reset_visual_feedback()
		if valid_movement_action():
			main_timer.stop()
			Utils.move_active_node(controller_name, get_local_position())
		else:
			if main_timer.is_stopped():
				main_timer.start(Globals.SAVE_DELAY)

		var collisions_length = controller_ref.group_collision.collisions.size()
		if collisions_length == 0:
			Utils.set_active_node(controller_name, null)
		elif collisions_length == 1:
			Utils.set_active_node(controller_name, controller_ref.group_collision.collisions[0])
		else:
			var closest_sphere = null
			var closest_distance = INF
			for sphere in controller_ref.group_collision.collisions:
				var distance = sphere_guide.global_transform.origin.distance_to(sphere.global_transform.origin)
				if distance < closest_distance:
					closest_distance = distance
					closest_sphere = sphere
			Utils.set_active_node(controller_name, closest_sphere)
