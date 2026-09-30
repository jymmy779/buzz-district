extends Node2D


const OFFICE_WORKER_SCENE = preload(
	"res://scenes/npc/OfficeWorker.tscn"
)


# =========================================================
# PROTOTYPE BALANCE DATA
# =========================================================

const CAFE_LEVEL_STATS := {
	1: {
		"capacity": 1,
		"service_time": 4.0,
		"income": 10
	},
	2: {
		"capacity": 2,
		"service_time": 3.2,
		"income": 12
	},
	3: {
		"capacity": 3,
		"service_time": 2.7,
		"income": 15
	}
}


# Khách spawn nhanh hơn để test demand/capacity.
# Sau này sẽ thay bằng Demand System thật.
const CUSTOMER_SPAWN_MIN := 0.2
const CUSTOMER_SPAWN_MAX := 0.5


@onready var plot_grid: GridContainer = $PlotGrid
@onready var money_label: Label = $UI/MoneyLabel
@onready var build_cafe_button: Button = $UI/BuildCafeButton
@onready var upgrade_cafe_button: Button = $UI/UpgradeCafeButton


var money := 1000
var selected_plot: Button = null

var customer_spawn_timer := 0.0
var next_customer_spawn := 1.0


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	update_money_label()

	for child in plot_grid.get_children():
		if child is Button:
			child.set_meta(
				"building_type",
				""
			)

			child.set_meta(
				"level",
				0
			)

			child.set_meta(
				"state",
				"empty"
			)

			child.set_meta(
				"customers",
				[]
			)

			child.set_meta(
				"upgrade_remaining",
				0
			)

			child.set_meta(
				"upgrade_target_level",
				0
			)

			child.pressed.connect(
				_on_plot_pressed.bind(child)
			)

	build_cafe_button.hide()
	upgrade_cafe_button.hide()

	schedule_next_customer()


# =========================================================
# GAME LOOP
# =========================================================

func _process(delta: float) -> void:
	customer_spawn_timer += delta

	if customer_spawn_timer >= next_customer_spawn:
		try_spawn_customer()
		schedule_next_customer()


func schedule_next_customer() -> void:
	customer_spawn_timer = 0.0

	next_customer_spawn = randf_range(
		CUSTOMER_SPAWN_MIN,
		CUSTOMER_SPAWN_MAX
	)

	print(
		"Next customer in: ",
		snapped(next_customer_spawn, 0.1),
		"s"
	)


# =========================================================
# PLOT SELECTION
# =========================================================

func _on_plot_pressed(plot: Button) -> void:
	if selected_plot != null and selected_plot != plot:
		selected_plot.modulate = Color.WHITE

		if selected_plot.get_meta("state") == "empty":
			selected_plot.text = "EMPTY"

	var plot_state: String = str(
		plot.get_meta(
			"state",
			"empty"
		)
	)

	if plot_state == "upgrading":
		plot.modulate = Color.WHITE
		selected_plot = null

		update_action_buttons()
		return

	selected_plot = plot

	selected_plot.modulate = Color(
		0.8,
		1.0,
		0.8
	)

	var building_type: String = str(
		selected_plot.get_meta(
			"building_type",
			""
		)
	)

	if building_type == "cafe":
		print(
			"Selected cafe: ",
			selected_plot.name
		)

		update_action_buttons()
		return

	selected_plot.text = "SELECTED"

	print(
		"Selected plot: ",
		selected_plot.name
	)

	update_action_buttons()


# =========================================================
# BUILD CAFE
# =========================================================

func build_cafe() -> void:
	if selected_plot == null:
		return

	if selected_plot.get_meta("state") != "empty":
		return

	if selected_plot.get_meta("building_type") != "":
		return

	var cafe_price := 300

	if money < cafe_price:
		print("Not enough money")
		return

	money -= cafe_price

	selected_plot.set_meta(
		"building_type",
		"cafe"
	)

	selected_plot.set_meta(
		"level",
		1
	)

	selected_plot.set_meta(
		"state",
		"active"
	)

	selected_plot.set_meta(
		"customers",
		[]
	)

	selected_plot.text = "CAFE\nLv.1"
	selected_plot.modulate = Color.WHITE

	update_money_label()

	print(
		"Built Cafe: ",
		selected_plot.name
	)

	selected_plot = null

	update_action_buttons()


# =========================================================
# UPGRADE CAFE
# =========================================================

