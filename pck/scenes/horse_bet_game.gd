extends Node

var websocket_url = ""
var isRunning = false
var runSpeed = 300
var win_chart = [
	[1,2,4],
	[1,3,2],
	[1,4,6],
	[1,5,2],
	[1,6,3],
	[2,3,5],
	[2,4,6],
	[2,5,1],
	[2,6,1],
	[3,4,5],
	[3,5,1],
	[3,6,2],
	[4,5,6],
	[4,6,1],
	[5,6,4]
]
var bet_arr = [100,500,1000,2000,10000,50000]
var bet_index = 0
var bet_amount = 100
var bet_area = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
var lastWinIndex = -1
var isExit = false
var tick = 0
var wait = 0
var fakeBet = false
var t2 = 0
var timer = 0

var _client = WebSocketClient.new()
var history_result = preload("res://pck/assets/horse_bet/Result.tscn")
var road_texture = preload("res://pck/assets/horse_bet/road.jpg")
var road_alt_texture = preload("res://pck/assets/horse_bet/road_alt.jpg")
var music = preload("res://pck/assets/horse_bet/bg.ogg")

var GameVoices = {
	"exit":preload("res://pck/assets/common/audio/exit.ogg"),
	"new_game":preload("res://pck/assets/common/audio/new_game.ogg"),
}

var WinResult = [
	null,
	preload("res://pck/assets/horse_bet/r1.png"),
	preload("res://pck/assets/horse_bet/r2.png"),
	preload("res://pck/assets/horse_bet/r3.png"),
	preload("res://pck/assets/horse_bet/r4.png"),
	preload("res://pck/assets/horse_bet/r5.png"),
	preload("res://pck/assets/horse_bet/r6.png"),
]

# Called when the node enters the scene tree for the first time.
func _ready():
	$BackDrop._show("ကစားပြဲႏွင့္ခ်ိတ္ဆက္ေနသည္။ ခဏေစာင့္ေပးပါ။")
	$"/root/bgm".stream = music
	$"/root/bgm".play()
	websocket_url = $"/root/Config".config.gameState.url
	_connect_ws()
	_reset()

func _process(delta):
	_client.poll()
	if isRunning:
		$Road.position.x -= runSpeed*delta
	
	tick += delta
	if tick > wait && fakeBet :
		tick = 0
		wait = randf()+0.5
		_bot_bet()
	
	t2 += delta
	if t2 > 1:
		t2 = 0
		if timer > 0:
			timer -= 1
			$BetPanel/Timer/Label.text = str(timer)

func _connect_ws():
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")

	# Initiate connection to the given URL.
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)

func _closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	get_tree().change_scene("res://start/conn_error.tscn")
	#set_process(false)
	#_client = null

func _connected(proto = ""):
	var request = {
		"head":"handshake",
		"body":{
			"id":$"/root/Config".config.user.username,
			"passcode":$"/root/Config".config.gameState.passcode
		}
	}
	send(request)

func _on_data():
	var respond = _client.get_peer(1).get_packet().get_string_from_utf8();
	#print("From server: ", respond)
	print("")
	var obj = JSON.parse(respond);
	var res = obj.result
	_on_server_respond(res)

func send(data):
	var json = JSON.print(data)
	print("From client --- " + json)
	print("")
	_client.get_peer(1).put_packet(json.to_utf8())

func _on_server_respond(respond):
	print(respond)
	match respond.head:
		"handshake":
			_handshake_respond(respond.body)
		"bet":
			_bet_respond(respond.body)
		"start":
			_start(respond.body)
		"end":
			_end(respond.body)

func _handshake_respond(body):
	if body.status == "ok":
		$BetPanel/Balance.text = str(body.player.balance)

func _bet_respond(body):
	bet_area[body.index] += body.amount
	$BetPanel/Balance.text = str(body.player.balance)
	for i in range(15):
		$BetPanel/Buttons.get_node(str(i)).get_node("Me").text = str(body.player.bet[i])
		$BetPanel/Buttons.get_node(str(i)).get_node("Total").text = str(bet_area[i])

func _start(body):
	if isExit:
		get_tree().change_scene("res://pck/scenes/menu.tscn")
		return
	
	$BackDrop._hide()
	timer = body.timer
	_reset()
	_playVoice("new_game")
	for N in $BetPanel/LastResult/ResultTable/VBoxContainer.get_children():
		N.queue_free()
	
	for result in body.winHistory:
		var box = history_result.instance()
		var winIndex = result.winIndex
		var first = win_chart[winIndex][0]
		var second = win_chart[winIndex][1]
		var multi = result.multiply
		box.get_node("first").text = str(first)
		box.get_node("second").text = str(second)
		box.get_node("multiply").text = str(multi)
		$BetPanel/LastResult/ResultTable/VBoxContainer.add_child(box)
	
	for i in range(15):
		$BetPanel/Buttons.get_node(str(i)).get_node("Multiply").text = "x" + str(body.multipliers[i])
	$BetPanel/AnimationPlayer.play("show")
	if lastWinIndex != -1:
		var pos = $BetPanel/Buttons.get_node(str(lastWinIndex)).rect_global_position
		pos.x += 70
		pos.y += 70
		$BetPanel/Highlight.global_position = pos
	else :
		$BetPanel/Highlight.global_position = Vector2(-200,-200)
	
	yield(get_tree().create_timer(1), "timeout")
	fakeBet = true

