extends Node

const CONTROLLER_LAYER = 1
const NODE_LAYER = 2
const LABEL_LAYER = 3
const CONNECTION_LAYER = 4
const MENU_LAYER = 5
const KEYBOARD_LAYER = 6

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