func upgrade_cafe() -> void:
	if selected_plot == null:
		return

	if selected_plot.get_meta("building_type") != "cafe":
		return

	if selected_plot.get_meta("state") != "active":
		return

	var cafe_plot := selected_plot

	var current_level: int = int(
		cafe_plot.get_meta(
			"level",
			1
		)
	)

	if current_level >= 3:
		print("Cafe already max level")
		return

	var upgrade_price := current_level * 200

	if money < upgrade_price:
		print("Not enough money")
		return

	money -= upgrade_price

	update_money_label()

	# Đóng Cafe trước.
	cafe_plot.set_meta(
		"state",
		"upgrading"
	)

	# Đuổi toàn bộ khách.
	evict_customers(
		cafe_plot
	)

	cafe_plot.set_meta(
		"upgrade_target_level",
		current_level + 1
	)

	# Lv1 -> Lv2 = 10 giây
	# Lv2 -> Lv3 = 20 giây
	var upgrade_time := current_level * 10

	cafe_plot.set_meta(
		"upgrade_remaining",
		upgrade_time
	)

	cafe_plot.modulate = Color.WHITE

	selected_plot = null

	update_action_buttons()

	print(
		"Started upgrading ",
		cafe_plot.name,
		" for ",
		upgrade_time,
		" seconds"
	)

	await run_upgrade_timer(
		cafe_plot
	)


func run_upgrade_timer(
	plot: Button
) -> void:
	while true:
		if not is_instance_valid(plot):
			return

		if plot.get_meta("state") != "upgrading":
			return

		var remaining: int = int(
			plot.get_meta(
				"upgrade_remaining",
				0
			)
		)

		if remaining <= 0:
			break

		plot.text = (
			"CAFE\n"
			+ "UPGRADING\n"
			+ str(remaining)
			+ "s"
		)

		await get_tree().create_timer(
			1.0
		).timeout

		if not is_instance_valid(plot):
			return

		if plot.get_meta("state") != "upgrading":
			return

		remaining = int(
			plot.get_meta(
				"upgrade_remaining",
				0
			)
		)

		remaining -= 1

		plot.set_meta(
			"upgrade_remaining",
			max(
				remaining,
				0
			)
		)

	finish_cafe_upgrade(
		plot
	)


func finish_cafe_upgrade(
	plot: Button
) -> void:
	if not is_instance_valid(plot):
		return

	if plot.get_meta("state") != "upgrading":
		return

	var target_level: int = int(
		plot.get_meta(
			"upgrade_target_level",
			0
		)
	)

	plot.set_meta(
		"level",
		target_level
	)

	plot.set_meta(
		"state",
		"active"
	)

	plot.set_meta(
		"upgrade_remaining",
		0
	)

	plot.set_meta(
		"upgrade_target_level",
		0
	)

	plot.text = (
		"CAFE\nLv."
		+ str(target_level)
	)

	print(
		"Cafe upgrade complete: ",
		plot.name,
		" Lv.",
		target_level
	)


# =========================================================
# CAFE STATS
# =========================================================

func get_cafe_stats(
	cafe_plot: Button
) -> Dictionary:
	var level: int = int(
		cafe_plot.get_meta(
			"level",
			1
		)
	)

	if CAFE_LEVEL_STATS.has(level):
		return CAFE_LEVEL_STATS[level]

	return CAFE_LEVEL_STATS[1]


func get_cafe_capacity(
	cafe_plot: Button
) -> int:
	var stats := get_cafe_stats(
		cafe_plot
	)

	return int(
		stats["capacity"]
	)


func get_cafe_service_time(
	cafe_plot: Button
) -> float:
	var stats := get_cafe_stats(
		cafe_plot
	)

	return float(
		stats["service_time"]
	)


func get_cafe_income(
	cafe_plot: Button
) -> int:
	var stats := get_cafe_stats(
		cafe_plot
	)

	return int(
		stats["income"]
	)


# =========================================================
# SERVICE SLOT SYSTEM
# =========================================================

func get_free_service_slot_index(
	cafe_plot: Button
) -> int:
	var capacity := get_cafe_capacity(
		cafe_plot
	)

	var customers: Array = cafe_plot.get_meta(
		"customers",
		[]
	)

	var used_slots := {}

	for customer in customers:
		if not is_instance_valid(customer):
			continue

		if bool(
			customer.get_meta(
				"leaving",
				false
			)
		):
			continue

		var slot_index: int = int(
			customer.get_meta(
				"service_slot_index",
				-1
			)
		)

		if slot_index >= 0:
			used_slots[slot_index] = true

	for index in range(capacity):
		if not used_slots.has(index):
			return index

	return -1


