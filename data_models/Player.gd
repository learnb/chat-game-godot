extends Node

class Player:
	var player_id: int
	var identity: String
	var avatar_config: String
	var position: Vector3
	var rotation: Vector3
	var is_online: bool
	
	func _init(player_id: int = 0, identity: String = "", avatar_config: String = "", position: Vector3 = Vector3.ZERO, rotation: Vector3 = Vector3.ZERO, is_online: bool = false):
		self.player_id = player_id
		self.identity = identity
		self.avatar_config = avatar_config
		self.position = position
		self.rotation = rotation
		self.is_online = is_online