func _end(body):
	$BackDrop._hide()
	fakeBet = false
	$BetPanel/AnimationPlayer.play("hide")
	
	$CountDown.visible = true
	var countdown = 6
	for i in range(5):
		countdown -= 1
		$CountDown/Label.text = str(countdown)
		$CountDown/Audio.play()
		yield(get_tree().create_timer(1), "timeout")
	$CountDown.visible = false
	
	lastWinIndex = body.winIndex
	$Audio/Whistle.play()
	$Audio/HorseRun.play()
	yield(get_tree().create_timer(1), "timeout")
	for N in $Horses.get_children():
		N.play("run")
		N.speed = 300
		N.target.x = (randi() % 200) + 900
	yield(get_tree().create_timer(2), "timeout")
	isRunning = true
	yield(get_tree().create_timer(2), "timeout")
	for N in $Horses.get_children():
		N.speed = 50
		N.target.x = (randi() % 200) + 900
	yield(get_tree().create_timer(2), "timeout")
	for N in $Horses.get_children():
		N.speed = 50
		N.target.x = (randi() % 200) + 900
	yield(get_tree().create_timer(2), "timeout")
	for N in $Horses.get_children():
		N.speed = 50
		N.target.x = (randi() % 200) + 900
	yield(get_tree().create_timer(2), "timeout")
	for N in $Horses.get_children():
		N.speed = 50
		N.target.x = (randi() % 200) + 900
	yield(get_tree().create_timer(2), "timeout")
	for N in $Horses.get_children():
		N.speed = 50
		N.target.x = (randi() % 200) + 900
	yield(get_tree().create_timer(3), "timeout")
	var winIndex = body.winIndex
	var first = win_chart[winIndex][0]
	var second = win_chart[winIndex][1]
	var third = win_chart[winIndex][2]
	for N in $Horses.get_children():
		if N.no == first :
			N.target.x = 1300
		elif N.no == second :
			N.target.x = 1200
		elif N.no == third :
			N.target.x = 1100
		else :
			N.target.x = (randi() % 200) + 800
	yield(get_tree().create_timer(5.5), "timeout")
	isRunning = false
	$Audio/HorseRun.stop()
	
	for N in $Horses.get_children():
		N.playing = false
	
	yield(get_tree().create_timer(1), "timeout")
	
	$"ResultStage/1".texture = WinResult[first]
	$"ResultStage/2".texture = WinResult[second]
	$ResultStage/WinAmount/Label.text = "x" + str(body.multiplier) + " " + str(body.player.winAmount)
	$ResultStage/AnimationPlayer.play("show")
	$BetPanel/Balance.text = str(body.player.balance)

func _reset():
	isRunning = false
	$Road.position.x = 0
	for i in range(15):
		bet_area[i] = 0
		$BetPanel/Buttons.get_node(str(i)).get_node("Me").text = "0"
		$BetPanel/Buttons.get_node(str(i)).get_node("Total").text = "0"
	for N in $Road.get_children():
		N.queue_free()
	for i in range(20):
		var sprite = Sprite.new()
		if i == 0 || i == 13:
			sprite.texture = road_alt_texture
		else :
			sprite.texture = road_texture
		sprite.position = Vector2((i*500) + 250,450)
		$Road.add_child(sprite)
	for N in $Horses.get_children():
		N.position.x = 200
		N.target.x = 200
		N.play("idle")

func _balance_round(balance):
	if(balance >= 1000):
		var d = stepify(balance/1000, 0.1)
		return str(d) + " K"
	else:
		return str(balance)

func _on_bet(index):
	$Audio/CoinMove.play()
	var request = {
		"head":"bet",
		"body":{
			"amount":bet_amount,
			"index":index
		}
	}
	send(request)

func _bot_bet():
	$Audio/CoinMove.play()
	var b = randi() % 15
	var r = randi() % 4
	bet_area[b] += bet_arr[r]
	for i in range(15):
		$BetPanel/Buttons.get_node(str(i)).get_node("Total").text = str(bet_area[i])

func _on_Exit_pressed():
	isExit = true
	_playVoice("exit")

func _playVoice(key):
	$Audio/GameVoice.stream = GameVoices[key]
	$Audio/GameVoice.play()

func _on_bet_select(index):
	bet_amount = bet_arr[index]
	var sel = $BetPanel/BetSelect.get_node(str(index))
	var pos = sel.rect_position
	pos.x += 50
	pos.y += 50
	$BetPanel/BetSelect/Select.position = pos
