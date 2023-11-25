extends Control

const profile_textures = []
onready var profile = $Profile


# Called when the node enters the scene tree for the first time.
func _ready():
	$playerInfoAnimation.play("RESET")
#	$playerInfoAnimation.play("In")
	profile.rect_scale = Vector2(1.6,1.6)
	$Exit.connect("pressed", self, "_on_exit")


func _load_profile_textures():
	for i in range(13):
		var path = "res://pck/assets/common/profiles/" + str(i) + ".png"
		var texture = load(path)
		profile_textures.append(texture) 

func _on_exit():
	$playerInfoAnimation.play("Out")

func _on_Profile_pressed():
	$playerInfoSetting.show()
