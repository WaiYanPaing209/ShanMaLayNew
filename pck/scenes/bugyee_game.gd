extends Node


# Configuration
const TOTAL_PLAYER = 7
const CARD_DELIVER_DELAY = 0.05
const COIN_MOVE_DELAY = 0.1
const SERVER_INTERVAL = 2

# Static
const music = preload("res://pck/assets/audio/music-2.mp3")

const GameStates = {
	"wait": 0,
	"start": 1,
	"deliver": 2,
	"end": 3,
};

var CardStatusVoices = [
	preload("res://pck/assets/common/audio/0.ogg"),
	preload("res://pck/assets/common/audio/1.ogg"),
	preload("res://pck/assets/common/audio/2.ogg"),
	preload("res://pck/assets/common/audio/3.ogg"),
	preload("res://pck/assets/common/audio/4.ogg"),
	preload("res://pck/assets/common/audio/5.ogg"),
	preload("res://pck/assets/common/audio/6.ogg"),
	preload("res://pck/assets/common/audio/7.ogg"),
	preload("res://pck/assets/common/audio/8.ogg"),
	preload("res://pck/assets/common/audio/9.ogg"),
	preload("res://pck/assets/common/audio/10.ogg"),
	preload("res://pck/assets/common/audio/11.ogg"),
]

var GameVoices = {
	"deliver":preload("res://pck/assets/shankoemee/audio/deliver.ogg"),
	"exit":preload("res://pck/assets/shankoemee/audio/exit.ogg"),
	"lose":preload("res://pck/assets/shankoemee/audio/lose.ogg"),
	"new_game":preload("res://pck/assets/shankoemee/audio/new_game.ogg"),
	"new_game_dealer":preload("res://pck/assets/shankoemee/audio/new_game_dealer.ogg"),
	"wait_game":preload("res://pck/assets/shankoemee/audio/wait_game.ogg"),
	"win":preload("res://pck/assets/shankoemee/audio/win.ogg"),
	"win_effect":preload("res://pck/assets/shankoemee/audio/win_effect.mp3"),
}

const playerPrefab = preload("res://pck/assets/bugyee/player.tscn")
const cardPrefab = preload("res://pck/assets/bugyee/card.tscn")
const coinPrefab = preload("res://pck/prefabs/Coin.tscn")

# System Variables
var playersNode = []
var card_textures = {}
var myIndex = 0
var prev_gameState = GameStates.wait
var _room = null
var bet_array = [100,200,300,500]
var minBet = 0
var isStart = true
var isWaitVoicePlayed = false
var countdown = 0;
var tick = 0;
var websocket_url = ""


var _client = WebSocketClient.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	$"/root/bgm".stream = music
	$"/root/bgm".play()
	_init_all()
	
	websocket_url = $"/root/Config".config.gameState.url
	_connect_ws()

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

func _process(delta):
	_client.poll()
	tick += delta
	if tick > 1:
		tick = 0
		if countdown > 0:
			countdown -= 1
			$CardCheck/Timer.text = str(countdown)
			$Timer.text = str(countdown)

func send(data):
	var json = JSON.print(data)
	print("From client --- " + json)
	print("")
	_client.get_peer(1).put_packet(json.to_utf8())

func _on_server_respond(respond):
	var body = respond.body
	print(body)
	match respond.head:
		"room info":
			if body == null :
				get_tree().change_scene("res://pck/scenes/menu.tscn")
				return
			_update_room(body)
		"emoji":
			_emoji_respond(body.senderIndex, body.emoji)
		"exit":
			pass
		"handshake":
			_handshake(body)
		"message":
			_message_respond(body.senderIndex, body.message)

# ----- Main Functions -----

func _init_all():
	for i in range(TOTAL_PLAYER):
		var player = playerPrefab.instance()
		player.position = $PlayerPos.get_node(str(i)).position
		if i == 4 || i == 5 :
			player.get_node("CardPos").position.x = -200
			player.get_node("CardStatus").position.x = -200
		playersNode.append(player)
		$Players.add_child(player)
	
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
	
	$MenuPanel.visible = false
	$CardCheck.visible = false
	$BetPanel.visible = false
	$Rules.visible = false

func _update_room(room):
	if minBet == 0:
		minBet = room.minBet
	
	if room.players[myIndex] == null:
		get_tree().change_scene("res://pck/scenes/menu.tscn")
		return
		
	if room.players[myIndex].isWaiting:
		if !isWaitVoicePlayed:
			_playVoice(GameVoices.wait_game)
			isWaitVoicePlayed = true
	
	# Game States
	if room.gameState == GameStates.start:
		_start(room)
	elif room.gameState == GameStates.deliver:
		_deliver(room)
	elif room.gameState == GameStates.end:
		_end(room)
	elif room.gameState == GameStates.wait:
		_wait()

