extends Node2D

var card_textures = {}
var touchPos = Vector2()
var init_pos = [null,null,null]

var cardBack = preload("res://pck/assets/common/cards/Card.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(4):
		for j in range(1,10):
			var key = str(j) + str(i)
			var path = "res://pck/assets/common/cards/"+key+".png"
			card_textures[key] = load(path)
		var key1 = "D"+str(i)
		card_textures[key1] = load("res://pck/assets/common/cards/"+key1+".png")
		var key2 = "J"+str(i)
		card_textures[key2] = load("res://pck/assets/common/cards/"+key2+".png")
		var key3 = "Q"+str(i)
		card_textures[key3] = load("res://pck/assets/common/cards/"+key3+".png")
		var key4 = "K"+str(i)
		card_textures[key4] = load("res://pck/assets/common/cards/"+key4+".png")
	
	init_pos[0] = $"1".position
	init_pos[1] = $"2".position
	init_pos[2] = $"3".position
	visible = false

func _input(event):
	if event is InputEventScreenTouch && event.is_pressed():
		touchPos = event.position
		$ArrowRight.visible = false
		
	# Gotta Comment it for a while
	
	if event is InputEventScreenDrag:
		var x = event.position.x - touchPos.x
		var y = event.position.y - touchPos.y
		x *= 0.6
		y *= 0.6
		$"1".position = Vector2(-x,-y) + init_pos[0]
		$"3".position = Vector2(x,y) + init_pos[2]

func _show(cards):
	$"1".position = init_pos[0]
	$"2".position = init_pos[1]
	$"3".position = init_pos[2]
	
	var card = cards[0]
	var key = str(card.rank)+str(card.shape)
	$"2".texture = card_textures[key]
	
	card = cards[1]
	key = str(card.rank)+str(card.shape)
	$"3".texture = card_textures[key]
	
	if cards.size() == 3:
		card = cards[2]
		key = str(card.rank)+str(card.shape)
		$"1".texture = card_textures[key]
		$"1".visible = true
	else:
		$"1".visible = false
	
	visible = true
	$ArrowRight.visible = true

func _hide():
	visible = false
