extends Node3D

@onready var ChatUI = $ChatUI
@onready var stdbClient = $Spacetime_Client

var playerMap: Dictionary = {}

func _ready() -> void:
	stdbClient.connect("websocket_open", _on_stdb_socket_open)
	stdbClient.connect("websocket_closed", _on_stdb_socket_closed)
	#stdbClient.connect("new_message", _on_stdb_new_message)
	stdbClient.connect("initial_subscription", _on_stdb_initial_subscription)
	stdbClient.connect("transaction_update", _on_stdb_transaction_update)
	stdbClient.connect("identity_token", _on_stdb_identity_token)
	
	ChatUI.connect("send_message", send_chat_message)

func _process(delta: float) -> void:
	render_player_list()

func _on_stdb_socket_open() -> void:
	pass

func _on_stdb_socket_closed() -> void:
	pass

func _on_stdb_initial_subscription(data) -> void:
	print("Received Initial Subscription: %s" % [data])
	for table in data.keys():
		if table == "ChatMessages":
			for insert in data[table].inserts:
				var chatMessage: String = "[%s]: %s" % [insert.SenderId, insert.Message]
				ChatUI.render_message("", chatMessage)
				print("sent message: %s" % [chatMessage])
		if table == "Players":
			for insert in data[table].inserts:
				insert_player(insert)

func _on_stdb_transaction_update(data) -> void:
	print("Received Transaction Update: %s" % [data])
	for table in data.keys():
		if table == "ChatMessages":
			for insert in data[table].inserts:
				var row = {
					"MessageId": insert[0],
					"SenderId": insert[1],
					"Message": insert[2],
					"Timestamp": insert[3]
				}
				var chatMessage: String = "[%s]: %s" % [row.SenderId, row.Message]
				ChatUI.render_message("", chatMessage)
		if table == "Players":
			for delete in data[table].deletes:
				var row = {
					"PlayerId": delete[0],
					"Identity": delete[1],
					"AvatarConfig": delete[2],
					"Position": delete[3],
					"Rotation": delete[4],
					"isOnline": delete[5]
				}
				delete_player(row)
			for insert in data[table].inserts:
				var row = {
					"PlayerId": insert[0],
					"Identity": insert[1],
					"AvatarConfig": insert[2],
					"Position": insert[3],
					"Rotation": insert[4],
					"isOnline": insert[5]
				}	
				insert_player(row)

func _on_stdb_identity_token(data) -> void:
	print("Received Identity Token: %s" % [data])
	stdbClient.subscribe()

func _on_stdb_new_message(msg: Variant) -> void:
	parseStdbMessage(msg)

func send_chat_message(username: String, text: String) -> void:
	var argData = JSON.stringify([username, text])
	stdbClient.callReducer("AddChatMessage", argData)

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
			parseInitialSubscription(item)
		elif key == "TransactionUpdate":
			print("Received %s" % [key])
			parseTransactionUpdate(item)
		else:
			print("Unhandled message type: %s" % [key])
	render_player_list()

func parseInitialSubscription(data) -> void:
	var tables = data.database_update.tables
	for table in tables:
		print("processing table: %s" % [table])
		if table.table_name not in ["ChatMessages", "Players"]:
			continue
		if table.table_name == "ChatMessages":
			var updates = table.updates
			for update in updates:
				var inserts = update.inserts
				for insert in inserts:
					var row = JSON.parse_string(insert)
					print("insert row: %s" % [row])
					var chatMessage: String = "[%s]: %s" % [row.SenderId, row.Message]
					ChatUI.render_message("", chatMessage)
		if table.table_name == "Players":
			var updates = table.updates
			for update in updates:
				var inserts = update.inserts
				for insert in inserts:
					var row = JSON.parse_string(insert)
					print("insert row: %s" % [row])
					var playerData = {
						"PlayerId": row.PlayerId,
						"Identity": row.Identity,
						"AvatarConfig": row.AvatarConfig,
						"Position": row.Position,
						"Rotation": row.Rotation,
						"IsOnline": row.IsOnline
					}
					print("playerData: %s" % [playerData])
					insert_player(playerData)

func parseTransactionUpdate(data) -> void:
	var tables = data.status.Committed.tables
	for table in tables:
		print("processing table: %s" % [table])
		if table.table_name not in ["ChatMessages", "Players"]:
			continue
		if table.table_name == "ChatMessages":
			var updates = table.updates
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
					print("insert row: %s" % [row])
					var chatMessage: String = "[%s]: %s" % [row.SenderId, row.Message]
					ChatUI.render_message("", chatMessage)
		if table.table_name == "Players":
			var updates = table.updates
			for update in updates:
				var deletes = update.deletes
				for delete in deletes:
					var messageArray = JSON.parse_string(delete)
					var playerData = {
						"PlayerId": messageArray[0],
						"Identity": messageArray[1],
						"AvatarConfig": messageArray[2],
						"Position": messageArray[3],
						"Rotation": messageArray[4],
						"IsOnline": messageArray[5]
					}
					print("delete playerData: %s" % [playerData])
					delete_player(playerData)
				var inserts = update.inserts
				for insert in inserts:
					var messageArray = JSON.parse_string(insert)
					var playerData = {
						"PlayerId": messageArray[0],
						"Identity": messageArray[1],
						"AvatarConfig": messageArray[2],
						"Position": messageArray[3],
						"Rotation": messageArray[4],
						"IsOnline": messageArray[5]
					}
					print("insert playerData: %s" % [playerData])
					insert_player(playerData)	

func update_player(playerData) -> void:
	playerMap[playerData.PlayerId] = playerData
	if !playerData.isOnline:
		playerMap.erase(playerData.PlayerId)

func insert_player(playerData) -> void:
	playerMap[playerData.PlayerId] = playerData

func delete_player(playerData) -> void:
	playerMap.erase(playerData.PlayerId)

func render_player_list() -> void:
	var playerList: Array[String] = []
	for playerId in playerMap:
		playerList.append(playerMap[playerId].Identity)
	ChatUI.render_player_list(playerList)
