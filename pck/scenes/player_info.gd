extends Control

const profile_textures = []
onready var profile = $"Icon-profile-box/Profile"


# Called when the node enters the scene tree for the first time.
func _ready():
	profile.rect_scale = Vector2(1.5,1.5)


func _load_profile_textures():
	for i in range(13):
		var path = "res://pck/assets/common/profiles/" + str(i) + ".png"
		var texture = load(path)
		profile_textures.append(texture) 


func _on_Exit_pressed():
	self.hide()
