extends Node2D

export var speed = 2000
var target = Vector2(1000,-500)
var rank = -1
var shape = -1
var originalScale
var selected =false
var index = -1
var id = -1;
var destroyOnArrive = false
var isDragging = false
var matchColors = [
	Color(0,1,0),
	Color(1,0,0),
	Color(0,0,1),
	Color(0,1,1),
	Color(1,1,1),
]

# Called when the node enters the scene tree for the first time.
func _ready():
	originalScale = scale
	$MoneyCard.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if isDragging :
		return
	position = position.move_toward(target,delta*speed)
	if destroyOnArrive == true :
		if position == target :
			queue_free()

func _set_texture(texture):
	get_node("TouchScreenButton").normal = texture

# Uncomment if you want colored matches
func _set_match(m):
	$Marker.modulate = Color(0,1,0)
#	$Marker.modulate = matchColors[m]
#	$Marker.visible = true

func _hide_match():
	$Marker.modulate = Color(0.8,0.8,0)
#	$Marker.visible = false

func _set_money(isMoney):
	$MoneyCard.visible = isMoney

func _highlight():
	$AnimationPlayer.play("highlight")

func _on_TouchScreenButton_released():
	get_parent().get_parent()._card_select(index)

func _hover():
	modulate = Color(0.5,0.5,1,1)

func _unhover():
	modulate = Color(1,1,1,1)

func _lock():
	get_node("Lock").visible = true

func _unlock():
	get_node("Lock").visible = false
