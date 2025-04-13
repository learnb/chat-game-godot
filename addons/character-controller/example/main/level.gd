extends Node3D

## Base class for demo level.
## Manages mouse inputs and their capture.

## If true, Esc key quit game
@export var fast_close := true

@onready var player = $Player
@onready var stdbClient = $Spacetime_Client
var playerMap: Dictionary = {}
var entityMap: Dictionary = {}

var username: String
var localPlayerId: int
var remotePlayer: PackedScene = preload("res://remote_player.tscn")
var remoteEntity: PackedScene = preload("res://remote_entity.tscn")

func _ready() -> void:
	#if !OS.is_debug_build():
	#	fast_close = false
	#if fast_close:
	#	print("** Fast Close enabled in the 'level.gd' script **")
	#	print("** 'Esc' to close 'Shift + F1' to release mouse **")
	#set_process_input(fast_close)

	self.username = generate_username()
	print("username: %s" % [self.username])

	stdbClient.connect("websocket_open", _on_stdb_socket_open)
	stdbClient.connect("websocket_closed", _on_stdb_socket_closed)
	stdbClient.connect("initial_subscription", _on_stdb_initial_subscription)
	stdbClient.connect("transaction_update", _on_stdb_transaction_update)
	stdbClient.connect("identity_token", _on_stdb_identity_token)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit() # Quits the game
	
	if event.is_action_pressed("change_mouse_input"):
		match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta: float) -> void:
	pass
	sync_player()

# Capture mouse if clicked on the game, needed for HTML5
# Called when an InputEvent hasn't been consumed by _input() or any GUI item
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_stdb_socket_open() -> void:
	pass
	sync_player(true)
	#spawn_stuff()
	
func _on_stdb_socket_closed() -> void:
	pass

func _on_stdb_initial_subscription(data: Dictionary) -> void:
	pass
	for table in data.keys():
		if table == "Players":
			for newPlayer in data[table].inserts:
				insert_player(newPlayer)
		if table == "Entities":
			for newEnt in data[table].inserts:
				insert_entity(newEnt)

func _on_stdb_transaction_update(data: Dictionary) -> void:
	pass
	for table in data.keys():
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
		if table == "Entities":
			print("Entity update")
			var deleted_entities: Dictionary = {}
			var inserted_entities: Dictionary = {}
			
			for delEnt in data[table].deletes:
				deleted_entities[delEnt.entity_id] = delEnt
			for newEnt in data[table].inserts:
				inserted_entities[newEnt.entity_id] = newEnt

			for entity_id in deleted_entities.keys():
				if !inserted_entities.has(entity_id):
					# actual removed entity
					delete_entity(deleted_entities[entity_id])

			for entity_id in inserted_entities.keys():
				if !deleted_entities.has(entity_id):
					# actual new entity
					insert_entity(inserted_entities[entity_id])
				else:
					# entity update
					update_entity(inserted_entities[entity_id])

func _on_stdb_identity_token(data: Dictionary) -> void:
	pass
	stdbClient.subscribe()

func _exit_tree() -> void:
	set_process(false)
	# Remove player from Spacetime DB
	var argData = JSON.stringify([username])
	stdbClient.callReducer("RemovePlayer", argData)

	# wait a few seconds before closing
	await get_tree().create_timer(5.0).timeout
	stdbClient.websocket_close()

func sync_player(first_time: bool=false) -> void:
	pass
	if !stdbClient.isSocketOpen:
		return
	
	var argData = JSON.stringify([
		username,
		"",
		{
			"X": self.player.position.x,
			"Y": self.player.position.y,
			"Z": self.player.position.z
		},
		{
			"X": self.player.rotation.x,
			"Y": self.player.rotation.y,
			"Z": self.player.rotation.z
		}
	])
	
	if first_time:
		stdbClient.callReducer("UpsertPlayer", argData)
	else:
		stdbClient.callReducer("UpdatePlayer", argData)

