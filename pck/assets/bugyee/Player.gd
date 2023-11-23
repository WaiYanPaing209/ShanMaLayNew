extends Node2D

const profile_textures = []
var cardPosArray = []

const textures = {
	"win":preload("res://pck/assets/shankoemee/win.png"),
	"lose":preload("res://pck/assets/shankoemee/lose.png")
}

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
	visible = false
	$ResultFlag.visible = false
	$Profile/Bet.visible = false
	
	var cards = get_node("CardPos")
	for card in cards.get_children():
		cardPosArray.append(card.global_position)
		card.queue_free()
	print(cardPosArray)

func _reset():
	_hide_result_flag()
	_hide_bet()
	_hide_card_status()

func _transfer_balance(amount):
	if amount > 0 :
		get_node("TransferBalance/Label").set("custom_colors/font_color", Color(0,1,0))
		get_node("TransferBalance/Label").text = "+" + str(amount)
	else :
		get_node("TransferBalance/Label").set("custom_colors/font_color", Color(1,0,0))
		get_node("TransferBalance/Label").text = str(amount)
	get_node("TransferBalance/AnimationPlayer").play("show")
	pass

func _show_card_status(status):
	if status == 0:
		get_node("CardStatus/BG/Label").text = "rjzpfzJ"
	elif status == 10:
		get_node("CardStatus/BG/Label").text = "blMuD;"
	elif status == 11:
		get_node("CardStatus/BG/Label").text = "blav;"
	else:
		get_node("CardStatus/BG/Label").text = str(status) + " ayguf"
	get_node("CardStatus/AnimationPlayer").play("show")

func _hide_card_status():
	$CardStatus/AnimationPlayer.play("hide")

func _show_bet(x):
	$Profile/Bet.text = "x" + str(x)
	$Profile/Bet.visible = true

func _hide_bet():
	$Profile/Bet.visible = false

func _load_profile_textures():
	for i in range(13):
		var path = "res://pck/assets/common/profiles/" + str(i) + ".png"
		var texture = load(path)
		profile_textures.append(texture) 

func _set_info(nickname, balance, profile):
	$Panel/Nickname.text = nickname
	_set_balance(balance)
	$Profile.texture = profile_textures[profile]

func _set_balance(balance):
	if(balance >= 1000):
		var d = stepify(balance/1000, 0.1)
		$Panel/Balance.text = str(d) + " K"
	else:
		$Panel/Balance.text = str(balance)

func _show_result_flag(isWin):
	if isWin == true:
		get_node("ResultFlag").texture = textures.win
	else :
		get_node("ResultFlag").texture = textures.lose
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
