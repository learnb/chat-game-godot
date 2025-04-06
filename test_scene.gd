extends Node3D

#@onready var viewport_container = $SubViewportContainer

#var chat_scene = preload("res://UI.tscn")

func _ready():
	pass
	# Create the chat UI instance
	#var chat_ui_instance = chat_scene.instantiate()
	#chat_ui_instance.visible = true
	#$SubViewportContainer/SubViewport.add_child(chat_ui_instance)

	# Position the HUD (update based on your preferences)
	#viewport_container.position = Vector2(10, 10)  # Position in the screen space if needed
