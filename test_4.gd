extends Node3D

@onready var ChatUI = $ChatUI
@onready var stdbClient = $Spacetime_Client
@onready var playerCharacter = $PlayerCharacter

var stdbPlayer: Player = preload("res://data_models/Player.tres")
var remotePlayer: PackedScene = preload("res://remote_player.tscn")

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

func _exit_tree() -> void:
	set_process(false)
	# Remove player from Spacetime DB
	var argData = JSON.stringify([username])
	stdbClient.callReducer("RemovePlayer", argData)
	
	# wait a few seconds
	await get_tree().create_timer(5).timeout

	# Disconnect from Spacetime DB
	stdbClient.websocket_close()

func _process(_delta: float) -> void:
	render_player_list()
	sync_player()	

func _on_stdb_socket_open() -> void:
	pass

func _on_stdb_socket_closed() -> void:
	pass

func _on_stdb_initial_subscription(data) -> void:
	#print("Received Initial Subscription: %s" % [data])
	for table in data.keys():
		if table == "ChatMessages":
			for newChatMessage in data[table].inserts:
				var chatMessage: String = "[%s]: %s" % [newChatMessage.sender_id, newChatMessage.message]
				ChatUI.render_message("", chatMessage)
		if table == "Players":
			for newPlayer in data[table].inserts:
				insert_player(newPlayer)

func _on_stdb_transaction_update(data) -> void:
	#print("Received Transaction Update: %s" % [data])
	for table in data.keys():
		if table == "ChatMessages":
			for newChatMessage in data[table].inserts:
				ChatUI.render_message("", "[%s]: %s" % [newChatMessage.sender_id, newChatMessage.message])
		if table == "Players":
			var deleted_players: Dictionary = {}
			var inserted_players: Dictionary = {}
			
			for delPlayer in data[table].deletes:
				deleted_players[delPlayer.player_id] = delPlayer
			for newPlayer in data[table].inserts:
				inserted_players[newPlayer.player_id] = newPlayer

			for player_id in deleted_players.keys():
				if !inserted_players.has(player_id):
					# actual removed player
					delete_player(deleted_players[player_id])

			for player_id in inserted_players.keys():
				if !deleted_players.has(player_id):
					# actual new player
					insert_player(inserted_players[player_id])
				else:
					# player update
					update_player(inserted_players[player_id])


func _on_stdb_identity_token(data) -> void:
	print("Received Identity Token: %s" % [data])
	stdbClient.subscribe()

func send_chat_message(user: String, text: String) -> void:
	var argData = JSON.stringify([user, text])
	stdbClient.callReducer("AddChatMessage", argData)

func update_player(playerData) -> void:
	playerMap[playerData.player_id] = playerData

func insert_player(playerData) -> void:
	# ignore own player
	if playerData.identity == username:
		print("Ignoring own player.\n\tidentity: %s\n\tplayer_id: %s" % [playerData.identity, playerData.player_id])
		return
	playerMap[playerData.player_id] = playerData
	# add player to scene
	print("Adding player: %s" % [playerData.identity])
	spawn_player(playerData)

func delete_player(playerData) -> void:
	# remove player from scene
	print("Removing player: %s" % [playerData.identity])
	despawn_player(playerData)
	playerMap.erase(playerData.player_id)

func spawn_player(playerData) -> void:
	var newPlayerScene = remotePlayer.instantiate()
	newPlayerScene.name = playerData.identity
	print("adding remote player to scene: %s" % [newPlayerScene])
	add_child(newPlayerScene)

func despawn_player(playerData) -> void:
	for child in get_children():
		if child.name == playerData.identity:
			child.queue_free()

func sync_player() -> void:
	if !stdbClient.isSocketOpen:
		return

	var argData = JSON.stringify([
		username,
		"",
		{
			"X": playerCharacter.position.x,
			"Y": playerCharacter.position.y,
			"Z": playerCharacter.position.z
		},
		{
			"X": playerCharacter.rotation.x,
			"Y": playerCharacter.rotation.y,
			"Z": playerCharacter.rotation.z
		}
	])
	stdbClient.callReducer("UpsertPlayer", argData)

func render_player_list() -> void:
	var playerList: Array[String] = []
	for playerId in playerMap:
		playerList.append(playerMap[playerId].identity)
	ChatUI.render_player_list(playerList)

func generate_username() -> String:
	var adjectives = ["happy", "sad", "angry", "tall", "short"]
	var nouns = ["cat", "dog", "bird", "car", "tree"]

	var adj = adjectives.pick_random()
	var noun = nouns.pick_random()
	return "%s %s" % [adj, noun]
