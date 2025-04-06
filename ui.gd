extends Control

@onready var chatLog = $VBoxContainer/RichTextLabel
@onready var inputLabel = $VBoxContainer/HBoxContainer/Label
@onready var inputField = $VBoxContainer/HBoxContainer/LineEdit

var username = "🐿"

func _ready():
	# Optional: Connect key press to send message on Enter
	inputField.connect("text_submitted", _on_message_entered)
	inputLabel.text = username

func _on_message_entered(text: String) -> void:
	if inputField.text:
		send_message(username, text)

func send_message(username: String, text: String) -> void:
	var msg: String = "\n[%s] %s" % [username, text]
	chatLog.add_text(msg)
	inputField.text = '' # clear input field
