extends Node

# Configuration
const TOTAL_PLAYER = 5
const CARD_DELIVER_DELAY = 0.05
const COIN_MOVE_DELAY = 0.1

export var deckCardSpacing = 95

var GameStates = {
	"destory": -1,
	"wait": 0,
	"start": 1,
	"taxMoney": 2,
	"play": 3,
	"end": 4,
  };

var GameVoices = {
	"wait_game":preload("res://pck/assets/shankoemee/audio/wait_game.ogg"),
	"new_game":preload("res://pck/assets/shankoemee/audio/new_game_dealer.ogg"),
	"eat_or_draw":preload("res://pck/assets/common/audio/eat_or_draw.ogg"),
	"eat":preload("res://pck/assets/common/audio/eat_only.ogg"),
	"draw":preload("res://pck/assets/common/audio/draw_only.ogg"),
	"down":preload("res://pck/assets/common/audio/poker_down.ogg"),
	"compare_money":preload("res://pck/assets/common/audio/compare_money_cards.ogg"),
	"exit":preload("res://pck/assets/common/audio/exit.ogg"),
}

# Static
const music = preload("res://pck/assets/audio/music-2.mp3")

const playerPrefab = preload("res://pck/assets/poker_13/poker_13_player.tscn")
const deckCardPrefab = preload("res://pck/assets/poker_13/DeckCard.tscn")
const cardPrefab = preload("res://pck/assets/poker_13/PokerCard.tscn")
const coinPrefab = preload("res://pck/prefabs/Coin.tscn")

# System Variables
var playersNode = []
var card_deck_pos = []
var card_textures = {}
var myIndex = 0
var gameState = GameStates.wait
var isWaitVoicePlayed = false
var _room = null
var websocket_url = ""
var selectedCard = -1
var deckCardPosArray = []
var deckCardArray = null
var selectedDeckCard = -1
var taxMoney = 0
var downMoney = 0

var _client = WebSocketClient.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	$"/root/bgm".stream = music
	$"/root/bgm".play()
	
	for i in range(TOTAL_PLAYER):
		var player = playerPrefab.instance()
		player.position = $PlayerPos.get_node(str(i)).position
		if i == 0:
			player.get_node("Side").position = Vector2(600,-270)
			player.get_node("Side/show").visible = false
		elif i >= 3:
			player._set_left()
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
	
	var key1 = "X0"
	card_textures[key1] = load("res://pck/assets/common/cards/"+key1+".png")
	var key2 = "X1"
	card_textures[key2] = load("res://pck/assets/common/cards/"+key2+".png")
	var key3 = "X2"
	card_textures[key3] = load("res://pck/assets/common/cards/"+key3+".png")
	var key4 = "X3"
	card_textures[key4] = load("res://pck/assets/common/cards/"+key4+".png")
	
	for i in range(14):
		var home_pos = $CardDeckHome.position
		var pos = Vector2((i*deckCardSpacing)+home_pos.x,home_pos.y)
		deckCardPosArray.append(pos)
	
	$MenuPanel.visible = false
	$Rules.visible = false
	$EmojiPanel.visible = false
	$AutoOrder.visible = false
	$Draw.visible = false
	$Shoot.visible = false
	
	websocket_url = $"/root/Config".config.gameState.url
	_connect_ws()

func _process(delta):
	_client.poll()

