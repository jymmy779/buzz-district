extends SceneTree
# Run: godot --headless --path . --script tests/customer_profiles_test.gd
const TEST_SAVE := "user://buzz_district_customer_profiles_test.json"
var game
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TEST FAILED: " + message)

func plot(index: int) -> Button:
	return game.plot_grid.get_child(index)

func sample_first_stop(profile_id: String, count: int) -> Dictionary:
	var result := {"cafe": 0, "minimart": 0}
	for i in range(count):
		var plan: Array[String] = game.generate_trip_plan(profile_id)
		result[plan[0]] += 1
	return result

func sample_cafe_offerings(profile_id: String, cafe: Button, count: int) -> Dictionary:
	var npc = load("res://scenes/npc/OfficeWorker.tscn").instantiate()
	npc.set_meta("customer_profile_id", profile_id)
	var result := {"coffee": 0, "matcha_latte": 0}
	for i in range(count):
		result[game.choose_offering(cafe, npc)] += 1
	npc.free()
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
	game.money = 10000
	game.build_business(plot(0), "cafe")
	game.build_business(plot(1), "minimart")

	seed(13579)
	var profiles := {"office_worker": 0, "student": 0, "shipper": 0}
	for i in range(5000):
		profiles[game.choose_customer_profile()] += 1
	check(profiles["office_worker"] > 2100 and profiles["office_worker"] < 2400, "Office Worker spawn weight")
	check(profiles["student"] > 1600 and profiles["student"] < 1900, "Student spawn weight")
	check(profiles["shipper"] > 850 and profiles["shipper"] < 1150, "Shipper spawn weight")

	seed(24680)
	var office_stops := sample_first_stop("office_worker", 4000)
	var shipper_stops := sample_first_stop("shipper", 4000)
	check(office_stops["cafe"] > 2280 and office_stops["cafe"] < 2520, "Office Workers generally prefer Cafe")
	check(shipper_stops["minimart"] > 3000 and shipper_stops["minimart"] < 3250, "Shippers generally prefer Minimart")

	seed(97531)
	var office_orders := sample_cafe_offerings("office_worker", plot(0), 4000)
	var student_orders := sample_cafe_offerings("student", plot(0), 4000)
	check(office_orders["coffee"] > 3080 and office_orders["coffee"] < 3320, "Office Worker baseline Coffee preference")
	check(student_orders["matcha_latte"] > 2480 and student_orders["matcha_latte"] < 2720, "Student baseline Matcha preference")
	check(student_orders["matcha_latte"] > office_orders["matcha_latte"], "Students choose Matcha more often than Office Workers")

	game.start_trend("matcha_wave")
	seed(97531)
	var office_wave := sample_cafe_offerings("office_worker", plot(0), 4000)
	var student_wave := sample_cafe_offerings("student", plot(0), 4000)
	check(office_wave["matcha_latte"] > office_orders["matcha_latte"] + 1200, "Matcha Wave shifts Office Workers")
	check(student_wave["matcha_latte"] > student_orders["matcha_latte"] + 700, "Matcha Wave shifts Students")
	game.end_trend("matcha_wave")

	for profile_id in game.CUSTOMER_PROFILE_DATA:
		var one_stop: Array[String] = ["cafe"]
		game.spawn_customer_for_business(plot(0), profile_id, one_stop)
		var customers: Array = plot(0).get_meta("customers", [])
		var waiting: Array = plot(0).get_meta("waiting_customers", [])
		var npc = waiting.back() if not waiting.is_empty() else customers.back()
		var patience_range: Vector2 = game.CUSTOMER_PROFILE_DATA[profile_id]["patience_range"]
		var patience := float(npc.get_meta("patience_max"))
		check(patience >= patience_range.x and patience <= patience_range.y, profile_id + " patience range")

	game.save_game()
	var raw := FileAccess.get_file_as_string(TEST_SAVE)
	check(not raw.contains("customer_profile_id") and JSON.parse_string(raw)["version"] == 1, "Profiles remain transient and save-compatible")
	game.free()
	DirAccess.remove_absolute(TEST_SAVE)
	print("CUSTOMER PROFILE TEST FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
