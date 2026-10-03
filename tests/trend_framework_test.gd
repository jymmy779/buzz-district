extends SceneTree
# Run: godot --headless --path . --script tests/trend_framework_test.gd
const TEST_SAVE := "user://buzz_district_trend_framework_test.json"
var game
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TEST FAILED: " + message)

func sample_profiles(count: int) -> Dictionary:
	var result := {"office_worker": 0, "student": 0, "shipper": 0}
	for i in range(count):
		result[game.choose_customer_profile()] += 1
	return result

func sample_offerings(cafe: Button, count: int) -> Dictionary:
	var result := {"coffee": 0, "matcha_latte": 0}
	for i in range(count):
		result[game.choose_offering(cafe)] += 1
	return result

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	game = load("res://scenes/world/Main.tscn").instantiate()
	game.save_path = TEST_SAVE
	root.add_child(game)
	game.set_process(false)
	game.money = 5000
	var cafe: Button = game.plot_grid.get_child(0)
	var mart: Button = game.plot_grid.get_child(1)
	game.build_business(cafe, "cafe")
	game.build_business(mart, "minimart")

	seed(112233)
	var normal_profiles := sample_profiles(5000)
	check(normal_profiles["office_worker"] > 2100 and normal_profiles["office_worker"] < 2400, "Base profile distribution")
	seed(445566)
	var normal_offerings := sample_offerings(cafe, 5000)

	game.start_trend("matcha_wave")
	seed(112233)
	check(sample_profiles(5000) == normal_profiles, "Matcha Wave leaves profile weights unchanged")
	seed(445566)
	var matcha_offerings := sample_offerings(cafe, 5000)
	check(matcha_offerings["matcha_latte"] > normal_offerings["matcha_latte"] + 2000, "Matcha Wave increases Matcha")
	check(game.get_trend_modifier("customer_profile_spawn_modifiers", "office_worker") == 1.0, "Missing modifier defaults to one")

	game.update_trend(20.0)
	game.start_trend("lunch_rush")
	check(game.is_trend_active("lunch_rush") and not game.is_trend_active("matcha_wave"), "New trend replaces old trend")
	check(game.get_active_trend()["id"] == "lunch_rush", "Generic active trend lookup")
	check(game.trend_label.text == "TREND: Lunch Rush" and game.trend_remaining == 30.0, "Replacement resets indicator and duration")
	check(game.get_offering_selection_weight("coffee") == 70.0 and game.get_offering_selection_weight("matcha_latte") == 30.0, "No stale Matcha modifier")
	seed(445566)
	check(sample_offerings(cafe, 5000) == normal_offerings, "Lunch Rush leaves offering weights unchanged")
	seed(112233)
	var lunch_profiles := sample_profiles(5000)
	check(lunch_profiles["office_worker"] > 3150 and lunch_profiles["office_worker"] < 3450, "Lunch Rush increases Office Workers")

	game.update_trend(10.1)
	check(game.is_trend_active("lunch_rush"), "Replaced trend lifetime does not end newer trend")
	game.update_trend(19.9)
	check(not game.is_trend_active("lunch_rush") and not game.trend_label.visible, "Lunch Rush expires at its own duration")
	check(game.get_trend_modifier("customer_profile_spawn_modifiers", "office_worker") == 1.0, "Expiration restores profile weights")
	check(game.TREND_DATA["lunch_rush"]["threadz_end_posts"].has(game.threadz_posts[0]["text"]), "Lunch Rush publishes one end post")
	check(game.TREND_DATA["lunch_rush"]["threadz_start_posts"].has(game.threadz_posts[1]["text"]), "Lunch Rush publishes one start post")

	var y_event := InputEventKey.new()
	y_event.physical_keycode = KEY_Y
	y_event.pressed = true
	game._unhandled_key_input(y_event)
	check(game.is_trend_active("lunch_rush") and game.trend_label.text == "TREND: Lunch Rush", "Debug Y starts Lunch Rush")
	game.save_game()
	var raw := FileAccess.get_file_as_string(TEST_SAVE)
	check(not raw.contains("active_trend") and JSON.parse_string(raw)["version"] == 1, "Trend remains transient")
	game.free()
	DirAccess.remove_absolute(TEST_SAVE)
	print("TREND FRAMEWORK TEST FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
