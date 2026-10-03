extends SceneTree
# Run: godot --headless --path . --script tests/local_persistence_test.gd
# Uses a dedicated save, never the player's user://save.json.
const TEST_SAVE := "user://buzz_district_persistence_test.json"
var game
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TEST FAILED: " + message)

func snapshot() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(TEST_SAVE))

func write_snapshot(value: Variant) -> void:
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

func new_game() -> void:
	game = load("res://scenes/world/Main.tscn").instantiate()
	game.save_path = TEST_SAVE
	root.add_child(game)
	game.set_process(false)

func restart() -> void:
	game.free()
	new_game()

func plot(index: int) -> Button:
	return game.plot_grid.get_child(index)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--write-restart-fixture"):
		if FileAccess.file_exists(TEST_SAVE):
			DirAccess.remove_absolute(TEST_SAVE)
		new_game()
		game.build_business(plot(0), "cafe")
		game.build_business(plot(1), "minimart")
		game.money = 5000
		game.set_demand_state(game.DemandState.LOW)
		game.upgrade_business(plot(0))
		game.upgrade_business(plot(1))
		plot(0).set_meta("upgrade_remaining", 7)
		plot(1).set_meta("upgrade_remaining", 7)
		check(game.save_game(), "Process fixture saved")
		game.free()
		quit(failures)
		return
	if args.has("--read-restart-fixture"):
		new_game()
		check(game.money == 4550 and game.demand_state == game.DemandState.LOW, "Separate process restores money/demand")
		for p in [plot(0), plot(1)]:
			check(p.get_meta("upgrade_remaining") == 7, "Separate process restores remaining time")
			check(p.get_meta("customers").is_empty(), "Separate process starts without customers")
		await create_timer(1.2).timeout
		for p in [plot(0), plot(1)]:
			check(p.get_meta("upgrade_remaining") == 6, "Separate process resumes one timer")
		game.free()
		DirAccess.remove_absolute(TEST_SAVE)
		print("PROCESS RESTART TEST FAILURES: ", failures)
		quit(failures)
		return
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	new_game()
	check(not game.has_save_game() and game.money == 1000, "Fresh state without save")
	check(plot(0).get_meta("state") == "empty", "Fresh metadata")
	game._on_plot_pressed(plot(0))
	check(game.build_cafe_button.visible and game.build_minimart_button.visible and game.build_photobooth_button.visible, "Build selection UI")
	game.build_cafe_button.pressed.emit()
	check(snapshot()["money"] == 700, "Cafe build saves")
	game._on_plot_pressed(plot(1))
	game.build_minimart_button.pressed.emit()
	check(snapshot()["money"] == 300, "Minimart build saves")
	game.set_demand_state(game.DemandState.HIGH)
	check(snapshot()["demand_state"] == game.DemandState.HIGH, "Demand saves")
	game.money = 2345
	check(game.save_game(), "Overwrite save via temporary file")
	restart()
	check(game.money == 2345 and game.money_label.text == "$2345", "Money restore survives ready")
	check(game.demand_state == game.DemandState.HIGH, "Demand restore")
	check(plot(0).text == "CAFE
Lv.1" and plot(1).text == "MINIMART
Lv.1", "Both buildings restore")
	# Save a busy district and reload while movement, service and patience flows exist.
	for i in range(4):
		game.spawn_customer_for_business(plot(0))
	for i in range(3):
		game.spawn_customer_for_business(plot(1))
	check(plot(0).get_meta("waiting_customers").size() == 3, "Cafe FIFO capacity")
	check(plot(1).get_meta("waiting_customers").size() == 2, "Minimart queue capacity")
	game.save_game()
	var raw := FileAccess.get_file_as_string(TEST_SAVE)
	for forbidden in ["customers", "assignment", "patience", "Tween", "offering_id"]:
		check(not raw.contains(forbidden), "Save excludes " + forbidden)
	check(game.load_game(), "In-place reload")
	check(get_nodes_in_group("district_customers").is_empty(), "Old NPCs removed")
	for p in [plot(0), plot(1)]:
		check(p.get_meta("customers").is_empty() and p.get_meta("waiting_customers").is_empty(), "Collections cleared")
	await create_timer(0.1).timeout
	check(game.money == 2345, "Stale service does not pay")

	# Both business countdowns resume at the saved time, even on repeated loads.
	for p in [plot(0), plot(1)]:
		game.upgrade_business(p)
	check(snapshot()["money"] == 1895, "Both upgrade charges saved")
	for p in [plot(0), plot(1)]:
		p.set_meta("upgrade_remaining", 7)
	game.save_game()
	restart()
	for p in [plot(0), plot(1)]:
		check(p.get_meta("upgrade_remaining") == 7 and p.get_meta("state") == "upgrading", "No offline progression")
		check(p.text.contains("UPGRADING
7s"), "Restored countdown display")
	game.load_game()
	game.load_game()
	game.run_upgrade_timer(plot(0))
	await create_timer(1.2).timeout
	check(plot(0).get_meta("upgrade_remaining") == 6 and plot(1).get_meta("upgrade_remaining") == 6, "Only one timer decrements")
	Engine.time_scale = 6.0
	await create_timer(7.5).timeout
	for p in [plot(0), plot(1)]:
		check(p.get_meta("level") == 2 and game.is_active_business(p), "Upgrade completes after load")
		check(p.get_meta("upgrade_target_level") == 0 and p.get_meta("upgrade_remaining") == 0, "Upgrade fields reset")
	check(snapshot()["plots"][0]["level"] == 2 and snapshot()["plots"][1]["level"] == 2, "Upgrade completion saves")
	restart()
	check(plot(0).get_meta("level") == 2 and plot(1).get_meta("level") == 2, "Completed levels survive restart")

	# Payment once, popup and periodic save, then new spawning after load.
	var before: int = game.money
	game.spawn_customer_for_business(plot(1))
	await create_timer(4.9).timeout
	check(game.money == before + 11, "Normal service payment once")
	check(not get_nodes_in_group("income_popups").is_empty(), "Income popup")
	game.save_game()
	game.load_game()
	await create_timer(2.0).timeout
	check(game.money == before + 11, "Reload removes popup safely and no duplicate payment")
	game.money = 3456
	game.next_customer_spawn = 1000.0
	game._process(14.9)
	check(snapshot()["money"] != 3456, "No early autosave")
	game._process(0.2)
	check(snapshot()["money"] == 3456, "15-second autosave")
	game.money = 4567
	game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(snapshot()["money"] == 4567, "Close notification saves")
	game.load_game()
	game._process(game.next_customer_spawn + 0.1)
	check(get_nodes_in_group("district_customers").size() == 1, "Normal spawning resumes")

	# Existing queue/patience/reroute behavior still works after restoring.
	game.load_game()
	plot(0).set_meta("level", 1)
	plot(1).set_meta("level", 1)
	game.build_business(plot(2), "cafe")
	game.spawn_customer_for_business(plot(0))
	game.spawn_customer_for_business(plot(0))
	var first = plot(0).get_meta("waiting_customers")[0]
	game.send_customer_out(plot(0).get_meta("customers")[0], plot(0))
	check(plot(0).get_meta("customers")[0] == first, "FIFO promotion")
	game.spawn_customer_for_business(plot(0))
	var waiting = plot(0).get_meta("waiting_customers")[0]
	waiting.set_meta("patience_remaining", 4.0)
	# Temporarily close the other type to isolate queue fallback at the Cafe.
	plot(1).set_meta("state", "upgrading")
	game.upgrade_business(plot(0))
	check(first.get_meta("current_business") == plot(2), "Same-type reroute service")
	check(waiting.get_meta("current_business") == plot(2) and waiting.get_meta("patience_remaining") == 4.0, "Reroute queue preserves patience")
	check(plot(1).get_meta("customers").is_empty(), "Unavailable business skipped")
	plot(1).set_meta("state", "active")
	game.spawn_customer_for_business(plot(1))
	game.spawn_customer_for_business(plot(1))
	var impatient = plot(1).get_meta("waiting_customers")[0]
	impatient.set_meta("patience_remaining", 0.8)
	await create_timer(2.3).timeout
	impatient.update_patience_bar()
	check(impatient.patience_bar.visible, "Patience bar")
	await create_timer(1.0).timeout
	check(impatient.get_meta("leaving"), "Patience expiry")
	# Loading invalid data resets a busy district without partial restoration.
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(not game.load_game() and game.money == 1000, "Corrupt JSON -> fresh")
	check(get_nodes_in_group("district_customers").is_empty(), "Corrupt reload clears NPCs")
	for invalid in [
		[], {"version": 99}, {"version": 1, "money": []},
		{"version": 1, "demand_state": "HIGH"}, {"version": 1, "plots": {}},
		{"version": 1, "plots": [{"name": "Plot1", "building_type": "missing"}]},
		{"version": 1, "plots": [{"name": "Plot1", "building_type": "cafe", "level": 99}]},
		{"version": 1, "plots": [{"name": "Plot1", "building_type": "cafe", "state": "upgrading", "upgrade_target_level": 3}]}
	]:
		write_snapshot(invalid)
		check(not game.load_game() and game.money == 1000 and plot(0).get_meta("state") == "empty", "Malformed snapshot rejected")
	write_snapshot({"version": 1, "plots": [{"name": "Plot1", "building_type": "minimart"}]})
	check(game.load_game() and game.money == 1000 and plot(0).text == "MINIMART
Lv.1", "Missing fields default")
	write_snapshot({"version": 1, "plots": [{"name": "Plot1", "building_type": "cafe", "state": "upgrading", "upgrade_remaining": 0}]})
	check(game.load_game() and plot(0).get_meta("level") == 2, "Zero remaining completes once")
	await create_timer(1.2).timeout
	check(plot(0).get_meta("level") == 2, "Stale timers cannot finish again")
	game.free()
	DirAccess.remove_absolute(TEST_SAVE)
	print("LOCAL PERSISTENCE TEST FAILURES: ", failures)
	quit(0 if failures == 0 else 1)
