extends Node2D

export var card_spacing = 200
const profile_textures = []
var card_textures = {}
var _balance = 0
var isLeft = false

const cardPrefab = preload("res://pck/assets/poker_13/PokerCard.tscn")

var msg_textures = {
	"bet_more":preload("res://pck/assets/common/messages/bet_more.png"),
	"haha":preload("res://pck/assets/common/messages/haha.png"),
	"hurry":preload("res://pck/assets/common/messages/hurry.png"),
	"lose":preload("res://pck/assets/common/messages/lose.png"),
	"mingalar":preload("res://pck/assets/common/messages/mingalar.png"),
	"play_again":preload("res://pck/assets/common/messages/play_again.png"),
	"quit":preload("res://pck/assets/common/messages/quit.png")
}

var voices = {
	"bet_more":preload("res://pck/assets/common/messages/bet_more.ogg"),
	"haha":preload("res://pck/assets/common/messages/haha.ogg"),
	"hurry":preload("res://pck/assets/common/messages/hurry.ogg"),
	"lose":preload("res://pck/assets/common/messages/lose.ogg"),
	"mingalar":preload("res://pck/assets/common/messages/mingalar.ogg"),
	"play_again":preload("res://pck/assets/common/messages/play_again.ogg"),
	"quit":preload("res://pck/assets/common/messages/quit.ogg")
}

func _ready():
	_load_profile_textures()
	_load_card_texture()
	_reset()

func _load_card_texture():
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
	var key1 = "X0"
	card_textures[key1] = load("res://pck/assets/common/cards/"+key1+".png")
	var key2 = "X1"
	card_textures[key2] = load("res://pck/assets/common/cards/"+key2+".png")
	var key3 = "X2"
	card_textures[key3] = load("res://pck/assets/common/cards/"+key3+".png")
	var key4 = "X3"
	card_textures[key4] = load("res://pck/assets/common/cards/"+key4+".png")

func _reset():
	visible = false
	_hide_result_flag()
	$MoneyCard.visible = false

func _transfer_balance(amount):
	if amount > 0 :
		get_node("TransferBalance/Label").set("custom_colors/font_color", Color(0,1,0))
		get_node("TransferBalance/Label").text = "+" + str(amount)
	else :
		get_node("TransferBalance/Label").set("custom_colors/font_color", Color(1,0,0))
		get_node("TransferBalance/Label").text = str(amount)
	get_node("TransferBalance/AnimationPlayer").play("show")

func _load_profile_textures():
	for i in range(13):
		var path = "res://pck/assets/common/profiles/" + str(i) + ".png"
		var texture = load(path)
		profile_textures.append(texture) 

func _set_info(nickname, balance, profile):
	$Panel/Nickname.text = nickname
	_balance = balance
	_set_balance(balance)
	$Profile.texture = profile_textures[profile]

func _set_balance(balance):
	if(balance >= 1000):
		var d = stepify(balance/1000, 0.1)
		$Panel/Balance.text = str(d) + " K"
	else:
		$Panel/Balance.text = str(balance)

func _remove_cards():
	for card in get_node("Side/show").get_children():
		card.queue_free()
	for card in get_node("Side/throw").get_children():
		card.queue_free()

func _set_cards(player):
	_remove_cards()
	
	var i = 0
	for card in player.show:
		var c = Sprite.new()
		var key = str(card.mark)+str(card.shape)
		c.texture = card_textures[key]
		var x = i*card_spacing
		if isLeft == true:
			x = -x
		c.position = Vector2(x,0)
		get_node("Side/show").add_child(c)
		i += 1
	
	var j = 0
	for card in player.throw:
		print(card)
		var c = Sprite.new()
		var key = str(card.mark)+str(card.shape)
		c.texture = card_textures[key]
		var x = j*card_spacing
		if isLeft == true:
			x = -x
		c.position = Vector2(x,0)
		get_node("Side/throw").add_child(c)
		j += 1

func _set_total_money_card(point):
	$MoneyCard/Label.text = str(point) + " Point"
	$MoneyCard.visible = true

func _show_final_cards(player):
	_remove_cards()
	var y = 0
	for m in player.matches:
		var i = 0
		for card in m:
			var c = Sprite.new()
			var key = str(card.mark)+str(card.shape)
			c.texture = card_textures[key]
			var x = i*card_spacing
			if isLeft == true:
				x = -x
			c.position = Vector2(x,y)
			get_node("Side/show").add_child(c)
			i += 1
		y += 500

func _show_money_cards(player):
	_remove_cards()
	var i = 0
	for card in player.moneyCards:
		var c = Sprite.new()
		var key = str(card.mark)+str(card.shape)
		c.texture = card_textures[key]
		var x = i*card_spacing
		if isLeft == true:
			x = -x
		c.position = Vector2(x,0)
		get_node("Side/show").add_child(c)
		i += 1


func _add_balance(amount):
	_balance += amount
	_set_balance(_balance)

func _show_result_flag():
	get_node("ResultFlag").visible = true

func _hide_result_flag():
	$ResultFlag.visible = false

func _play_emoji(emoji):
	$Emoji.play(emoji)
	$Emoji.visible = true
	yield(get_tree().create_timer(2), "timeout")
	$Emoji.stop()
	$Emoji.visible = false

func _play_message(msg):
	$AudioStreamPlayer.stream = voices[msg]
	$AudioStreamPlayer.play()
	$Message.texture = msg_textures[msg]
	$Message/AnimationPlayer.play("show")

func _set_left():
	isLeft = true
	get_node("Side").position.x = -120

func _stop_count_down():
	$CountDown.playing = false
	$CountDown.frame = 0
	$CountDown.visible = false

func _set_count_down(sec):
	print("count down set " + str(sec))
	if sec == 0 :
		return
	$CountDown.speed_scale = 1/float(sec)
	$CountDown.frame = 0
	$CountDown.playing = true
	$CountDown.visible = true
