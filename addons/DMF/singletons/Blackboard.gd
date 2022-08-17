extends Node

"""
	A Simple Blackboard Singleton
		adapted from "This Is Vini"'s code
			(https://github.com/viniciusgerevini/godot-behavior-tree-example/blob/master/addons/behavior_tree/blackboard.gd)
		https://www.youtube.com/c/ThisIsVini  (Youtube)
		https://github.com/viniciusgerevini   (github)

	A simple blackboard. This singleton is where the MusicController Singleton gets its
	data from. All the properties listed in the Playlist Generator, also reffer to data
	within this blackboard.
"""

var blackboard = {}


## A signal for any value changes
## 		(for updating MusicController Singleton's state)
signal blackboard_value_set( key )



func set(key, value, blackboard_name = 'default'):
	if not blackboard.has(blackboard_name):
		blackboard[blackboard_name] = {}

	blackboard[blackboard_name][key] = value
	emit_signal("blackboard_value_set", key) ## Update MusicController's state


func get(key, blackboard_name = 'default'):
	if has(key, blackboard_name):
		return blackboard[blackboard_name][key]


func has(key, blackboard_name = 'default'):
	return blackboard.has(blackboard_name) and blackboard[blackboard_name].has(key) and blackboard[blackboard_name][key] != null


func erase(key, blackboard_name = 'default'):
	if blackboard.has(blackboard_name):
		 blackboard[blackboard_name][key] = null
