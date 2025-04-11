extends Node3D

@onready var ChatUI = $ChatUI
@onready var stdbClient = $Spacetime_Client

var username: String

var playerMap: Dictionary = {}

func _ready() -> void:
	stdbClient.connect("websocket_open", _on_stdb_socket_open)
	stdbClient.connect("websocket_closed", _on_stdb_socket_closed)
	stdbClient.connect("initial_subscription", _on_stdb_initial_subscription)
	stdbClient.connect("transaction_update", _on_stdb_transaction_update)
	stdbClient.connect("identity_token", _on_stdb_identity_token)
	ChatUI.connect("send_message", send_chat_message)

	username = generate_username()
	ChatUI.set_username(username)

func _process(_delta: float) -> void:
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

func send_chat_message(user: String, text: String) -> void:
	var argData = JSON.stringify([user, text])
	stdbClient.callReducer("AddChatMessage", argData)

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

func generate_username() -> String:
	var adjectives = ["happy", "sad", "angry", "tall", "short"]
	var nouns = ["cat", "dog", "bird", "car", "tree"]

	var adj = adjectives.pick_random()
	var noun = nouns.pick_random()
	return "%s %s" % [adj, noun]
