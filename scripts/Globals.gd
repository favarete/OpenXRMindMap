extends Node

# Timw without action before autosave
const SAVE_DELAY := 1

# Collisoon Layers
const CONTROLLER_LAYER := 1
const NODE_LAYER := 2
const LABEL_LAYER := 3
const CONNECTION_LAYER := 4
const MENU_LAYER := 5
const KEYBOARD_LAYER := 6

# Default Values
const DEFAULT_EDGE_RADIUS := 0.002
const DEFAULT_EDGE_SEGMENTS := 32
const DEFAULT_NODE_TYPE := "common_sphere"
const DEFAULT_NODE_COLOR := "#FFFFFF"
const DEFAULT_NODE_SCALE := 0.05
const DEFAULT_LABEL_TEXT := ""
const DEFAULT_LABEL_SCALE := 1

# GLobal Placeholders
var DEFAULT_EDGE_MATERIAL: StandardMaterial3D = null

#-------------------------------------------------------------------------------

var LoadedMindMap = null

func set_active_mindmap(mindmap_data):
	LoadedMindMap = mindmap_data
	
func get_active_mindmap() -> Dictionary:
	return LoadedMindMap
	

func connection_is_new(uuid1: String, uuid2: String) -> bool:
	var actual_mindmap = get_active_mindmap()
	
	for key in actual_mindmap.edges.keys():
		var entry = actual_mindmap.edges[key]
		if (entry["source"] == uuid1 and entry["target"] == uuid2) or \
		   (entry["source"] == uuid2 and entry["target"] == uuid1):
			return false
	return true

#-------------------------------------------------------------------------------

var controllers = {
	"LeftController": {
		"active_node": null,
		"offset": Vector3.ZERO,
		"active_actions": [],
		"node_connection": {
			"is_adding_edge": false,
			"start": null,
			"end": null
		}
	},
	"RightController": {
		"active_node": null,
		"offset": Vector3.ZERO,
		"active_actions": [],
		"node_connection": {
			"is_adding_edge": false,
			"start": null,
			"end": null
		}
	}
}