func get_service_slot_position(
	cafe_plot: Button,
	slot_index: int
) -> Vector2:
	var center := (
		cafe_plot.global_position
		+ cafe_plot.size / 2.0
	)

	var capacity := get_cafe_capacity(
		cafe_plot
	)

	match capacity:
		1:
			return center

		2:
			if slot_index == 0:
				return center + Vector2(
					-25,
					0
				)

			return center + Vector2(
				25,
				0
			)

		3:
			if slot_index == 0:
				return center + Vector2(
					-28,
					-12
				)

			if slot_index == 1:
				return center + Vector2(
					28,
					-12
				)

			return center + Vector2(
				0,
				25
			)

	return center


# =========================================================
# CUSTOMER SPAWNING
# =========================================================

func try_spawn_customer() -> void:
	var available_cafes: Array[Button] = []

	for plot in plot_grid.get_children():
		if not (plot is Button):
			continue

		if plot.get_meta("building_type") != "cafe":
			continue

		if plot.get_meta("state") != "active":
			continue

		cleanup_customer_list(
			plot
		)

		var free_slot := get_free_service_slot_index(
			plot
		)

		if free_slot != -1:
			available_cafes.append(
				plot
			)

	if available_cafes.is_empty():
		return

	var cafe: Button = available_cafes.pick_random()

	spawn_customer_for_cafe(
		cafe
	)


# =========================================================
# UI
# =========================================================

func update_money_label() -> void:
	money_label.text = (
		"$"
		+ str(money)
	)


func update_action_buttons() -> void:
	build_cafe_button.hide()
	upgrade_cafe_button.hide()

	if selected_plot == null:
		return

	var state: String = str(
		selected_plot.get_meta(
			"state",
			"empty"
		)
	)

	if state == "upgrading":
		return

	var building_type: String = str(
		selected_plot.get_meta(
			"building_type",
			""
		)
	)

	if state == "empty":
		build_cafe_button.show()
		return

	if (
		building_type == "cafe"
		and state == "active"
	):
		var level: int = int(
			selected_plot.get_meta(
				"level",
				1
			)
		)

		upgrade_cafe_button.show()

		if level >= 3:
			upgrade_cafe_button.text = (
				"Cafe MAX LEVEL"
			)

			upgrade_cafe_button.disabled = true

		else:
			var upgrade_price := (
				level * 200
			)

			upgrade_cafe_button.text = (
				"Upgrade Cafe - $"
				+ str(upgrade_price)
			)

			upgrade_cafe_button.disabled = false


func _on_build_cafe_button_pressed() -> void:
	build_cafe()


func _on_upgrade_cafe_button_pressed() -> void:
	upgrade_cafe()


# =========================================================
# INCOME POPUP
# =========================================================

func show_income_popup(
	plot: Button,
	amount: int
) -> void:
	var popup := Label.new()

	popup.text = (
		"+$"
		+ str(amount)
	)

	popup.add_theme_font_size_override(
		"font_size",
		22
	)

	popup.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	popup.z_index = 100

	add_child(
		popup
	)

	popup.position = (
		plot.global_position
		+ Vector2(
			plot.size.x / 2.0 - 20,
			plot.size.y / 2.0 - 10
		)
	)

	var start_position := popup.position

	var tween := create_tween()

	tween.parallel().tween_property(
		popup,
		"position",
		start_position
		+ Vector2(
			0,
			-50
		),
		0.8
	)

	tween.parallel().tween_property(
		popup,
		"modulate:a",
		0.0,
		0.8
	)

	tween.tween_callback(
		popup.queue_free
	)


# =========================================================
# CUSTOMER TRACKING
# =========================================================

func cleanup_customer_list(
	cafe_plot: Button
) -> void:
	if not is_instance_valid(cafe_plot):
		return

	var customers: Array = cafe_plot.get_meta(
		"customers",
		[]
	)

	var valid_customers: Array = []

	for customer in customers:
		if not is_instance_valid(customer):
			continue

		if bool(
			customer.get_meta(
				"leaving",
				false
			)
		):
			continue

		valid_customers.append(
			customer
		)

	cafe_plot.set_meta(
		"customers",
		valid_customers
	)


func register_customer(
	cafe_plot: Button,
	npc: Node2D
) -> void:
	if not is_instance_valid(cafe_plot):
		return

	if not is_instance_valid(npc):
		return

	var customers: Array = cafe_plot.get_meta(
		"customers",
		[]
	)

	if not customers.has(npc):
		customers.append(
			npc
		)

	cafe_plot.set_meta(
		"customers",
		customers
	)


func unregister_customer(
	cafe_plot: Button,
	npc: Node2D
) -> void:
	if not is_instance_valid(cafe_plot):
		return

	var customers: Array = cafe_plot.get_meta(
		"customers",
		[]
	)

	customers.erase(
		npc
	)

	cafe_plot.set_meta(
		"customers",
		customers
	)

	cleanup_customer_list(
		cafe_plot
	)


