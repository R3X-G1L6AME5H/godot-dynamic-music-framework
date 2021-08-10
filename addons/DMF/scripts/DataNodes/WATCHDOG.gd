tool
extends DMFLibraryClasses
class_name DMFWatchdog

const lib_node_type = 3

var target_track : String
export (String) var property_current
export (String) var property_max
export (String) var change_property
export (Curve)  var change_graph

var hint = ""


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

func _get_hint():
	hint = ""
	for neibourgh in get_parent().get_children():
		if neibourgh != self and neibourgh is DMFTrack:
			hint += neibourgh.name + ","
	hint = hint.rstrip(",")
	yield(get_tree().create_timer(1.0), "timeout")
	_get_hint()