func _input(event):
	if gameState != GameStates.play:
		return
	
	var touchPos = event.position
		
	if event is InputEventScreenTouch && event.is_pressed():
		for i in range($CardDeck.get_child_count()):
			var pos = deckCardPosArray[i]
			if touchPos.x > pos.x && touchPos.x < (pos.x + deckCardSpacing) && touchPos.y > pos.y && touchPos.y < (pos.y + 120):
				selectedDeckCard = i
				for card in $CardDeck.get_children():
					if card.index == i:
						card.isDragging = true
						card.z_index = 20
				break
	
	if event is InputEventScreenTouch && !event.is_pressed():
		if selectedDeckCard == -1:
			return
		for i in range($CardDeck.get_child_count()):
			var pos = deckCardPosArray[i]
			if touchPos.x > pos.x && touchPos.x < (pos.x + deckCardSpacing) && touchPos.y > pos.y && touchPos.y < (pos.y + 120):
				if i != selectedDeckCard:
					var from = deckCardArray[selectedDeckCard].id;
					var to = deckCardArray[i].id
					var request = {
						"head":"move card",
						"body": {
							"from":from,
							"to":to
						}
					}
					send(request)
				break
		for card in $CardDeck.get_children():
			card._unhover()
			if card.index == selectedDeckCard:
				card.isDragging = false
				card.z_index = card.index
		selectedDeckCard = -1
	
	if event is InputEventScreenDrag:
		var x = event.position.x - 45
		var y = event.position.y - 60
		if selectedDeckCard != -1:
			for card in $CardDeck.get_children():
				var pos = deckCardPosArray[card.index]
				if card.index == selectedDeckCard:
					card.global_position = Vector2(x,y)
				elif touchPos.x > pos.x && touchPos.x < (pos.x + deckCardSpacing) && touchPos.y > pos.y && touchPos.y < (pos.y + 120):
					card._hover()
				else:
					card._unhover()

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

func send(data):
	var json = JSON.print(data)
	#print("From client --- " + json)
	_client.get_peer(1).put_packet(json.to_utf8())

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
	var obj = JSON.parse(respond);
	var res = obj.result
	_on_server_respond(res)

func _on_server_respond(respond):
	var body = respond.body
	match respond.head:
		"room info":
			if body == null :
				get_tree().change_scene("res://pck/scenes/menu.tscn")
				return
			_update_room(body)
		"emoji":
			_emoji_respond(body.senderIndex, body.emoji)
		"message":
			_message_respond(body.senderIndex, body.message)
		"exit":
			pass
		"handshake":
			_handshake(body)
		"card sorted":
			_sort_card(body)
		"eat":
			_eat(body)
		"draw":
			_draw(body)
		"shoot":
			_shoot(body)

# ----- Main Functions -----

func _handshake(body):
	if body.status == "ok":
		print("handshake respond ok!")
		taxMoney = body.taxMoney
		downMoney = body.downMoney
		myIndex = body.index

func _update_room(room):
	if room.players[myIndex] == null:
		get_tree().change_scene("res://pck/scenes/menu.tscn")
		return
		
	if room.players[myIndex].isWaiting:
		if room.gameState == GameStates.wait:
			$BackDrop._show("အျခားကစားသမားမ်ားေစာင့္ေပးပါ။")
			return
		else:
			if !isWaitVoicePlayed:
				_playVoice("wait_game")
				isWaitVoicePlayed = true
	
	if room.gameState == GameStates.play:
		$AutoOrder.visible = true
	else:
		$AutoOrder.visible = false
	
	$TotalCard.text = "Total Card : " + str(room.totalCard)
	
	# Game States
	gameState = room.gameState
	if room.gameState == GameStates.start:
		_start(room)
	elif room.gameState == GameStates.taxMoney:
		_taxMoney(room)
	elif room.gameState == GameStates.play:
		_play(room)
	elif room.gameState == GameStates.end:
		_end(room)
	elif room.gameState == GameStates.wait:
		_wait()
	_room = room

func _update_players(room, setCard = true):
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
		if setCard == true:
			N._set_cards(player)
		if i == myIndex:
			N._set_total_money_card(player.moneyPoints)

func _emoji_respond(senderIndex, emoji):
	$Audio/Emoji.play()
	var v = _get_vIndex(senderIndex)
	playersNode[v]._play_emoji(emoji)

func _message_respond(senderIndex, msg):
	var v = _get_vIndex(senderIndex)
	playersNode[v]._play_message(msg)

