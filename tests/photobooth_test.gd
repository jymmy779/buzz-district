extends SceneTree
# Run: godot --headless --path . --script tests/photobooth_test.gd
const TEST_SAVE := "user://buzz_district_photobooth_test.json"
var game
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TEST FAILED: " + message)

func plot(index: int) -> Button:
	return game.plot_grid.get_child(index)

func sample_first_stops(profile_id: String, count: int) -> Dictionary:
	var result := {"cafe": 0, "minimart": 0, "photobooth": 0}
	for i in range(count):
		var plan: Array[String] = game.generate_trip_plan(profile_id)
		result[plan[0]] += 1
		check(plan.size() <= 2, "Trips remain limited to two stops")
		if plan.size() == 2:
			check(plan[0] != plan[1], "Two-stop trips use different business types")
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
	game.money = 1000

	game._on_plot_pressed(plot(0))
	check(game.build_cafe_button.visible and game.build_minimart_button.visible and game.build_photobooth_button.visible, "Empty plot offers all three businesses")
	game.build_photobooth_button.pressed.emit()
	check(game.money == 500 and plot(0).get_meta("building_type") == "photobooth", "Photobooth builds for $500")
	check(game.OFFERING_DATA["quick_shot"]["building_type"] == "photobooth" and game.OFFERING_DATA["premium_strip"]["building_type"] == "photobooth", "Photobooth offerings use generic data")

	seed(314159)
	var base_orders := {"quick_shot": 0, "premium_strip": 0}
	for i in range(5000):
		base_orders[game.choose_offering(plot(0))] += 1
	check(base_orders["quick_shot"] > 3350 and base_orders["quick_shot"] < 3650, "Base offering weights are approximately 70/30")
	check(game.get_offering_service_time(plot(0), "quick_shot") == 4.5, "Lv1 Quick Shot duration")
	check(game.get_offering_service_time(plot(0), "premium_strip") == 7.0, "Lv1 Premium Strip duration")
	check(game.get_offering_income(plot(0), "quick_shot") == 12 and game.get_offering_income(plot(0), "premium_strip") == 20, "Lv1 offering payments")
	plot(0).set_meta("level", 2)
	check(is_equal_approx(game.get_offering_service_time(plot(0), "premium_strip"), 7.0 / 1.2) and game.get_offering_income(plot(0), "premium_strip") == 23, "Lv2 speed and bonus")
	plot(0).set_meta("level", 3)
	check(is_equal_approx(game.get_offering_service_time(plot(0), "quick_shot"), 4.5 / 1.45) and game.get_offering_income(plot(0), "quick_shot") == 18, "Lv3 speed and bonus")
	plot(0).set_meta("level", 1)

	game.money = 5000
	game.build_business(plot(1), "cafe")
	game.build_business(plot(2), "minimart")
	game.build_business(plot(3), "photobooth")
	seed(271828)
	var student_stops := sample_first_stops("student", 5000)
	var shipper_stops := sample_first_stops("shipper", 5000)
	check(student_stops["photobooth"] > 1550 and student_stops["photobooth"] < 1950, "Students visit Photobooth near 35 percent")
	check(shipper_stops["photobooth"] > 350 and shipper_stops["photobooth"] < 650, "Shippers visit Photobooth near 10 percent")
	check(student_stops["photobooth"] > shipper_stops["photobooth"] * 2, "Students prefer Photobooth more than Shippers")
	var saw_cafe_photo := false
	var saw_photo_mart := false
	for i in range(3000):
		var plan: Array[String] = game.generate_trip_plan("student")
		saw_cafe_photo = saw_cafe_photo or plan == ["cafe", "photobooth"]
		saw_photo_mart = saw_photo_mart or plan == ["photobooth", "minimart"]
	check(saw_cafe_photo and saw_photo_mart, "Three-type district generates Photobooth trip combinations")

	Engine.time_scale = 6.0
	var one_photo_stop: Array[String] = ["photobooth"]
	for i in range(3):
		game.spawn_customer_for_business(plot(0), "student", one_photo_stop)
	check(plot(0).get_meta("customers").size() == 1 and plot(0).get_meta("waiting_customers").size() == 2, "Photobooth uses generic service and queue capacity")
	check(not game.threadz_posts.is_empty() and game.threadz_posts[0]["text"] == game.BUILDING_DATA["photobooth"]["queue_reaction"]["text"], "Photobooth congestion uses generic ThreadZ reaction")
	var impatient = plot(0).get_meta("waiting_customers")[0]
	impatient.set_meta("patience_remaining", 0.2)
	await create_timer(3.0).timeout
	check(impatient.get_meta("leaving"), "Photobooth queue uses generic patience expiry")
	var cleanup_customers: Array = plot(0).get_meta("customers", []).duplicate()
	cleanup_customers.append_array(plot(0).get_meta("waiting_customers", []).duplicate())
	for customer in cleanup_customers:
		if is_instance_valid(customer) and not customer.get_meta("leaving", false):
			game.send_customer_out(customer, plot(0))

	game.spawn_customer_for_business(plot(0), "student", one_photo_stop)
	var paid_customer = plot(0).get_meta("customers")[0]
	paid_customer.set_meta("offering_id", "premium_strip")
	var before: int = game.money
	await create_timer(9.5).timeout
	check(game.money == before + 20, "Premium Strip pays once after service")
	await create_timer(2.5).timeout
	check(game.money == before + 20, "Photobooth payment is not duplicated")

	# Same-need upgrade interruption may use another Photobooth, never another type.
	game.spawn_customer_for_business(plot(0), "student", one_photo_stop)
	var rerouted = plot(0).get_meta("customers")[0]
	rerouted.set_meta("patience_remaining", 5.0)
	game.upgrade_business(plot(0))
	check(rerouted.get_meta("current_business") == plot(3), "Photobooth reroutes only to another Photobooth")
	check(float(rerouted.get_meta("patience_remaining")) == 5.0, "Photobooth reroute preserves patience")

	# Generic persistence accepts the new building type and upgrade fields.
	plot(3).set_meta("level", 2)
	game.upgrade_business(plot(3))
	plot(3).set_meta("upgrade_remaining", 7)
	game.save_game()
	game.load_game()
	check(plot(0).get_meta("building_type") == "photobooth", "Active Photobooth type restores")
	check(plot(3).get_meta("building_type") == "photobooth" and plot(3).get_meta("state") == "upgrading", "Upgrading Photobooth restores")
	check(plot(3).get_meta("level") == 2 and plot(3).get_meta("upgrade_target_level") == 3 and plot(3).get_meta("upgrade_remaining") == 7, "Photobooth upgrade progress restores")

	game.free()
	DirAccess.remove_absolute(TEST_SAVE)
	print("PHOTOBOOTH TEST FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
