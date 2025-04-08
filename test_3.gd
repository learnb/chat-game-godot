extends Node3D

@onready var ChatBox = $ChatBox
@onready var stdbClient = $Spacetime_Client

func _ready() -> void:
	stdbClient.connect("websocket_open", _on_stdb_socket_open)
	stdbClient.connect("websocket_closed", _on_stdb_socket_closed)
	stdbClient.connect("new_message", _on_stdb_new_message)
	ChatBox.connect("send_message", send_chat_message)


func _process(delta: float) -> void:
	pass

func _on_stdb_socket_open() -> void:
	pass

func _on_stdb_socket_closed() -> void:
	pass

func _on_stdb_new_message(msg: Variant) -> void:
	# TODO process messages
	parseStdbMessage(msg)
	#ChatBox.send_message("", msg)

func parseStdbMessage(msg: PackedByteArray) -> void:
	print("Server message: %s" % [msg.get_string_from_utf8()])
	var json = JSON.parse_string(msg.get_string_from_utf8())
	assert(json != null)
	
	for key in json:
		var item = json.get(key)
		if key == "IdentityToken":
			print("Received %s" % [key])
			stdbClient.subscribe()
		elif key == "InitialSubscription":
			print("Received %s" % [key])
			var updates = item.database_update.tables[0].updates
			for update in updates:
				var inserts = update.inserts
				for insert in inserts:
					var row = JSON.parse_string(insert)
					print("row: %s" % [row])
					var chatMessage: String = "[%s]: %s" % [row.SenderId, row.Message]
					ChatBox.render_message("", chatMessage)
		elif key == "TransactionUpdate":
			print("Received %s" % [key])
			var updates = item.status.Committed.tables[0].updates
			for update in updates:
				var inserts = update.inserts
				for insert in inserts:
					var messageArray = JSON.parse_string(insert)
					var row = {
						"MessageId": messageArray[0],
						"SenderId": messageArray[1],
						"Message": messageArray[2],
						"Timestamp": messageArray[3]
					}
					print("row: %s" % [row])
					var chatMessage: String = "[%s]: %s" % [row.SenderId, row.Message]
					ChatBox.render_message("", chatMessage)
		else:
			print("Unhandled message type: %s" % [key])

func send_chat_message(username: String, text: String) -> void:
	var argData = JSON.stringify([username, text])
	stdbClient.callReducer("AddChatMessage", argData)
