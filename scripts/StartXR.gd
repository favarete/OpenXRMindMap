class_name StartXR
extends Node3D

# This script uses "A Better XR Start Script" in the Godot Docs as a starting template
# https://docs.godotengine.org/en/latest/tutorials/xr/a_better_xr_start_script.html

signal focus_lost
signal focus_gained
signal pose_recentered

@export var maximum_refresh_rate : int = 90

var xr_interface: OpenXRInterface
var xr_is_focussed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR instantiated successfully.")
		var vp : Viewport = get_viewport()

		# Enable XR on our viewport
		vp.use_xr = true

		# Make sure v-sync is off, v-sync is handled by OpenXR
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		var foveation_level: String = ProjectSettings.get_setting("xr/openxr/foveation_level")
		# Enable VRS
		if RenderingServer.get_rendering_device():
			vp.vrs_mode = Viewport.VRS_XR
		elif int(foveation_level) == 0:
			push_warning("OpenXR: Recommend setting Foveation level to High in Project Settings")

		# Connect the OpenXR events
		var status_code_a: int = xr_interface.session_begun.connect(_on_openxr_session_begun)
		if status_code_a != 0:
			print("session_begun error: ", status_code_a)
		var status_code_b: int = xr_interface.session_visible.connect(_on_openxr_visible_state)
		if status_code_b != 0:
			print("session_visible error: ", status_code_b)
		var status_code_c: int = xr_interface.session_focussed.connect(_on_openxr_focused_state)
		if status_code_c != 0:
			print("session_focussed error: ", status_code_c)
		var status_code_d: int = xr_interface.session_stopping.connect(_on_openxr_stopping)
		if status_code_d != 0:
			print("session_stopping error: ", status_code_d)
		var status_code_e: int = xr_interface.pose_recentered.connect(_on_openxr_pose_recentered)
		if status_code_e != 0:
			print("pose_recentered error: ", status_code_e)
	else:
		# We couldn't start OpenXR.
		print("OpenXR not instantiated!")
		get_tree().quit()


# Handle OpenXR session ready
func _on_openxr_session_begun() -> void:
	# Get the reported refresh rate
	var current_refresh_rate: float = xr_interface.get_display_refresh_rate()
	if current_refresh_rate > 0:
		print("OpenXR: Refresh rate reported as ", str(current_refresh_rate))
	else:
		print("OpenXR: No refresh rate given by XR runtime")

	# See if we have a better refresh rate available
	var new_rate: float = current_refresh_rate
	var available_rates : Array = xr_interface.get_available_display_refresh_rates()
	if available_rates.size() == 0:
		print("OpenXR: Target does not support refresh rate extension")
	elif available_rates.size() == 1:
		# Only one available, so use it
		new_rate = available_rates[0]
	else:
		for rate: float in available_rates:
			if rate > new_rate and rate <= maximum_refresh_rate:
				new_rate = rate

	# Did we find a better rate?
	if current_refresh_rate != new_rate:
		print("OpenXR: Setting refresh rate to ", str(new_rate))
		xr_interface.set_display_refresh_rate(new_rate)
		current_refresh_rate = new_rate

	# Now match our physics rate
	Engine.physics_ticks_per_second = int(current_refresh_rate)


# Handle OpenXR visible state
func _on_openxr_visible_state() -> void:
	# We always pass this state at startup,
	# but the second time we get this it means our player took off their headset
	if xr_is_focussed:
		print("OpenXR lost focus")

		xr_is_focussed = false

		# pause our game
		process_mode = Node.PROCESS_MODE_DISABLED
		focus_lost.emit()


# Handle OpenXR focused state
func _on_openxr_focused_state() -> void:
	print("OpenXR gained focus")
	xr_is_focussed = true

	# unpause our game
	process_mode = Node.PROCESS_MODE_INHERIT

	focus_gained.emit()

# Handle OpenXR stopping state
func _on_openxr_stopping() -> void:
	# Our session is being stopped.
	print("OpenXR is stopping")

	if "--xrsim-automated-tests" in OS.get_cmdline_user_args():
		# When we're running tests via the XR Simulator, it will end the OpenXR
		# session automatically, and in that case, we want to quit.
		get_tree().quit()


# Handle OpenXR pose recentered signal
func _on_openxr_pose_recentered() -> void:
	# User recentered view, we have to react to this by recentering the view.
	# This is game implementation dependent.
	pose_recentered.emit()
