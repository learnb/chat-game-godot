extends Node3D

@onready var ChatBox = $ChatBox

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _on_spacetime_db_new_chat_message(msg: Variant) -> void:
	pass # Replace with function body.
	ChatBox.send_message("", msg)
