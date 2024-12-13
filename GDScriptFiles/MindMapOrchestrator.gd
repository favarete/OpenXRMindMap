extends Node3D

@onready var camera: XRCamera3D = get_parent().get_node("XRCamera3D")

var initial_position_is_not_set: bool = true

var MESHES: Dictionary = {
	"common_sphere": load("res://DefaultMeshes/common_sphere.obj"),
	"common_cube": load("res://DefaultMeshes/common_cube.obj")
}

func _ready() -> void:
	load_graph()
	var status_code_a: int = Utils.connect("update_edge", Callable(self, "update_thick_line"))
	if status_code_a != 0:
		printerr("update_thick_line signal error: ", status_code_a)
	var status_code_b: int = Utils.connect("add_node", Callable(self, "create_node"))
	if status_code_b != 0:
		printerr("create_node signal error: ", status_code_b)
	var status_code_c: int = Utils.connect("add_edge", Callable(self, "create_edge"))
	if status_code_c != 0:
		printerr("create_edge signal error: ", status_code_c)

func create_save_file() -> void:
	var file: FileAccess = FileAccess.open(Globals.SAVE_FILE, FileAccess.WRITE)
	var content: Dictionary = { "title": Globals.DEFAULT_MAP_TITLE, "nodes": {}, "edges": {}}

	file.store_string(JSON.stringify(content))
	
func load_from_file() -> Dictionary:
	var file: FileAccess = FileAccess.open(Globals.SAVE_FILE, FileAccess.READ)
	var content: String = file.get_as_text()
	return JSON.parse_string(content)

func load_graph() -> void:
	if not FileAccess.file_exists(Globals.SAVE_FILE):
		create_save_file()
	
	var json_file: Dictionary = load_from_file()
	
	if json_file is Dictionary:
		Globals.set_active_mindmap(json_file) 
		build_graph(json_file)
	else:
		printerr("Failed to parse JSON. Ensure the file format is correct.")

func build_graph(graph_data: Dictionary) -> void:
	if graph_data:
		var graph_nodes: Dictionary = graph_data.nodes
		for key: String in graph_nodes.keys():
			var value: Dictionary = graph_nodes[key]
			create_node(key, value)
		
		var graph_edges: Dictionary = graph_data.edges
		for key: String in graph_edges.keys():
			var value: Dictionary = graph_edges[key]
			create_edge(key, value)


func get_basic_collision_shapes(mesh_type: String, node_instance: MeshInstance3D) -> CollisionShape3D:
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
		
	var aabb: AABB = node_instance.get_aabb()
	var aabb_size: Vector3 = aabb.size
			
	match mesh_type:
		"common_sphere":
			var sphere_shape: SphereShape3D = SphereShape3D.new()
			sphere_shape.radius = max(aabb_size.x, aabb_size.y, aabb_size.z) / 2
			
			collision_shape.shape = sphere_shape
			return collision_shape
		"common_cube":
			var cube_shape: BoxShape3D = BoxShape3D.new()
			cube_shape.size = aabb_size
			
			collision_shape.shape = cube_shape
			return collision_shape
		_:
			# TODO: Add any way to identify wich basic shape is more adequate
			# Using Box as a fallback for now
			var cube_shape: BoxShape3D = BoxShape3D.new()
			cube_shape.size = aabb_size
			
			collision_shape.shape = cube_shape
			return collision_shape 
	
func create_node(key: String, value: Dictionary) -> void:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.mesh = MESHES.get(value.type, null)
	if node.mesh:
		var color_hex: String = value.color
		node.material_override = create_material(color_hex)
		node.scale = Vector3.ONE * value.scales.node
		node.name = key
		node.set_meta("edges", value.edges)
		
		var node_position_x: float = value.position.x
		var node_position_y: float = value.position.y
		var node_position_z: float = value.position.z
		
		node.position = Vector3( 
			node_position_x,
			node_position_y,
			node_position_z
			)
			
		node.set_script(load("res://GDScriptFiles/MapNodeInstance.gd"))
		add_child(node)
		
		# Adicionar um Area3D ao nó
		var area: Area3D = Area3D.new()
		area.monitorable = true
		area.monitoring = false
		area.set_collision_layer(Globals.NODE_LAYER)
		area.set_collision_mask(Globals.CONTROLLER_LAYER)
		node.add_child(area)
		
		var collision_shape_type: String = value.type
		var collision_shape: CollisionShape3D = get_basic_collision_shapes(collision_shape_type, node)
		area.add_child(collision_shape)
		
		var tween: Tween = create_tween().bind_node(node)
		var scale_in_vector: Vector3 = node.scale * (Vector3.ONE * 1.1)
		var _tween_in: PropertyTweener = tween.tween_property(node, "scale", scale_in_vector, 
			Globals.TWEEN_CONSTRUCTION_DELAY).set_ease(Tween.EASE_IN)
		var _tween_out: PropertyTweener = tween.tween_property(node, "scale", node.scale, 
			Globals.TWEEN_CONSTRUCTION_DELAY).set_ease(Tween.EASE_OUT)
		var _cb: CallbackTweener = tween.tween_callback(func () -> void: tween.kill())
		
		# Add label above the node
		var local_label : String = value.label
		if local_label != "":
			var label: Label3D = create_label(value)
			node.add_child(label)


func create_label(node_data: Dictionary) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = node_data.label
	label.scale = Vector3.ONE * node_data.scales.label
	label.position = Vector3(0, 1.5, 0)
	label.add_to_group("billboard_labels")
	return label


