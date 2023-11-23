extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var url = $"/root/Config".config.account_url + "user_info?id=" + $"/root/Config".config.user.id
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed",self,"_update_info")
	http.request(url)


func _update_info(result, response_code, headers, body):
	var respond = JSON.parse(body.get_string_from_utf8()).result
	$Balance/Label.text = comma_sep(respond.balance)

func comma_sep(number):
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	return res

func _on_Exit_pressed():
	get_tree().change_scene("res://pck/scenes/menu.tscn")

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_Exit_pressed()

func _on_SKM_pressed():
	var data = {
		"username":$"/root/Config".config.user.username,
		"session":$"/root/Config".config.user.session
	}
	var url = $"/root/Config".config.account_url + "skm_bet"
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed",self,"_on_skm_respond")
	var headers = ["Content-Type: application/json"]
	var body = JSON.print(data)
	http.request(url,headers,false,HTTPClient.METHOD_POST,body)

func _on_skm_respond(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	var res = json.result;
	print(res)
	if res.status == "ok":
		$"/root/Config".config.gameState = {
			"passcode":res.passcode,
			"url":res.url
		}
		get_tree().change_scene("res://pck/scenes/skm_bet_game.tscn")

func _on_HorseRacing_pressed():
	var data = {
		"username":$"/root/Config".config.user.username,
		"session":$"/root/Config".config.user.session
	}
	var url = $"/root/Config".config.account_url + "horse_bet"
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed",self,"_on_HorseRacing_respond")
	var headers = ["Content-Type: application/json"]
	var body = JSON.print(data)
	http.request(url,headers,false,HTTPClient.METHOD_POST,body)

func _on_HorseRacing_respond(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	var res = json.result;
	print(res)
	if res.status == "ok":
		$"/root/Config".config.gameState = {
			"passcode":res.passcode,
			"url":res.url
		}
		get_tree().change_scene("res://pck/scenes/horse_bet_game.tscn")

func _on_TigerDragon_pressed():
	var data = {
		"username":$"/root/Config".config.user.username,
		"session":$"/root/Config".config.user.session
	}
	var url = $"/root/Config".config.account_url + "dragon_tiger_bet"
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed",self,"_on_dragon_tiger_respond")
	var headers = ["Content-Type: application/json"]
	var body = JSON.print(data)
	http.request(url,headers,false,HTTPClient.METHOD_POST,body)

func _on_dragon_tiger_respond(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	var res = json.result;
	print(res)
	if res.status == "ok":
		$"/root/Config".config.gameState = {
			"passcode":res.passcode,
			"url":res.url
		}
		get_tree().change_scene("res://pck/scenes/tiger_dragon_bet_game.tscn")
