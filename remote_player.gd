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

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