func _sort_card(player):
	deckCardArray = player.cards
	for N in $"CardDeck".get_children():
		var found = false
		for i in range(len(deckCardArray)):
			var card = deckCardArray[i]
			if N.id == card.id:
				var pos = deckCardPosArray[i]
				N.index = i
				N.target = pos
				N.z_index = i
				found = true
				if card.lock:
					N._lock()
				else:
					N._unlock()
				if card.match != null:
					N._set_match(card.match)
				else:
					N._hide_match()
				N._set_money(card.isMoney)
				break
		if found == false:
			N.target = $CardHome.position
			N.destroyOnArrive = true

func _eat(body):
	$Shoot.visible = true
	_playVoice("eat")
	if body.index == myIndex:
		var card = body.card
		deckCardArray.append(card)
		var sprite = deckCardPrefab.instance()
		var key = str(card.mark)+str(card.shape)
		sprite.position = $CardHome.position
		var home_pos = $CardDeckHome.position
		var pos = Vector2((13*deckCardSpacing)+home_pos.x,home_pos.y)
		sprite._set_texture(card_textures[key])
		sprite.id = card.id
		sprite.index = 13
		sprite.target = pos
		sprite.z_index = 13
		sprite._lock()
		$CardDeck.add_child(sprite)
		$Audio/CardMove.play()
	else:
		var card = body.card
		var sprite = cardPrefab.instance()
		var key = str(card.mark)+str(card.shape)
		var v = _get_vIndex(body.index)
		sprite.position = $CardHome.position
		sprite.texture = card_textures[key]
		sprite.destroyOnArrive = true
		sprite.target = playersNode[v].position
		$Cards.add_child(sprite)
		$Audio/CardMove.play()

func _draw(body):
	$Shoot.visible = true
	_playVoice("draw")
	if body.index == myIndex:
		var card = body.card
		deckCardArray.append(card)
		var sprite = deckCardPrefab.instance()
		var key = str(card.mark)+str(card.shape)
		sprite.position = $CardHome.position
		var home_pos = $CardDeckHome.position
		var pos = Vector2((13*deckCardSpacing)+home_pos.x,home_pos.y)
		sprite._set_texture(card_textures[key])
		sprite.id = card.id
		sprite.target = pos
		sprite.z_index = 13
		sprite.index = 13
		$CardDeck.add_child(sprite)
		$Audio/CardMove.play()
	else:
		var card = body.card
		var sprite = cardPrefab.instance()
		var key = str(card.mark)+str(card.shape)
		var v = _get_vIndex(body.index)
		sprite.position = $CardHome.position
		sprite.texture = card_textures[key]
		sprite.destroyOnArrive = true
		sprite.target = playersNode[v].position
		$Cards.add_child(sprite)
		$Audio/CardMove.play()

func _shoot(body):
	if body.status == "ok":
		for N in $"CardDeck".get_children():
			if N.index == body.index:
				N.target = $CardHome.position
				N.destroyOnArrive = true
	else :
		$Shoot.visible = true

func _card_select(index):
	selectedCard = index
	for N in $"CardDeck".get_children():
		if N.index == selectedCard:
			N.target.y = $CardDeckHome.position.y - 60
		else:
			N.target.y = $CardDeckHome.position.y

# ----- Game State Functions -----

func _start(room):
	for N in $Players.get_children():
		N._reset()
	_update_players(room)
	$BackDrop._hide()
	_playVoice("new_game")
	yield(get_tree().create_timer(1), "timeout")
	deckCardArray = room.players[myIndex].cards
	for N in $"CardDeck".get_children():
		N.queue_free()
	for N in $"Cards".get_children():
		N.queue_free()
	
	$ShanMa.play("deliver")
	
	for i in range(13):
		var card = deckCardArray[i]
		var sprite = deckCardPrefab.instance()
		var key = str(card.mark)+str(card.shape)
		sprite.position = $CardHome.position
		sprite._set_texture(card_textures[key])
		sprite.id = card.id
		sprite.index = i
		sprite.target = deckCardPosArray[i]
		sprite.z_index = i
		$CardDeck.add_child(sprite)
		$Audio/CardMove.play()
		yield(get_tree().create_timer(CARD_DELIVER_DELAY), "timeout")
	
	$ShanMa.play("idle")

