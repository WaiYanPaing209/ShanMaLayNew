extends Control

const profile_textures = []

func _load_profile_textures():
	for i in range(31):
		var path = "res://pck/assets/HomeScence/Home-Photo/icon-photo-" + str(i+1) + ".png"
		var texture = load(path)
		profile_textures.append(texture) 


func _ready():
	_load_profile_textures()
	var buttons = $ProfilePanel/ScrollContainer/Container.get_children()
	for i in range(buttons.size()):
		var button = buttons[i]
		if button is TextureButton:
			button.texture_normal = profile_textures[i]
	
	$playerInfoAnimation.play("Null")
	
func _on_Exit_pressed():
	hide()
	$playerInfoAnimation.play("Out")
