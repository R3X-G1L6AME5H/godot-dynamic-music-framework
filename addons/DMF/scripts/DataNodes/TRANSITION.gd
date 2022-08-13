tool
extends DMFLibraryClasses
class_name DMFTransition

"""
	Dynamic Music Framework Transition Node
		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)

	A (child) data node used by the DMF Playlist Generator. Its purpuse is holding data
	which determine when, and if there should occur a transition between segments.
"""

const lib_node_type = 5  # Dirty and cheap way of determinig if a Node is a part of this plugin.

## Which property in the BLACKBOARD is being monitored for its current state
export (String) var property_current
## Which property in the BLACKBOARD is being read for the Max value possible value of the current state
## 		This is in purpuse of normalizing the range i.e.  current / max = normalized value [0, 1]
export (String) var property_max
## Within which normalized range is the transition triggered.
export (float, 0.0, 1.0) var trigger_min = 0.0
export (float, 0.0, 1.0) var trigger_max = 1.0

## The segment names
var from_segment : String
var to_segment   : String


## A variable holding the data of all the segments in editor
var hint = ""



####  B O I L E R P L A T E  #####
##################################
func _get( property : String ):
	match property:
		"from_segment" :
			return from_segment
		"to_segment" :
			return to_segment
		_ :
			return null

func _set( property : String, value ) -> bool:
	match property:
		"from_segment" :
			from_segment = str(value)
			return true
		"to_segment" :
			to_segment = str(value)
			return true
		_ :
			return false

func _get_property_list():
	var result = []
	result.push_back({
			"name": "from_segment",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": hint
	})
	result.push_back({
			"name": "to_segment",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": hint
	})
	return result

func _ready():
	property_list_changed_notify()
	_get_hint()



## Fetches the available Segments
func _get_hint():
	hint = "NULL,"
	for neighbourgh in get_parent().get_children():
		if neighbourgh != self and neighbourgh is DMFSegment:
			hint += neighbourgh.name + ","
	hint = hint.rstrip(",")
	yield(get_tree().create_timer(1.0), "timeout")
	_get_hint()
