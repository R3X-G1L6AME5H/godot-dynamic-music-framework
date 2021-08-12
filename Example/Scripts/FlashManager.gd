extends Node2D

#enum {C, CS, D, DS, E, F, FS, G, GS, A, AS, B}

var is_awaiting_notes = false
var current_note : int = 0
var wholenote_length : float
var d : float = 16

signal current_note_changed( note )

func _ready():
	$Timer.wait_time = 0.005
	$Timer.one_shot = true
# warning-ignore:return_value_discarded
	MusicController.connect("note_on", self, "_on_Node_note_on")
# warning-ignore:return_value_discarded
	MusicController.connect("note_off", self, "_on_Node_note_off")
	##################
	wholenote_length = (60.0 / MusicController.SONG_LIBRARY[MusicController.current_song].bpm) #* 4.0
	$BulletCircle.wait_time = wholenote_length / d
	get_parent().get_node("AnimationPlayer").play("EnemyMovement")

func _on_Node_note_on(_channel, _on_note):
	#print("++++")
	if not is_awaiting_notes:
		is_awaiting_notes = true
		$Timer.start()


func _on_Node_note_off(_channel, off_note):
	var note = off_note % 12
	if note == current_note:
		is_awaiting_notes = false

func _on_Timer_timeout():
	#print("####")
	var r = randf()
	var s = sum(MusicController.notes_on.values())
	var border : float = 1.0
	for key in MusicController.notes_on.keys():
		border -= MusicController.notes_on[key] / s
		if border < r:
			current_note = key % 12
			emit_signal("current_note_changed", current_note)
			break

static func sum(array) -> float:
	var sum = 0.0
	for element in array:
		sum += element
	return sum


###################################################################
###################################################################
###################################################################
func _on_Enemy_current_note_changed(note):
	var target = (get_parent().get_node("Player").position - self.position).normalized()
	if note == 0:
		var y = 3
		for _i in range(y-1):
			shoot( target.normalized(), 10 )
			$BulletBurst.start()
			yield($BulletBurst, "timeout")
		shoot( target.normalized(), 10 )
	elif note == 2:
		shoot( target.normalized().rotated(deg2rad(25)), 10)
		shoot( target.normalized(), 10 )
		shoot( target.normalized().rotated(deg2rad(-25)), 10 )
		
	elif note == 4:
		var br = 3
		var br2 = 0
		var division = deg2rad(360.0/d)
		for i in range(d):
			for j in range(br):
				shoot( target.normalized().rotated( 2*PI/br*j + division * i), 5 )
			$BulletCircle.start()
			yield($BulletCircle, "timeout")
			
			for j in range(br2):
				shoot( target.normalized().rotated( 2*PI/br2*j + division * (d-i)), 5 )
			$BulletCircle.start()
			yield($BulletCircle, "timeout")
		
	#elif note == 6:
	#	var division = deg2rad(360.0/16.0)
	#	for i in range(16):
	#		shoot( target.normalized().rotated(division * i), 7.5 )
	#		$BulletCircle.start()
	#		yield($BulletCircle, "timeout")

############################################################################################
############################################################################################
############################################################################################
const BULLET = preload("res://Example/Scenes/Bullet.tscn")

func _process(_delta):
	for child in get_parent().get_node("Bullets").get_children():
		child.position += child.dir * child.spe

func shoot(dir : Vector2, speed : float):
	var b = BULLET.instance()
	var tmp = Vector3(dir.x, dir.y, 0).cross(Vector3(0,0,1)).normalized()
	b.transform = Transform2D(dir, Vector2(tmp.x, tmp.y), self.position)
	b.spe = speed
	b.dir = dir
	b.connect("body_entered", b, "_on_hit")
	get_parent().get_node("Bullets").add_child(b)
	$Shoot.play()


func _on_OOB_area_entered(area):
	area.queue_free()
