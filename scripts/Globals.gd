extends Node

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
