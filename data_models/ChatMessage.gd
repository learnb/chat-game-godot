class_name StdbChatMessage extends Resource

var table_name = "ChatMessages"

var message_id: int
var sender_id: String
var message: String
var timestamp: float

func _init(args: Array = []) -> void:
	if args.size() == 0:
		return
	self.message_id = args[0]
	self.sender_id = args[1]
	self.message = args[2]
	self.timestamp = args[3]

func _to_array() -> Array:
	return [message_id, sender_id, message, timestamp]

func update(args: Array = []) -> void:
	if args.size() == 0:
		return
	self.message_id = args[0]
	self.sender_id = args[1]
	self.message = args[2]

	if typeof(args[3]) == TYPE_DICTIONARY:
		self.timestamp = args[3].get("__timestamp_micros_since_unix_epoch__", 0)
	elif typeof(args[3]) == TYPE_ARRAY:
		self.timestamp = args[3][0]
	else:
		self.timestamp = args[3]
