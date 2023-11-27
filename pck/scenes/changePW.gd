extends Control

const profile_textures = []

func _ready():
	_load_profile_textures()
	var request = {
		"head":"user info"
	}
	var url = $"/root/Config".config.account_url + "user_info?id=" + $"/root/Config".config.user.id
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed",self,"_update_info")
	http.request(url)

#func _update_info(result, response_code, headers, body):
#	var respond = JSON.parse(body.get_string_from_utf8()).result
#	$PWpanel/Username.text = respond.nickname
##	$NicknamePanel/Nickname.text = respond.nickname
#	$ProfilePanel/Profile.texture = profile_textures[int(respond.profile)]

func _load_profile_textures():
	for i in range(32):
		var path = "res://pck/assets/HomeScence/Home-Photo/icon-photo-" + str(i+1) + ".png"
		var texture = load(path)
		profile_textures.append(texture) 
