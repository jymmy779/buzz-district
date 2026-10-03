extends SceneTree
const TEST_SAVE := "user://buzz_district_trends_test.json"
var game
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TEST FAILED: " + message)

func sample(p: Button) -> Dictionary:
	var matcha := 0
	var workload := 0.0
	for i in range(10000):
		var id: String = game.choose_offering(p)
		if id == "matcha_latte":
			matcha += 1
		workload += game.get_offering_service_time(p, id)
	return {"matcha": matcha, "mean_time": workload / 10000.0}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	game = load("res://scenes/world/Main.tscn").instantiate()
	game.save_path = TEST_SAVE
	root.add_child(game)
	game.set_process(false)
	var cafe: Button = game.plot_grid.get_child(0)
	var mart: Button = game.plot_grid.get_child(1)
	game.build_business(cafe, "cafe")
	game.build_business(mart, "minimart")
	check(not game.trend_label.visible and not game.is_trend_active("matcha_wave"), "Initially inactive")
	seed(98765)
	var normal := sample(cafe)
	check(normal["matcha"] > 2500 and normal["matcha"] < 3500, "Baseline distribution")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_T
	event.pressed = true
	game._unhandled_key_input(event)
	check(game.is_trend_active("matcha_wave") and game.trend_label.visible, "Debug T starts indicator")
	check(game.trend_label.text == "TREND: Matcha Wave", "Indicator text")
	check(game.trend_remaining == 30.0, "Configured duration")
	check(game.get_offering_selection_weight("coffee") == 35.0 and game.get_offering_selection_weight("matcha_latte") == 105.0, "Effective weights")
	check(game.get_offering_selection_weight("quick_purchase") == 100.0, "Minimart weight unchanged")
	seed(98765)
	var wave := sample(cafe)
	check(wave["matcha"] > 7000 and wave["matcha"] < 8000, "Trend distribution")
	check(wave["mean_time"] > normal["mean_time"] + 0.5, "Offering mix increases service workload")
	print("TREND SAMPLE normal=", normal, " wave=", wave)
	for i in range(100):
		check(game.choose_offering(mart) == "quick_purchase", "Minimart choice unchanged")
	check(game.get_offering_service_time(cafe, "matcha_latte") == 5.5, "Trend does not change service time")
	check(game.get_offering_income(cafe, "matcha_latte") == 14, "Trend does not change payment")
	check(game.demand_state == game.DemandState.NORMAL, "Demand unchanged")
	game.update_trend(4.0)
	game.start_trend("matcha_wave")
	check(game.trend_remaining == 26.0, "Duplicate start ignored, no refresh")
	game.end_trend("unknown")
	check(game.is_trend_active("matcha_wave"), "Unrelated end ignored")
	game.update_trend(25.9)
	check(game.is_trend_active("matcha_wave"), "Active before deadline")
	game.update_trend(0.2)
	check(not game.is_trend_active("matcha_wave") and not game.trend_label.visible, "Automatic end hides indicator")
	check(game.get_offering_selection_weight("coffee") == 70.0 and game.get_offering_selection_weight("matcha_latte") == 30.0, "Original weights restored")
	seed(98765)
	check(sample(cafe) == normal, "Baseline distribution restored exactly under same seed")

	# Save/load does not serialize trend or leave a modifier behind.
	game.debug_start_matcha_wave()
	game.save_game()
	var raw := FileAccess.get_file_as_string(TEST_SAVE)
	check(not raw.contains("trend") and JSON.parse_string(raw)["version"] == 1, "Save version/schema unchanged")
	game.load_game()
	check(not game.is_trend_active("matcha_wave") and not game.trend_label.visible, "Load clears trend")
	check(game.get_offering_selection_weight("matcha_latte") == 30.0, "Load clears modifier")

	# Real wave service/queue/patience, automatic 30-second expiry via game loop.
	game.debug_start_matcha_wave()
	game.spawn_customer_for_business(cafe)
	var npc = cafe.get_meta("customers")[0]
	npc.set_meta("offering_id", "matcha_latte")
	var before: int = game.money
	game.next_customer_spawn = 1000.0
	game.set_process(true)
	Engine.time_scale = 6.0
	await create_timer(6.8).timeout
	check(game.money == before, "Matcha has not finished its longer service yet")
	await create_timer(1.2).timeout
	check(game.money == before + 14, "Matcha pays once")
	game.spawn_customer_for_business(cafe)
	for i in range(3):
		game.spawn_customer_for_business(cafe)
	var waiting = cafe.get_meta("waiting_customers")[0]
	waiting.set_meta("patience_remaining", 4.0)
	check(cafe.get_meta("waiting_customers").size() == 3, "Actual queue pressure under sufficient arrivals")
	var assigned: String = waiting.get_meta("offering_id")
	await create_timer(0.6).timeout
	waiting.update_patience_bar()
	check(waiting.patience_bar.visible, "Waiting bar still works")
	await create_timer(4.0).timeout
	check(waiting.get_meta("leaving") and waiting.get_meta("offering_id") == assigned, "Patience expiry, choice retained")
	await create_timer(19.5).timeout
	check(not game.is_trend_active("matcha_wave") and not game.trend_label.visible, "Process expires wave after 30 seconds")
	check(game.get_offering_selection_weight("matcha_latte") == 30.0, "No stale modifier")
	game.debug_start_matcha_wave()
	check(game.trend_remaining == 30.0, "Can start a new wave after expiry")
	game.end_trend("matcha_wave")
	game.end_trend("matcha_wave")
	check(game.trend_remaining == 0.0, "End is idempotent")
	game.free()
	DirAccess.remove_absolute(TEST_SAVE)
	print("TREND TEST FAILURES: ", failures)
	quit(0 if failures == 0 else 1)