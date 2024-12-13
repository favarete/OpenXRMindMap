extends Node

# Time without action before autosave
const SAVE_FILE: String = "user://oxrmindmap_save.json"
const SAVE_DELAY: int = 1
const TWEEN_CONSTRUCTION_DELAY: float = 0.1

# Collisoon Layers
const CONTROLLER_LAYER: int = 1
const NODE_LAYER: int = 2
const LABEL_LAYER: int = 3
const CONNECTION_LAYER: int = 4
const MENU_LAYER: int = 5
const KEYBOARD_LAYER: int = 6

# Default Values
const DEFAULT_MAP_TITLE: String = "My First Mind Map"
const DEFAULT_EDGE_RADIUS: float = 0.001
const DEFAULT_EDGE_SEGMENTS: int = 32
const DEFAULT_NODE_TYPE: String = "common_sphere"
const DEFAULT_NODE_COLOR: String = "#FFFFFF"
const DEFAULT_NODE_SCALE: float = 0.05
const DEFAULT_LABEL_TEXT: String = ""
const DEFAULT_LABEL_SCALE: int = 1

# GLobal Placeholders
var DEFAULT_EDGE_MATERIAL: StandardMaterial3D = null

#-------------------------------------------------------------------------------

var LoadedMindMap: Dictionary

func set_active_mindmap(mindmap_data: Dictionary) -> void:
	LoadedMindMap = mindmap_data
	
func get_active_mindmap() -> Dictionary:
	return LoadedMindMap
	

func connection_is_new(uuid1: String, uuid2: String) -> bool:
	var actual_mindmap: Dictionary = get_active_mindmap()
	var actual_mindmap_edges: Dictionary = actual_mindmap.edges
	
	for key: String in actual_mindmap_edges.keys():
		var entry: Dictionary = actual_mindmap.edges[key]
		if (entry["source"] == uuid1 and entry["target"] == uuid2) or \
		   (entry["source"] == uuid2 and entry["target"] == uuid1):
			return false
	return true

#-------------------------------------------------------------------------------

var CONTROLLER_PROPS: Dictionary = {
		"active_node": null,
		"active_node_selected": false,
		"offset": Vector3.ZERO,
		"active_actions": [],
		"node_connection": {
			"is_adding_edge": false,
			"start": null,
			"end": null
		},
		"group_collision": {
			"is_group_colliding": false,
			"collisions": []
		}
	}
	
var controllers: Dictionary = {
	"LeftController": CONTROLLER_PROPS.duplicate(true),
	"RightController": CONTROLLER_PROPS.duplicate(true)
}
