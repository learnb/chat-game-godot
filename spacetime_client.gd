extends Node

@export var host_url: String = "wss://"
@export var database_name: String = ""
@export var table_names: Array[String] = []

var socket: WebSocketPeer
var isSocketOpen: bool		# Mutex lock for processing socket messages

signal websocket_open
signal websocket_closed
#signal new_message(msg: PackedByteArray)
signal initial_subscription(data: Dictionary)
signal transaction_update(data: Dictionary)
signal identity_token(data: Dictionary)

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
				websocket_open.emit()
			
			# Process messages
			while socket.get_available_packet_count():
				process_message(socket.get_packet())
				#new_message.emit(socket.get_packet())
		WebSocketPeer.STATE_CLOSING:
			print("WebSocket Closing")
		WebSocketPeer.STATE_CLOSED:
			# Trigger close event
			if isSocketOpen:
				isSocketOpen = false
				var code = socket.get_close_code()
				print("WebSocket Closed with code: %d, Clean: %s" % [code, code != -1])
				websocket_closed.emit()
	
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
	var err = socket.connect_to_url(websocket_url)
	assert(err == OK)
	print("Socket request complete.")


## Sends a Subscribe request to the SpacetimeDB Server.
##
## Creates a subscription message for all tables defined in the `table_names` export array, then sends it to the server.
func subscribe() -> int:
	var request_id: int = randi() % (1 << 32)
	var queries: Array = table_names.map(func(t): return "SELECT * FROM %s" % [t])	
	var subscribeMessage: Dictionary = {
		"Subscribe": {
			"query_strings": queries,	# list of SQL queries to subscribe to.
			"request_id": request_id 	# server will include the same ID in the `TransactionUpdate` response.
		}
	}
	var msgString: String = JSON.stringify(subscribeMessage)
	print("Sending message: %s" % [msgString])
	socket.send_text(msgString)
	return request_id

## Sends a CallReducer request to the SpacetimeDB Server.
##
## Creates a CallReducer message for the reducer spefied in the `reducer` argument, then sends it to the server.
func callReducer(reducer: String, args: String) -> int:
	var request_id: int = randi() % (1 << 32)
	var callReducerMessage: Dictionary = {
		"CallReducer": {
			"reducer": reducer, 		# name of the reducer to call.
			"args": args,				# arguments to the reducer.
			"request_id": request_id,	# server will include the same ID in the `TransactionUpdate` response.
			"flags": 0					# 0 or 1; 1 means the caller does not want to be notified about the reducer without being subscribed.
		}
	}
	var msgString: String = JSON.stringify(callReducerMessage)
	print("Sending message: %s" % [msgString])
	socket.send_text(msgString)
	return request_id

func process_message(msg: PackedByteArray) -> void:
	var json = JSON.parse_string(msg.get_string_from_utf8())
	assert(json != null)
	
	for key in json:
		var item = json.get(key)
		if key == "IdentityToken":
			print("Received %s" % [key])
			var data: Dictionary = {}
			data["identity"] = item["identity"]["__identity__"]
			data["identity"] = item["connection_id"]["__connection_id__"]
			data["identity"] = item["token"]
			identity_token.emit(data)
		elif key == "InitialSubscription":
			print("Received %s" % [key])
			var data: Dictionary = {}
			for table in item.database_update.tables:
				data[table.table_name] = {}
				for update in table.updates:
					data[table.table_name]["deletes"] = []
					data[table.table_name]["inserts"] = []
					for delete in update.deletes:
						data[table.table_name].deletes.append(JSON.parse_string(delete))
					for insert in update.inserts:
						data[table.table_name].inserts.append(JSON.parse_string(insert))
			initial_subscription.emit(data)

		elif key == "TransactionUpdate":
			print("Received %s" % [key])
			var data: Dictionary = {}
			for table in item.status.Committed.tables:
				data[table.table_name] = {}
				for update in table.updates:
					data[table.table_name]["deletes"] = []
					data[table.table_name]["inserts"] = []
					for delete in update.deletes:
						data[table.table_name].deletes.append(JSON.parse_string(delete))
					for insert in update.inserts:
						data[table.table_name].inserts.append(JSON.parse_string(insert))
			transaction_update.emit(data)
		else:
			print("Unhandled message type: %s" % [key])
