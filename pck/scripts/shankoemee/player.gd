extends Node2D

const profile_textures = []

const textures = {
	"win":preload("res://pck/assets/shankoemee/win.png"),
	"lose":preload("res://pck/assets/shankoemee/lose.png")
}

const flag_textures = {
	"auto":preload("res://pck/assets/shankoemee/auto-flag.png"),
	"pauk":preload("res://pck/assets/shankoemee/pauk-flag.png")
}

const multiply = {
	2:preload("res://pck/assets/shankoemee/2x.png"),
	3:preload("res://pck/assets/shankoemee/3x.png"),
	5:preload("res://pck/assets/shankoemee/5x.png"),
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

# Called when the node enters the scene tree for the first time.
func _ready():
	_load_profile_textures()
	visible = false
	$CountDown.connect("animation_finished",self,"_stop_count_down")
	_reset()

func _load_profile_textures():
	for i in range(13):
		var path = "res://pck/assets/common/profiles/" + str(i) + ".png"
		var texture = load(path)
		profile_textures.append(texture) 

func _reset():
	$Catch.visible = false
	$PaukFlag.visible = false
	$ResultFlag.visible = false
	$Bet/Label.text = "0"
	_hide_multiply()

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

func _bet_pos():
	return $Bet.global_position

func _banker_pos():
	return $Bet.global_position

func _hide_bet():
	$Bet.visible = false

func _set_bet(bet):
	$Bet.visible = true
	$Bet/Label.text = str(bet)

func _show_pauk(num):
	if num >= 8:
		$PaukFlag/Label.text = str(num) + " ayguf"
		$PaukFlag.texture = flag_textures["auto"]
	else :
		if num == 0:
			$PaukFlag/Label.text = "bl"
		else:
			$PaukFlag/Label.text = str(num) + " ayguf"
		$PaukFlag.texture = flag_textures["pauk"]
	$PaukFlag.visible = true

func _show_catch():
	$Catch.visible = true

func _hide_catch():
	$Catch.visible = false

func _show_result_flag(isWin):
	if isWin == true:
		$ResultFlag.texture = textures.win
	else :
		$ResultFlag.texture = textures.lose
	$ResultFlag.visible = true

func _hide_result_flag():
	$ResultFlag.visible = false

func _stop_count_down():
	$CountDown.playing = false
	$CountDown.frame = 0
	$CountDown.visible = false

func _set_count_down(sec):
	if sec == 0 :
		return
	$CountDown.speed_scale = 1/float(sec)
	$CountDown.frame = 0
	$CountDown.playing = true
	$CountDown.visible = true

func _play_emoji(emoji):
	$Emoji.play(emoji)
	$Emoji.visible = true
	yield(get_tree().create_timer(2), "timeout")
	$Emoji.stop()
	$Emoji.visible = false

func _show_multiply(x):
	$Multiply.texture = multiply[x]
	$Multiply.visible = true
	$Multiply/AnimationPlayer.play("show")

func _hide_multiply():
	$Multiply/AnimationPlayer.play("hide")
	yield(get_tree().create_timer(0.5), "timeout")
	$Multiply.visible = false

func _transfer_balance(amount):
	if amount > 0 :
		get_node("TransferBalance/Label").set("custom_colors/font_color", Color(0,1,0))
		get_node("TransferBalance/Label").text = "+" + str(amount)
	else :
		get_node("TransferBalance/Label").set("custom_colors/font_color", Color(1,0,0))
		get_node("TransferBalance/Label").text = str(amount)
	get_node("TransferBalance/AnimationPlayer").play("show")

func _play_message(msg):
	$AudioStreamPlayer.stream = voices[msg]
	$AudioStreamPlayer.play()
	$Message.texture = msg_textures[msg]
	$Message/AnimationPlayer.play("show")
