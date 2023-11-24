extends Node2D

# Configuration
const TOTAL_PLAYER = 9
const CARD_DELIVER_DELAY = 0.15
const COIN_MOVE_DELAY = 0.1
const CARD_CHECK_TIME = 3

# Static
const music = preload("res://pck/assets/audio/music-2.mp3")

const GameStates = {
	"wait": 0,
	"start": 1,
	"firstDeliver": 2,
	"secondDeliver": 3,
	"dealerDraw": 4,
	"end": 5,
	"destory": 6,
};

const PlayStates = {
	"waiting": 0,
	"uncatch": 1,
	"win": 2,
	"lose": 3,
};

var GameVoices = {
	"catch":preload("res://pck/assets/shankoemee/audio/catch.ogg"),
	"catch_all":preload("res://pck/assets/shankoemee/audio/catch_all.ogg"),
	"change_dealer":preload("res://pck/assets/shankoemee/audio/change_dealer.ogg"),
	"deliver":preload("res://pck/assets/shankoemee/audio/deliver.ogg"),
	"draw_card":preload("res://pck/assets/shankoemee/audio/draw_card.ogg"),
	"exit":preload("res://pck/assets/shankoemee/audio/exit.ogg"),
	"lose":preload("res://pck/assets/shankoemee/audio/lose.ogg"),
	"new_game":preload("res://pck/assets/shankoemee/audio/new_game.ogg"),
	"new_game_dealer":preload("res://pck/assets/shankoemee/audio/new_game_dealer.ogg"),
	"wait_game":preload("res://pck/assets/shankoemee/audio/wait_game.ogg"),
	"win":preload("res://pck/assets/shankoemee/audio/win.ogg"),
	"win_effect":preload("res://pck/assets/shankoemee/audio/win_effect.mp3"),
	"dealer_cannot_exit":preload("res://pck/assets/shankoemee/audio/dealer_cannot_exit.ogg"),
	"pauk8":preload("res://pck/assets/shankoemee/audio/pauk8.ogg"),
	"pauk9":preload("res://pck/assets/shankoemee/audio/pauk9.ogg"),
}

const playerPrefab = preload("res://pck/assets/shankoemee/skm_player.tscn")
const cardPrefab = preload("res://pck/prefabs/shankoemee/card.tscn")
const coinPrefab = preload("res://pck/prefabs/Coin.tscn")

# System Variables
var playersNode = []
var card_textures = {}
var myIndex = 0
var prev_gameState = GameStates.wait
var _room = null
var bet_array = [100,200,300,500]
var bet_amount = 0
var isStart = true
var isWaitVoicePlayed = false
var websocket_url = ""

var _client = WebSocketClient.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	$"/root/bgm".stream = music
	$"/root/bgm".play()
	_init_all()
	websocket_url = $"/root/Config".config.gameState.url
	_connect_ws()
	
#	if $"/root/ws".rejoin :
#		$BackDrop._show("Reconnecting please wait!")
#		return


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
			if body.room == null :
				get_tree().change_scene("res://pck/scenes/menu.tscn")
				return
			_update_room(body.room)
		"emoji":
			_emoji_respond(body.senderIndex, body.emoji)
		"exit":
			_exit_respond(body.status)
		"handshake":
			_handshake(body)
		"message":
			_message_respond(body.senderIndex, body.message)


# ----- Main Functions -----

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

func _exit_respond(status):
	if status == "allow":
		_playVoice(GameVoices.exit)
	elif status == "not allow":
		# Dealer cannot exit
		_playVoice(GameVoices.dealer_cannot_exit)


