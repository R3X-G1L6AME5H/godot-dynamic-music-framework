tool
extends DynamicMusicFramework
class_name DMFPlaylistGenerator


enum LIBRARY_NODE_TYPES {
	TRACK,
	SEGMENT,
	ONESHOT, 
	WATCHDOG, 
	MIDI
}

export (bool) var toggle = false setget _save_library
export (bool) var debug_save = false

var library = {}

func _save_library(val):
	if val == false:
		return
	
	toggle = true
	library = {}
	if Engine.editor_hint:
		toggle = false
		for song in get_children():
			library[ song.name ] = {
				"bpm"         : song.bpm,
				"timesig1"    : song.timesig_numerator,
				"timesig2"    : song.timesig_denominator,
				"tracks"      : {},
				"midis"       : {},
				"segments"    : {},
				"watchdogs"   : [],
				"oneshots"    : []
			}
		
			for element in song.get_children():
				if element.lib_node_type == LIBRARY_NODE_TYPES.TRACK:
					if not element.music_track: 
						push_error(element.name + " INVALID")
						continue
				
					library[ song.name ][ "tracks" ][ element.name ] = {
						"path"  : element.music_track,
						"start" : element.start_bar,
						"end"   : element.end_bar
					}
				elif element.lib_node_type == LIBRARY_NODE_TYPES.SEGMENT:
					if element.starting_bar == element.ending_bar: 
						push_error(element.name + " INVALID")
						continue
					
					library[ song.name ][ "segments" ][ element.name ] = {
						"start" : element.starting_bar,
						"end"   : element.ending_bar
					}
				elif element.lib_node_type == LIBRARY_NODE_TYPES.WATCHDOG:
					if not element.target_track \
						or not element.property_current \
						or not element.property_max \
						or not element.change_property: 
							push_error(element.name + " INVALID")
							continue
					
					library[ song.name ][ "watchdogs" ].append( {
						"track"   : element.target_track,
						"current" : element.property_current,
						"max"     : element.property_max,
						"target"  : element.change_property,
						"graph"   : _graph_2_json(element.change_graph)
					} )
				elif element.lib_node_type == LIBRARY_NODE_TYPES.ONESHOT:
					library[ song.name ][ "oneshots" ].append({
						"path"   : element.oneshot_sound,
						"start"  : element.start_bar,
						"chance" : element.trigger_chance
					})
				elif element.lib_node_type == LIBRARY_NODE_TYPES.MIDI:
					if element.midi_file == "":
						push_error(element.name + " INVALID")
						continue
						
					var temp_dict = {}
					temp_dict["midi"]            = element.midi_file
					temp_dict["start"]           = element.starting_bar
					temp_dict["end"]             = element.ending_bar
					temp_dict["single_trigger"]  = element.single_value_trigger
					
					temp_dict["pitch"] = element.pitch_correction
					if element.pitch_correction:
						if element.pitch_bus == "":
							push_error(element.name + " INVALID")
							continue
						temp_dict["bus"] = element.pitch_bus
						temp_dict["sfx"] = element.pitch_effect_id
					
					if element.single_value_trigger:
						if element.trigger_property == "":
							push_error(element.name + " INVALID")
							continue
					
						temp_dict["value"]    = element.trigger_value
						temp_dict["property"] = element.trigger_property
					
					else:
						temp_dict["floor"]    = element.trigger_min
						temp_dict["ceil"]     = element.trigger_max
						
						if element.trigger_min != 0 or element.trigger_max != 1:
							if element.property_current == "" or element.property_max == "":
								push_error(element.name + " INVALID")
								continue 
					
							temp_dict["current"] = element.property_current
							temp_dict["max"]     = element.property_max
					
					library[ song.name ][ "midis" ][element.name] = temp_dict
		
		## Write to file
		var file = File.new()
		push_warning("Saving SongLibrary to \"res://Library.tres\" as a Dictionary.")
		file.open("res://Library.tres", File.WRITE)
		file.store_var(library)
		file.close()

		if debug_save:
			push_warning("Saving SongLibrary to \"res://Library.gd\" as a GDScript for DEBUG.")
			var content = "extends Object\n"
			content += "const library = " + JSON.print(library, "\t")
			file.open("res://Library.gd", File.WRITE)
			file.store_string(content)
			file.close()
		
		toggle = false

static func _graph_2_json( gp : Curve ) -> Dictionary:
	var dict = {"pos" : [], "tg" : [], "tgm" : []}
	for idx in gp.get_point_count():
		var tmp = gp.get_point_position(idx)
		dict.pos.append( [tmp.x, tmp.y] )
		dict.tg.append(  [gp.get_point_left_tangent(idx), gp.get_point_right_tangent(idx)] )
		dict.tgm.append( int(gp.get_point_left_mode(idx)) + 2 * int(gp.get_point_right_mode(idx)) )
	return(dict)