func _taxMoney(room):
	# Show tax card
	var totalActivePlayer = 0
	var taxCard = room.taxCard
	var sprite = cardPrefab.instance()
	var key = str(taxCard.mark)+str(taxCard.shape)
	sprite.position = $CardHome.position
	sprite.texture = card_textures[key]
	sprite.target = $TaxCardPos.position
	sprite._point_card()
	$Cards.add_child(sprite)
	$Audio/CardMove.play()
	
	yield(get_tree().create_timer(1), "timeout")
	
	if room.taxWinner == myIndex:
		var t = room.taxWinnerCard
		for c in $CardDeck.get_children():
			if c.id == t.id:
				c._highlight()
	else:
		pass
	
	yield(get_tree().create_timer(1), "timeout")
	
	var players = room.players
	for i in range(TOTAL_PLAYER):
		var player = players[i]
		if player == null:
			continue
		totalActivePlayer += 1
		if i == room.taxWinner:
			continue
		_coin_move_to_center(i)
		$Audio/CoinMove.play()
	
	yield(get_tree().create_timer(1.5), "timeout")
	
	# Move all tax money to winner
	_coin_move_all_to_player(room.taxWinner)
	$Audio/CoinMove.play()
	
	for i in range(TOTAL_PLAYER):
		var player = players[i]
		if player == null:
			continue
		var v = _get_vIndex(i)
		var N = playersNode[v]
		if i == room.taxWinner:
			var winAmt = taxMoney * (totalActivePlayer - 1)
			N._transfer_balance(winAmt)
			N._add_balance(winAmt)
		elif !player.isWaiting :
			N._transfer_balance(-taxMoney)
			N._add_balance(-taxMoney)
	
	_update_players(room)
	
	yield(get_tree().create_timer(1), "timeout")
	
	# Show tax card
	var secondCard = room.secondCard
	var sprite2 = cardPrefab.instance()
	var key2 = str(secondCard.mark)+str(secondCard.shape)
	sprite2.position = $CardHome.position
	sprite2.texture = card_textures[key2]
	sprite2.target = $SecondCardPos.position
	sprite2._point_card()
	$Cards.add_child(sprite2)
	$Audio/CardMove.play()

func _play(room):
	print(room)
	for p in room.players:
		if p == null:
			continue
		var v = _get_vIndex(p.index)
		if p.index == room.turnIndex:
			playersNode[v]._set_count_down(room.wait)
		else:
			playersNode[v]._stop_count_down()
	if room.turnIndex == myIndex:
		_playVoice("eat_or_draw")
		$Draw.visible = true
		$Shoot.visible = false
	else:
		$Draw.visible = false
		$Shoot.visible = false
	
	var player = room.players[myIndex]
	var cards = player.cards
	_update_players(room)
	if _room != null:
		if _room.turnIndex == myIndex:
			_sort_card(room.players[myIndex])

