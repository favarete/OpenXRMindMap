extends Node3D

@onready var camera: XRCamera3D = get_parent().get_node("XRCamera3D")

var initial_position_is_not_set = true

var MESHES = {
	"common_sphere": load("res://DefaultMeshes/common_sphere.obj"),
	"common_cube": load("res://DefaultMeshes/common_cube.obj")
}

func _ready() -> void:
	load_graph()
	Utils.connect("update_edge", Callable(self, "update_thick_line"))
	Utils.connect("add_node", Callable(self, "create_node"))
	Utils.connect("add_edge", Callable(self, "create_edge"))

func create_save_file():
	var file = FileAccess.open(Globals.SAVE_FILE, FileAccess.WRITE)
	var content = { "title": "My First Mind Map", "nodes": {}, "edges": {}}

	file.store_string(JSON.stringify(content))
	
func load_from_file():
	var file = FileAccess.open(Globals.SAVE_FILE, FileAccess.READ)
	var content = file.get_as_text()
	return JSON.parse_string(content)

func load_graph():
	if not FileAccess.file_exists(Globals.SAVE_FILE):
		create_save_file()
	
	var json_file = load_from_file()
	
	if json_file is Dictionary:
		Globals.set_active_mindmap(json_file) 
		build_graph(json_file)
	else:
		print("Failed to parse JSON. Ensure the file format is correct.")
		return


func build_graph(graph_data):
	if graph_data:
		for key in graph_data.nodes.keys():
			var value = graph_data.nodes[key]
			create_node(key, value)
		
		for key in graph_data.edges.keys():
			var value = graph_data.edges[key]
			create_edge(key, value)


func get_basic_collision_shapes(mesh_type, node_instance):
	var collision_shape = CollisionShape3D.new()
		
	var aabb = node_instance.get_aabb()
	var aabb_size = aabb.size
			
	match mesh_type:
		"common_sphere":
			var sphere_shape = SphereShape3D.new()
			sphere_shape.radius = max(aabb_size.x, aabb_size.y, aabb_size.z) / 2
			
			collision_shape.shape = sphere_shape
			return collision_shape
		"common_cube":
			var cube_shape = BoxShape3D.new()
			cube_shape.size = aabb_size
			
			collision_shape.shape = cube_shape
			return collision_shape
		_:
			# TODO: Add any way to identify wich basic shape is more adequate
			# Using Box as a fallback for now
			var cube_shape = BoxShape3D.new()
			cube_shape.size = aabb_size
			
			collision_shape.shape = cube_shape
			return collision_shape 
	
func create_node(key, value):
	var node = MeshInstance3D.new()
	node.mesh = MESHES.get(value.type, null)
	if node.mesh:
		node.material_override = create_material(value.color)
		node.scale = Vector3.ONE * value.scales.node
		node.name = key
		node.set_meta("edges", value.edges)
		
		node.position = Vector3( 
			value.position.x,
			value.position.y,
			value.position.z
			)
			
		node.set_script(load("res://Scripts/MapNodeInstance.gd"))
		add_child(node)
		
		# Adicionar um Area3D ao nó
		var area = Area3D.new()
		area.monitorable = true
		area.monitoring = false
		area.set_collision_layer(Globals.NODE_LAYER)
		area.set_collision_mask(Globals.CONTROLLER_LAYER)
		node.add_child(area)
		
		var collision_shape = get_basic_collision_shapes(value.type, node)
		area.add_child(collision_shape)
		
		var tween = create_tween().bind_node(node)
		var scale_in_vector = node.scale * (Vector3.ONE * 1.1)
		tween.tween_property(node, "scale", scale_in_vector, 
			Globals.TWEEN_CONSTRUCTION_DELAY).set_ease(Tween.EASE_IN)
		tween.tween_property(node, "scale", node.scale, 
			Globals.TWEEN_CONSTRUCTION_DELAY).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func (): tween.kill())
		
		# Add label above the node
		if value.label != "":
			var label = create_label(value)
			node.add_child(label)
	
	return node


func create_label(node_data):
	var label = Label3D.new()
	label.text = node_data.label
	label.scale = Vector3.ONE * node_data.scales.label
	label.position = Vector3(0, 1.5, 0)
	label.add_to_group("billboard_labels")
	return label


