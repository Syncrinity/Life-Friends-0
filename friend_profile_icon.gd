extends Control

signal delete_requested(friend_id: String)
signal check_in_requested(friend_id: String)

@onready var friend_image: TextureRect = $VBoxContainer/FriendImage
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var first_name_label: Label = $VBoxContainer/HBoxContainer/FirstNameLabel
@onready var last_name_label: Label = $VBoxContainer/HBoxContainer/LastNameLabel
#@onready var delete_button: Button = $DeleteButton
@onready var delete_button: Button = $VBoxContainer/DeleteButton
@onready var check_in_button: Button = $VBoxContainer/CheckInButton
@onready var last_seen_label: Label = $VBoxContainer/LastSeenLabel

var friend_id: String = ""
const MAX_DAYS_WITHOUT_SEEING := 30.0

func _ready() -> void:
	check_in_button.pressed.connect(_on_check_in_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)

func setup(id: String, first_name: String, last_name: String, image: Texture2D, last_seen_timestamp: int) -> void:
	friend_id = id
	first_name_label.text = first_name
	last_name_label.text = last_name
	friend_image.texture = image
	update_last_seen_display(last_seen_timestamp)

func update_last_seen_display(last_seen_timestamp: int) -> void:
	if last_seen_timestamp <= 0:
		last_seen_label.text = "Never seen"
		progress_bar.value = 0
		return

	var now := Time.get_unix_time_from_system()
	var seconds_since_seen := now - last_seen_timestamp
	var days_since_seen := seconds_since_seen / 86400.0
	
	# display today if just recently updated
	if int(days_since_seen) == 0:
		last_seen_label.text = "Last seen today"
	else:
		last_seen_label.text = "Last seen %d days ago" % int(days_since_seen)

	var hpPercent: float = 1.0 - clamp(days_since_seen / MAX_DAYS_WITHOUT_SEEING, 0.0, 1.0)
	progress_bar.value = hpPercent * 100.0

func _on_check_in_pressed() -> void:
	check_in_requested.emit(friend_id)

func _on_delete_button_pressed() -> void:
	delete_requested.emit(friend_id)
