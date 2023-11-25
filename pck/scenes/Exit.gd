extends TextureButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	rect_pivot_offset = rect_size / 2 
	connect("button_down",self,"_on_button_down")
	#connect("button_up",self,"_on_button_up")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_button_down():
	if self.name == "Exit":
		ExitClick.play()
	else:
		$"/root/AudioClick".play()
#		rect_scale = Vector2(0.9,0.9)
#		self_modulate = Color(1,1,1,0.9)


#func _on_button_up():
#	rect_scale = Vector2(1,1)
#	self_modulate = Color(1,1,1,1)


func _on_e2_pressed():
	pass # Replace with function body.

