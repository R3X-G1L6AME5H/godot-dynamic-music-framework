tool
extends DynamicMusicFramework
class_name DMFSong

"""
	Dynamic Music Framework Song Node
		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)

	A (child) data node used by the DMF Playlist Generator. Holds vital information
	about the song being played. As all child nodes position themselves on the timeline
	using bar numbers, it is essencial that bpm and time signature match those of
	the audio track. In addition, it specifies the first segment that gets played.
"""

## Self-explainatory variables
export (float) var bpm = 140
export (int) var timesig_numerator   = 4
export (int) var timesig_denominator = 4
## The first segment that gets played when the song starts
var default_segment = ""



## A variable holding the data of all the segments in editor
var hint = ""



####  B O I L E R P L A T E  #####
##################################
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



## Fetches the available Segments
func _get_hint():
	hint = ""
	for child in get_children():
		if child is DMFSegment:
			hint += child.name + ","
	hint = hint.rstrip(",")
	yield(get_tree().create_timer(1.0), "timeout")
	_get_hint()
