extends Control

#edit hangout variables
#signal edit_requested(friend_id: String, hangout_id: String)

@onready var edit_hangout_window: ConfirmationDialog = $EditHangoutWindow
@onready var hangout_type_option: OptionButton = $EditHangoutWindow/VBoxContainer/HangoutTypeOption
@onready var edit_hangout_label: TextEdit = $EditHangoutWindow/VBoxContainer/editHangoutLabel

@onready var edit_month_option: OptionButton = $EditHangoutWindow/VBoxContainer/DateHContainer/EditMonthOption
@onready var edit_day_option: OptionButton = $EditHangoutWindow/VBoxContainer/DateHContainer/EditDayOption
@onready var edit_year_option: OptionButton = $EditHangoutWindow/VBoxContainer/DateHContainer/EditYearOption

@onready var edit_start_time_input: LineEdit = $EditHangoutWindow/VBoxContainer/TimeHContainer/EditStartTimeInput
@onready var edit_end_time_input: LineEdit = $EditHangoutWindow/VBoxContainer/TimeHContainer/EditEndTimeInput

@onready var calendar_view: PanelContainer = $CalendarView

var day_names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
#var day_names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

@onready var hangout_search_bar: LineEdit = $VBoxContainer/HangoutSearchBar
var all_hangouts: Array = []
var filtered_hangouts: Array = []

var editing_friend_id := ""
var editing_hangout_id := ""
var friends: Array = []

@export var hangout_log_entry_scene: PackedScene
@export var default_profile_image: Texture2D
@onready var hangout_list_container: VBoxContainer = $VBoxContainer/ScrollContainer/HangoutListContainer

func _ready() -> void:
	setup_date_dropdowns()
	edit_hangout_window.hide()
	edit_hangout_window.confirmed.connect(_on_save_edit_button_pressed)
	setup_hangout_type_options()
	
	hangout_search_bar.text_changed.connect(apply_search_filter)
	refresh()

func refresh() -> void:
	all_hangouts = build_all_hangouts()
	# No search by default.
	apply_search_filter(hangout_search_bar.text)
	
	#for child in hangout_list_container.get_children():
		#child.queue_free()
#
	#var friends: Array = DataManager.load_friends()
	#var all_hangouts := []
#
	#for friend in friends: 
		#var friend_name := "%s %s" % [
			#friend.get("first_name", ""),
			#friend.get("last_name", "")
		#]
#
		#for hangout in friend.get("hangouts", []):
			#all_hangouts.append({
				#"friend_id": friend.get("id", ""),
				#"hangout_id": hangout.get("id", ""),
				#"participants": [friend],
				#"date_timestamp": hangout.get("date_timestamp", 0),
				#"date_key": get_date_key_from_unix(hangout.get("date_unix", 0)),
				#"type": hangout.get("type", "Hangout"),
				#"notes": hangout.get("notes", "")
			#})
#
		#all_hangouts.sort_custom(
		#func(a, b):
			#return a["date_timestamp"] > b["date_timestamp"]
	#)
#
	#for hangout in all_hangouts:
		#var entry = hangout_log_entry_scene.instantiate()
		#hangout_list_container.add_child(entry)
#
		#entry.setup(
			#hangout["participants"],
			#hangout["date_timestamp"],
			#format_unix_date(hangout["date_timestamp"]),
			#hangout["type"],
			#hangout["notes"],
			#default_profile_image,
			#hangout["friend_id"],
			#hangout["hangout_id"]
		#)
	#
		#entry.selected.connect(_on_hangout_selected)
		#entry.edit_requested.connect(_on_hangout_edit_requested)

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
	
	var date_dict := get_local_datetime_from_unix(hangout.get("date_timestamp", 0))
	
	print(date_dict["month"])
	print(date_dict["day"])
	print(date_dict["year"])
	select_option_by_id(edit_month_option, date_dict["month"])
	select_option_by_id(edit_day_option, date_dict["day"])
	select_option_by_id(edit_year_option, date_dict["year"])

	edit_end_time_input.text = format_time_12h(
		date_dict["hour"],
		date_dict["minute"]
	)


func _on_save_edit_button_pressed() -> void:
	var selected_date := get_selected_date_dict()

	var edited_timestamp: int = parse_local_datetime_to_unix_from_parts(
		selected_date["year"],
		selected_date["month"],
		selected_date["day"],
		edit_end_time_input.text
	)
	
	if edited_timestamp <= 0:
		push_error("Invalid date/time.")
		return
	
	for friend in friends:
		if friend.get("id", "") != editing_friend_id:
			continue

		for hangout in friend.get("hangouts", []):
			if hangout.get("id", "") == editing_hangout_id:
				hangout["type"] = hangout_type_option.get_item_text(hangout_type_option.selected)
				hangout["notes"] = edit_hangout_label.text.strip_edges()
				hangout["date_timestamp"] = edited_timestamp
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
		
	return "%s • %02d/%02d/%d • %d:%02d %s" % [
		day_names[date["weekday"]],
		date["month"],
		date["day"],
		date["year"],
		hour_12,
		minute,
		meridian
	]

