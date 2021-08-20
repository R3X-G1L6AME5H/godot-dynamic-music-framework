tool
extends DMFLibraryClasses
class_name DMFTransition

const lib_node_type = 5

export (String) var property_current
export (String) var property_max
export (float, 0.0, 1.0) var trigger_min = 0.0
export (float, 0.0, 1.0) var trigger_max = 1.0

var from_segment : String
var to_segment   : String
var hint = ""

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

func _get_hint():
	hint = "NULL,"
	for neibourgh in get_parent().get_children():
		if neibourgh != self and neibourgh is DMFSegment:
			hint += neibourgh.name + ","
	hint = hint.rstrip(",")
	yield(get_tree().create_timer(1.0), "timeout")
	_get_hint()
