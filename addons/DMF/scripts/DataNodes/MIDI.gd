tool
extends DMFLibraryClasses
class_name DMFMidiPlayer

"""
	Dynamic Music Framework MIDI Node
		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)

	A (child) data node used by the DMF Playlist Generator. This is where the music may
	influence the game world. The purpuse of this node is to refference a midi file which
	acts as a orchestrator of behaviour i.e. a midi key press can trigger an event in game.
"""


const lib_node_type = 4 # Dirty and cheap way of determinig if a Node is a part of this plugin.


## Path to the MIDI track
export (String, FILE, "*.mid") var midi_file
## The bar at which the MIDI track is ment to start playing
export (int) var starting_bar
## The bar at which the MIDI track is ment to stop playing
export (int) var ending_bar
## Whether a the midi is played when a property is a single value, or within a range of values
export (bool) var single_value_trigger = true setget _single_val_bool_toggeled


#### SINGLE VALUE TRIGGER
## What values makes the MIDI track play
var trigger_value : int = 1
## Where does the value come from in BLACKBOARD
var trigger_property : String

### MULTIPLE VALUE TRIGGER
## Within what range of values will the MIDI track play
var trigger_min : float = 0.0 setget _trigger_min_set
var trigger_max : float = 1.0 setget _trigger_max_set

## Which property in the BLACKBOARD is being monitored for its current state
var property_current : String = ""
## Which property in the BLACKBOARD is being read for the Max value possible value of the current state
## 		This is in purpuse of normalizing the range i.e.  current / max = normalized value [0, 1]
var property_max : String = ""

#### PITCH CORRECTION ON
## Whether the MIDI track is ment to pitch shift an audio Bus
var pitch_correction : bool = false setget _pitch_correction_toggled
var pitch_bus : String = ""
## What is the effect ID of the PitchShift within the Bus
var pitch_effect_id : int = 0


####  B O I L E R P L A T E  #####
##################################

func _pitch_correction_toggled(val):
	pitch_correction = bool(val)
	property_list_changed_notify()

func _single_val_bool_toggeled(val):
	single_value_trigger = bool(val)
	property_list_changed_notify()

func _trigger_min_set(val : float ):
	trigger_min = val
	property_list_changed_notify()

func _trigger_max_set(val : float ):
	trigger_max = val
	property_list_changed_notify()

func _get( property : String ):
	if property == "pitch_correction":
		return pitch_correction
	
	elif pitch_correction and property == "pitch_bus":
		return pitch_bus
	
	elif pitch_correction and property == "pitch_effect_id":
		return pitch_effect_id
	
	if single_value_trigger:
		match property:
			"trigger_value" :
				return trigger_value
			"trigger_property" :
				return trigger_property
			_ :
				return null
	else:
		match property:
			"trigger_min" :
				return trigger_min
			"trigger_max" :
				return trigger_max
			"property_current" :
				return property_current
			"property_max" :
				return property_max
			_ :
				return null


func _set( property : String, value ) -> bool:
	if property == "pitch_correction":
		self.set("pitch_correction", value)
		return true
	
	elif pitch_correction and property == "pitch_bus":
		pitch_bus = str(value)
		return true
	
	elif pitch_correction and property == "pitch_effect_id":
		pitch_effect_id = int(value)
		return true
	
	if single_value_trigger:
		match property:
			"trigger_value" :
				trigger_value = int(value)
				return true
			"trigger_property" :
				trigger_property = str(value)
				return true
			_ :
				return false
	else:
		match property:
			"trigger_min" :
				self.set("trigger_min", float(value)) 
				return true
			"trigger_max" :
				self.set("trigger_max", float(value)) 
				return true
			"property_current" :
				property_current = str(value)
				return true
			"property_max" :
				property_max = str(value)
				return true
			_ :
				return false


func _get_property_list():
	var result = []
	if single_value_trigger:
		result.push_back({
				"name": "trigger_value",
				"type": TYPE_INT,
				"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
		})
		result.push_back({
				"name": "trigger_property",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
		})
	else:
		result.push_back({
				"name": "trigger_min",
				"type": TYPE_REAL,
				"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "0,1"
		})
		result.push_back({
				"name": "trigger_max",
				"type": TYPE_REAL,
				"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "0,1"
		})
		if trigger_min != 0 or trigger_max != 1:
			result.push_back({
					"name": "property_current",
					"type": TYPE_STRING,
					"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
					"hint": PROPERTY_HINT_NONE
			})
			result.push_back({
					"name": "property_max",
					"type": TYPE_STRING,
					"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
					"hint": PROPERTY_HINT_NONE
			})
	
	result.push_back({
				"name": "pitch_correction",
				"type": TYPE_BOOL,
				"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
		})
	
	if pitch_correction:
		result.push_back({
				"name": "pitch_bus",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
		})
		result.push_back({
				"name": "pitch_effect_id",
				"type": TYPE_INT,
				"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NONE
		})
	return result
