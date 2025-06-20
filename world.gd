extends CharacterBody3D

signal health_changed(health_value)

var SPEED = 6.5
const JUMP_VELOCITY = 5.5
const SENSITIVITY = 0.0015
var gravity = 10.0
var PistolBullets = 8
var AKBullets = 30
var health = 100
var slide_speed = 20.0  # Speed during slide
var slide_direction = Vector3.ZERO  # Store the direction during the slide
var slide_slow = 0.25
var double_jumps = 1
enum PlayerGunState {AK, pistol}
enum PlayerMovementState {Sliding, Sprinting, Normal}
var current_gun_state = PlayerGunState.pistol
var current_movement_state = PlayerMovementState.Normal
var last_shot_time = 0.0
var shoot_delay = 0.2
var kills = 0
var deaths = 0

@onready var head = $head
@onready var camera = $head/Camera3D
@onready var anim_player = $AnimationPlayer
@onready var pistol_muzzle_flash = $head/Camera3D/pistol/pistolmuzzleflash
@onready var raycast = $head/Camera3D/RayCast3D
@onready var slide_dust = $slideDust
@onready var AK_muzzle_flash = $head/Camera3D/AK/AKmuzzleflash

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	
	
#ON READY
func _ready():
	var id = multiplayer.get_unique_id()
	if is_multiplayer_authority(): 
		
		Global.player = self
		Global._on_player_spawned(id, self)
		Global.game_active = true
		$PauseMenu.showID(id)
		print("Authorized player: ", id)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		camera.current = true
		$MeshInstance3D.rotation.x = deg_to_rad(0)
		$CollisionShape3D.rotation.x = deg_to_rad(0)
		slide_dust.emitting = false
		update_slide_dust.rpc(true)
		current_gun_state = PlayerGunState.pistol
	else:
		print("no authority for ", name)
		return
	

func _process(delta):
	if Global.game_active == false:
		current_movement_state = PlayerMovementState.Normal
		SPEED = 0.0

#CAMERA AND MULTIPLAYER AUTHORITY
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

#deals with pause menu
	if event.is_action_pressed("ui_cancel"):
		$PauseMenu.onpress()
		if $PauseMenu.visible:
			$PauseMenu.showStats(kills, deaths)
			
#Resetting
	if Input.is_action_just_pressed("reset"):
		die()
		
#GunSelect
	if event.is_action_pressed("WeaponSelect"):
		$WeaponMenu.onpress()

#AmmoCounting
		
#SHOOTING AND RELOADING
	if Input.is_action_just_pressed("shoot") and current_gun_state == PlayerGunState.pistol:
		if PistolBullets > 0 and anim_player.current_animation != "pistol_shot" and anim_player.current_animation != "pistol_reload":
			PistolBullets -= 1
			play_pistol_shoot_effects.rpc()
			if raycast.is_colliding():
				var hit_player = raycast.get_collider()
				if hit_player.has_method("recieve_damage"):
					hit_player.rpc("recieve_damage", 35, get_multiplayer().get_unique_id())
					hit_player.health-=35
					if(hit_player.health <= 0):
						hit_player.health = 100
						if multiplayer.is_server():
							kills+=1
							Global.playerStats[multiplayer.get_unique_id()].kills += 1
						else:
							rpc_id(1, "report_kill", multiplayer.get_unique_id())
							kills+=1
						print("kill given")
					print(hit_player.health)
		if PistolBullets == 0 and anim_player.current_animation != "pistol_reload" and anim_player.current_animation != "pistol_shot":
			play_pistol_reload_effects.rpc()

	if Input.is_action_just_pressed("Reload") and PistolBullets < 8 and anim_player.current_animation != "pistol_reload" and anim_player.current_animation != "pistol_shot" and current_gun_state == PlayerGunState.pistol:
		play_pistol_reload_effects.rpc()
		
	if Input.is_action_pressed("shoot") and AKBullets > 0 and current_gun_state == PlayerGunState.AK:
		if AKBullets > 0 and anim_player.current_animation != "AK_shot" and anim_player.current_animation!= "AK_reload" and last_shot_time >= shoot_delay:
			last_shot_time = 0.0
			AKBullets -= 1
			print("Shooting AK, bullets left: ", AKBullets)  # Debugging
			play_AK_shoot_effects.rpc()  # Ensure this is called remotely
			if raycast.is_colliding():
				var hit_player = raycast.get_collider()
				if hit_player.has_method("recieve_damage"):
					hit_player.rpc("recieve_damage", 15, get_multiplayer().get_unique_id())
					hit_player.health-=15
					if(hit_player.health <= 0):
						hit_player.health = 100
						if multiplayer.is_server():
							kills+=1
							Global.playerStats[multiplayer.get_unique_id()].kills += 1
						else:
							rpc_id(1, "report_kill", multiplayer.get_unique_id())
							kills+=1
						print("kill given")
					print(hit_player.health)
		if AKBullets == 0 and anim_player.current_animation != "AK_reload":
			play_AK_reload_effects.rpc()

	if Input.is_action_just_pressed("Reload") and AKBullets < 30 and anim_player.current_animation != "AK_reload" and anim_player.current_animation != "AK_shot" and current_gun_state == PlayerGunState.AK:
		play_AK_reload_effects.rpc()