func _update_room(room):
	if room.players[myIndex] == null:
		get_tree().change_scene("res://pck/scenes/menu.tscn")
		return
		
	if room.gameState != GameStates.start && isStart:
		if isWaitVoicePlayed:
			return
		_playVoice(GameVoices.wait_game)
		isWaitVoicePlayed = true
	
	# Game States
	if room.gameState == GameStates.start:
		_start(room)
	elif room.gameState == GameStates.firstDeliver:
		_first_deliver(room)
	elif room.gameState == GameStates.secondDeliver:
		_second_deliver(room)
	elif room.gameState == GameStates.dealerDraw:
		_dealer_draw(room)
	elif room.gameState == GameStates.end:
		_end(room)
	elif room.gameState == GameStates.wait:
		_wait()


func _init_all():
	for i in range(TOTAL_PLAYER):
		var player = playerPrefab.instance()
		player.position = $PlayerPos.get_node(str(i)).position
		player.get_node("Bet").position = $PlayerPos.get_node(str(i)+"/Bet").position
		player.get_node("Catch").connect("pressed",self,"_on_Catch_pressed",[i])
		if i == 5 || i == 6 || i == 7 :
			player.get_node("Catch").rect_position.x = -211
			player.get_node("CardPos").position.x = -147.5
			player.get_node("Multiply").position.x = -98
			player.get_node("PaukFlag").position.x = -135.5
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
	
	$BetPanel.visible = false
	$DrawBtns.visible = false
	$DealerWinScene.visible = false
	$DealerLoseScene.visible = false
	$MenuPanel.visible = false
	$Rules.visible = false;
	$CatchAllDraw.visible = false


# ----- Game State Functions -----


func _wait():
	$BackDrop._show()


func _start(room):
	$ShanMa.play("shuffle")
	_check_dealer_change(room)
	_check_player_bet_for_coin_move(room)
	_room = room
	$BackDrop._hide()
	_common_update(room)
	
	if room.gameState == prev_gameState:
		return
	prev_gameState = room.gameState
	
	_move_all_coin_from_player_bet_to_balance()
	_set_bet_buttons(room.minBet, room.dealerBet)
	
	# Set Count Down
	var count_down = (room.wait - room.tick) * 2
	var v = _get_vIndex(myIndex)
	playersNode[v]._set_count_down(count_down)
	
	# Dealer Count
	if room.warning:
		$GameCount/Label.text = "0rfwdef ("+str(room.dealerCount+1)+") cg"
		$GameCount/AnimationPlayer.play("show")
	
	bet_amount = 0
	if room.dealerIndex == myIndex :
		_playVoice(GameVoices.new_game_dealer)
	else:
		_playVoice(GameVoices.new_game)
		$BetPanel/Amount.text = str(bet_amount)
		$BetPanel.visible = true
	_clear_all_player_cards()
	_reset_all_players()


func _first_deliver(room):
	_check_player_bet_for_coin_move(room)
	_room = room
	_common_update(room)
	
	if room.gameState == prev_gameState:
		return
	prev_gameState = room.gameState
	
	print("Game State : First Deliver")
	$ShanMa.play("deliver")
	
	var players = room.players
	
	# Set Count Down
	var count_down = (room.wait - room.tick) * 2
	for i in range(TOTAL_PLAYER):
		var player = players[i]
		var v = _get_vIndex(i)
		playersNode[v]._set_count_down(count_down)
	
	_playVoice(GameVoices.deliver)
	$BetPanel.visible = false
	var start = room.dealerIndex + 1
	for j in range(2):
		for i in range(TOTAL_PLAYER):
			var k = start + i
			if k >= TOTAL_PLAYER:
				k = k - TOTAL_PLAYER
			var player = players[k]
			if player == null:
				continue
			if player.playState == PlayStates.waiting:
				continue
			var v = _get_vIndex(k)
			var card = player.cards[j]
			var pos = playersNode[v].get_node("CardPos").global_position
			pos.x += 20 * j
			_deliver_card(card,pos,v)
			yield(get_tree().create_timer(CARD_DELIVER_DELAY), "timeout")
	
	if players[myIndex].playState == PlayStates.waiting:
		return
	
	yield(get_tree().create_timer(1), "timeout")
	$ShanMa.play("idle")
	if room.dealerIndex != myIndex :
		$DrawBtns.visible = true
		$DrawBtns.position = Vector2(1000,800)
	$CardCheck._show(players[myIndex].cards)
	yield(get_tree().create_timer(CARD_CHECK_TIME), "timeout")
	$CardCheck._hide()
	$DrawBtns.position = Vector2(1760,800)
	
	_show_player_cards(myIndex)
	_show_all_auto(room.players)
	
	var dealer = players[room.dealerIndex]
	var pauk = _get_pauk(dealer.cards)
	if pauk >= 8:
		$DrawBtns.visible = false
	
	var me = players[myIndex]
	var myPauk = _get_pauk(me.cards)
	if myPauk >= 8:
		$DrawBtns.visible = false
		if myPauk == 8:
			_playVoice(GameVoices.pauk8)
		elif myPauk == 9:
			_playVoice(GameVoices.pauk9)