#region DateInfo
func setup_date_dropdowns() -> void:
	edit_month_option.clear()
	edit_day_option.clear()
	edit_year_option.clear()

	for month in range(1, 13):
		edit_month_option.add_item(str(month), month)

	for day in range(1, 32):
		edit_day_option.add_item(str(day), day)

	var current_year: int = Time.get_datetime_dict_from_system()["year"]

	# add the last 10 years as available year options
	for offset in range(11):
		var year := current_year - offset
		edit_year_option.add_item(str(year), year)


func select_option_by_id(option_button: OptionButton, id: int) -> void:
	for i in range(option_button.item_count):
		if option_button.get_item_id(i) == id:
			option_button.select(i)
			return

func get_selected_date_dict() -> Dictionary:
	return {
		"year": edit_year_option.get_selected_id(),
		"month": edit_month_option.get_selected_id(),
		"day": edit_day_option.get_selected_id()
	}

func format_time_12h(hour_24: int, minute: int) -> String:
	var meridian := "AM"

	if hour_24 >= 12:
		meridian = "PM"

	var hour_12 := hour_24 % 12

	if hour_12 == 0:
		hour_12 = 12

	return "%d:%02d %s" % [
		hour_12,
		minute,
		meridian
	]

func parse_local_datetime_to_unix_from_parts(year: int, month: int, day: int, time_text: String) -> int:
	var cleaned_time := time_text.strip_edges().to_upper()
	var is_pm := cleaned_time.ends_with("PM")
	var is_am := cleaned_time.ends_with("AM")

	cleaned_time = cleaned_time.replace("AM", "")
	cleaned_time = cleaned_time.replace("PM", "")
	cleaned_time = cleaned_time.strip_edges()

	var time_parts := cleaned_time.split(":")

	if time_parts.size() != 2:
		return -1

	var hour := int(time_parts[0])
	var minute := int(time_parts[1])

	if is_pm and hour < 12:
		hour += 12

	if is_am and hour == 12:
		hour = 0

	var datetime := {
		"year": year,
		"month": month,
		"day": day,
		"hour": hour,
		"minute": minute,
		"second": 0
	}

	var local_unix := Time.get_unix_time_from_datetime_dict(datetime)

	var timezone_info := Time.get_time_zone_from_system()
	var bias_minutes: int = timezone_info.get("bias", 0)

	return local_unix - (bias_minutes * 60)

func get_date_key_from_unix(unix_time: int) -> String:
	var date := get_local_datetime_from_unix(unix_time)

	return "%04d-%02d-%02d" % [
		date["year"],
		date["month"],
		date["day"]
	]

#endregion

func _on_hangout_selected(hangout_id: String, date_timestamp: int) -> void:
	var date := get_local_datetime_from_unix(date_timestamp)

	calendar_view.jump_to_month(
		date["year"],
		date["month"],
		hangout_id
	)

func apply_search_filter(search_text: String) -> void:
	var cleaned := search_text.to_lower().strip_edges()

	if cleaned == "":
		filtered_hangouts = all_hangouts
	else:
		filtered_hangouts = all_hangouts.filter(
			func(hangout):
				return hangout.get("friend_name", "").to_lower().contains(cleaned)
		)

	populate_hangout_list(filtered_hangouts)
	calendar_view.set_hangouts(filtered_hangouts)

func populate_hangout_list(hangout_list: Array) -> void:
	for child in hangout_list_container.get_children():
		child.queue_free()

	for hangout in hangout_list:
		var entry = hangout_log_entry_scene.instantiate()

		hangout_list_container.add_child(entry)

		entry.setup(
			hangout["participants"],
			hangout["date_timestamp"],
			format_unix_date(hangout["date_timestamp"]),
			hangout["type"],
			hangout["notes"],
			default_profile_image,
			hangout["friend_id"],
			hangout["id"]
		)

		entry.edit_requested.connect(_on_hangout_edit_requested)
		entry.selected.connect(_on_hangout_selected)

func build_all_hangouts() -> Array:
	var friends := DataManager.load_friends()
	var results := []

	for friend in friends:
		var friend_name := "%s %s" % [
			friend.get("first_name", ""),
			friend.get("last_name", "")
		]

		for hangout in friend.get("hangouts", []):
			results.append({
				"id": hangout.get("id", ""),
				"friend_id": friend.get("id", ""),
				"friend_name": friend_name.strip_edges(),
				"participants": [friend],
				"date_timestamp": hangout.get("date_timestamp", 0),
				"date_key": get_date_key_from_unix(hangout.get("date_timestamp", 0)),
				"type": hangout.get("type", "Hangout"),
				"notes": hangout.get("notes", "")
			})

	results.sort_custom(
		func(a, b):
			return a["date_timestamp"] > b["date_timestamp"]
	)

	return results