#MOVEMENT
func _physics_process(delta):
	last_shot_time += delta
	if not is_multiplayer_authority(): return
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() or double_jumps > 0:
			velocity.y = JUMP_VELOCITY  # Add jump height
			double_jumps = 0
			if current_movement_state == PlayerMovementState.Sliding:
				slide_dust.emitting = false
				update_slide_dust.rpc(false)
				velocity.x = slide_direction.x * slide_speed
				velocity.z = slide_direction.z * slide_speed
				current_movement_state = PlayerMovementState.Normal
				slide_speed = 20  # Reset for future slides
				$MeshInstance3D.rotation.x = deg_to_rad(0)
				$CollisionShape3D.rotation.x = deg_to_rad(0)
		else:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED

	if is_on_floor():
		double_jumps = 1
	
	if current_movement_state == PlayerMovementState.Sliding:
		velocity.x = slide_direction.x * slide_speed
		velocity.z = slide_direction.z * slide_speed
		if slide_speed > 0:
			slide_dust.emitting = true
			update_slide_dust.rpc(true)
			slide_speed -= slide_slow
			$MeshInstance3D.rotation.x = deg_to_rad(50)
			$CollisionShape3D.rotation.x = deg_to_rad(50)
		elif slide_speed == 0:
			current_movement_state = PlayerMovementState.Normal
			slide_dust.emitting = false
			update_slide_dust.rpc(false)
			slide_speed = 20
			$MeshInstance3D.rotation.x = deg_to_rad(0)
			$CollisionShape3D.rotation.x = deg_to_rad(0)
	elif direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if Input.is_action_pressed("Sprint"):
		if current_movement_state == PlayerMovementState.Sliding:
			current_movement_state = PlayerMovementState.Sprinting
			slide_dust.emitting = false
			update_slide_dust.rpc(false)
			$MeshInstance3D.rotation.x = deg_to_rad(0)
			$CollisionShape3D.rotation.x = deg_to_rad(0)
			slide_speed = 20
		else:
			SPEED = 8.25
			current_movement_state = PlayerMovementState.Sprinting


	if Input.is_action_just_released("Sprint"):
		SPEED = 6.5
		current_movement_state == PlayerMovementState.Normal
	
	if Input.is_action_just_pressed("slide"):
		if is_on_floor() and current_movement_state != PlayerMovementState.Sliding and direction:
			current_movement_state = PlayerMovementState.Sliding
			slide_direction = direction
			velocity.x = slide_direction.x * slide_speed
			velocity.z = slide_direction.z * slide_speed


	if anim_player.current_animation == "pistol_shot":
		pass
	elif anim_player.current_animation == "pistol_reload":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor() and current_movement_state != PlayerMovementState.Sliding and current_gun_state == PlayerGunState.pistol:
			anim_player.play("pistol_walk")
	elif current_gun_state == PlayerGunState.pistol:
		anim_player.play("pistol_idle")
	elif anim_player.current_animation == "AK_shot":
		pass
	elif anim_player.current_animation == "AK_reload":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor() and current_movement_state != PlayerMovementState.Sliding and current_gun_state == PlayerGunState.AK:
		anim_player.play("AK_walk")
	elif current_gun_state == PlayerGunState.AK:
		anim_player.play("AK_idle")
	
	if Input.is_action_just_pressed("secondary_gun"):
		current_gun_state = PlayerGunState.pistol
		$head/Camera3D/pistol.show()
		$head/Camera3D/AK.hide()
	if Input.is_action_just_pressed("primary_gun"):
		current_gun_state = PlayerGunState.AK
		$head/Camera3D/AK.show()
		$head/Camera3D/pistol.hide()
	move_and_slide()

#MULTIPLAYER UPDATES
@rpc("call_local")
func play_pistol_shoot_effects():
	anim_player.stop()
	anim_player.play("pistol_shot")
	pistol_muzzle_flash.restart()
	pistol_muzzle_flash.emitting = true
	
@rpc("call_local")
func play_pistol_reload_effects():
	anim_player.stop()
	anim_player.play("pistol_reload")
	
@rpc("call_local")
func play_AK_reload_effects():
	anim_player.stop()
	anim_player.play("AK_reload")
	
@rpc("call_local")
func play_AK_shoot_effects():
	anim_player.stop()
	anim_player.play("AK_shot")
	AK_muzzle_flash.restart()
	AK_muzzle_flash.emitting = true

@rpc("any_peer")
func recieve_damage(damage: int, attacker: int):
	if not is_multiplayer_authority():
		print("no damage")
	health -= damage
	print("shot by: ", attacker)
	if health <= 0:
		if multiplayer.is_server():
			deaths+=1
			Global.playerStats[multiplayer.get_unique_id()].deaths += 1
			die()
		else:
			rpc_id(1, "report_death", multiplayer.get_unique_id())
			deaths+=1
			die()
	health_changed.emit(health)
	
@rpc("authority")
func report_kill(peer_id):
	if not Global.playerStats.has(peer_id):
		Global.playerStats[peer_id] = {"kills": 0, "deaths": 0}
	Global.playerStats[peer_id].kills += 1
	
@rpc("authority")
func report_death(peer_id):
	if not Global.playerStats.has(peer_id):
		Global.playerStats[peer_id] = {"kills": 0, "deaths": 0}
	Global.playerStats[peer_id].deaths += 1
	
func die():
	health = 100
	position = Vector3.ZERO
	PistolBullets = 8
	AKBullets = 30
	

@rpc("call_remote")
func update_slide_dust(emitting: bool):
	slide_dust.emitting = emitting


#ANIMATIONS FINISHED
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "pistol_reload":
		PistolBullets = 8
		print("reload finished")
		anim_player.play("pistol_idle")
	if anim_name == "pistol_shot":
		print("shot finished")
		anim_player.play("pistol_idle")
	if anim_name == "AK_reload":
		AKBullets = 30
		anim_player.play("AK_idle")
	if anim_name == "AK_shot":
		anim_player.play("AK_idle")
		
