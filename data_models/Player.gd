class_name Player extends Resource

var table_name = "Players"

var player_id: int
var identity: String
var avatar_config: String
var position: Vector3
var rotation: Vector3
var is_online: bool

func _init(args: Array = []) -> void:
	if args.size() == 0:
		return
	self.player_id = args[0]
	self.identity = args[1]
	self.avatar_config = args[2]
	self.position = args[3]
	self.rotation = args[4]
	self.is_online = args[5]

func _to_array() -> Array:
	return [player_id, identity, avatar_config, position, rotation, is_online]

func update(args: Array = []) -> void:
	#for index in range(args.size()):
	#	print("arg %d: %s (%s)" % [index, args[index], typeof(args[index])])

	if args.size() == 0:
		return
	self.player_id = args[0]
	self.identity = args[1]
	self.avatar_config = args[2]

	if typeof(args[3]) == TYPE_DICTIONARY:
		self.position = Vector3(args[3].get("X", 0), args[3].get("Y", 0), args[3].get("Z", 0))
	elif typeof(args[3]) == TYPE_ARRAY:
		self.position = Vector3(args[3][0], args[3][1], args[3][2])	
	else:
		self.position = args[3]
	
	if typeof(args[4]) == TYPE_DICTIONARY:
		self.rotation = Vector3(args[4].get("X", 0), args[4].get("Y", 0), args[4].get("Z", 0))
	elif typeof(args[4]) == TYPE_ARRAY:
		self.rotation = Vector3(args[4][0], args[4][1], args[4][2])	
	else:
		self.rotation = args[4]	
	
	self.is_online = args[5]

	#print("[Player resource - Update]:\n\tplayer_id: %s\n\tidentity: %s\n\tavatar_config: %s\n\tposition: %s\n\trotation: %s\n\tisOnline: %s" % 
	#[self.player_id, self.identity, self.avatar_config, self.position, self.rotation, self.is_online])
