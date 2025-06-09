extends Control

@onready var right = $Center/right
@onready var bottom = $Center/bottom
@onready var left = $Center/left
@onready var top = $Center/top
@onready var ak = $"../head/Camera3D/AK"

var growpos = 35
var growspeed = 4

func _physics_process(delta):
	if Input.is_action_pressed("shoot") and ak.is_visible_in_tree():
		right.position = lerp(right.position, Vector2(growpos, 0), growspeed * delta)
		bottom.position = lerp(bottom.position, Vector2(0, growpos), growspeed * delta)
		left.position = lerp(left.position, Vector2(-growpos, 0), growspeed * delta)
		top.position = lerp(top.position, Vector2(0, -growpos), growspeed * delta)
		
	else:
		right.position = lerp(right.position, Vector2(10,0), growspeed * delta)
		bottom.position = lerp(bottom.position, Vector2(0,10), growspeed * delta)
		left.position = lerp(left.position, Vector2(-10,0), growspeed * delta)
		top.position = lerp(top.position, Vector2(0,-10), growspeed * delta)