func _second_deliver(room):
	_room = room
	_common_update(room)
	if room.gameState == prev_gameState:
		return
	prev_gameState = room.gameState
	print("Game State : Second Deliver")
	$DrawBtns.visible = false
	var players = room.players
	
	# Set Count Down
	var count_down = (room.wait - room.tick) * 2
	for i in range(TOTAL_PLAYER):
		var player = players[i]
		if player == null :
			continue
		if player.cards.size() == 2 :
			continue
		var v = _get_vIndex(i)
		playersNode[v]._set_count_down(count_down)
	
	var start = room.dealerIndex + 1
	for i in range(TOTAL_PLAYER):
		var k = start + i
		if k >= TOTAL_PLAYER:
			k = k - TOTAL_PLAYER
		var player = players[k]
		if player == null:
			continue
		if player.playState == PlayStates.waiting:
			continue
		if player.cards.size() == 3:
			var v = _get_vIndex(k)
			var card = player.cards[2]
			var pos = playersNode[v].get_node("CardPos").global_position
			pos.x += 40
			_deliver_card(card,pos,v)
			yield(get_tree().create_timer(CARD_DELIVER_DELAY), "timeout")
	
	if players[myIndex].playState == PlayStates.waiting:
		return
	
	if players[myIndex].cards.size() == 3:
		yield(get_tree().create_timer(1), "timeout")
		$CardCheck._show(players[myIndex].cards)
		yield(get_tree().create_timer(CARD_CHECK_TIME), "timeout")
		$CardCheck._hide()
	
	_show_player_cards(myIndex)


func _dealer_draw(room):
	_check_player_catch(room)
	_room = room
	_common_update(room)
	print("Game State : Dealer Draw")
	var players = room.players
	var dealer = players[room.dealerIndex]
	var v = _get_vIndex(room.dealerIndex)
	var childCount = $Cards.get_node(str(v)).get_child_count()
	if dealer.cards.size() == 3 && childCount == 2:
		playersNode[v]._stop_count_down()
		var card = dealer.cards[2]
		var pos = playersNode[v].get_node("CardPos").global_position
		pos.x += 40
		_deliver_card(card,pos,v)
		if room.dealerIndex == myIndex :
			yield(get_tree().create_timer(0.5), "timeout")
			$CardCheck._show(players[myIndex].cards)
			yield(get_tree().create_timer(CARD_CHECK_TIME), "timeout")
			$CardCheck._hide()
	
	if room.gameState == prev_gameState:
		return
	prev_gameState = room.gameState
	if room.dealerIndex == myIndex :
		_show_all_catch(room)
		$DrawBtns.visible = true
		$CatchAllDraw.visible = true
	
	# Set Count Down
	var count_down = (room.wait - room.tick) * 2
	playersNode[v]._set_count_down(count_down)


