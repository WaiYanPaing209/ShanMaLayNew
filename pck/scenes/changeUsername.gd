extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_affirmative_pressed():
	var username = $usernamePanel/Username.text
	var data = {
		"username":$"/root/Config".config.user.username,
		"session":$"/root/Config".config.user.session,
		"nickname":username
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
