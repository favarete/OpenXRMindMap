extends XROrigin3D

@onready var camera: XRCamera3D = $XRCamera3D
@onready var mind_map_container: Node3D = $MindMapContainer

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
	#for edge_data in graph_data["edges"]:
		#create_edge(edge_data, nodes_map)
		
func create_node(node_data):
	var node = MeshInstance3D.new()
	node.mesh = MESHES.get(node_data["type"], null)
	if node.mesh:
		#node.material_override = create_material(node_data["color"])
		node.scale = Vector3.ONE * node_data.scales.node
		node.name = node_data.id
		
		node.position = Vector3( 
			node_data.position.x,
			node_data.position.y,
			node_data.position.z
			)
		mind_map_container.add_child(node)

		# Add label above the node
		#if node_data["label"] != "":
			#var label = create_label(node_data)
			#node.add_child(label)
	
	return node


#func create_label(node_data):
	#var label = Label3D.new()
	#label.text = node_data["label"]
	#label.scale = Vector3.ONE * node_data["scales"]["label"]
	#label.position = Vector3(0, 2, 0)
	#label.add_to_group("billboard_labels")
	#return label
	
func set_initial_position():
	var camera_position = camera.position
	for child in mind_map_container.get_children():
		child.position += camera_position
	initial_position_is_not_set = false

func _process(delta):
	if camera:
		if initial_position_is_not_set:
			set_initial_position()
		#for label in get_tree().get_nodes_in_group("billboard_labels"):
			#var direction = camera.global_position - label.global_position
#
			## Validate the direction vector
			#if direction.is_zero_approx():
				#print("Direction vector is zero. Camera:", camera.global_position, "Label:", label.global_position)
				#direction = Vector3(0, 0, 1)  # Fallback direction
#
			## Normalize the direction vector
			#direction = direction.normalized()
			#var up = Vector3.UP
#
			## Avoid parallel up and direction vectors
			#if abs(direction.dot(up)) > 0.999:
				#up = Vector3(0, 0, 1)
#
			## Apply the transform safely
			#label.transform = Transform3D(Basis().looking_at(direction, up), label.global_position)
#


#func create_edge(edge_data, nodes_map):
	#var start_node = nodes_map.get(edge_data["source"], null)
	#var end_node = nodes_map.get(edge_data["target"], null)
#
	#if start_node and end_node:
		#var line = create_line(start_node.global_position, end_node.global_position)
		#add_child(line)

#func create_line(start_pos: Vector3, end_pos: Vector3):
	#var line = ImmediateMesh.new()
	#var surface_tool = SurfaceTool.new()
	#surface_tool.begin(Mesh.PRIMITIVE_LINES)
	#surface_tool.add_vertex(start_pos)
	#surface_tool.add_vertex(end_pos)
	#surface_tool.commit(line)
	#var line_instance = MeshInstance3D.new()
	#line_instance.mesh = line
	#return line_instance

#func create_material(hex_color: String):
	#var material = StandardMaterial3D.new()
	#material.albedo_color = Color.html(hex_color)
	#return material
