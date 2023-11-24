extends Node

var CARD_DELIVER_DELAY = 0.2

var betArr = [100,500,1000,2000,10000,50000]
var betArea = []
var betAmount = [0,0,0,0]
var myBetAmount = [0,0,0,0]
var bot = []
var botBalance = [0,0,0,0,0,0,0]
var fakeBet = false
var isExit = false
var wait = 1
var tick = 0
var websocket_url = ""
var selectedBet = 0
var cardPos = []
var profile_textures = []
var card_textures = {}
var t2 = 0
var timer = 0

var _client = WebSocketClient.new()

var CardStatusVoices = [
	preload("res://pck/assets/skm_bet/audio/0.ogg"),
	preload("res://pck/assets/skm_bet/audio/1.ogg"),
	preload("res://pck/assets/skm_bet/audio/2.ogg"),
	preload("res://pck/assets/skm_bet/audio/3.ogg"),
	preload("res://pck/assets/skm_bet/audio/4.ogg"),
	preload("res://pck/assets/skm_bet/audio/5.ogg"),
	preload("res://pck/assets/skm_bet/audio/6.ogg"),
	preload("res://pck/assets/skm_bet/audio/7.ogg"),
	preload("res://pck/assets/skm_bet/audio/8.ogg"),
	preload("res://pck/assets/skm_bet/audio/9.ogg"),
]

var music = preload("res://pck/assets/audio/music-2.mp3")
var coinPrefab = preload("res://pck/prefabs/Coin.tscn")
var cardPrefab = preload("res://pck/assets/skm_bet/Card.tscn")
var historyPrefab = preload("res://pck/assets/skm_bet/HistoryRow.tscn")

const historyTextures = [
	preload("res://pck/assets/skm_bet/history-win.png"),
	preload("res://pck/assets/skm_bet/history-lose.png")
]

const resultTextures = {
	"win":preload("res://pck/assets/shankoemee/win.png"),
	"lose":preload("res://pck/assets/shankoemee/lose.png")
}

var GameVoices = {
	"exit":preload("res://pck/assets/common/audio/exit.ogg"),
	"new_game":preload("res://pck/assets/common/audio/new_game.ogg")
}

# Called when the node enters the scene tree for the first time.
func _ready():
	$"/root/bgm".stream = music
	$"/root/bgm".play()
	_load_profile_textures()
	
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
	
	for u in $CardPos.get_children():
		var arr = []
		for c in u.get_children():
			arr.append(c.global_position) 
		cardPos.append(arr)
	$CardPos.queue_free()
	print(cardPos)
	
	bot.append($Bots/Bot1)
	bot.append($Bots/Bot2)
	bot.append($Bots/Bot3)
	bot.append($Bots/Bot4)
	bot.append($Bots/Bot5)
	bot.append($Bots/Bot6)
	bot.append($Bots/Bot7)
	
	betArea.append($BetArea/B1)
	betArea.append($BetArea/B2)
	betArea.append($BetArea/B3)
	betArea.append($BetArea/B4)
	
	websocket_url = $"/root/Config".config.gameState.url
	_connect_ws()
	_reset()
	$BackDrop._show("ကစားပြဲႏွင့္ခ်ိတ္ဆက္ေနသည္။ ခဏေစာင့္ေပးပါ။")

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
	#print("From client --- " + json)
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

func _start(body):
	if isExit:
		get_tree().change_scene("res://pck/scenes/menu.tscn")
		return
	
	_reset()
	
	$BackDrop._hide()
	timer = body.timer
	_playVoice("new_game")
	
	# Show history
	for N in $History/VBoxContainer.get_children():
		N.queue_free()
	for h in body.history:
		var row = historyPrefab.instance()
		for i in range(4):
			if _array_include(h,i):
				row.get_node(str(i)).texture = historyTextures[0]
		$History/VBoxContainer.add_child(row)
	
	for p in $Pauk.get_children():
		p.visible = false
	
	$ShanMa.play("deliver")
	
	for i in range(5):
		var sprite = cardPrefab.instance()
		sprite.position = $CardHome.position
		sprite.target = cardPos[i][0]
		var card = body.cards[i][0]
		var key = str(card.rank)+str(card.shape)
		sprite.texture = card_textures[key]
		$Cards.add_child(sprite)
		yield(get_tree().create_timer(CARD_DELIVER_DELAY), "timeout")
	
	for i in range(5):
		var sprite = cardPrefab.instance()
		sprite.position = $CardHome.position
		sprite.target = cardPos[i][1]
		$Cards.add_child(sprite)
		yield(get_tree().create_timer(CARD_DELIVER_DELAY), "timeout")
	
	yield(get_tree().create_timer(1), "timeout")
	
	$ShanMa.play("idle")
	
	fakeBet = true

