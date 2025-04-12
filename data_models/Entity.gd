class_name StdbEntity extends Resource

var table_name = "Entities"

var entity_id: int
var type: String
var position: Vector3
var rotation: Vector3

func _init(args: Array = []) -> void:
	if args.size() == 0:
		return
	self.entity_id = args[0]
	self.type = args[1]
	self.position = args[2]
	self.rotation = args[3]

func _to_array() -> Array:
	return [entity_id, type, position, rotation]

func update(args: Array = []) -> void:
	#for index in range(args.size()):
	#	print("arg %d: %s (%s)" % [index, args[index], typeof(args[index])])

	if args.size() == 0:
		return
	self.entity_id = args[0]
	self.type = args[1]

	if typeof(args[2]) == TYPE_DICTIONARY:
		self.position = Vector3(args[2].get("X", 0), args[2].get("Y", 0), args[2].get("Z", 0))
	elif typeof(args[2]) == TYPE_ARRAY:
		self.position = Vector3(args[2][0], args[2][1], args[2][2])	
	else:
		self.position = args[2]
	
	if typeof(args[3]) == TYPE_DICTIONARY:
		self.rotation = Vector3(args[3].get("X", 0), args[3].get("Y", 0), args[3].get("Z", 0))
	elif typeof(args[3]) == TYPE_ARRAY:
		self.rotation = Vector3(args[3][0], args[3][1], args[3][2])	
	else:
		self.rotation = args[3]	