func insert_player(player: StdbPlayer) -> void:
	pass
	# ignore own player
	if player.identity == username:
		print("Ignoring own player.\n\tidentity: %s\n\tplayer_id: %s" % [player.identity, player.player_id])
		return
	playerMap[player.player_id] = player
	# add player to scene
	print("Adding player: %s" % [player.identity])
	spawn_player(player)

func update_player(player: StdbPlayer) -> void:
	pass
	playerMap[player.player_id] = player
	print("updated player %s position: %s" % [player.identity, player.position])

func delete_player(player: StdbPlayer) -> void:
	pass
	# remove player from scene
	print("Removing player: %s" % [player.identity])
	despawn_player(player)
	playerMap.erase(player.player_id)

func spawn_player(player: StdbPlayer) -> void:
	pass
	var newPlayerScene = remotePlayer.instantiate()
	newPlayerScene.name = "remotePlayer_%d" % player.player_id
	newPlayerScene.player_id = player.player_id
	newPlayerScene.stdbClient = stdbClient
	newPlayerScene.player = player
	print("adding remote player to scene: %s" % [newPlayerScene])
	add_child(newPlayerScene)

func despawn_player(player: StdbPlayer) -> void:
	pass
	for child in get_children():
		if child.name == "remotePlayer_%d" % player.player_id:
			print("removing remote player from scene: %s" % [child.name])
			child.despawn()

func insert_entity(entity: StdbEntity) -> void:
	pass
	entityMap[entity.entity_id] = entity
	print("Adding entity: %s" % [entity.entity_id])
	spawn_entity(entity)

func update_entity(entity: StdbEntity) -> void:
	pass
	entityMap[entity.entity_id] = entity

func delete_entity(entity: StdbEntity) -> void:
	pass
	# remove entity from scene
	print("Removing entity: %s" % [entity.entity_id])
	despawn_entity(entity)
	entityMap.erase(entity.entity_id)

func spawn_entity(entity: StdbEntity) -> void:
	pass
	var newEntityScene = remoteEntity.instantiate()
	newEntityScene.entity_id = entity.entity_id
	newEntityScene.name = "remoteEntity_%d" % entity.entity_id
	newEntityScene.stdbClient = stdbClient
	newEntityScene.entity = entity
	print("adding remote entity to scene: %s" % [newEntityScene])
	add_child(newEntityScene)

func despawn_entity(entity: StdbEntity) -> void:
	pass
	for child in get_children():
		if child.name == "remoteEntity_%d" % entity.entity_id:
			print("removing remote entity from scene: %s" % [child.name])
			child.despawn()

func spawn_stuff() -> void:
	if !stdbClient.isSocketOpen:
		return
	
	for index in range(0, 3):
		var argData = JSON.stringify([
			"Ball",
			{
				"X": randf_range(-15, 15), 
				"Y": randf_range(-15, 15), 
				"Z": randf_range(-15, 15)
			},
			{
				"X": 0,
				"Y": 0,
				"Z": 0
			}
		])
		
		stdbClient.callReducer("InsertEntity", argData)


#func spawn_stuff() -> void:
#	for index in range(0, 10):
#		var newEntityScene = remoteEntity.instantiate()
#		newEntityScene.entity_id = index
#		newEntityScene.name = "remoteEntity_%d" % [index]
#		newEntityScene.stdbClient = stdbClient
#		print("adding remote entity to scene: %s" % [newEntityScene])
#		add_child(newEntityScene)

func generate_username():
	var emojis = []
	for codepoint in range(0x1F600, 0x1F64F + 1):
		emojis.append(char(codepoint))
	for codepoint in range(0x1F300, 0x1F5FF + 1):
		emojis.append(char(codepoint))
	for codepoint in range(0x1F900, 0x1F9FF + 1):
		emojis.append(char(codepoint))
	var random_emojis = []
	for _i in range(3):
		#random_emojis.pick_random()
		random_emojis.append(emojis[randi() % emojis.size()])
	return "".join(random_emojis)
