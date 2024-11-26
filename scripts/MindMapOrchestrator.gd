extends Node3D

@onready var camera: XRCamera3D = get_parent().get_node("XRCamera3D")

var initial_position_is_not_set = true

const MESHES = {
	"common_sphere": preload("res://meshes/common_sphere.obj"),
	"common_cube": preload("res://meshes/common_cube.obj")
}

func _ready() -> void:
	load_graph("res://data/map.json")


func load_graph(json_file_path: String):
	var json_file = FileAccess.open(json_file_path, FileAccess.READ)
	if not json_file:
		print("Failed to open JSON file.")
		return
	
	var json_text = json_file.get_as_text()
	var json_result = JSON.parse_string(json_text)
	
	if json_result is Dictionary:
		build_graph(json_result)
	else:
		print("Failed to parse JSON. Ensure the file format is correct.")
		return


func build_graph(graph_data):
	# Create nodes
	for node_data in graph_data.nodes:
		create_node(node_data)
	
	# Create edges (connections)
	for edge_data in graph_data.edges:
		create_edge(edge_data)


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
	
func create_node(node_data):
	var node = MeshInstance3D.new()
	node.mesh = MESHES.get(node_data.type, null)
	if node.mesh:
		node.material_override = create_material(node_data.color)
		node.scale = Vector3.ONE * node_data.scales.node
		node.name = node_data.id
		
		node.position = Vector3( 
			node_data.position.x,
			node_data.position.y,
			node_data.position.z
			)
			
		add_child(node)
		
		# Adicionar um Area3D ao nó
		var area = Area3D.new()
		area.monitorable = true
		area.monitoring = false
		area.set_collision_layer(Globals.NODE_LAYER)
		area.set_collision_mask(Globals.CONTROLLER_LAYER)
		node.add_child(area)
		
		var collision_shape = get_basic_collision_shapes(node_data.type, node)
		area.add_child(collision_shape)
		
		# Add label above the node
		if node_data.label != "":
			var label = create_label(node_data)
			node.add_child(label)
	
	return node


func create_label(node_data):
	var label = Label3D.new()
	label.text = node_data.label
	label.scale = Vector3.ONE * node_data.scales.label
	label.position = Vector3(0, 1.5, 0)
	label.add_to_group("billboard_labels")
	return label


func create_edge(edge_data):
	var source_node_id = edge_data.source
	var target_node_id = edge_data.target
	
	var start_node = get_node(source_node_id)
	var end_node = get_node(target_node_id)

	if start_node and end_node:
		var link = create_thick_line(start_node.position, end_node.position)
		add_child(link)


func create_thick_line(start_pos: Vector3, end_pos: Vector3, radius: float = 0.002, segments: int = 32) -> MeshInstance3D:
	# Create the MeshInstance3D and ImmediateMesh
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = create_material("#F5F5F5")
	mesh_instance.mesh = immediate_mesh
	#mesh_instance.material_override = material

	# Calculate the direction vector and length
	var direction = end_pos - start_pos
	var length = direction.length()
	var normalized_dir = -direction.normalized()

	# Calculate orthogonal vectors for creating the circular cross-section
	var up = Vector3.UP if abs(Vector3.UP.dot(normalized_dir)) < 0.99 else Vector3.RIGHT
	var side_vector = normalized_dir.cross(up).normalized()
	var up_vector = side_vector.cross(normalized_dir).normalized()

	# Create the circular vertices at the start and end
	var start_circle = []
	var end_circle = []
	for i in range(segments):
		var angle = i * TAU / segments
		var offset = side_vector * cos(angle) * radius + up_vector * sin(angle) * radius
		start_circle.append(start_pos + offset)
		end_circle.append(end_pos + offset)

	# Begin defining the cylinder surface
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)

	for i in range(segments):
		# Connect current segment to the next segment
		var next = (i + 1) % segments
		
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

	return mesh_instance


func set_initial_position():
	var camera_position = camera.position
	for child in get_children():
		child.position += camera_position
	initial_position_is_not_set = false


func _process(delta):
	if camera:
		if initial_position_is_not_set:
			set_initial_position()
			
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
			label.transform = Transform3D(Basis().looking_at(direction, up), label.position)


func create_material(hex_color: String):
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.html(hex_color)
	material.metallic = 0.2  # Adds a slight metallic sheen
	material.roughness = 0.4  # Controls how shiny or matte the surface looks
	material.metallic_specular = 0.4  # Maximum specular highlights for reflections
	return material