func _end(room):
	_room = room
	if room.gameState == prev_gameState:
		return
	prev_gameState = room.gameState
	print("Game State : End")
	var dealerVIndex = _get_vIndex(room.dealerIndex)
	playersNode[dealerVIndex]._stop_count_down()
	
	_hide_all_catch()
	_playVoice(GameVoices.catch_all)
	$DrawBtns.visible = false
	$CatchAllDraw.visible = false
	var players = room.players
	_show_all_player_cards(players)
	_show_all_multiply(players)
	
	var dealerPauk = _get_pauk(players[room.dealerIndex].cards)
	playersNode[dealerVIndex]._show_pauk(dealerPauk)
	
	var winners = room.catchInfo.winners
	var losers = room.catchInfo.losers
	
	# --- Show Losers ---
	if losers.size() > 0:
		var loseAmount = 0
		for i in losers:
			var player = players[i]
			loseAmount += player.loseAmount
			var v = _get_vIndex(i)
			var pauk = _get_pauk(player.cards)
			playersNode[v]._show_pauk(pauk)
			playersNode[v]._set_count_down(2)
			var cards = $Cards.get_node(str(v))
			for card in cards.get_children():
				card._highlight()
		yield(get_tree().create_timer(1), "timeout")
		var dealerBet = int($DealerBet/Label.text);
		dealerBet += loseAmount
		$DealerBet/Label.text = str(dealerBet)
		$Audio/CoinMove.play()
		for i in losers:
			_coin_move_from_player_to_dealer(i)
			var player = players[i]
			var v = _get_vIndex(i)
			if i == myIndex :
				_playVoice(GameVoices.lose)
			playersNode[v]._show_result_flag(false)
			playersNode[v]._set_bet(0)
			playersNode[v]._set_balance(player.balance)
		yield(get_tree().create_timer(1), "timeout")
		for i in losers:
			var player = players[i]
			var v = _get_vIndex(i)
			var cards = $Cards.get_node(str(v))
			for card in cards.get_children():
				card._unhighlight()
	
	# --- Show Winners ---
	if winners.size() > 0:
		for i in winners:
			var player = players[i]
			var v = _get_vIndex(i)
			var pauk = _get_pauk(player.cards)
			playersNode[v]._show_pauk(pauk)
			playersNode[v]._set_count_down(2)
			var cards = $Cards.get_node(str(v))
			for card in cards.get_children():
				card._highlight()
			yield(get_tree().create_timer(0.5), "timeout")
			var coin_count = ceil(player.winAmount / room.minBet)
			print("Win amount : " + str(player.winAmount))
			print("Coin count : " + str(coin_count))
			if player.winAmount > 0:
				$Audio/CoinMove.play()
			for j in range(coin_count):
				_coin_move_from_dealer_to_player(i)
			yield(get_tree().create_timer(0.5), "timeout")
			var dealerBet = int($DealerBet/Label.text);
			dealerBet -= player.winAmount
			$DealerBet/Label.text = str(dealerBet)
			if i == myIndex :
				_playVoice(GameVoices.win)
			else :
				_playVoice(GameVoices.win_effect)
			playersNode[v]._show_result_flag(true)
			playersNode[v]._set_bet(player.bet)
			yield(get_tree().create_timer(1), "timeout")
			for card in cards.get_children():
				card._unhighlight()
	
	$DealerBet/Label.text = str(room.dealerBet)
	
	_show_all_win_lose_amount(room)
	
	# --- Show Dealer Win Amount ---
	if room.dealerBet <= 0 :
		$DealerLoseScene/AnimationPlayer.play("show")
	elif  room.dealerCount >= room.dealerLimit - 1 :
		var dealerWinAmount = room.dealerBet - room.dealerAmount
		if dealerWinAmount > 0 :
			$DealerWinScene/WinBg/Label.text = str(dealerWinAmount)
			$DealerWinScene/AnimationPlayer.play("show")
		else :
			$DealerLoseScene/AnimationPlayer.play("show")


