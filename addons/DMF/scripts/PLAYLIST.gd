tool
extends DynamicMusicFramework
class_name DMFPlaylistGenerator

"""
	Dynamic Music Framework - Playlist Generator
		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)

	The node that takes a tree of data nodes, and converts all that data into
	a .tres file, Which can then be used directly by the Music Controller singleton.
	This node and all the data nodes are for organizing data in a more intuitive
	way.
"""

enum LIBRARY_NODE_TYPES {
	TRACK,
	SEGMENT,
	ONESHOT, 
	WATCHDOG, 
	MIDI,
	TRANSITION
}


## A button that converts the tree to "res://Library.tres"
export (bool) var toggle = false setget _save_library
## When ticked, saves to "res://Library.gd"; makes all the data visible
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
			assert(song.default_segment != "", "Cannot construnct a playlist if there is no start to a song")
			
			## This is the template according to which the MusicController operates
			library[ song.name ] = {
				"bpm"              : song.bpm,
				"timesig1"         : song.timesig_numerator,
				"timesig2"         : song.timesig_denominator,
				"starting_segment" : song.default_segment,
				"tracks"           : {},
				"midis"            : {},
				"segments"         : {},
				"watchdogs"        : [],
				"oneshots"         : []
			}
		
			## Descend the tree and store the node's data into the dictionary
			for element in song.get_children():
				match(element.lib_node_type):
					LIBRARY_NODE_TYPES.TRACK:
						assert(element.music_track != null, element.name + " INVALID")
						library[ song.name ][ "tracks" ][ element.name ] = {
							"path"  : element.music_track,
							"start" : element.start_bar,
							"end"   : element.end_bar
						}
					
					LIBRARY_NODE_TYPES.SEGMENT:
						assert ( element.starting_bar != element.ending_bar, element.name + " the section starts and ends on the same bar")
						
						library[ song.name ][ "segments" ][ element.name ] = {
							"start"       : element.starting_bar,
							"end"         : element.ending_bar,
							"transitions" : []
						}
					
					LIBRARY_NODE_TYPES.WATCHDOG:
						assert(element.target_track and element.property_current \
							and element.property_max and element.change_property, element.name + " a property is missing")
						
						library[ song.name ][ "watchdogs" ].append( {
							"track"   : element.target_track,
							"current" : element.property_current,
							"max"     : element.property_max,
							"target"  : element.change_property,
							"graph"   : _graph_2_json(element.change_graph)
						} )
				
					LIBRARY_NODE_TYPES.ONESHOT:
						assert(element.oneshot_sound != null, element.name + " no sound defined")
						library[ song.name ][ "oneshots" ].append({
							"path"   : element.oneshot_sound,
							"start"  : element.start_bar,
							"chance" : element.trigger_chance
						})
					
					LIBRARY_NODE_TYPES.MIDI:
						assert(element.midi_file != "", element.name + " no midi file selected")
						
						var temp_dict = {}
						temp_dict["midi"]            = element.midi_file
						temp_dict["start"]           = element.starting_bar
						temp_dict["end"]             = element.ending_bar
						temp_dict["single_trigger"]  = element.single_value_trigger
						
						temp_dict["pitch"] = element.pitch_correction
						if element.pitch_correction:
							assert( element.pitch_bus != "", element.name + " pitch bus not defined")
							temp_dict["bus"] = element.pitch_bus
							temp_dict["sfx"] = element.pitch_effect_id
						
						if element.single_value_trigger:
							assert(element.trigger_property != "", element.name + " INVALID")
							temp_dict["value"]    = element.trigger_value
							temp_dict["property"] = element.trigger_property
						
						else:
							temp_dict["floor"]    = element.trigger_min
							temp_dict["ceil"]     = element.trigger_max
							
							if element.trigger_min != 0 or element.trigger_max != 1:
								assert (element.property_current != "" and element.property_max != "", element.name + " INVALID")
								temp_dict["current"] = element.property_current
								temp_dict["max"]     = element.property_max
						
						library[ song.name ][ "midis" ][element.name] = temp_dict
				
					LIBRARY_NODE_TYPES.TRANSITION:
						assert( element.from_segment != "NULL" and element.to_segment != "NULL" and \
								element.property_current != "" and element.property_max != "", element.name + " INVALID")
						library[ song.name ][ "segments" ][ element.from_segment ]["transitions"].append({
							"current" : element.property_current,
							"max"     : element.property_max,
							"ceil"    : element.trigger_max,
							"floor"   : element.trigger_min,
							"target"  : element.to_segment
						})
		
		
		## Write to file
		var file = File.new()
		push_warning("Saving SongLibrary to \"res://Library.tres\" as a Dictionary.")
		file.open("res://Library.tres", File.WRITE)
		file.store_var(library)
		file.close()
		
		## This option exists purely so that the developer MAY SEE how the node tree was converted to the dictionary
		if debug_save:
			push_warning("Saving SongLibrary to \"res://Library.gd\" as a GDScript for DEBUG.")
			var content = "extends Object\n"
			content += "const library = " + JSON.print(library, "\t")
			file.open("res://Library.gd", File.WRITE)
			file.store_string(content)
			file.close()
		
		toggle = false

"""
A function that stores Curve object's data into a dictionary, so that it may be reconstructed later.
(this is because Godot will just store a string if writen to a GDScript file)
"""
static func _graph_2_json( gp : Curve ) -> Dictionary:
	var dict = {"pos" : [], "tg" : [], "tgm" : []}
	for idx in gp.get_point_count():
		var tmp = gp.get_point_position(idx)
		dict.pos.append( [tmp.x, tmp.y] )
		dict.tg.append(  [gp.get_point_left_tangent(idx), gp.get_point_right_tangent(idx)] )
		dict.tgm.append( int(gp.get_point_left_mode(idx)) + 2 * int(gp.get_point_right_mode(idx)) )
	return(dict)
