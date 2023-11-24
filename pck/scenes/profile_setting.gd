extends Node2D


const profile_textures = []
var filepath = "user://session.txt"

# Called when the node enters the scene tree for the first time.
func _ready():
	_load_profile_textures()
	var url = $"/root/Config".config.account_url + "user_info?id=" + $"/root/Config".config.user.id
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed",self,"_update_info")
	http.request(url)


func _update_info(result, response_code, headers, body):
	var respond = JSON.parse(body.get_string_from_utf8()).result
	$NicknamePanel/Nickname.text = respond.nickname
	$ProfilePanel/Profile.texture = profile_textures[respond.profile]


func _load_profile_textures():
	for i in range(13):
		var path = "res://pck/assets/common/profiles/" + str(i) + ".png"
		var texture = load(path)
		profile_textures.append(texture) 


func _on_profile_select(index):
	$ProfilePanel/Profile.texture = profile_textures[index]
	var data = {
		"username":$"/root/Config".config.user.username,
		"session":$"/root/Config".config.user.session,
		"index":index
	}
	var url = $"/root/Config".config.account_url + "profile_change"
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed",self,"_profile_changed")
	var headers = ["Content-Type: application/json"]
	var body = JSON.print(data)
	http.request(url,headers,false,HTTPClient.METHOD_POST,body)


func _profile_changed(result, response_code, headers, body):
	if body.get_string_from_utf8() == "ok":
		$AlertBox._show("Profile image changed!")


func _on_Exit_pressed():
	get_tree().change_scene("res://pck/scenes/menu.tscn")


func _on_ChangeNickname_pressed():
	var nickname = $NicknamePanel/Nickname.text
	var data = {
		"username":$"/root/Config".config.user.username,
		"session":$"/root/Config".config.user.session,
		"nickname":nickname
	}
	var url = $"/root/Config".config.account_url + "nickname_change"
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed",self,"_nickname_changed")
	var headers = ["Content-Type: application/json"]
	var body = JSON.print(data)
	http.request(url,headers,false,HTTPClient.METHOD_POST,body)


func _nickname_changed(result, response_code, headers, body):
	if body.get_string_from_utf8() == "ok":
		$AlertBox._show("Nickname changed!")


func _on_ChangePassword_pressed():
	var oldPassword = $PasswordPanel/PasswordOld.text
	var newPassword = $PasswordPanel/PasswordNew.text
	var data = {
			"username":$"/root/Config".config.user.username,
			"session":$"/root/Config".config.user.session,
			"oldPassword":oldPassword,
			"newPassword":newPassword
		}
	var url = $"/root/Config".config.account_url + "password_change"
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed",self,"_password_changed")
	var headers = ["Content-Type: application/json"]
	var body = JSON.print(data)
	http.request(url,headers,false,HTTPClient.METHOD_POST,body)


func _password_changed(result, response_code, headers, body):
	if body.get_string_from_utf8() == "ok":
		$AlertBox._show("Password changed!")
	else:
		$AlertBox._show("Old password incorrect!");


func _on_Logout_pressed():
	var file = File.new()
	file.open(filepath, File.WRITE)
	file.store_string("")
	file.close()
	get_tree().change_scene("res://pck/scenes/login.tscn")
