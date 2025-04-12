extends RigidBody3D

var entity_id: int:
	get:
		return entity_id
	set(value):
		entity_id = value

var player: StdbPlayer:
	get:
		return player
	set(value):
		player = value
		entity_id = player.player_id

var stdbClient:
	get:
		return stdbClient
	set(value):
		stdbClient = value

func _ready() -> void:
	pass
	# randomize initial position
	#self.position = Vector3(randf_range(-100, 100), randf_range(-100, 100), randf_range(-100, 100))
	self.position = Vector3(
		randf_range(-15, 15), 
		randf_range(-15, 15), 
		randf_range(-15, 15)
	)
	sync_player(true)

func _process(_delta: float) -> void:
	sync_player()
	pass

func despawn() -> void:
	set_process(false)
	queue_free()

func sync_player(first_time: bool=false) -> void:
	if !stdbClient.isSocketOpen:
		return
	
	var argData = JSON.stringify([
		"ball",
		{
			"X": self.position.x,
			"Y": self.position.y,
			"Z": self.position.z
		},
		{
			"X": self.rotation.x,
			"Y": self.rotation.y,
			"Z": self.rotation.z
		}
	])
	
	if first_time:
		stdbClient.callReducer("UpsertPlayer", argData)
	else:
		stdbClient.callReducer("UpdatePlayer", argData)
