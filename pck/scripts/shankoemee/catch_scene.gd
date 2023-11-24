extends Node2D


var card_textures = {}

const result_textures = {
	"win":preload("res://pck/assets/shankoemee/win.png"),
	"lose":preload("res://pck/assets/shankoemee/lose.png")
}

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


func _show(playerCards, dealerCards, isWin):
	print("Player Catch!")
	var card = playerCards[0]
	var key = str(card.rank)+str(card.shape)
	$"Player/1".texture = card_textures[key]
	
	card = playerCards[1]
	key = str(card.rank)+str(card.shape)
	$"Player/2".texture = card_textures[key]
	
	if playerCards.size() == 3:
		card = playerCards[2]
		key = str(card.rank)+str(card.shape)
		$"Player/3".texture = card_textures[key]
		$"Player/3".visible = true
	else:
		$"Player/3".visible = false
	
	card = dealerCards[0]
	key = str(card.rank)+str(card.shape)
	$"Dealer/1".texture = card_textures[key]
	
	card = dealerCards[1]
	key = str(card.rank)+str(card.shape)
	$"Dealer/2".texture = card_textures[key]
	
	if dealerCards.size() == 3:
		card = dealerCards[2]
		key = str(card.rank)+str(card.shape)
		$"Dealer/3".texture = card_textures[key]
		$"Dealer/3".visible = true
	else:
		$"Dealer/3".visible = false
	
	if isWin == true :
		$ResultFlag.texture = result_textures.win
	else :
		$ResultFlag.texture = result_textures.lose
	
	$AnimationPlayer.play("show")