func evict_customers(
	cafe_plot: Button
) -> void:
	if not is_instance_valid(cafe_plot):
		return

	var customers: Array = cafe_plot.get_meta(
		"customers",
		[]
	)

	for npc in customers.duplicate():
		if not is_instance_valid(npc):
			continue

		send_customer_out(
			npc,
			cafe_plot
		)


# =========================================================
# CUSTOMER BEHAVIOUR
# =========================================================

func spawn_customer_for_cafe(
	cafe_plot: Button
) -> void:
	if not is_instance_valid(cafe_plot):
		return

	if cafe_plot.get_meta("state") != "active":
		return

	# -----------------------------------------------------
	# FIND SERVICE SLOT
	# -----------------------------------------------------

	var slot_index := get_free_service_slot_index(
		cafe_plot
	)

	if slot_index == -1:
		return

	var service_position := get_service_slot_position(
		cafe_plot,
		slot_index
	)

	# -----------------------------------------------------
	# CREATE NPC
	# -----------------------------------------------------

	var npc = OFFICE_WORKER_SCENE.instantiate()

	add_child(
		npc
	)

	npc.set_meta(
		"leaving",
		false
	)

	npc.set_meta(
		"service_slot_index",
		slot_index
	)

	register_customer(
		cafe_plot,
		npc
	)

	var current_customers: Array = cafe_plot.get_meta(
		"customers",
		[]
	)

	print(
		"NPC assigned to ",
		cafe_plot.name,
		" slot ",
		slot_index,
		" | customers: ",
		current_customers.size(),
		"/",
		get_cafe_capacity(cafe_plot)
	)

	# -----------------------------------------------------
	# SPAWN POSITION
	# -----------------------------------------------------

	npc.global_position = Vector2(
		50,
		350
	)

	# =====================================================
	# WALK TO SERVICE SLOT
	# =====================================================

	var walk_in: Tween = npc.walk_to(
		service_position,
		2.0
	)

	while (
		is_instance_valid(npc)
		and walk_in.is_valid()
		and walk_in.is_running()
	):
		await get_tree().process_frame

		if not is_instance_valid(npc):
			return

		if bool(
			npc.get_meta(
				"leaving",
				false
			)
		):
			return

		if cafe_plot.get_meta("state") != "active":
			send_customer_out(
				npc,
				cafe_plot
			)

			return

	if not is_instance_valid(npc):
		return

	if bool(
		npc.get_meta(
			"leaving",
			false
		)
	):
		return

	if cafe_plot.get_meta("state") != "active":
		send_customer_out(
			npc,
			cafe_plot
		)

		return

	# =====================================================
	# SERVICE
	# =====================================================

	var service_time := get_cafe_service_time(
		cafe_plot
	)

	var elapsed := 0.0

	print(
		npc.name,
		" using slot ",
		slot_index,
		" for ",
		service_time,
		"s"
	)

	while elapsed < service_time:
		await get_tree().process_frame

		if not is_instance_valid(npc):
			return

		if bool(
			npc.get_meta(
				"leaving",
				false
			)
		):
			return

		if cafe_plot.get_meta("state") != "active":
			send_customer_out(
				npc,
				cafe_plot
			)

			return

		elapsed += get_process_delta_time()

	# =====================================================
	# PAYMENT
	# =====================================================

	if not is_instance_valid(npc):
		return

	if bool(
		npc.get_meta(
			"leaving",
			false
		)
	):
		return

	if cafe_plot.get_meta("state") != "active":
		send_customer_out(
			npc,
			cafe_plot
		)

		return

	var income := get_cafe_income(
		cafe_plot
	)

	money += income

	update_money_label()

	show_income_popup(
		cafe_plot,
		income
	)

	print(
		npc.name,
		" paid $",
		income
	)

	# =====================================================
	# LEAVE
	# =====================================================

	await send_customer_out(
		npc,
		cafe_plot
	)


# =========================================================
# CUSTOMER EXIT
# =========================================================

func send_customer_out(
	npc: Node2D,
	cafe_plot: Button
) -> void:
	if not is_instance_valid(npc):
		return

	if bool(
		npc.get_meta(
			"leaving",
			false
		)
	):
		return

	npc.set_meta(
		"leaving",
		true
	)

	# Giải phóng slot ngay khi khách bắt đầu rời đi.
	npc.set_meta(
		"service_slot_index",
		-1
	)

	unregister_customer(
		cafe_plot,
		npc
	)

	npc.cancel_movement()

	var walk_out: Tween = npc.walk_to(
		Vector2(
			1100,
			350
		),
		2.0
	)

	await walk_out.finished

	if is_instance_valid(npc):
		npc.queue_free()
