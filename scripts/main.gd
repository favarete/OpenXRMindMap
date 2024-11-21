extends StartXR

var fb_passthrough
var countdown_to_recenter_hmd: int = 3

@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var left_controller_ray_cast: RayCast3D = $XROrigin3D/LeftController/Controller/ControllerRayCast
@onready var right_controller_ray_cast: RayCast3D = $XROrigin3D/RightController/Controller/ControllerRayCast
@onready var passthrough_geometry: OpenXRFbPassthroughGeometry = $XROrigin3D/OpenXRFbPassthroughGeometry


func _ready() -> void:
	super._ready()
	enable_passthrough_mode()


func _process(_delta: float) -> void:
	if countdown_to_recenter_hmd > 0:
		countdown_to_recenter_hmd -= 1
		if countdown_to_recenter_hmd == 0:
			XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)

func enable_passthrough_mode() -> void:
	get_viewport().transparent_bg = true
	world_environment.environment.background_mode = Environment.BG_COLOR
	world_environment.environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
	xr_interface.environment_blend_mode = XRInterface.XR_ENV_BLEND_MODE_ALPHA_BLEND
	passthrough_geometry.hide()
	
	fb_passthrough = Engine.get_singleton("OpenXRFbPassthroughExtensionWrapper")
	fb_passthrough.set_passthrough_filter(OpenXRFbPassthroughExtensionWrapper.PASSTHROUGH_FILTER_DISABLED)

func _on_left_controller_button_pressed(name: String) -> void:
	if name == "trigger_click" and left_controller_ray_cast.is_colliding():
		var collider = left_controller_ray_cast.get_collider()
		# func_name(collider.name)

		# if true:
		#	collider.update_value(left_controller_ray_cast.get_collision_point())
		# else:
		#	update(collider.name)

func _on_right_controller_button_pressed(name: String) -> void:
	if name == "trigger_click" and right_controller_ray_cast.is_colliding():
		var collider = right_controller_ray_cast.get_collider()

		# if true:
		#	collider.update_value(right_controller_ray_cast.get_collision_point())
		# else:
		#	update(collider.name)
