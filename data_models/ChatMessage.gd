extends Node

class ChatMessage:
	var message_id: int
	var sender_id: String
	var message: String
	var timestamp: float
	
	func _init(message_id: int = 0, sender_id: String = "", message: String = "", timestamp: float = 0.0):
		self.message_id = message_id
		self.sender_id = sender_id
		self.message = message
		self.timestamp = timestamp
