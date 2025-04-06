extends Node

# WebSocket(`wss://spacetime.bryanlearn.com/v1/database/chat-game-dev/subscribe`, "v1.json.spacetimedb")
@export var websocket_url = "wss://spacetime.bryanlearn.com/v1/database/chat-game-dev/subscribe"
@export var api_url = "https://spacetime.bryanlearn.com"

var http: HTTPRequest
var socket: WebSocketPeer

var stdb_identity: String
var stdb_token: String
var isOnline: bool

var isSocketOpen: bool = false
signal websocket_open

signal new_chat_message(msg)

func _ready() -> void:
	isOnline = false
	
	# Set up http request node
	http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", _on_request_completed)
	
	# Set up WebSocket
	#self.connect("websocket_open", sendSubMessage)
	
	# Request identity
	sendIdentityAPIRequest()
	
func _on_request_completed(result, response_code, headers, body):
	print("Request completed - response_code: %s, result: %s" % [response_code, result])
	var json = JSON.parse_string(body.get_string_from_utf8())
	assert(json != null)
	print(json)
	print(type_string(typeof(json)))
	
	# Parse message
	for key in json:
		var item = json.get(key)
		if key == "identity":
			setIdentity(item)
		elif key == "token":
			setToken(item)
	
func _process(delta: float) -> void:
	# Handle online state
	if !isOnline and stdb_identity and stdb_token:
		login()
	
	if isOnline and !stdb_identity:
		logout()
	
	processSocket()
	
func processSocket() -> void:
	if socket:
		socket.poll()
		var state = socket.get_ready_state()
		#print("socket state: %s" % [state])
		
		if state == WebSocketPeer.STATE_OPEN:
			if !isSocketOpen:
				isSocketOpen = true
				emit_signal("websocket_open")
			while socket.get_available_packet_count():
				parseStdbMessage(socket.get_packet())
		elif state == WebSocketPeer.STATE_CLOSING:
			print("WebSocket connection closing...")
		elif state == WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
			set_process(false)

func parseStdbMessage(msg: PackedByteArray) -> void:
	print("Server message: %s" % [msg.get_string_from_utf8()])
	var json = JSON.parse_string(msg.get_string_from_utf8())
	assert(json != null)
	
	for key in json:
		var item = json.get(key)
		if key == "IdentityToken":
			print("Received %s" % [key])
			# send sub request now that we have WS established
			sendSubMessage()
		elif key == "InitialSubscription":
			print("Received %s" % [key])
			var updates = item.database_update.tables[0].updates
			for update in updates:
				var inserts = update.inserts
				for insert in inserts:
					var row = JSON.parse_string(insert)
					print("row: %s" % [row])
					var chatMessage: String = "[%s]: %s" % [row.SenderId, row.Message]
					emit_signal("new_chat_message", chatMessage)
		elif key == "TransactionUpdate":
			print("Received %s" % [key])
			pass
		else:
			print("Unhandled message type: %s" % [key])
		

func sendIdentityAPIRequest() -> void:
	var id_url: String = "%s/v1/identity" % [api_url]
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var method: HTTPClient.Method = HTTPClient.Method.METHOD_POST
	http.request(id_url, headers, method)

func subscribeToChatMessages() -> void:
	if !isOnline:
		print("Cannot subscribe while offline")
		return
	
	# Start websocket connection
	socket = WebSocketPeer.new()
	var headers: PackedStringArray = [
		#"Sec-WebSocket-Protocol: v1.json.spacetimedb"
	]
	var protocols: PackedStringArray = [
		"v1.json.spacetimedb"
	]
	socket.handshake_headers = headers
	socket.supported_protocols = protocols
	print(socket.supported_protocols)
	print(socket.handshake_headers)
	var err = socket.connect_to_url(websocket_url, TLSOptions.client())
	assert(err == OK)
	
func sendSubMessage() -> void:
	print("Sending subscribe message")
	
	var subscribeMessage: Dictionary = {
		"Subscribe": {
			"query_strings": ["SELECT * FROM ChatMessages"],
			"request_id": 420
		}
	}
	var msgStr:String = JSON.stringify(subscribeMessage)
	socket.send_text(msgStr)
	
func login() -> void:
	print("Now online!")
	isOnline = true
	subscribeToChatMessages()
	
func logout() -> void:
	print("now offline")
	isOnline = false
	
func setIdentity(id: String) -> void:
	self.stdb_identity = id

func setToken(token: String) -> void:
	self.stdb_token = token