func _end(body):
	if fakeBet == false:
		return
	fakeBet = false
	var winners = []
	for w in body.winners:
		winners.append(w)
	yield(get_tree().create_timer(1), "timeout")
	
	#Show second card
	var cards = $Cards.get_children()
	for i in range(5):
		var card = body.cards[i][1]
		var key = str(card.rank)+str(card.shape)
		cards[i+5].texture = card_textures[key]
	
	yield(get_tree().create_timer(1), "timeout")
	
	# Deliver third card
	for i in range(5):
		var card = body.cards[i][2]
		if card:
			var sprite = cardPrefab.instance()
			sprite.position = $CardHome.position
			sprite.target = cardPos[i][2]
			var key = str(card.rank)+str(card.shape)
			sprite.texture = card_textures[key]
			$Cards.add_child(sprite)
			yield(get_tree().create_timer(CARD_DELIVER_DELAY), "timeout")
	
	yield(get_tree().create_timer(1), "timeout")
	
	for i in range(5):
		if body.pauk[i] == 0:
			$Pauk.get_node(str(i)+"/Label").text = "bl"
		else :
			$Pauk.get_node(str(i)+"/Label").text = str(body.pauk[i]) + " ayguf"
		yield(get_tree().create_timer(0.5), "timeout")
		$Pauk.get_node(str(i)).visible = true
		_playCardStatus(body.pauk[i])
		yield(get_tree().create_timer(0.5), "timeout")
	
	yield(get_tree().create_timer(1), "timeout")
	
	var j = 0
	for f in $ResultFlag.get_children():
		if _array_include(winners,j):
			f.texture = resultTextures["win"]
		else :
			f.texture = resultTextures["lose"]
		f.visible = true
		yield(get_tree().create_timer(0.25), "timeout")
		j += 1
	
	# Move lose coin
	var winCoinCount = [0,0,0,0]
	$Audio/CoinMove.play()
	for coin in $CoinContainer.get_children():
		if _array_include(winners,coin.playerIndex):
			winCoinCount[coin.playerIndex] += 1
		else :
			coin.target = $DealerHome.global_position
			coin.destroyOnArrive = true
	
	var a = 0
	for N in $AmountTransfer.get_children():
		if !_array_include(winners,a) && myBetAmount[a] > 0:
			N.set("custom_colors/font_color", Color(1,0,0))
			N.text = "-" + str(myBetAmount[a])
			N.visible = true
		a += 1
	
	yield(get_tree().create_timer(1), "timeout")
	
	# Move win coin
	$Audio/CoinMove.play()
	for k in winners:
		for i in range(winCoinCount[k]):
			var coin = coinPrefab.instance()
			coin.position = $DealerHome.global_position
			var rx = (randi() % 100) - 50
			var ry = (randi() % 100) - 50
			var rb = randi() % 4
			var target = betArea[k].global_position
			target.x += rx
			target.y += ry
			coin.target = target
			coin.playerIndex = k
			$CoinContainer.add_child(coin)
	
	yield(get_tree().create_timer(0.5), "timeout")
	
	for k in winners:
		if myBetAmount[k] > 0 :
			$AmountTransfer.get_node(str(k)).set("custom_colors/font_color", Color(1,1,0))
			$AmountTransfer.get_node(str(k)).text = "+" + str(myBetAmount[k])
			$AmountTransfer.get_node(str(k)).visible = true
	
	yield(get_tree().create_timer(0.5), "timeout")
	
	# Refund coin to player
	for k in winners:
		var t = 0
		var playerWinCoin = 2
		$Audio/CoinMove.play()
		for coin in $CoinContainer.get_children():
			if myBetAmount[k] > 0 && t < playerWinCoin && coin.playerIndex == k :
				coin.target = $Profile.global_position
				coin.destroyOnArrive = true
				coin.playerIndex = -2
				t += 1
	
	# Refund coin to bot
	for k in winners:
		for coin in $CoinContainer.get_children():
			if coin.playerIndex == k:
				var r = randi() % 10
				if r >= 7:
					coin.target = $Bots/Players.global_position
				else :
					coin.target = bot[r].global_position
				coin.destroyOnArrive = true
				coin.playerIndex = -2
	
	$Profile/Panel/Balance.text = str(body.player.balance)

