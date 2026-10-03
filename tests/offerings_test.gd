extends SceneTree
# godot --headless --path . --script tests/offerings_test.gd
const TEST_SAVE := "user://buzz_district_offerings_test.json"
var game
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TEST FAILED: " + message)

func fresh() -> void:
	if is_instance_valid(game):
		game.free()
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	game = load("res://scenes/world/Main.tscn").instantiate()
	game.save_path = TEST_SAVE
	root.add_child(game)
	game.set_process(false)
	game.money = 10000

func plot(index: int) -> Button:
	return game.plot_grid.get_child(index)

func spawn_with_offering(p: Button, offering: String):
	game.spawn_customer_for_business(p)
	var customers: Array = p.get_meta("customers")
	var npc = customers.back()
	# Deterministic fixture before arrival; production chooses by weight at spawn.
	npc.set_meta("offering_id", offering)
	return npc

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	fresh()
	game.build_business(plot(0), "cafe")
	game.build_business(plot(1), "minimart")
	seed(12345)
	var counts := {"coffee": 0, "matcha_latte": 0}
	for i in range(10000):
		var offering: String = game.choose_offering(plot(0))
		check(counts.has(offering), "Cafe only chooses supported offerings")
		counts[offering] += 1
		check(game.choose_offering(plot(1)) == "quick_purchase", "Minimart selection")
	check(counts["coffee"] > 6500 and counts["coffee"] < 7500, "Weighted distribution ~70/30")
	print("WEIGHTED SAMPLE: ", counts)
	check(game.choose_offering(plot(2)) == "", "Empty plot has no offering")
	for level in [1, 2, 3]:
		plot(0).set_meta("level", level)
		plot(1).set_meta("level", level)
		check(is_equal_approx(game.get_offering_service_time(plot(0), "coffee"), 4.0 / [1.0, 1.25, 1.5][level - 1]), "Coffee speed")
		check(is_equal_approx(game.get_offering_service_time(plot(0), "matcha_latte"), 5.5 / [1.0, 1.25, 1.5][level - 1]), "Matcha speed")
		check(game.get_offering_income(plot(0), "coffee") == [10, 12, 15][level - 1], "Coffee income")
		check(game.get_offering_income(plot(0), "matcha_latte") == [14, 16, 19][level - 1], "Matcha income")
		check(is_equal_approx(game.get_offering_service_time(plot(1), "quick_purchase"), [3.0, 2.5, 2.0][level - 1]), "Purchase speed")
		check(game.get_offering_income(plot(1), "quick_purchase") == [8, 11, 14][level - 1], "Purchase income")
	# Actual service/payments at every level, with one NPC per business.
	Engine.time_scale = 6.0
	for offering in ["coffee", "matcha_latte", "quick_purchase"]:
		for level in [1, 2, 3]:
			fresh()
			var p := plot(0)
			game.build_business(p, "minimart" if offering == "quick_purchase" else "cafe")
			p.set_meta("level", level)
			spawn_with_offering(p, offering)
			var before: int = game.money
			var duration: float = game.get_offering_service_time(p, offering)
			await create_timer(2.0 + duration - 0.5).timeout
			check(game.money == before, "No payment before service completes")
			await create_timer(1.0).timeout
			check(game.money == before + game.get_offering_income(p, offering), "Offering payment")
			await create_timer(2.5).timeout
			check(game.money == before + game.get_offering_income(p, offering), "No duplicate payment")
			check(p.get_meta("customers").is_empty(), "Service slot released")

	# An interrupted Cafe need cannot reroute to an unrelated Minimart.
	fresh()
	game.build_business(plot(0), "cafe")
	game.build_business(plot(1), "minimart")
	var npc = spawn_with_offering(plot(0), "matcha_latte")
	await create_timer(2.4).timeout
	check(npc.get_meta("customer_state") == "serving", "Matcha service started")
	game.upgrade_business(plot(0))
	var before: int = game.money
	check(npc.get_meta("leaving") and not npc.has_meta("current_business"), "Cafe need refuses Minimart reroute")
	await create_timer(6.0).timeout
	check(game.money == before, "Interrupted offering never pays")

	# Minimart customers leave when only an unrelated Cafe can accept them.
	fresh()
	game.build_business(plot(0), "minimart")
	game.build_business(plot(1), "cafe")
	game.spawn_customer_for_business(plot(0))
	game.spawn_customer_for_business(plot(0))
	var serving = plot(0).get_meta("customers")[0]
	var waiting = plot(0).get_meta("waiting_customers")[0]
	waiting.set_meta("patience_remaining", 6.0)
	game.upgrade_business(plot(0))
	for customer in [serving, waiting]:
		check(customer.get_meta("leaving") and not customer.has_meta("current_business"), "Minimart need refuses Cafe reroute")
	check(plot(1).get_meta("customers").is_empty() and plot(1).get_meta("waiting_customers").is_empty(), "Unrelated Cafe receives no reroutes")

	# Same-type reroute keeps the chosen offering.
	fresh()
	game.build_business(plot(0), "cafe")
	game.build_business(plot(1), "cafe")
	npc = spawn_with_offering(plot(0), "matcha_latte")
	game.upgrade_business(plot(0))
	check(npc.get_meta("offering_id") == "matcha_latte", "Compatible offering preserved")

	# Queue/patience work for either Cafe offering and save remains version 1.
	for offering in ["coffee", "matcha_latte"]:
		fresh()
		game.build_business(plot(0), "cafe")
		game.spawn_customer_for_business(plot(0))
		game.spawn_customer_for_business(plot(0))
		waiting = plot(0).get_meta("waiting_customers")[0]
		waiting.set_meta("offering_id", offering)
		waiting.set_meta("patience_remaining", 0.8)
		before = game.money
		await create_timer(2.3).timeout
		waiting.update_patience_bar()
		check(waiting.patience_bar.visible, "Offering-independent patience bar")
		await create_timer(1.0).timeout
		check(waiting.get_meta("leaving") and game.money == before, "Patience expiry without payment")
		game.save_game()
		var raw := FileAccess.get_file_as_string(TEST_SAVE)
		check(not raw.contains("offering_id") and JSON.parse_string(raw)["version"] == 1, "Save schema unchanged")
		game.load_game()
		check(get_nodes_in_group("district_customers").is_empty(), "Load clears assignments")
		game.spawn_customer_for_business(plot(0))
		check(game.is_offering_supported(plot(0).get_meta("customers")[0].get_meta("offering_id"), plot(0)), "New customers select after load")
	game.free()
	DirAccess.remove_absolute(TEST_SAVE)
	print("OFFERING TEST FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