# ----- Coin Move Functions -----


func _check_dealer_change(room):
	if isStart == true :
		isStart = false
		$Audio/CoinMove.play()
		var t = ceil(room.dealerBet / room.minBet)
		for i in range(t):
			_coin_move_from_player_balance_to_dealer(room.dealerIndex)
			yield(get_tree().create_timer(COIN_MOVE_DELAY), "timeout")
	elif room.dealerIndex != _room.dealerIndex :
		$Audio/CoinMove.play()
		_move_all_coin_from_dealer_player(_room.dealerIndex)
		yield(get_tree().create_timer(0.5), "timeout")
		$Audio/CoinMove.play()
		var t = ceil(room.dealerBet / room.minBet)
		for i in range(t):
			_coin_move_from_player_balance_to_dealer(room.dealerIndex)
			yield(get_tree().create_timer(COIN_MOVE_DELAY), "timeout")


func _check_player_bet_for_coin_move(room):
	if _room == null :
		return
	var players = room.players
	var _players = _room.players
	for i in range(TOTAL_PLAYER) :
		var player = players[i]
		if player == null:
			continue
		if _players[i] == null:
			continue
		var _player = _players[i]
		if player.bet != _player.bet :
			$Audio/CoinMove.play()
			var t = ceil(player.bet / room.minBet)
			for j in range(t):
				_coin_move_from_player_balance_to_bet(i)
				yield(get_tree().create_timer(COIN_MOVE_DELAY), "timeout")


func _move_all_coin_from_player_bet_to_balance():
	for coin in $CoinContainer.get_children():
		if coin.playerIndex == -1 :
			continue
		var v = _get_vIndex(coin.playerIndex)
		var target = playersNode[v].get_node("Profile").global_position
		coin.target = target
		coin.destroyOnArrive = true


func _coin_move_from_player_balance_to_dealer(index):
	var coin = coinPrefab.instance()
	var v = _get_vIndex(index)
	var pos = playersNode[v].get_node("Profile").global_position
	coin.playerIndex = -1
	coin.position = pos
	var bankerPos = $BankerCoinPos.position
	var xRand = (randi()%120)-60
	var yRand = (randi()%60)-30
	var x = bankerPos.x + xRand
	var y = bankerPos.y + yRand
	var target = Vector2(x,y)
	coin.target = target
	$CoinContainer.add_child(coin)


func _coin_move_from_player_balance_to_bet(index):
	var coin = coinPrefab.instance()
	var v = _get_vIndex(index)
	var pos = playersNode[v].get_node("Profile").global_position
	coin.playerIndex = index
	coin.position = pos
	var betPos = playersNode[v].get_node("Bet").global_position
	var xRand = (randi()%40)-20
	var yRand = (randi()%40)-20
	var x = betPos.x + xRand
	var y = betPos.y + yRand + 50
	var target = Vector2(x,y)
	coin.target = target
	$CoinContainer.add_child(coin)


func _coin_move_from_player_to_dealer(index):
	var bankerPos = $BankerCoinPos.position
	var count = $CoinContainer.get_child_count()
	if count == 0 :
		return
	for coin in $CoinContainer.get_children():
		if coin.playerIndex != index :
			continue
		var xRand = (randi()%120)-120
		var yRand = (randi()%60)-30
		var x = bankerPos.x + xRand
		var y = bankerPos.y + yRand
		var target = Vector2(x,y)
		coin.playerIndex = -1
		coin.target = target


func _coin_move_from_dealer_to_player(index):
	var v = _get_vIndex(index)
	var betPos = playersNode[v].get_node("Bet").global_position
	var xRand = (randi()%40)-20
	var yRand = (randi()%40)-20
	var x = betPos.x + xRand
	var y = betPos.y + yRand + 50
	var target = Vector2(x,y)
	for coin in $CoinContainer.get_children():
		if coin.playerIndex == -1 :
			coin.playerIndex = index
			coin.target = target
			return


