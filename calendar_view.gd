extends PanelContainer

@export var day_cell_scene: PackedScene

@onready var previous_month_button: Button = $VBoxContainer/HBoxContainer/PreviousMonthButton
@onready var month_year_label: Label = $VBoxContainer/HBoxContainer/MonthYearLabel
@onready var next_month_button: Button = $VBoxContainer/HBoxContainer/NextMonthButton

@onready var calendar_grid: GridContainer = $VBoxContainer/CalendarGrid

var displayed_month: int
var displayed_year: int

var month_name: Array = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ]

var hangouts: Array = []
var highlighted_hangout_id := ""

func _ready() -> void:
	var now:= Time.get_datetime_dict_from_system()
	displayed_month = now["month"]
	displayed_year = now["year"]
	
	previous_month_button.pressed.connect(_on_previous_month_button_pressed)
	next_month_button.pressed.connect(_on_next_month_button_pressed)
	
	refresh_calendar()


func convert_month_to_text(display_month: int) -> String:
	return month_name[display_month - 1]

func refresh_calendar() -> void:
	for child in calendar_grid.get_children():
		child.queue_free()

	month_year_label.text = "%s %d" % [convert_month_to_text(displayed_month), displayed_year]

	var first_day := {
		"year": displayed_year,
		"month": displayed_month,
		"day": 1,
		"hour": 12,
		"minute": 0,
		"second": 0
	}

	var first_unix := Time.get_unix_time_from_datetime_dict(first_day)
	var first_date := Time.get_datetime_dict_from_unix_time(first_unix)

	var weekday_offset: int = first_date["weekday"]
	var days_in_month := get_days_in_month(displayed_year, displayed_month)

	for i in range(weekday_offset):
		var empty_cell = day_cell_scene.instantiate()
		calendar_grid.add_child(empty_cell)
		empty_cell.setup_empty()

	for day in range(1, days_in_month + 1):
		var date_key := "%04d-%02d-%02d" % [
			displayed_year,
			displayed_month,
			day
		]

		var hangouts_on_day := get_hangouts_for_date_key(date_key)

		var cell = day_cell_scene.instantiate()
		calendar_grid.add_child(cell)

		cell.setup_day(
			day,
			hangouts_on_day.size(),
			should_highlight_day(hangouts_on_day)
		)

func get_hangouts_for_date_key(date_key: String) -> Array:
	return hangouts.filter(
		func(hangout):
			return hangout.get("date_key", "") == date_key
	)


func should_highlight_day(hangouts_on_day: Array) -> bool:
	for hangout in hangouts_on_day:
		if hangout.get("id", "") == highlighted_hangout_id:
			return true

	return hangouts_on_day.size() > 0


func get_days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			if is_leap_year(year):
				return 29
			return 28

	return 30


func is_leap_year(year: int) -> bool:
	return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

func _on_previous_month_button_pressed() -> void:
	displayed_month -= 1
	
	if displayed_month < 1:
		displayed_month = 12
		displayed_year -= 1
	
	refresh_calendar()

func _on_next_month_button_pressed() -> void:
	displayed_month += 1
	
	if displayed_month > 12:
		displayed_month = 1
		displayed_year += 1
		
	refresh_calendar()

func set_hangouts(new_hangouts: Array) -> void:
	print("Calendar received hangouts: ", hangouts.size())
	
	hangouts = new_hangouts
	refresh_calendar()

func jump_to_month(year: int, month: int, hangout_id: String) -> void:
	displayed_year = year
	displayed_month = month
	highlighted_hangout_id = hangout_id
	refresh_calendar()
