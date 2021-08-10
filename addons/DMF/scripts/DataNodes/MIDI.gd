tool
extends DMFLibraryClasses
class_name DMFMidiPlayer

const lib_node_type = 4

export (String, FILE, "*.mid") var midi_file
export (int) var starting_bar
export (int) var ending_bar
export (bool) var single_value_trigger = true setget _single_val_bool_toggeled
### SINGLE VALUE TRIGGER
var trigger_value : int = 1
var trigger_property : String

### MULTIPLE VALUE TRIGGER
var trigger_min : float = 0.0 setget _trigger_min_set
var trigger_max : float = 1.0 setget _trigger_max_set
var property_current : String = ""
var property_max : String = ""

### PITCH CORRECTION ON
var pitch_correction : bool = false setget _pitch_correction_toggled
var pitch_bus : String = ""
var pitch_effect_id : int = 0


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
