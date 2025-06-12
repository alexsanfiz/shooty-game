extends ColorRect

@onready var opened = false
@onready var Player = $player

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false

func onpress():
	if opened == false:
		open()
		
func open():
	visible = true
	opened = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#print($Player.current_gun_state)
	
func close():
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_pistol_button_pressed():
	Player.current_gun_state = Player.PlayerGunState.pistol
