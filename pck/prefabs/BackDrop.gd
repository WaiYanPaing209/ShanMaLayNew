extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _show(text = null):
	if(text != null):
		$Label.text = text
	visible = true

func _hide():
	visible = false




