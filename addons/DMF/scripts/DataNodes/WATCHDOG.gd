tool
extends DMFLibraryClasses
class_name DMFWatchdog

"""
	Dynamic Music Framework Watchdog Node
		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)

	A (child) data node used by the DMF Song. Watchdogs look at the
	changes in properties, and applies the change to the track property e.g. control
	volume according to the current HP.
"""

const lib_node_type = 3 # Dirty and cheap way of determinig if a Node is a part of this plugin.


var target_track : String

## Which property in the BLACKBOARD is being monitored for its current state
export (String) var property_current
## Which property in the BLACKBOARD is being read for the Max value possible value of the current state
## 		This is in purpuse of normalizing the range i.e.  current / max = normalized value [0, 1]
export (String) var property_max
## To which property in the DMF TRACK is the change applied
export (String) var change_property
## The graph of the relation between property state, and the value applied to the DMF Track property
export (Curve)  var change_graph


## A variable holding the data of all the segments in editor
var hint = ""


####  B O I L E R P L A T E  #####
##################################
func _get( property : String ):
	match property:
		"target_track" :
			return target_track
		_ :
			return null

func _set( property : String, value ) -> bool:
	match property:
		"target_track" :
			target_track = str(value)
			return true
		_ :
			return false

func _get_property_list():
	var result = []
	result.push_back({
			"name": "target_track",
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
	hint = ""
	for neighbourg in get_parent().get_children():
		if neighbourg != self and neighbourg is DMFTrack:
			hint += neighbourg.name + ","
	hint = hint.rstrip(",")
	yield(get_tree().create_timer(1.0), "timeout")
	_get_hint()
