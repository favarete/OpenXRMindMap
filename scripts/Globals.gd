extends Node

const CONTROLLER_LAYER = 1
const NODE_LAYER = 2
const LABEL_LAYER = 3
const CONNECTION_LAYER = 4
const MENU_LAYER = 5
const KEYBOARD_LAYER = 6

const EDGE_RADIUS: float = 0.002
const EDGE_SEGMENTS: int = 32
var EDGE_MATERIAL: StandardMaterial3D = null

#-------------------------------------------------------------------------------

var LoadedMindMap = null

func set_active_mindmap(mindmap_data):
	LoadedMindMap = mindmap_data
	
func get_active_mindmap():
	return LoadedMindMap

#-------------------------------------------------------------------------------

var controllers = {
	"LeftController": {
		"is_interacting": false,
		"active_node": null,
		"offset": Vector3.ZERO,
		"active_actions": []
	},
	"RightController": {
		"is_interacting": false,
		"active_node": null,
		"offset": Vector3.ZERO,
		"active_actions": []
	}
}
