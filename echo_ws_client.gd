extends Node

# WebSocket(`wss://spacetime.bryanlearn.com/v1/database/chat-game-dev/subscribe`, "v1.json.spacetimedb")
@export var websocket_url = "wss://echo.websocket.org"
#@export var websocket_url = "wss://spacetime.bryanlearn.com/v1/database/chat-game-dev/subscribe"

var socket = WebSocketPeer.new()

func _ready() -> void:
	pass
	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	else:
		# wait for socket to connect
		await get_tree().create_timer(2).timeout
		
		socket.send_text("test")


func _process(delta: float) -> void:
	pass
	socket.poll()
	
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			print("Got data from server: ", socket.get_packet().get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false)
