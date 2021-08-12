tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("Blackboard", "res://addons/DMF/singletons/Blackboard.gd")
	add_autoload_singleton("MusicController", "res://addons/DMF/singletons/MusicController.tscn")

func _exit_tree():
	remove_autoload_singleton("Blackboard")
	remove_autoload_singleton("MusicController")
