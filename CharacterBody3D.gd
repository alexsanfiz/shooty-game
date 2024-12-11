extends CharacterBody3D


var SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.0015
var gravity = 9.8

@onready var head = $head
@onready var camera = $head/Camera3D
@onready var anim_player = $animationplayer
@onready var muzzle_flash = $head/Camera3D/pistol/muzzleflash
	
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	if Input.is_action_just_pressed("shoot") \
			and anim_player.current_animation != "shot":
		play_shoot_effects()
		
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	if anim_player.current_animation == "shot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
			anim_player.play("move")
	else:
		anim_player.play("idle")
		
	if Input.is_action_pressed("Sprint"):
		SPEED = 7.5
		
	if Input.is_action_just_released("Sprint"):
		SPEED = 5.0
	
	move_and_slide()
	
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true
