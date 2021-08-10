extends Area2D

var spe : float
var dir : Vector2

func _on_hit( _body ):
	Blackboard.set("HP", max(0, Blackboard.get("HP") - 15))
	get_parent().get_parent().get_node("Player").get_node("Hit").play()
	self.queue_free()