func create_edge(key, value):
	var source_node_id = NodePath(value.source)
	var target_node_id = NodePath(value.target)
	
	var start_node = get_node(source_node_id)
	var end_node = get_node(target_node_id)

	if start_node and end_node:
		var edge = create_thick_line(start_node.position, end_node.position)
		edge.name = key
		add_child(edge)

func create_immediate_mesh_line(
	immediate_mesh: ImmediateMesh,
	material: StandardMaterial3D,
	start_pos: Vector3, 
	end_pos: Vector3
	):
	# Calculate the direction vector and length
	var direction = end_pos - start_pos
	#var length = direction.length()
	var normalized_dir = -direction.normalized()

	# Calculate orthogonal vectors for creating the circular cross-section
	var up = Vector3.UP if abs(Vector3.UP.dot(normalized_dir)) < 0.99 else Vector3.RIGHT
	var side_vector = normalized_dir.cross(up).normalized()
	var up_vector = side_vector.cross(normalized_dir).normalized()

	# Create the circular vertices at the start and end
	var start_circle = []
	var end_circle = []
	for i in range(Globals.DEFAULT_EDGE_SEGMENTS):
		var angle = i * TAU / Globals.DEFAULT_EDGE_SEGMENTS
		var offset = side_vector * cos(angle) * Globals.DEFAULT_EDGE_RADIUS + up_vector * sin(angle) * Globals.DEFAULT_EDGE_RADIUS
		start_circle.append(start_pos + offset)
		end_circle.append(end_pos + offset)

	# Begin defining the cylinder surface
	if material:
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	else:
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(Globals.DEFAULT_EDGE_SEGMENTS):
		# Connect current segment to the next segment
		var next = (i + 1) % Globals.DEFAULT_EDGE_SEGMENTS
		
		# Calculate the normal for the current segment
		var normal = (start_circle[i] - start_pos).normalized()

		# Add two triangles for the quad between start_circle and end_circle
		# First triangle
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_add_vertex(start_circle[i])
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_add_vertex(end_circle[i])
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_add_vertex(end_circle[next])

		# Second triangle
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_add_vertex(start_circle[i])
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_add_vertex(end_circle[next])
		immediate_mesh.surface_set_normal(normal)
		immediate_mesh.surface_add_vertex(start_circle[next])

	# End the surface
	immediate_mesh.surface_end()

func create_thick_line(start_pos: Vector3, end_pos: Vector3) -> MeshInstance3D:
	# Create the MeshInstance3D and ImmediateMesh
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	Globals.DEFAULT_EDGE_MATERIAL = create_material("#F5F5F5")
	mesh_instance.mesh = immediate_mesh
	mesh_instance.material_override = Globals.DEFAULT_EDGE_MATERIAL
	create_immediate_mesh_line(immediate_mesh, Globals.DEFAULT_EDGE_MATERIAL, start_pos, end_pos)
	return mesh_instance


func update_thick_line(line: MeshInstance3D, start_pos: Vector3, end_pos: Vector3):
	var immediate_mesh = line.mesh as ImmediateMesh
	if immediate_mesh == null:
		return
	immediate_mesh.clear_surfaces()
	create_immediate_mesh_line(immediate_mesh, Globals.DEFAULT_EDGE_MATERIAL, start_pos, end_pos)


#func set_initial_position():
	#var camera_position = camera.position
	#for child in get_children():
		#child.position += camera_position
	#initial_position_is_not_set = false

func _process(_delta):
	if camera:
		#if initial_position_is_not_set:
			#set_initial_position()
			
		# Make labels look at camera
		for label in get_tree().get_nodes_in_group("billboard_labels"):
			var direction = camera.global_position - label.global_position
#
			## Normalize the direction vector
			direction = -direction.normalized()
			var up = Vector3.UP
#
			## Avoid parallel up and direction vectors
			if abs(direction.dot(up)) > 0.999:
				up = Vector3(0, 0, 1)
#
			## Apply the transform safely
			label.transform = Transform3D(Basis.looking_at(direction, up), label.position)


func create_material(hex_color: String):
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.html(hex_color)
	material.metallic = 0.2  # Adds a slight metallic sheen
	material.roughness = 0.4  # Controls how shiny or matte the surface looks
	material.metallic_specular = 0.4  # Maximum specular highlights for reflections
	return material
