extends KinematicBody2D

export (int) var speed = 200

var velocity = Vector2()

func _ready():
	Blackboard.set("HP", 200)
	Blackboard.set("HP_MAX", 200.0)

func get_input():
	velocity = Vector2()
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	if Input.is_action_just_pressed("ui_accept"):
		Blackboard.set("HP", min(Blackboard.get("HP") + 10, Blackboard.get("HP_MAX") ))
	velocity = velocity.normalized() * speed

func _physics_process(_delta):
	get_input()
	velocity = move_and_slide(velocity)