func _move_all_coin_from_dealer_player(index):
	var v = _get_vIndex(index)
	var target = playersNode[v].get_node("Profile").global_position
	for coin in $CoinContainer.get_children():
		if coin.playerIndex == -1 :
			coin.playerIndex = index
			coin.target = target
			coin.destroyOnArrive = true


# ----- Utility Functions -----

func _show_all_win_lose_amount(room):
	var players = room.players
	for i in range(TOTAL_PLAYER):
		var player = players[i]
		if player == null:
			continue
		var v = _get_vIndex(i)
		var N = playersNode[v]
		if player.winAmount > 0:
			N._transfer_balance(player.winAmount)
		elif player.loseAmount > 0:
			N._transfer_balance(-player.loseAmount)


func _set_bet_buttons(minBet, maxBet):
	$BetPanel/Slider.value = 0;
	$BetPanel/Slider.max_value = maxBet
	bet_array[0] = minBet
	bet_array[1] = minBet * 2
	bet_array[2] = minBet * 3
	bet_array[3] = minBet * 5
	$BetPanel/C1/Label.text = str(bet_array[0])
	$BetPanel/C2/Label.text = str(bet_array[1])
	$BetPanel/C3/Label.text = str(bet_array[2])
	$BetPanel/C4/Label.text = str(bet_array[3])


func _check_player_catch(room):
	for i in range(TOTAL_PLAYER) :
		var player = room.players[i]
		if player == null:
			continue
		if player.playState == PlayStates.win || player.playState == PlayStates.lose :
			var _player = _room.players[i]
			if _player.playState == PlayStates.uncatch:
				_playVoice(GameVoices.catch)
				_show_player_cards(i)
				_show_multiply(i)
				var v = _get_vIndex(i)
				var isWin = player.playState == PlayStates.win
				playersNode[v]._hide_catch()
				if i == myIndex :
					var dealer = room.players[room.dealerIndex]
					$CatchScene._show(player.cards,dealer.cards, isWin)
				if isWin:
					_playVoice(GameVoices.win_effect)
				playersNode[v]._show_result_flag(isWin)


func _show_all_catch(room):
	var players = room.players
	for i in range(TOTAL_PLAYER) :
		var player = players[i]
		if player == null :
			continue
		if player.playState == PlayStates.waiting :
			continue
		if _get_pauk(player.cards) >= 8 :
			continue
		if i == room.dealerIndex :
			continue
		var v = _get_vIndex(i)
		playersNode[v]._show_catch()


func _hide_all_catch():
	for i in range(TOTAL_PLAYER) :
		playersNode[i]._hide_catch()


func _common_update(room):
	$DealerBet/Label.text = str(room.dealerBet)
	
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
		if(i == room.dealerIndex):
			N._hide_bet()
			$Banker.target = N._banker_pos()
		else :
			N._set_bet(player.bet)


func _playVoice(voice):
	$Audio/GameVoice.stream = voice
	$Audio/GameVoice.play()


func _reset_all_players():
	for i in range(TOTAL_PLAYER):
		playersNode[i]._reset()


func _get_pauk(cards):
	var count = 0
	for card in cards:
		count += card.count
	var pauk = int(count) % 10
	return pauk


func _show_all_auto(players):
	for i in range(TOTAL_PLAYER):
		var player = players[i]
		if player == null:
			continue
		var pauk = _get_pauk(player.cards)
		if player.cards.size() == 2 && pauk >= 8:
			var v = _get_vIndex(i)
			playersNode[v]._show_pauk(pauk)
			_show_player_cards(i)


func _clear_all_player_cards():
	for i in range(TOTAL_PLAYER):
		var cards = $Cards.get_node(str(i))
		for card in cards.get_children():
			card.queue_free()


