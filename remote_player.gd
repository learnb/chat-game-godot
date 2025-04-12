extends RigidBody3D

var player_id: int:
	get:
		return player_id
	set(value):
		player_id = value

var player: StdbPlayer:
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

func _process(_delta: float) -> void:
	sync_player()
	pass

func despawn() -> void:
	set_process(false)
	queue_free()

func sync_player() -> void:
	if !player:
		print("no player set for player: %s" % [name])
		return
	self.player = self.get_parent().playerMap[player.player_id]
	print("[sync player] id: %s, position: %s" % [player.identity, player.position])
	#print("player: %s\n\tposition: %s" % [player.identity, player.position])	
	self.position = player.position
	self.rotation = player.rotation	
