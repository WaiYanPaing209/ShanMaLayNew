extends Node2D

var card_textures = {}
var cardPosArray = []
var cardArray = []
var selectedIndex = -1
var touchPos = Vector2()
var touchDelta = Vector2()
var isUncover = [false,false]
var coverPosArray = []
var selectedCover = -1

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
	
	cardPosArray.append($"0".global_position)
	cardPosArray.append($"1".global_position)
	cardPosArray.append($"2".global_position)
	cardPosArray.append($"3".global_position)
	cardPosArray.append($"4".global_position)
	
	coverPosArray.append($B0.global_position)
	coverPosArray.append($B1.global_position)

func _input(event):
	if !visible :
		return
	
	if isUncover[0] == false || isUncover[1] == false:
		_cover_move(event)
		return
	
	if event is InputEventScreenTouch && event.is_pressed():
		touchPos = event.position
		for i in range(5):
			var pos = cardPosArray[i]
			if touchPos.x > (pos.x - 90) && touchPos.x < (pos.x + 90) && touchPos.y > (pos.y - 120) && touchPos.y < (pos.y + 120):
				selectedIndex = i
				get_node(str(selectedIndex)).z_index = 1
				print(str(selectedIndex)+" selected")
				break
	
	if event is InputEventScreenTouch && !event.is_pressed():
		touchPos = event.position
		if selectedIndex == -1:
			return
		for i in range(5):
			var pos = cardPosArray[i]
			if touchPos.x > (pos.x - 90) && touchPos.x < (pos.x + 90) && touchPos.y > (pos.y - 120) && touchPos.y < (pos.y + 120):
				var tmp = cardArray[i]
				cardArray[i] = cardArray[selectedIndex]
				cardArray[selectedIndex] = tmp
				_renderCards()
				get_node(str(selectedIndex)).z_index = 0
				selectedIndex = -1
				break
		
	if event is InputEventScreenDrag:
		var x = event.position.x
		var y = event.position.y
		if selectedIndex != -1:
			get_node(str(selectedIndex)).global_position = Vector2(x,y)

func _cover_move(event):
	if event is InputEventScreenTouch && event.is_pressed():
		touchPos = event.position
		for i in range(2):
			var pos = coverPosArray[i]
			if touchPos.x > (pos.x - 90) && touchPos.x < (pos.x + 90) && touchPos.y > (pos.y - 120) && touchPos.y < (pos.y + 120):
				touchDelta = pos - touchPos
				selectedCover = i
	
	if event is InputEventScreenTouch && !event.is_pressed():
		if selectedCover == 0:
			$B0/AnimationPlayer.play("hide")
			isUncover[0] = true
		
		if selectedCover == 1:
			$B1/AnimationPlayer.play("hide")
			isUncover[1] = true
		
		if isUncover[0] == true && isUncover[1] == true:
			$Arrow.visible = true
			$OK.visible = true
			$Stop.visible = true
			$Label1.visible = true
			$Label2.visible = true
	
	if event is InputEventScreenDrag:
		var x = event.position.x
		var y = event.position.y
		if selectedCover == 0 || selectedCover == 1:
			get_node("B"+str(selectedCover)).global_position = Vector2(x,y) + touchDelta

func _renderCards():
	print(cardArray)
	$"/root/AudioClick".play()
	for i in range(5):
		var card = cardArray[i]
		var key = str(card.rank)+str(card.shape)
		get_node(str(i)).texture = card_textures[key]
		get_node(str(i)).global_position = cardPosArray[i]
	
	var p1 = int(cardArray[0].count + cardArray[1].count) % 10
	if p1 == 0 :
		$Label1/Label.text = "bl"
	else :
		$Label1/Label.text = str(p1)
		
	var p2 = int(cardArray[2].count + cardArray[3].count + cardArray[4].count) % 10
	if p2 == 0 :
		$Label2/Label.text = "bl"
		$Success.play()
	else :
		$Label2/Label.text = str(p2)

func _show(cards):
	cardArray = cards
	_renderCards()
	visible = true
	# Reset
	$B0.global_position = coverPosArray[0]
	$B1.global_position = coverPosArray[1]
	$B0.modulate = Color(1,1,1,1)
	$B1.modulate = Color(1,1,1,1)
	isUncover[0] = false
	isUncover[1] = false
	$Arrow.visible = false
	$OK.visible = false
	$Stop.visible = false
	$Label1.visible = false
	$Label2.visible = false

func _hide():
	visible = false

func _on_OK_pressed():
	get_parent()._submit_card(cardArray)
	visible = false

func _on_Stop_pressed():
	get_parent()._submit_card(cardArray)
	visible = false