func _end(room):
	print("Game State End!")
	var totalActivePlayer = 0
	
	_playVoice("down")
	for N in $Players.get_children():
		N._stop_count_down()
	
	var players = room.players
	var v = _get_vIndex(room.finalWinner)
	playersNode[v]._show_result_flag()
	
	yield(get_tree().create_timer(1), "timeout")
	
	# Show all player cards and points
	for i in range(TOTAL_PLAYER):
		var player = players[i]
		if player == null:
			continue
		v = _get_vIndex(i)
		var N = playersNode[v]
		N._show_final_cards(player)
		N._set_total_money_card(player.moneyPoints)
	
	yield(get_tree().create_timer(1), "timeout")
	
	# Move all down money from losers
	for i in range(TOTAL_PLAYER):
		var player = players[i]
		if player == null:
			continue
		totalActivePlayer += 1
		if i == room.finalWinner || player.isWaiting:
			continue
		_coin_move_to_center(i)
		$Audio/CoinMove.play()
	
	yield(get_tree().create_timer(1.5), "timeout")
	
	# Move all down money to winner
	_coin_move_all_to_player(room.finalWinner)
	$Audio/CoinMove.play()
	
	# Show transfer balance after down
	for i in range(TOTAL_PLAYER):
		var player = players[i]
		if player == null:
			continue
		v = _get_vIndex(i)
		var N = playersNode[v]
		if i == room.finalWinner:
			var amt = room.finalDownAmount * (totalActivePlayer - 1)
			N._transfer_balance(amt)
			N._add_balance(amt)
		elif !player.isWaiting :
			N._transfer_balance(room.finalDownAmount)
			N._add_balance(room.finalDownAmount)
	
	yield(get_tree().create_timer(1), "timeout")
	
	for i in range(TOTAL_PLAYER):
		var player = players[i]
		if player == null:
			continue
		v = _get_vIndex(i)
		var N = playersNode[v]
		N._show_money_cards(player)
	_playVoice("compare_money")
	
	yield(get_tree().create_timer(1), "timeout")
	
	$Audio/CoinMove.play()
	for i in range(TOTAL_PLAYER):
		var _v = _get_vIndex(i)
		var N = playersNode[_v]
		var player = players[i]
		if player == null:
			continue
		var amt = room.finalTransactions[i]
		if amt < 0:
			var count = ceil(abs(amt) / taxMoney)
			for j in range(count):
				_coin_move_to_center(i)
			N._transfer_balance(amt)
	yield(get_tree().create_timer(1.5), "timeout")
	
	$Audio/CoinMove.play()
	for i in range(len(room.finalTransactions)):
		var amt = room.finalTransactions[i]
		if amt > 0:
			var _v = _get_vIndex(i)
			var N = playersNode[_v]
			N._transfer_balance(amt)
			var count = ceil(amt / taxMoney)
			for j in range(count):
				_coin_move_from_center(i)
	yield(get_tree().create_timer(1.5), "timeout")
	
	for i in range(TOTAL_PLAYER):
		var _v = _get_vIndex(i)
		var N = playersNode[_v]
		var player = players[i]
		if player == null:
			continue
		N._transfer_balance(player.winAmount)
	
	_update_players(room,false)

func _wait():
	print("")
	$BackDrop._show()

# ----- Utility Functions -----

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

func _playVoice(key):
	$Audio/GameVoice.stream = GameVoices[key]
	$Audio/GameVoice.play()

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

func _coin_move_to_center(from):
	var coin = coinPrefab.instance()
	var v1 = _get_vIndex(from)
	var pos1 = playersNode[v1].global_position
	var pos2 = $CoinCenter.position
	coin.position = pos1
	var xRand = (randi()%60)-30
	var yRand = (randi()%60)-30
	var x = pos2.x + xRand
	var y = pos2.y + yRand
	var target = Vector2(x,y)
	coin.target = target
	coin.playerIndex = -1
	$CoinContainer.add_child(coin)

func _coin_move_from_center(to):
	var v = _get_vIndex(to)
	var target = playersNode[v].global_position
	for coin in $CoinContainer.get_children():
		if coin.playerIndex == -1 :
			coin.playerIndex = to
			coin.target = target
			coin.destroyOnArrive = true
			return

func _coin_move_all_to_player(to):
	var v = _get_vIndex(to)
	var target = playersNode[v].global_position
	for coin in $CoinContainer.get_children():
		coin.target = target
		coin.destroyOnArrive = true

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

func _on_AutoOrder_pressed():
	var request = {
		"head":"auto sort",
	}
	send(request)

func _on_Eat_pressed():
	$Draw.visible = false;
	var request = {
		"head":"eat",
	}
	send(request)

func _on_Draw_pressed():
	$Draw.visible = false;
	var request = {
		"head":"draw",
	}
	send(request)

func _on_Shoot_pressed():
	if selectedCard == -1:
		return
	$Shoot.visible = false
	var request = {
		"head":"shoot",
		"index":selectedCard
	}
	send(request)

func _on_Exit_pressed():
	var request = {
		"head":"exit",
	}
	send(request)
	$MenuPanel.visible = false
	_playVoice("exit")

func _on_Menu_pressed():
	$MenuPanel.visible = !$MenuPanel.visible

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
