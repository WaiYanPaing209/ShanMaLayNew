extends Control

const profile_textures = []
const music = preload("res://pck/assets/audio/music-main-background.mp3")


# Called when the node enters the scene tree for the first time.
func _ready():
	_load_profile_textures()
	$AnimationPlayer.play("in")
	$GamesOutAnimation.play("Games_in")
	$UpperbracketAnimation.play("in")
	$BottomBarAnimation.play("In ")
	var request = {
		"head":"user info"
	}
	var url = $"/root/Config".config.account_url + "user_info?id=" + $"/root/Config".config.user.id
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed",self,"_update_info")
	http.request(url)
	
	var currentMusic = $"/root/bgm".stream.resource_path.get_file().get_basename()
	if currentMusic != "music-main-background":
		$"/root/bgm".stream = music
		$"/root/bgm".play()


func _update_info(result, response_code, headers, body):
	var respond = JSON.parse(body.get_string_from_utf8()).result
	print(respond)
	$Balance.text = comma_sep(respond.balance)
	$Username.text = respond.username
	$Nickname.text = respond.nickname
	$Profile.texture_normal = profile_textures[respond.profile]


func _load_profile_textures():
	for i in range(13):
		var path = "res://pck/assets/common/profiles/" + str(i) + ".png"
		var texture = load(path)
		profile_textures.append(texture) 


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		$AnimationPlayer.play("out")
		$GamesOutAnimation.play("Games_out")
		$UpperbracketAnimation.play("out")
		$BottomBarAnimation.play("Out")
		yield(get_tree().create_timer(0.5), "timeout")
		get_tree().change_scene("res://pck/scenes/confirm_exit.tscn")


func comma_sep(number):
	var string = str(number)
	var mod = string.length() % 3
	var res = ""

	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]

	return res


func _on_Profile_pressed():
	$AnimationPlayer.play("out")
	$GamesOutAnimation.play("Games_out")
	$UpperbracketAnimation.play("out")
	$BottomBarAnimation.play("Out")
	yield(get_tree().create_timer(0.5), "timeout")
	get_tree().change_scene("res://pck/scenes/profile_setting.tscn")


func _on_SettingToggle_pressed():
	$Setting._show()


func _on_ShanKoeMee_pressed():
	$AnimationPlayer.play("out")
	$GamesOutAnimation.play("Games_out")
	$UpperbracketAnimation.play("out")
	$BottomBarAnimation.play("Out")
	yield(get_tree().create_timer(0.5), "timeout")
	get_tree().change_scene("res://pck/scenes/shankoemee_level.tscn")


func _on_BuGyee_pressed():
	$AnimationPlayer.play("out")
	$GamesOutAnimation.play("Games_out")
	$UpperbracketAnimation.play("out")
	$BottomBarAnimation.play("Out")
	yield(get_tree().create_timer(0.5), "timeout")
	get_tree().change_scene("res://pck/scenes/bugyee_level.tscn")


#func _on_Bet_pressed():
#	$AnimationPlayer.play("out")
#	yield(get_tree().create_timer(1), "timeout")
#	get_tree().change_scene("res://pck/scenes/bet_game.tscn")


func _on_ShweShan_pressed():
	$AnimationPlayer.play("out")
	$GamesOutAnimation.play("Games_out")
	$UpperbracketAnimation.play("out")
	$BottomBarAnimation.play("Out")
	yield(get_tree().create_timer(0.5), "timeout")
	get_tree().change_scene("res://pck/scenes/shwe_shan_level.tscn")


func _on_Poker_pressed():
	$AnimationPlayer.play("out")
	$GamesOutAnimation.play("Games_out")
	$UpperbracketAnimation.play("out")
	$BottomBarAnimation.play("Out")
	yield(get_tree().create_timer(0.5), "timeout")
	get_tree().change_scene("res://pck/scenes/poker_level.tscn")


func _on_Viber_pressed():
	OS.shell_open("viber://chat/?number=%2B959266714552")


func _on_Slot_pressed():
	var username = $"/root/Config".config.user.username
	var session = $"/root/Config".config.user.session
	OS.shell_open("https://shanmalay-slots-client.vercel.app/?uD="+str(username)+"&sD="+str(session))


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


func _on_ABCD_pressed():
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
