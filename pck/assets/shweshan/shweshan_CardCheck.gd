extends Node2D

var card_textures = {}
var cardPosArray = []
var cardArray = []
var selectedIndex = -1
var touchPos = Vector2()
var touchDelta = Vector2()

var status_texture = [
	preload("res://pck/assets/shweshan/wrong.png"),
	preload("res://pck/assets/shweshan/correct.png"),
]

var multiplier_texture = [
	null,
	null,
	preload("res://pck/assets/shankoemee/2x.png"),
	preload("res://pck/assets/shankoemee/3x.png"),
	null,
	preload("res://pck/assets/shankoemee/5x.png"),
]

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
	cardPosArray.append($"5".global_position)
	cardPosArray.append($"6".global_position)
	cardPosArray.append($"7".global_position)

func _input(event):
	if !visible :
		return
	
	if event is InputEventScreenTouch && event.is_pressed():
		touchPos = event.position
		for i in range(8):
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
		get_parent()._ping()
		for i in range(8):
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

func _renderCards():
	$"/root/AudioClick".play()
	for i in range(8):
		var card = cardArray[i]
		var key = str(card.rank)+str(card.shape)
		get_node(str(i)).texture = card_textures[key]
		get_node(str(i)).global_position = cardPosArray[i]
	
	var p1 = int(cardArray[0].count + cardArray[1].count) % 10
	if p1 == 0 :
		$Label1/Label.text = "bl"
	else :
		$Label1/Label.text = str(p1)
	if p1 == 8 || p1 == 9 :
		get_node("Correct/0").texture = status_texture[1]
		$Label1.self_modulate = Color(0.7,1,0.7)
		$Success.play()
		if cardArray[0].shape == cardArray[1].shape :
			get_node("Multiply/0").texture = multiplier_texture[2]
			get_node("Multiply/0").visible = true
		else :
			get_node("Multiply/0").visible = false
	else :
		$Label1.self_modulate = Color(1,1,1)
		get_node("Multiply/0").visible = false
		get_node("Correct/0").texture = status_texture[0]
	
	var p2 = int(cardArray[2].count + cardArray[3].count + cardArray[4].count) % 10
	if str(cardArray[2].rank) == str(cardArray[3].rank) && str(cardArray[3].rank) == str(cardArray[4].rank) :
		$Label2/Label.text = "axG"
	elif p2 == 0:
		$Label2/Label.text = "bl"
	else :
		$Label2/Label.text = str(p2)
	
	var p3 = int(cardArray[5].count + cardArray[6].count + cardArray[7].count) % 10
	if str(cardArray[5].rank) == str(cardArray[6].rank) && str(cardArray[6].rank) == str(cardArray[7].rank) :
		$Label3/Label.text = "axG"
	elif p3 == 0:
		$Label3/Label.text = "bl"
	else :
		$Label3/Label.text = str(p3)
	
	if _check_correct_on_23() :
		get_node("Correct/1").texture = status_texture[1]
		get_node("Correct/2").texture = status_texture[1]
		$Label2.self_modulate = Color(0.7,1,0.7)
		$Label3.self_modulate = Color(0.7,1,0.7)
		$Success.play()
		# Multiply for second step
		if cardArray[2].shape == cardArray[3].shape && cardArray[3].shape == cardArray[4].shape :
			get_node("Multiply/1").texture = multiplier_texture[3]
			get_node("Multiply/1").visible = true
		elif str(cardArray[2].rank) == str(cardArray[3].rank) && str(cardArray[3].rank) == str(cardArray[4].rank) :
			get_node("Multiply/1").texture = multiplier_texture[5]
			get_node("Multiply/1").visible = true
		else :
			get_node("Multiply/1").visible = false
		# Multiply for third step
		if cardArray[5].shape == cardArray[6].shape && cardArray[6].shape == cardArray[7].shape :
			get_node("Multiply/2").texture = multiplier_texture[3]
			get_node("Multiply/2").visible = true
		elif str(cardArray[5].rank) == str(cardArray[6].rank) && str(cardArray[6].rank) == str(cardArray[7].rank) :
			get_node("Multiply/2").texture = multiplier_texture[5]
			get_node("Multiply/2").visible = true
		else :
			get_node("Multiply/2").visible = false
	else :
		get_node("Correct/1").texture = status_texture[0]
		get_node("Correct/2").texture = status_texture[0]
		$Label2.self_modulate = Color(1,1,1)
		$Label3.self_modulate = Color(1,1,1)

func _check_correct_on_23():
	var p2 = int(cardArray[2].count + cardArray[3].count + cardArray[4].count) % 10
	var p3 = int(cardArray[5].count + cardArray[6].count + cardArray[7].count) % 10
	var is_p2_5x = str(cardArray[2].rank) == str(cardArray[3].rank) && str(cardArray[3].rank) == str(cardArray[4].rank)
	var is_p3_5x = str(cardArray[5].rank) == str(cardArray[6].rank) && str(cardArray[6].rank) == str(cardArray[7].rank)
	
	if is_p3_5x == true && is_p2_5x == false :
		return true
	elif is_p3_5x == false && is_p2_5x == true :
		return false
	
	if p2 < p3:
		return true
	elif p2 == p3:
		var m2 = _max_rank_card(cardArray[2], cardArray[3], cardArray[4])
		print(m2)
		var m3 = _max_rank_card(cardArray[5], cardArray[6], cardArray[7])
		print(m3)
		if _get_rank(m2) < _get_rank(m3):
			return true
		elif _get_rank(m2) == _get_rank(m3):
			if m2.shape < m3.shape:
				return true
			else:
				return false
		else:
			return false
	else :
		return false

func _max_rank_card(c1,c2,c3):
	var _max = c1
	if _get_rank(c2) > _get_rank(_max):
		_max = c2
	if _get_rank(c3) > _get_rank(_max):
		_max = c3
	return _max

func _get_rank(card):
	var result = card.rank
	match str(card.rank):
		"D":
			result = 10
		"J":
			result = 11
		"Q":
			result = 12
		"K":
			result = 13
		"1":
			result = 14
	return result
	

func _show(cards):
	cardArray = cards
	_renderCards()
	visible = true
	get_node("Multiply/0").visible = false
	get_node("Multiply/1").visible = false
	get_node("Multiply/2").visible = false

func _hide():
	visible = false

func _on_OK_pressed():
	get_parent()._submit_card(cardArray)
	visible = false

func _on_Stop_pressed():
	get_parent()._submit_card(cardArray)
	visible = false

func _on_GiveUp_pressed():
	get_parent()._giveUp()
	visible = false
