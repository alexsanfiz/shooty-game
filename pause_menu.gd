extends ColorRect

@onready var paused = false
@onready var animation: AnimationPlayer = $BlurIn
@onready var play_button: Button = find_child("Resume")
@onready var quit_button: Button = find_child("QuitButton")

func _ready():
	visible = false
	paused = false

func onpress():
	if paused == false:
		open()

func open():
	visible = true
	paused = true
	animation.play("menufadein")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("paused")

func close():
	visible = false
	paused = false
	animation.play_backwards("menufadein")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("unpaused")
	
func showStats(kills, deaths):
	$CenterContainer/PanelContainer2/VBoxContainer/KillDisplay.text = "Kills: %d" % kills
	$CenterContainer/PanelContainer2/VBoxContainer/DeathDisplay.text = "Deaths: %d" % deaths

func _on_resume_pressed():
	close()

func _on_exit_pressed():
	get_tree().quit()
