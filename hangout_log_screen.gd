extends Control

#edit hangout variables
#signal edit_requested(friend_id: String, hangout_id: String)

@onready var edit_hangout_window: ConfirmationDialog = $EditHangoutWindow
@onready var hangout_type_option: OptionButton = $EditHangoutWindow/VBoxContainer/HangoutTypeOption
@onready var edit_hangout_label: TextEdit = $EditHangoutWindow/VBoxContainer/editHangoutLabel

var editing_friend_id := ""
var editing_hangout_id := ""
var friends: Array = []

@export var hangout_log_entry_scene: PackedScene
@export var default_profile_image: Texture2D
@onready var hangout_list_container: VBoxContainer = $VBoxContainer/ScrollContainer/HangoutListContainer

func _ready() -> void:
	edit_hangout_window.hide()
	edit_hangout_window.confirmed.connect(_on_save_edit_button_pressed)
	setup_hangout_type_options()
	refresh()

func refresh() -> void:
	for child in hangout_list_container.get_children():
		child.queue_free()

	var friends: Array = DataManager.load_friends()
	var all_hangouts := []

	for friend in friends: 
		var friend_name := "%s %s" % [
			friend.get("first_name", ""),
			friend.get("last_name", "")
		]

		for hangout in friend.get("hangouts", []):
			all_hangouts.append({
				"friend_id": friend.get("id", ""),
				"hangout_id": hangout.get("id", ""),
				"participants": [friend],
				"date_timestamp": hangout.get("date_timestamp", 0),
				"type": hangout.get("type", "Hangout"),
				"notes": hangout.get("notes", "")
			})

		all_hangouts.sort_custom(
		func(a, b):
			return a["date_timestamp"] > b["date_timestamp"]
	)

	for hangout in all_hangouts:
		var entry = hangout_log_entry_scene.instantiate()
		hangout_list_container.add_child(entry)

		entry.setup(
			hangout["participants"],
			format_unix_date(hangout["date_timestamp"]),
			hangout["type"],
			hangout["notes"],
			default_profile_image,
			hangout["friend_id"],
			hangout["hangout_id"]
		)
	
		entry.edit_requested.connect(_on_hangout_edit_requested)

func _on_hangout_edit_requested(friend_id: String, hangout_id: String) -> void:
	friends = DataManager.load_friends()

	var hangout := get_hangout_by_id(friend_id, hangout_id)

	if hangout.is_empty():
		return

	editing_friend_id = friend_id
	editing_hangout_id = hangout_id

	select_option_by_text(hangout_type_option, hangout.get("type", "Hangout"))
	edit_hangout_label.text = hangout.get("notes", "")

	edit_hangout_window.popup_centered()
	edit_hangout_label.grab_focus()

func _on_save_edit_button_pressed() -> void:
	for friend in friends:
		if friend.get("id", "") != editing_friend_id:
			continue

		for hangout in friend.get("hangouts", []):
			if hangout.get("id", "") == editing_hangout_id:
				hangout["type"] = hangout_type_option.get_item_text(hangout_type_option.selected)
				hangout["notes"] = edit_hangout_label.text.strip_edges()
				break

	DataManager.save_friends(friends)

	edit_hangout_window.hide()
	editing_friend_id = ""
	editing_hangout_id = ""

	refresh()

func get_hangout_by_id(friend_id: String, hangout_id: String) -> Dictionary:
	for friend in friends:
		if friend.get("id", "") != friend_id:
			continue

		for hangout in friend.get("hangouts", []):
			if hangout.get("id", "") == hangout_id:
				return hangout

	return {}


func setup_hangout_type_options() -> void:
	hangout_type_option.clear()
	hangout_type_option.add_item("Hangout")
	hangout_type_option.add_item("Dinner")
	hangout_type_option.add_item("Coffee")
	hangout_type_option.add_item("Call")
	hangout_type_option.add_item("Text")
	hangout_type_option.add_item("Game Night")
	hangout_type_option.add_item("Other")
	

func select_option_by_text(option_button: OptionButton, text: String) -> void:
	for i in range(option_button.item_count):
		if option_button.get_item_text(i) == text:
			option_button.select(i)
			return

	option_button.select(0)

func get_local_datetime_from_unix(unix_time: int) -> Dictionary:
	var timezone_info := Time.get_time_zone_from_system()
	var bias_minutes: int = timezone_info.get("bias", 0)

	# bias is minutes offset from UTC
	var local_unix: int = unix_time + (bias_minutes * 60)

	return Time.get_datetime_dict_from_unix_time(local_unix)

func format_unix_date(unix_time: int) -> String:
	if unix_time <= 0:
		return "Unknown date"

	var date := get_local_datetime_from_unix(unix_time)

	var hour_24: int = date["hour"]
	var minute: int = date["minute"]

	var meridian := "AM"
	if hour_24 >= 12:
		meridian = "PM"

	var hour_12 := hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
		
	return "%02d/%02d/%d%s %d:%02d %s" % [
		date["month"],
		date["day"],
		date["year"],
		" •",
		hour_12,
		minute,
		meridian
	]
