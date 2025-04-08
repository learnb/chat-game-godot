extends Node

@export var host_url: String = "wss://"
@export var database_name: String = ""
@export var table_names: Array[String] = []

var socket: WebSocketPeer
var isSocketOpen: bool

signal websocket_open
signal websocket_closed
signal new_message(msg: PackedByteArray)

func _ready():
	websocket_init()

## Processes the WebSocket connection state and incoming messages.
func _process(delta: float) -> void:
	# Process WebSocket state
	socket.poll()
	var state = socket.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			# Trigger open event
			if !isSocketOpen:
				isSocketOpen = true
				print("WebSocket Open")
				emit_signal("websocket_open")
			
			# Process messages
			while socket.get_available_packet_count():
				emit_signal("new_message", socket.get_packet())
		WebSocketPeer.STATE_CLOSING:
			print("WebSocket Closing")
		WebSocketPeer.STATE_CLOSED:
			# Trigger close event
			if isSocketOpen:
				isSocketOpen = false
				var code = socket.get_close_code()
				print("WebSocket Closed with code: %d, Clean: %s" % [code, code != -1])
				emit_signal("websocket_closed")
	
## Initializes the WebSocket connection to the SpacetimeDB server.
##
## Sets up the WebSocket URL, supported protocols, and establishes the connection.
func websocket_init() -> void:
	# Process SpacetimeDB Config
	var websocket_url: String = "%s/v1/database/%s/subscribe" % [host_url, database_name]

	# Start websocket connection
	isSocketOpen = false
	var protocols: PackedStringArray = [
		"v1.json.spacetimedb"
	]	
	socket = WebSocketPeer.new()
	socket.supported_protocols = protocols
	print("Sending socket open request: %s" % [websocket_url])
	await socket.connect_to_url(websocket_url)
	#var err = socket.connect_to_url(websocket_url)
	#assert(err == OK)
	print("Socket request complete.")


## Sends a subscription request to the SpacetimeDB Server.
##
## Creates a subscription message for all tables defined in the `table_names` export array, then sends it to the server.
func subscribe() -> void:
	var subscribeMessage: Dictionary = {
		"Subscribe": {
			"query_strings": table_names.map(func(t): return "SELECT * FROM %s" % [t]),
			"request_id": 420
		}
	}
	var msgString: String = JSON.stringify(subscribeMessage)
	socket.send_text(msgString)
