extends RigidBody3D

var player_id: int:
	get:
		return player_id
	set(value):
		player_id = value

var player: Player:
	get:
		return player
	set(value):
		player = value
		player_id = player.player_id

var stdbClient:
	get:
		return stdbClient
	set(value):
		stdbClient = value

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	sync_player()
	pass

func despawn() -> void:
	set_process(false)
	queue_free()

func sync_player() -> void:
	if !stdbClient:
		print("no stdbClient for player: %s" % [name])
		return
	
	if !player:
		print("no player set for player: %s" % [name])
		return
	
	if !stdbClient.isSocketOpen:
		return

	var argData = JSON.stringify([
		player.identity,
		"",
		{
			"X": player.position.x,
			"Y": player.position.y,
			"Z": player.position.z
		},
		{
			"X": player.rotation.x,
			"Y": player.rotation.y,
			"Z": player.rotation.z
		}
	])
	stdbClient.callReducer("UpdatePlayer", argData)
