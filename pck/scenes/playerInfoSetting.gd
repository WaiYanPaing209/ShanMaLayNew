extends Control

const profile_textures = []
var filepath = "user://session.txt"
signal profile_changed(selectedTexture)

var connected = false
func _load_profile_textures():
	for i in range(32):
		var path = "res://pck/assets/HomeScence/Home-Photo/icon-photo-" + str(i+1) + ".png"
		var texture = load(path)
		profile_textures.append(texture) 


func _ready():
	_load_profile_textures()
	var url = $"/root/Config".config.account_url + "user_info?id=" + $"/root/Config".config.user.id
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed",self,"_update_info")
	http.request(url)
	$playerInfoAnimation.play("Null")
	var buttons = $ProfilePanel/ScrollContainer/Container.get_children()
	
	for i in range(buttons.size()):
		var button = buttons[i]
		if button is TextureButton:
			button.texture_normal = profile_textures[i]
#	for i in range(1, 33): # Assuming TextureButtons named 1 to 32
#		var button = $ProfilePanel/ScrollContainer/Container.find_node(str(i))
#		if button:
#			button.connect("pressed", self, "_on_profile_button_pressed", [i])
	
func _update_info(result, response_code, headers, body):
	var respond = JSON.parse(body.get_string_from_utf8()).result
#	$ProfilePanel/Nickname.text = respond.nickname
#	print(respond.nickname)
	$ProfilePanel/Profile.texture = profile_textures[int(respond.profile) - 1]

func _on_profile_select(index):
	if $Accept.is_connected("pressed", self, "_on_Accept_pressed"):
		$Accept.disconnect("pressed", self, "_on_Accept_pressed")

	$Accept.connect("pressed", self, "_on_Accept_pressed", [index])
	$ProfilePanel/Profile.texture = profile_textures[int(index) - 1]
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

#func _on_profile_button_pressed(index):
#	if $Accept.is_connected("pressed", self, "_on_Accept_pressed"):
#		$Accept.disconnect("pressed", self, "_on_Accept_pressed")
#
#	$Accept.connect("pressed", self, "_on_Accept_pressed", [index])
#	$ProfilePanel/Profile.texture = profile_textures[int(index) - 1]

#	var data = {
#		"username": $"/root/Config".config.user.username,
#		"session": $"/root/Config".config.user.session,
#		"index": index
#	}
#
#	var url = $"/root/Config".config.account_url + "profile_change"
#	var http = HTTPRequest.new()
#	add_child(http)
#	http.connect("request_completed", self, "_profile_changed")
#	var headers = ["Content-Type: application/json"]
#	var body = JSON.print(data)
#	http.request(url, headers, false, HTTPClient.METHOD_POST, body)

func _on_Accept_pressed(index):
#	$ProfilePanel/Profile.texture = profile_textures[int(index) - 1]
	var selectedTexture = profile_textures[int(index) - 1]
	print(str(index) + " OK")
	var data = {
		"username": $"/root/Config".config.user.username,
		"session": $"/root/Config".config.user.session,
		"index": index
	}

	var url = $"/root/Config".config.account_url + "profile_change"
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", self, "_profile_changed")
	var headers = ["Content-Type: application/json"]
	var body = JSON.print(data)
	http.request(url, headers, false, HTTPClient.METHOD_POST, body)
	print(data)
	emit_signal("profile_changed", selectedTexture)
	
	
func _profile_changed(result, response_code, headers, body):
	pass
#	if body.get_string_from_utf8() == "ok":
#		$AlertBox._show("Profile image changed!")

func _on_Exit_pressed():
	$playerInfoAnimation.play("Out")
	hide()	