func _handshake(body):
	if body.status == "ok":
		myIndex = body.index
		var request = {
			"head":"room info"
		}
		send(request)

func _emoji_respond(senderIndex, emoji):
	$Audio/Emoji.play()
	var v = _get_vIndex(senderIndex)
	playersNode[v]._play_emoji(emoji)

func _message_respond(senderIndex, msg):
	var v = _get_vIndex(senderIndex)
	playersNode[v]._play_message(msg)

func _submit_card(cards):
	var N = $Cards.get_node("0")
	var arr = N.get_children()
	for i in range(5):
		var card = cards[i]
		var sprite = arr[i]
		var key = str(card.rank)+str(card.shape)
		sprite.texture = card_textures[key]
	var request = {
		"head":"reorder",
		"body":cards
		}
	send(request)

func _on_Bet_select(index):
	$BetPanel.visible = false
	var bet = minBet * index
	
	var x = bet / minBet
	playersNode[0]._show_bet(x)
	
	var request = {
		"head":"bet",
		"body":bet
		}
	send(request)

# ----- Game State Functions -----

func _start(room):
	_common_update(room)
	if room.gameState == prev_gameState:
		return
	prev_gameState = room.gameState
	print("Game State : Start")
	$ShanMa.play("shuffle")
	
	# Set Timer
	countdown = (room.wait - room.tick) * SERVER_INTERVAL
	
	_clear_all_player_cards()
	_reset_all_player()
	if myIndex != room.dealerIndex :
		$BetPanel.visible = true
		_playVoice(GameVoices.new_game)
	else :
		_playVoice(GameVoices.new_game_dealer)
	
	if !room.players[myIndex].isWaiting :
		$BackDrop._hide()

func _deliver(room):
	_common_update(room)
	if room.gameState == prev_gameState:
		return
	prev_gameState = room.gameState
	print("Game State : Deliver")
	$BetPanel.visible = false
	$ShanMa.play("deliver")
	
	# Set Timer
	countdown = (room.wait - room.tick) * SERVER_INTERVAL
	
	for i in range(TOTAL_PLAYER):
		var player = room.players[i]
		if player == null:
			continue
		if player.isWaiting:
			continue
		if i == room.dealerIndex:
			continue
		print(player.info.nickname + " bet " + str(player.bet))
		print("Min Bet : " + str(minBet))
		var x = player.bet / minBet
		var v = _get_vIndex(i)
		playersNode[v]._show_bet(x)
	
	yield(get_tree().create_timer(1), "timeout")
	
	_playVoice(GameVoices.deliver)
	for j in range(5):
		for i in range(TOTAL_PLAYER):
			var player = room.players[i]
			if player == null:
				continue
			if player.isWaiting:
				continue
			var v = _get_vIndex(i)
			var card = player.cards[j]
			var pos = playersNode[v].cardPosArray[j]
			_deliver_card(card,pos,v)
			yield(get_tree().create_timer(CARD_DELIVER_DELAY), "timeout")
	
	yield(get_tree().create_timer(1), "timeout")
	
	$ShanMa.play("idle")
	$CardCheck._show(room.players[myIndex].cards)

func _end(room):
	if room.gameState == prev_gameState:
		return
	prev_gameState = room.gameState
	print("Game State : End")
	$CardCheck._hide()
	_show_all_player_cards(room)
	
	var dealer = room.players[room.dealerIndex]
	var vd = _get_vIndex(room.dealerIndex)
	var dealerNode = playersNode[vd]
	dealerNode._show_card_status(dealer.cardStatus)
	_playVoice(CardStatusVoices[dealer.cardStatus])
	
	yield(get_tree().create_timer(2), "timeout")
	
	var losers = room.losers
	if losers.size() > 0 :
		for i in losers :
			var player = room.players[i]
			var v = _get_vIndex(i)
			playersNode[v]._show_card_status(player.cardStatus)
			_playVoice(CardStatusVoices[player.cardStatus])
			yield(get_tree().create_timer(1), "timeout")
			playersNode[v]._show_result_flag(false)
			playersNode[v]._transfer_balance(-player.loseAmount)
			var count = ceil(player.loseAmount / minBet)
			$Audio/CoinMove.play()
			for j in range(count):
				_coin_move(i,room.dealerIndex)
				yield(get_tree().create_timer(0.05), "timeout")
			yield(get_tree().create_timer(1), "timeout")
	
	var winners = room.winners
	if winners.size() > 0 :
		for i in winners :
			var player = room.players[i]
			var v = _get_vIndex(i)
			playersNode[v]._show_card_status(player.cardStatus)
			_playVoice(CardStatusVoices[player.cardStatus])
			yield(get_tree().create_timer(1), "timeout")
			playersNode[v]._show_result_flag(true)
			playersNode[v]._transfer_balance(player.winAmount)
			var count = ceil(player.winAmount / minBet)
			$Audio/CoinMove.play()
			for j in range(count):
				_coin_move(room.dealerIndex,i)
				yield(get_tree().create_timer(0.05), "timeout")
			yield(get_tree().create_timer(1), "timeout")
		
	_common_update(room)

