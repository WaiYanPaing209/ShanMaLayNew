extends Node

var user = {}
var gameState = {}
var rejoin = false
var ws_retry = false
# The URL we will connect tos
#var websocket_url = "http://shanmalay99.com:9690"
var websocket_url = "http://192.168.1.100:9690"
var server_message = ""

# Our WebSocketClient
var _client = WebSocketClient.new()

func _ready():
	pass

func _retry():
	_client = WebSocketClient.new()
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
	get_tree().change_scene("res://pck/scenes/login.tscn")


func _on_data():
	var respond = _client.get_peer(1).get_packet().get_string_from_utf8();
	#print("From server: ", respond)
	print("")
	var obj = JSON.parse(respond);
	var res = obj.result
	$"/root/root"._on_server_respond(res)


func _process(delta):
	_client.poll()


func send(data):
	var json = JSON.print(data)
	print("From client --- " + json)
	print("")
	_client.get_peer(1).put_packet(json.to_utf8())
