extends Node2D

@onready var friend_list_button: Button = $VBoxContainer/HBoxContainer/ButtonContainer/FriendListButton
@onready var hangout_log_button: Button = $VBoxContainer/HBoxContainer/ButtonContainer/HangoutLogButton

@onready var friend_list: Control = $VBoxContainer/ScreenContainer/FriendList
@onready var hangout_log: Control = $VBoxContainer/ScreenContainer/HangoutLogScreen


func _ready() -> void:
	friend_list_button.pressed.connect(show_friend_list)
	hangout_log_button.pressed.connect(show_hangout_log)

	show_friend_list()


func show_friend_list() -> void:
	friend_list.visible = true
	hangout_log.visible = false


func show_hangout_log() -> void:
	friend_list.visible = false
	hangout_log.visible = true
	
	if hangout_log.has_method("refresh"):
		hangout_log.refresh()
