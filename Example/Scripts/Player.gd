extends KinematicBody2D

export (int) var speed = 200

var velocity = Vector2()

func _ready():
	Blackboard.set("HP", 200.0)
	Blackboard.set("HP_MAX", 200.0)
	Blackboard.set("INTENSITY", 1.0)
	Blackboard.set("INTENSITY_MAX", 10.0)

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
	
	if Input.is_key_pressed(KEY_9):
		Blackboard.set("INTENSITY", min(Blackboard.get("INTENSITY") + 1, Blackboard.get("INTENSITY_MAX") ))
		get_node("../GUI/MarginContainer/HBoxContainer2/HBoxContainer2/Panel/MarginContainer/HBoxContainer/Label2").text = str(Blackboard.get("INTENSITY"))
	
	if Input.is_key_pressed(KEY_0):
		Blackboard.set("INTENSITY", min(Blackboard.get("INTENSITY") + 1, Blackboard.get("INTENSITY_MAX") ))
		get_node("../GUI/MarginContainer/HBoxContainer2/HBoxContainer2/Panel/MarginContainer/HBoxContainer/Label2").text = str(Blackboard.get("INTENSITY"))

func _physics_process(_delta):
	get_input()
	velocity = move_and_slide(velocity)
