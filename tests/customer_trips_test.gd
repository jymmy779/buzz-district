extends SceneTree
# Run: godot --headless --path . --script tests/customer_trips_test.gd
const TEST_SAVE := "user://buzz_district_customer_trips_test.json"
var game
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TEST FAILED: " + message)

func plot(index: int) -> Button:
	return game.plot_grid.get_child(index)

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

	for i in range(100):
		check(game.generate_trip_plan("office_worker") == ["cafe"], "One supported type creates one-stop trips")

	game.build_business(plot(1), "minimart")
	seed(24680)
	var two_stop_count := 0
	var cafe_first := false
	var minimart_first := false
	for i in range(2000):
		var first := "cafe" if i % 2 == 0 else "minimart"
		var plan: Array[String] = game.generate_trip_plan("office_worker", first)
		check(plan.size() == 1 or (plan.size() == 2 and plan[0] != plan[1]), "Trips contain one stop or two different types")
		if plan.size() == 2:
			two_stop_count += 1
			cafe_first = cafe_first or plan == ["cafe", "minimart"]
			minimart_first = minimart_first or plan == ["minimart", "cafe"]
	check(two_stop_count > 800 and two_stop_count < 1000, "Office Worker two-stop share is approximately 45 percent")
	check(cafe_first and minimart_first, "Both two-stop orders are generated")

	Engine.time_scale = 10.0
	game.spawn_customer_for_business(plot(0), "office_worker")
	var npc = plot(0).get_meta("customers")[0]
	npc.set_meta("trip_plan", ["cafe", "minimart"])
	npc.set_meta("patience_remaining", 1.0)
	var patience_max := float(npc.get_meta("patience_max"))
	var before: int = game.money
	var first_income: int = game.get_offering_income(plot(0), str(npc.get_meta("offering_id")))
	await create_timer(8.0).timeout
	check(game.money == before + first_income, "First stop pays exactly once")
	check(npc.get_meta("trip_index") == 1 and npc.get_meta("current_business") == plot(1), "Customer continues to second stop")
	check(npc.get_meta("offering_id") == "quick_purchase", "Second stop chooses its own valid offering")
	check(float(npc.get_meta("patience_remaining")) == patience_max, "New stop resets remaining patience")
	await create_timer(6.0).timeout
	check(game.money == before + first_income + 8, "Second stop pays exactly once")
	check(npc.get_meta("leaving") and npc.get_meta("trip_index") == 2, "Customer leaves after completing trip")
	await create_timer(2.5).timeout
	check(game.money == before + first_income + 8, "No duplicate payment after completion")

	# A planned next stop that becomes unavailable is skipped without a stuck NPC.
	plot(1).set_meta("state", "upgrading")
	game.spawn_customer_for_business(plot(0), "office_worker")
	var skipped = plot(0).get_meta("customers")[0]
	skipped.set_meta("trip_plan", ["cafe", "minimart"])
	before = game.money
	first_income = game.get_offering_income(plot(0), str(skipped.get_meta("offering_id")))
	await create_timer(8.0).timeout
	check(game.money == before + first_income, "Completed stop still pays before unavailable next stop")
	check(skipped.get_meta("leaving") and not skipped.has_meta("current_business"), "Unavailable next stop leaves cleanly")
	plot(1).set_meta("state", "active")

	game.build_business(plot(2), "cafe")
	game.spawn_customer_for_business(plot(0), "office_worker")
	var rerouted = plot(0).get_meta("customers")[0]
	rerouted.set_meta("trip_plan", ["cafe", "minimart"])
	rerouted.set_meta("patience_remaining", 4.0)
	game.upgrade_business(plot(0))
	check(rerouted.get_meta("current_business") == plot(2), "Cafe need reroutes to another Cafe")
	check(float(rerouted.get_meta("patience_remaining")) == 4.0, "Reroute preserves remaining patience")

	game.save_game()
	var raw := FileAccess.get_file_as_string(TEST_SAVE)
	for forbidden in ["trip_plan", "trip_index", "visited_businesses", "offering_id", "patience_remaining"]:
		check(not raw.contains(forbidden), "Save excludes transient " + forbidden)
	game.free()
	DirAccess.remove_absolute(TEST_SAVE)
	print("CUSTOMER TRIP TEST FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