func _handshake_respond(body):
	if body.status == "ok":
		$Profile/Panel/Nickname.text = body.player.info.nickname
		$Profile/Panel/Balance.text = str(body.player.balance)
		$Profile/Img.texture = profile_textures[body.player.info.profile]

func _bet_respond(body):
	$Profile/Panel/Balance.text = str(body.player.balance)
	betAmount[body.index] += body.amount
	myBetAmount[body.index] += body.amount
	betArea[body.index].get_node("Btn/Total").text = _balance_round(betAmount[body.index])
	betArea[body.index].get_node("Btn/Me").text = _balance_round(myBetAmount[body.index])
	$Audio/CoinMove.play()
	var coin = coinPrefab.instance()
	coin.position = $Profile.global_position
	coin.playerIndex = body.index
	var rx = (randi() % 100) - 50
	var ry = (randi() % 100) - 50
	var target = betArea[body.index].global_position
	target.x += rx
	target.y += ry
	coin.target = target
	$CoinContainer.add_child(coin)

func _load_profile_textures():
	for i in range(13):
		var path = "res://pck/assets/common/profiles/" + str(i) + ".png"
		var texture = load(path)
		profile_textures.append(texture) 

func _reset():
	for i in range(7):
		var balance = (randi() % 100000) + 100000
		botBalance[i] = balance
		bot[i].get_node("Panel/Balance").text = _balance_round(balance)
		bot[i].get_node("Profile").texture = profile_textures[randi()%13]
	betAmount = [0,0,0,0]
	myBetAmount = [0,0,0,0]
	for i in range(4):
		betArea[i].get_node("Btn/Total").text = _balance_round(betAmount[i])
		betArea[i].get_node("Btn/Me").text = _balance_round(myBetAmount[i])
	for coin in $CoinContainer.get_children():
		coin.queue_free()
	for card in $Cards.get_children():
		card.queue_free()
	for f in $ResultFlag.get_children():
		f.visible = false
	for N in $AmountTransfer.get_children():
		N.visible = false

func _process(delta):
	_client.poll()
	
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
			$Timer/Label.text = str(timer)
			$Timer.visible = true
		else :
			$Timer.visible = false

func _bot_bet():
	$Audio/CoinMove.play()
	for i in range(7):
		var r = randi() % 12
		if r < 4:
			var coin = coinPrefab.instance()
			coin.position = bot[i].position
			var rx = (randi() % 100) - 50
			var ry = (randi() % 100) - 50
			var rb = randi() % 4
			var target = betArea[rb].global_position
			target.x += rx
			target.y += ry
			coin.target = target
			coin.playerIndex = rb
			$CoinContainer.add_child(coin)
			var amt = betArr[r]
			botBalance[i] -= amt
			betAmount[rb] += amt
			bot[i].get_node("Panel/Balance").text = _balance_round(botBalance[i])
			betArea[rb].get_node("Btn/Total").text = _balance_round(betAmount[rb])
	# Players bet
	var t = randi() % 4 + 1
	for i in range(t):
		var coin = coinPrefab.instance()
		coin.position = $Bots/Players.position
		var rx = (randi() % 100) - 50
		var ry = (randi() % 100) - 50
		var rb = randi() % 4
		var target = betArea[rb].global_position
		target.x += rx
		target.y += ry
		coin.target = target
		coin.playerIndex = rb
		$CoinContainer.add_child(coin)
		var amt = betArr[(randi() % 3)]
		betAmount[rb] += amt
		betArea[rb].get_node("Btn/Total").text = _balance_round(betAmount[rb])
		yield(get_tree().create_timer(0.15), "timeout")

func _on_bet_select(index):
	var sel = $BetSelect.get_node(str(index))
	var pos = sel.rect_position
	pos.x += 50
	pos.y += 50
	$BetSelect/Select.position = pos
	selectedBet = index

func _on_bet(index):
	var amount = betArr[selectedBet]
	var request = {
		"head":"bet",
		"body":{
			"amount":amount,
			"index":index
		}
	}
	send(request)

func _balance_round(balance):
	if(balance >= 1000):
		var d = stepify(balance/1000, 0.1)
		return str(d) + " K"
	else:
		return str(balance)

func _playCardStatus(pauk):
	$Audio/GameVoice.stream = CardStatusVoices[pauk]
	$Audio/GameVoice.play()

func _array_include(arr,value):
	for item in arr:
		if item == value:
			return true
	return false

func _on_Exit_pressed():
	isExit = true
	_playVoice("exit")

func _playVoice(key):
	$Audio/GameVoice.stream = GameVoices[key]
	$Audio/GameVoice.play()