func _show_player_cards(index):
	var v = _get_vIndex(index)
	var cards = $Cards.get_node(str(v))
	for card in cards.get_children():
		card._show()


func _show_multiply(index):
	var v = _get_vIndex(index)
	var c = _room.players[index].cards
	if c.size() == 2:
		if c[0].shape == c[1].shape:
			playersNode[v]._show_multiply(2)
	elif c.size() == 3:
		if c[0].shape == c[1].shape && c[0].shape == c[2].shape:
			playersNode[v]._show_multiply(3)
		elif str(c[0].rank) == str(c[1].rank) && str(c[0].rank) == str(c[2].rank):
			playersNode[v]._show_multiply(5)
		else:
			playersNode[v]._hide_multiply()


func _show_all_multiply(players):
	for i in range(TOTAL_PLAYER):
		if(players[i] != null):
			_show_multiply(i)


func _show_all_player_cards(players):
	for i in range(TOTAL_PLAYER):
		if(players[i] != null):
			_show_player_cards(i)


func _deliver_card(card,pos,index):
	var sprite = cardPrefab.instance()
	var key = str(card.rank)+str(card.shape)
	sprite.cardTexture = card_textures[key]
	sprite.position = $CardHome.position
	sprite.target = pos
	$Cards.get_node(str(index)).add_child(sprite)
	$Audio/CardMove.play()


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


# ----- Emoji/Message Functions -----


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


func _on_EmojiToggle_pressed():
	$EmojiPanel.visible = !$EmojiPanel.visible


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


func _on_MessageToggle_pressed():
	$MessagePanel.visible = !$MessagePanel.visible


# ----- Button Functions -----


func _on_Bet_pressed():
	var request = {
		"head":"bet",
		"body":{
			"amount":bet_amount
		}
	}
	send(request)
	$BetPanel.visible = false


func _on_Bet_select(i):
	var tmp = bet_amount + bet_array[i]
	var dealerBet = _room.dealerBet
	var minBet = _room.minBet
	if tmp > dealerBet || tmp < minBet :
		return
	bet_amount = tmp
	$BetPanel/Amount.text = str(bet_amount)
	$BetPanel/Slider.value = bet_amount


func _on_Draw_pressed():
	_playVoice(GameVoices.draw_card)
	var request = {
		"head":"draw",
		"body":{
			"isDraw":true
		}
	}
	send(request)
	$DrawBtns.visible = false


func _on_Stop_pressed():
	var request = {
		"head":"draw",
		"body":{
			"isDraw":false
		}
	}
	send(request)
	$DrawBtns.visible = false


func _on_Slider_value_changed(value):
	bet_amount = stepify(value,50)
	$BetPanel/Amount.text = str(bet_amount)


func _on_BetAll_pressed():
	bet_amount = _room.dealerBet
	$BetPanel/Amount.text = str(bet_amount)
	$BetPanel/Slider.value = bet_amount


func _on_Clear_pressed():
	bet_amount = 0
	$BetPanel/Amount.text = str(bet_amount)
	$BetPanel/Slider.value = bet_amount


func _on_Menu_pressed():
	$MenuPanel.visible = !$MenuPanel.visible


func _on_Exit_pressed():
	var request = {
		"head":"exit",
	}
	send(request)
	$MenuPanel.visible = false


func _on_Setting_pressed():
	$Setting._show()
	$MenuPanel.visible = false


func _on_GameRules_Close_pressed():
	$Rules.visible = false;


func _on_Rules_pressed():
	$Rules.visible = true;
	$MenuPanel.visible = false


func _on_Catch_pressed(v):
	playersNode[v]._hide_catch()
	var a = _get_aIndex(v)
	var request = {
		"head":"catch",
		"body":{
			"index":a
		}
	}
	send(request)


func _on_CatchAllDraw_pressed():
	$CatchAllDraw.visible = false
	var request = {
		"head":"catch all draw",
	}
	send(request)