func create_edge(key: String, value: Dictionary) -> void:
	var source_edge: String = value.source
	var target_edge: String = value.target
	var source_node_id: NodePath = NodePath(source_edge)
	var target_node_id: NodePath = NodePath(target_edge)
	
	var start_node: MeshInstance3D = get_node(source_node_id)
	var end_node: MeshInstance3D = get_node(target_node_id)

	if start_node and end_node:
		var edge: MeshInstance3D = create_thick_line(start_node.position, end_node.position)
		edge.name = key
		add_child(edge)

func create_immediate_mesh_line(
	immediate_mesh: ImmediateMesh,
	material: StandardMaterial3D,
	start_pos: Vector3, 
	end_pos: Vector3
	) -> void:
	# Calculate the direction vector and length
	var direction: Vector3 = end_pos - start_pos
	var normalized_dir: Vector3 = -direction.normalized()

	# Calculate orthogonal vectors for creating the circular cross-section
	var up: Vector3 = Vector3.UP if abs(Vector3.UP.dot(normalized_dir)) < 0.99 else Vector3.RIGHT
	var side_vector: Vector3 = normalized_dir.cross(up).normalized()
	var up_vector: Vector3 = side_vector.cross(normalized_dir).normalized()

	# Create the circular vertices at the start and end
	var start_circle: Array = []
	var end_circle: Array = []
	for i: int in range(Globals.DEFAULT_EDGE_SEGMENTS):
		var angle: float = i * TAU / Globals.DEFAULT_EDGE_SEGMENTS
		var offset: Vector3 = side_vector * cos(angle) * Globals.DEFAULT_EDGE_RADIUS + up_vector * sin(angle) * Globals.DEFAULT_EDGE_RADIUS
		start_circle.append(start_pos + offset)
		end_circle.append(end_pos + offset)

	# Begin defining the cylinder surface
	if material:
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	else:
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for i: int in range(Globals.DEFAULT_EDGE_SEGMENTS):
		# Connect current segment to the next segment
		var next: int = (i + 1) % Globals.DEFAULT_EDGE_SEGMENTS
		
		# Calculate the normal for the current segment
		var start_circle_instance_i: Vector3 = start_circle[i]
		var current_segment: Vector3 = start_circle_instance_i - start_pos
		var normal: Vector3 = current_segment.normalized()

		# Add two triangles for the quad between start_circle and end_circle
		# First triangle
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_add_vertex(start_circle_instance_i)
		immediate_mesh.surface_set_normal(normal)
		
		var end_circle_instance_i: Vector3 = end_circle[i]
		immediate_mesh.surface_add_vertex(end_circle_instance_i)
		immediate_mesh.surface_set_normal(normal)
		
		var end_circle_instance_next: Vector3 = end_circle[next]
		immediate_mesh.surface_add_vertex(end_circle_instance_next)

		# Second triangle
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_add_vertex(start_circle_instance_i)
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_add_vertex(end_circle_instance_next)
		immediate_mesh.surface_set_normal(normal)
		
		var start_circle_instance_next: Vector3 = start_circle[next]
		immediate_mesh.surface_add_vertex(start_circle_instance_next)

	# End the surface
	immediate_mesh.surface_end()

func create_thick_line(start_pos: Vector3, end_pos: Vector3) -> MeshInstance3D:
	# Create the MeshInstance3D and ImmediateMesh
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var immediate_mesh: ImmediateMesh = ImmediateMesh.new()
	Globals.DEFAULT_EDGE_MATERIAL = create_material("#F5F5F5")
	mesh_instance.mesh = immediate_mesh
	mesh_instance.material_override = Globals.DEFAULT_EDGE_MATERIAL
	create_immediate_mesh_line(immediate_mesh, Globals.DEFAULT_EDGE_MATERIAL, start_pos, end_pos)
	return mesh_instance


func update_thick_line(line: MeshInstance3D, start_pos: Vector3, end_pos: Vector3) -> void:
	var immediate_mesh: ImmediateMesh = line.mesh as ImmediateMesh
	if immediate_mesh == null:
		return
	immediate_mesh.clear_surfaces()
	create_immediate_mesh_line(immediate_mesh, Globals.DEFAULT_EDGE_MATERIAL, start_pos, end_pos)


#func set_initial_position():
	#var camera_position = camera.position
	#for child in get_children():
		#child.position += camera_position
	#initial_position_is_not_set = false

func _process(_delta: float) -> void:
	if camera:
		#if initial_position_is_not_set:
			#set_initial_position()
			
		# Make labels look at camera
		for label: Label3D in get_tree().get_nodes_in_group("billboard_labels"):
			var direction: Vector3 = camera.global_position - label.global_position
#
			## Normalize the direction vector
			direction = -direction.normalized()
			var up: Vector3 = Vector3.UP
#
			## Avoid parallel up and direction vectors
			if abs(direction.dot(up)) > 0.999:
				up = Vector3(0, 0, 1)
#
			## Apply the transform safely
			label.transform = Transform3D(Basis.looking_at(direction, up), label.position)


func create_material(hex_color: String) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color.html(hex_color)
	material.metallic = 0.2  # Adds a slight metallic sheen
	material.roughness = 0.4  # Controls how shiny or matte the surface looks
	material.metallic_specular = 0.4  # Maximum specular highlights for reflections
	return material
