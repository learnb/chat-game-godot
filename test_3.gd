extends Node3D

@onready var ChatBox = $ChatBox
@onready var stdbClient = $Spacetime_Client

func _ready() -> void:
	stdbClient.connect("websocket_open", _on_stdb_socket_open)
	stdbClient.connect("websocket_closed", _on_stdb_socket_closed)
	stdbClient.connect("new_message", _on_stdb_new_message)


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
					ChatBox.send_message("", chatMessage)
		elif key == "TransactionUpdate":
			print("Received %s" % [key])
		else:
			print("Unhandled message type: %s" % [key])
