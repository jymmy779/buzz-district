extends SceneTree
const TEST_SAVE := "user://buzz_district_threadz_test.json"
var game
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TEST FAILED: " + message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	game = load("res://scenes/world/Main.tscn").instantiate()
	game.save_path = TEST_SAVE
	root.add_child(game)
	game.set_process(false)
	check(game.threadz_posts.is_empty() and not game.threadz_panel.visible, "Empty closed feed")
	game.get_node("UI/ThreadZButton").pressed.emit()
	check(game.threadz_panel.visible, "Button opens")
	game.get_node("UI/ThreadZButton").pressed.emit()
	check(not game.threadz_panel.visible, "Button closes")
	game.get_node("UI/ThreadZButton").pressed.emit()
	game.get_node("UI/ThreadZPanel/Margin/Content/Header/CloseButton").pressed.emit()
	check(not game.threadz_panel.visible, "Close button")
	seed(4321)
	var expected_random := randf()
	seed(4321)
	game.debug_start_matcha_wave()
	check(randf() == expected_random, "Cosmetic post RNG does not change simulation RNG")
	check(game.threadz_posts.size() == 1 and game.threadz_posts[0]["type"] == "trend", "One trend post")
	check(game.TREND_DATA["matcha_wave"]["threadz_start_posts"].has(game.threadz_posts[0]["text"]), "Fictional copy from data")
	var first_text: String = game.threadz_posts[0]["text"]
	for i in range(20):
		game.start_trend("matcha_wave")
		game.update_trend(0.1)
	check(game.threadz_posts.size() == 1, "No repeated trend spam")
	game.end_trend("matcha_wave")
	game.money = 5000
	var cafe: Button = game.plot_grid.get_child(0)
	var cafe2: Button = game.plot_grid.get_child(1)
	var mart: Button = game.plot_grid.get_child(2)
	game.build_business(cafe, "cafe")
	game.build_business(cafe2, "cafe")
	game.build_business(mart, "minimart")
	for i in range(3):
		game.spawn_customer_for_business(cafe)
	check(game.threadz_posts.size() == 1, "Two waiting below threshold")
	game.spawn_customer_for_business(cafe)
	check(game.threadz_posts.size() == 2 and game.threadz_posts[0]["type"] == "local", "Queue threshold posts")
	check(game.threadz_feed.text.ends_with(first_text), "Newest first in rendered text")
	for i in range(20):
		game.cleanup_customer_lists(cafe)
		game.spawn_customer_for_business(cafe)
	check(game.threadz_posts.size() == 2, "Full queue stays silent")
	game.send_customer_out(cafe.get_meta("waiting_customers")[0], cafe)
	game.spawn_customer_for_business(cafe)
	check(game.threadz_posts.size() == 2, "2 -> 3 does not rearm")
	game.send_customer_out(cafe.get_meta("waiting_customers")[0], cafe)
	game.send_customer_out(cafe.get_meta("waiting_customers")[0], cafe)
	check(not cafe.get_meta("queue_threadz_posted"), "One waiting rearms")
	game.spawn_customer_for_business(cafe)
	game.spawn_customer_for_business(cafe)
	check(game.threadz_posts.size() == 2, "New episode suppressed during global cooldown")
	for i in range(4):
		game.spawn_customer_for_business(cafe2)
	check(game.threadz_posts.size() == 2, "Other business shares cooldown")
	game.next_customer_spawn = 1000.0
	game._process(29.9)
	check(game.threadz_queue_cooldown_remaining > 0.0, "Cooldown lasts 30 simulation seconds")
	game._process(0.2)
	check(game.threadz_queue_cooldown_remaining == 0.0, "Cooldown expires")
	game.cleanup_customer_lists(cafe)
	game.cleanup_customer_lists(cafe2)
	check(game.threadz_posts.size() == 2, "Suppressed episodes do not post later")
	game.send_customer_out(cafe.get_meta("waiting_customers")[0], cafe)
	game.send_customer_out(cafe.get_meta("waiting_customers")[0], cafe)
	game.spawn_customer_for_business(cafe)
	game.spawn_customer_for_business(cafe)
	check(game.threadz_posts.size() == 3, "Fresh episode after cooldown posts")
	mart.set_meta("level", 2)
	for i in range(5):
		game.spawn_customer_for_business(mart)
	check(game.threadz_posts.size() == 3, "Minimart no Cafe complaint")
	var temporary := Button.new()
	temporary.free()
	# Cleanup dead NPCs must rearm without accessing freed instances.
	var waiting: Array = cafe2.get_meta("waiting_customers").duplicate()
	for npc in waiting:
		npc.cancel_movement()
		npc.free()
	game.cleanup_customer_lists(cafe2)
	check(not cafe2.get_meta("queue_threadz_posted"), "Freed NPC cleanup rearms")
	for i in range(7):
		game.add_threadz_post("Bài thử " + str(i), "system")
	check(game.threadz_posts.size() == 5, "History bounded")
	check(game.threadz_posts[0]["text"] == "Bài thử 6" and game.threadz_posts[4]["text"] == "Bài thử 2", "Latest five retained")
	check(game.threadz_posts[0]["order"] > game.threadz_posts[1]["order"], "Monotonic order")
	game.add_threadz_post("   ", "local")
	check(game.threadz_posts.size() == 5, "Blank posts ignored")
	# Trend text must not repeat even if local/system posts intervene or evict it.
	var previous := first_text
	for i in range(12):
		game.debug_start_matcha_wave()
		var chosen: String = game.threadz_posts[0]["text"]
		check(chosen != previous, "Consecutive trend messages differ")
		previous = chosen
		game.end_trend("matcha_wave")
		for j in range(5):
			game.add_threadz_post("Tin khu phố " + str(j), "system")
	game.save_game()
	var raw := FileAccess.get_file_as_string(TEST_SAVE)
	check(not raw.contains("threadz") and JSON.parse_string(raw)["version"] == 1, "No persistence/schema change")
	game.load_game()
	check(game.threadz_posts.is_empty() and not game.threadz_panel.visible, "Load clears feed")
	check(not cafe.get_meta("queue_threadz_posted"), "Load resets episode")
	check(game.threadz_queue_cooldown_remaining == 0.0 and game.last_threadz_trend_text == "", "Load resets anti-spam state")
	await process_frame
	await process_frame
	game.get_node("UI/ThreadZButton").pressed.emit()
	await process_frame
	check(game.threadz_feed.size.x > 200 and game.threadz_feed.size.y > 200, "Feed layout has usable area")
	check(not game.threadz_panel.get_global_rect().intersects(game.plot_grid.get_global_rect()), "Panel does not cover plots")
	game.free()
	DirAccess.remove_absolute(TEST_SAVE)
	print("THREADZ TEST FAILURES: ", failures)
	quit(0 if failures == 0 else 1)