func _wait():
	pass

# ----- Utility Functions -----

func _common_update(room):
	# Dealer Crown
	var vd = _get_vIndex(room.dealerIndex)
	var bankerPos = $PlayerPos.get_node(str(vd)).position
	bankerPos.y -= 100
	$Banker.position = bankerPos
	
	# Players
	var players = room.players
	for i in range(TOTAL_PLAYER):
		var v = _get_vIndex(i)
		var N = playersNode[v]
		var player = players[i]
		if player == null:
			N.visible = false
			continue
		N.visible = true
		N._set_info(player.info.nickname, player.balance, player.info.profile)

func _deliver_card(card,pos,index):
	var sprite = cardPrefab.instance()
	var key = str(card.rank)+str(card.shape)
	sprite.position = $CardHome.position
	sprite.target = pos
	$Cards.get_node(str(index)).add_child(sprite)
	$Audio/CardMove.play()

func _clear_all_player_cards():
	for i in range(TOTAL_PLAYER):
		var cards = $Cards.get_node(str(i))
		for card in cards.get_children():
			card.queue_free()

func _show_all_player_cards(room):
	for i in range(TOTAL_PLAYER):
		var player  = room.players[i]
		if player == null:
			continue
		if player.isWaiting:
			continue
		_show_player_cards(i,player.cards)

func _show_player_cards(i,cards):
	var v = _get_vIndex(i)
	var N = $Cards.get_node(str(v))
	var arr = N.get_children()
	for j in range(5):
		var card = cards[j]
		var sprite = arr[j]
		var key = str(card.rank)+str(card.shape)
		sprite.texture = card_textures[key]

func _reset_all_player():
	for N in playersNode:
		N._reset()

func _playVoice(voice):
	$Audio/GameVoice.stream = voice
	$Audio/GameVoice.play()

func _get_vIndex(index):
	var a = index - myIndex
	if a < 0:
		a += TOTAL_PLAYER
	return a

func _get_aIndex(vIndex):
	var a = myIndex + vIndex
	if a >= TOTAL_PLAYER:
		a -= TOTAL_PLAYER
	return a

# ----- Coin Move Functions -----

func _coin_move(from,to):
	var coin = coinPrefab.instance()
	var v1 = _get_vIndex(from)
	var v2 = _get_vIndex(to)
	var pos1 = playersNode[v1].get_node("Profile").global_position
	var pos2 = playersNode[v2].get_node("Profile").global_position
	coin.destroyOnArrive = true
	coin.position = pos1
	var xRand = (randi()%60)-30
	var yRand = (randi()%60)-30
	var x = pos2.x + xRand
	var y = pos2.y + yRand
	var target = Vector2(x,y)
	coin.target = target
	$CoinContainer.add_child(coin)

func _on_Menu_pressed():
	$MenuPanel.visible = !$MenuPanel.visible

func _on_Exit_pressed():
	var request = {
		"head":"exit",
	}
	send(request)
	$MenuPanel.visible = false
	_playVoice(GameVoices.exit)

# ----- Emoji Functions -----

func _on_EmojiToggle_pressed():
	$EmojiPanel.visible = !$EmojiPanel.visible

func _on_Emoji_pressed(emoji):
	var request = {
		"head":"emoji",
		"body":{
			"senderIndex":myIndex,
			"emoji":emoji
		}
	}
	send(request)
	$EmojiPanel.visible = false

func _on_Rules_pressed():
	$Rules.visible = true

func _on_GameRules_Close_pressed():
	$Rules.visible = false

func _on_Setting_pressed():
	$Setting._show()

func _on_MessageToggle_pressed():
	$MessagePanel.visible = !$MessagePanel.visible

func _on_message_pressed(msg):
	var request = {
		"head":"message",
		"body":{
			"senderIndex":myIndex,
			"message":msg
		}
	}
	send(request)
	$MessagePanel.visible = false
