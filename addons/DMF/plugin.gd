tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("Blackboard", "res://addons/DMF/singletons/Blackboard.gd")

func _exit_tree():
	remove_autoload_singleton("Blackboard")
