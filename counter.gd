extends Label

var bulletCount = 7

# Called when the node enters the scene tree for the first time.
func _ready():
	text = "8/8"

func change():
	text = str(bulletCount)
	

	
