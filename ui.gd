extends Control

@onready var chatLog = $ChatBoxContainer/RichTextLabel
@onready var inputLabel = $ChatBoxContainer/HBoxContainer/Label
@onready var inputField = $ChatBoxContainer/HBoxContainer/LineEdit

@onready var playerList = $PlayerListContainer/RichTextLabel

var username = "🐿"

signal send_message(username: String, text: String)

func _ready():
	# Optional: Connect key press to send message on Enter
	inputField.connect("text_submitted", _on_message_entered)
	inputLabel.text = username

func _on_message_entered(text: String) -> void:
	if inputField.text:
		emit_signal("send_message", username, text)

func render_message(username: String, text: String) -> void:
	var msg: String = "\n[%s] %s" % [username, text]
	chatLog.add_text(msg) # render message
	chatLog.scroll_to_line(chatLog.get_line_count() - 1) # scroll to bottom
	inputField.text = '' # clear input field

func render_player_list(players: Array) -> void:
	playerList.clear()
	for player in players:
		playerList.add_text("\n%s" % player)
	playerList.scroll_to_line(playerList.get_line_count() - 1)
