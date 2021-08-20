tool
extends DynamicMusicFramework
class_name DMFSong

export (float) var bpm = 140
export (int) var timesig_numerator   = 4
export (int) var timesig_denominator = 4
var default_segment = ""
var hint = ""

func _get( property : String ):
	match property:
		"default_segment" :
			return default_segment
		_ :
			return null

func _set( property : String, value ) -> bool:
	match property:
		"default_segment" :
			default_segment = str(value)
			return true
		_ :
			return false

func _get_property_list():
	var result = []
	result.push_back({
			"name": "default_segment",
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
	for child in get_children():
		if child is DMFSegment:
			hint += child.name + ","
	hint = hint.rstrip(",")
	yield(get_tree().create_timer(1.0), "timeout")
	_get_hint()
