extends CharacterBody3D

signal health_changed(health_value)

var SPEED = 6.5
const JUMP_VELOCITY = 5.5
const SENSITIVITY = 0.0015
var gravity = 10.0
var PistolBullets = 8
var AK_is_equipped = false
var health = 100

@onready var head = $head
@onready var camera = $head/Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $head/Camera3D/pistol/pistolmuzzleflash
@onready var raycast = $head/Camera3D/RayCast3D


func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

#ON READY
func _ready():
	if not is_multiplayer_authority(): return
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	

#CAMERA AND MULTIPLAYER AUTHORITY
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

#SHOOTING AND RELOADING
	if Input.is_action_just_pressed("shoot"):
		if PistolBullets > 0 and anim_player.current_animation != "pistol_shot" and anim_player.current_animation != "pistol_reload":
			PistolBullets -= 1
			play_shoot_effects.rpc()
			if raycast.is_colliding():
				var hit_player = raycast.get_collider()
				if hit_player.has_method("recieve_damage"):
					hit_player.recieve_damage.rpc_id(hit_player.get_multiplayer_authority())
		if PistolBullets == 0 and anim_player.current_animation != "pistol_reload" and anim_player.current_animation != "pistol_shot":
			play_reload_effects.rpc()

	if Input.is_action_just_pressed("Reload") and PistolBullets < 8 and anim_player.current_animation != "pistol_reload" and anim_player.current_animation != "pistol_shot":
		play_reload_effects.rpc()

#JUMPING
func _physics_process(delta):
	if not is_multiplayer_authority(): return
	if not is_on_floor():
		velocity.y -= gravity * delta


	# HANDLE JUMP
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
	
	#HANDLE ANIMATIONS
	if anim_player.current_animation == "pistol_shot":
		pass
	elif anim_player.current_animation == "pistol_reload":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
			anim_player.play("pistol_walk")
	else:
		anim_player.play("pistol_idle")
		
	if Input.is_action_pressed("Sprint"):
		SPEED = 7.5
		
	if Input.is_action_just_released("Sprint"):
		SPEED = 5.0
	
	if Input.is_action_just_pressed("slide"):
		SPEED = 10
	move_and_slide()

#MULTIPLAYER UPDATES
@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("pistol_shot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true
	
@rpc("call_local")
func play_reload_effects():
	anim_player.stop()
	anim_player.play("pistol_reload")

@rpc("any_peer")
func recieve_damage():
	health -= 35
	if health <= 0:
		health = 100
		position = Vector3.ZERO
	health_changed.emit(health)


#ANIMATIONS FINISHED
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "pistol_reload":
		PistolBullets = 8
		print("reload finished")
		anim_player.play("pistol_idle")
	elif anim_name == "pistol_shot":
		print("shot finished")
		anim_player.play("pistol_idle")
