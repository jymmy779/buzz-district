extends Node2D


const OFFICE_WORKER_SCENE = preload(
	"res://scenes/npc/OfficeWorker.tscn"
)


enum DemandState {
	LOW,
	NORMAL,
	HIGH
}


const DEMAND_SPAWN_INTERVALS := {
	DemandState.LOW: Vector2(2.5, 5.0),
	DemandState.NORMAL: Vector2(1.2, 3.0),
	DemandState.HIGH: Vector2(0.5, 1.5)
}


const DEMAND_NAMES := {
	DemandState.LOW: "LOW",
	DemandState.NORMAL: "NORMAL",
	DemandState.HIGH: "HIGH"
}


const CUSTOMER_PROFILE_DATA := {
	"office_worker": {
		"display_name": "Office Worker",
		"spawn_weight": 45.0,
		"patience_range": Vector2(8.0, 12.0),
		"business_preferences": {"cafe": 55.0, "minimart": 35.0, "photobooth": 10.0},
		"trip_probabilities": {1: 0.55, 2: 0.45},
		"offering_preferences": {
			"coffee": 80.0, "matcha_latte": 20.0,
			"quick_shot": 75.0, "premium_strip": 25.0
		}
	},
	"student": {
		"display_name": "Student",
		"spawn_weight": 35.0,
		"patience_range": Vector2(12.0, 18.0),
		"business_preferences": {"cafe": 40.0, "minimart": 25.0, "photobooth": 35.0},
		"trip_probabilities": {1: 0.60, 2: 0.40},
		"offering_preferences": {
			"coffee": 35.0, "matcha_latte": 65.0,
			"quick_shot": 45.0, "premium_strip": 55.0
		}
	},
	"shipper": {
		"display_name": "Shipper",
		"spawn_weight": 20.0,
		"patience_range": Vector2(6.0, 10.0),
		"business_preferences": {"cafe": 20.0, "minimart": 70.0, "photobooth": 10.0},
		"trip_probabilities": {1: 0.80, 2: 0.20},
		"offering_preferences": {
			"coffee": 85.0, "matcha_latte": 15.0,
			"quick_shot": 90.0, "premium_strip": 10.0
		}
	}
}


# =========================================================
# PROTOTYPE BALANCE DATA
# =========================================================

const BUILDING_DATA := {
	"cafe": {
		"display_name": "Cafe",
		"queue_reaction": {
			"threshold": 3,
			"reset_below": 2,
			"text": "Hidden gem gì mà xếp hàng tới ngoài cửa vậy?"
		},
		"build_cost": 300,
		"max_level": 3,
		"levels": {
			1: {
				"capacity": 1,
				"queue_capacity": 3,
				"service_speed_multiplier": 1.0,
				"income_bonus": 0,
				"upgrade_cost": 200,
				"upgrade_time": 10
			},
			2: {
				"capacity": 2,
				"queue_capacity": 4,
				"service_speed_multiplier": 1.25,
				"income_bonus": 2,
				"upgrade_cost": 400,
				"upgrade_time": 20
			},
			3: {
				"capacity": 3,
				"queue_capacity": 5,
				"service_speed_multiplier": 1.5,
				"income_bonus": 5
			}
		}
	},
	"minimart": {
		"display_name": "Minimart",
		"build_cost": 400,
		"max_level": 3,
		"levels": {
			1: {
				"capacity": 1,
				"queue_capacity": 2,
				"service_speed_multiplier": 1.0,
				"income_bonus": 0,
				"upgrade_cost": 250,
				"upgrade_time": 10
			},
			2: {
				"capacity": 2,
				"queue_capacity": 3,
				"service_speed_multiplier": 1.2,
				"income_bonus": 3,
				"upgrade_cost": 500,
				"upgrade_time": 20
			},
			3: {
				"capacity": 3,
				"queue_capacity": 4,
				"service_speed_multiplier": 1.5,
				"income_bonus": 6
			}
		}
	},
	"photobooth": {
		"display_name": "Photobooth",
		"queue_reaction": {
			"threshold": 2,
			"reset_below": 2,
			"text": "Chụp mấy tấm hình thôi mà xếp hàng dài dữ vậy."
		},
		"build_cost": 500,
		"max_level": 3,
		"levels": {
			1: {
				"capacity": 1,
				"queue_capacity": 2,
				"service_speed_multiplier": 1.0,
				"income_bonus": 0,
				"upgrade_cost": 300,
				"upgrade_time": 12
			},
			2: {
				"capacity": 2,
				"queue_capacity": 3,
				"service_speed_multiplier": 1.2,
				"income_bonus": 3,
				"upgrade_cost": 600,
				"upgrade_time": 24
			},
			3: {
				"capacity": 2,
				"queue_capacity": 4,
				"service_speed_multiplier": 1.45,
				"income_bonus": 6
			}
		}
	}
}


# Dictionary keys are stable offering IDs; NPCs store only the ID.
const OFFERING_DATA := {
	"coffee": {
		"display_name": "Coffee",
		"building_type": "cafe",
		"base_service_time": 4.0,
		"base_price": 10,
		"weight": 70.0
	},
	"matcha_latte": {
		"display_name": "Matcha Latte",
		"building_type": "cafe",
		"base_service_time": 5.5,
		"base_price": 14,
		"weight": 30.0
	},
	"quick_purchase": {
		"display_name": "Quick Purchase",
		"building_type": "minimart",
		"base_service_time": 3.0,
		"base_price": 8,
		"weight": 100.0
	},
	"quick_shot": {
		"display_name": "Quick Shot",
		"building_type": "photobooth",
		"base_service_time": 4.5,
		"base_price": 12,
		"weight": 70.0
	},
	"premium_strip": {
		"display_name": "Premium Strip",
		"building_type": "photobooth",
		"base_service_time": 7.0,
		"base_price": 20,
		"weight": 30.0
	}
}

# Keys are stable trend IDs. Only one trend can be active in this prototype.
const TREND_DATA := {
	"matcha_wave": {
		"id": "matcha_wave",
		"display_name": "Matcha Wave",
		"threadz_start_posts": [
			"Ủa sao hôm nay quán nào cũng thấy người gọi matcha vậy?",
			"Đi mua cà phê mà cả hàng trước mặt đều gọi matcha.",
			"Tự nhiên hôm nay ai cũng cầm một ly xanh xanh."
		],
		"threadz_end_posts": [],
		"duration": 30.0,
		"offering_weight_modifiers": {
			"coffee": 0.5,
			"matcha_latte": 3.5
		},
		"customer_profile_spawn_modifiers": {}
	},
	"lunch_rush": {
		"id": "lunch_rush",
		"display_name": "Lunch Rush",
		"duration": 30.0,
		"offering_weight_modifiers": {},
		"customer_profile_spawn_modifiers": {
			"office_worker": 2.0,
			"student": 0.75,
			"shipper": 1.0
		},
		"threadz_start_posts": [
			"Trưa nay dân văn phòng kéo xuống đông dữ.",
			"Mới tới giờ nghỉ trưa mà quán xá kín người rồi.",
			"Ai cho cả văn phòng xuống cùng một lúc vậy trời?"
		],
		"threadz_end_posts": [
			"Hết giờ nghỉ trưa cái khu này yên hẳn.",
			"Dân văn phòng quay lại làm hết rồi."
		]
	}
}

# Khách spawn nhanh hơn để test demand/capacity.
# Sau này sẽ thay bằng Demand System thật.
@onready var plot_grid: GridContainer = $PlotGrid
@onready var money_label: Label = $UI/MoneyLabel
@onready var trend_label: Label = $UI/TrendLabel
@onready var threadz_panel: PanelContainer = $UI/ThreadZPanel
@onready var threadz_feed: RichTextLabel = $UI/ThreadZPanel/Margin/Content/Feed
@onready var build_cafe_button: Button = $UI/BuildCafeButton
@onready var build_minimart_button: Button = $UI/BuildMinimartButton
@onready var build_photobooth_button: Button = $UI/BuildPhotoboothButton
@onready var upgrade_cafe_button: Button = $UI/UpgradeCafeButton


const SAVE_VERSION := 1
const SAVE_PATH := "user://save.json"
const AUTOSAVE_INTERVAL := 15.0

# Can be overridden before _ready() by isolated regression tests.
var save_path := SAVE_PATH
var autosave_elapsed := 0.0
var simulation_generation := 0
const THREADZ_POST_LIMIT := 5
const THREADZ_QUEUE_COOLDOWN := 30.0
var threadz_queue_cooldown_remaining := 0.0
var last_threadz_trend_text := ""
var threadz_posts: Array[Dictionary] = []
var threadz_post_order := 0
# Cosmetic randomness must not consume the simulation's random sequence.
var threadz_rng := RandomNumberGenerator.new()

var active_trend_id := ""
var trend_remaining := 0.0

var money := 1000
var selected_plot: Button = null

var customer_spawn_timer := 0.0
var next_customer_spawn := 1.0
var demand_state: int = DemandState.NORMAL


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	threadz_rng.randomize()
	build_cafe_button.text = "Build Cafe - $" + str(get_building_data("cafe")["build_cost"])
	build_minimart_button.text = "Build Minimart - $" + str(get_building_data("minimart")["build_cost"])
	build_photobooth_button.text = "Build Photobooth - $" + str(get_building_data("photobooth")["build_cost"])
	update_money_label()

	for child in plot_grid.get_children():
		if child is Button:
			child.pressed.connect(_on_plot_pressed.bind(child))
	load_game()


# =========================================================
# GAME LOOP
# =========================================================

func _process(delta: float) -> void:
	threadz_queue_cooldown_remaining = maxf(threadz_queue_cooldown_remaining - delta, 0.0)
	update_trend(delta)
	autosave_elapsed += delta
	if autosave_elapsed >= AUTOSAVE_INTERVAL:
		autosave_elapsed = 0.0
		save_game()

	customer_spawn_timer += delta

	if customer_spawn_timer >= next_customer_spawn:
		try_spawn_customer()
		schedule_next_customer()


func schedule_next_customer() -> void:
	customer_spawn_timer = 0.0
	var spawn_interval := get_spawn_interval_for_demand()

	next_customer_spawn = randf_range(
		spawn_interval.x,
		spawn_interval.y
	)

	print(
		"Next customer in: ",
		snapped(next_customer_spawn, 0.1),
		"s"
	)


func get_spawn_interval_for_demand() -> Vector2:
	return DEMAND_SPAWN_INTERVALS.get(
		demand_state,
		DEMAND_SPAWN_INTERVALS[DemandState.NORMAL]
	)


func get_demand_name(state: int) -> String:
	return str(DEMAND_NAMES.get(state, "NORMAL"))


func set_demand_state(new_state: int) -> void:
	if not DEMAND_SPAWN_INTERVALS.has(new_state):
		push_warning("Ignored invalid demand state: " + str(new_state))
		return

	if demand_state == new_state:
		return

	var previous_state := demand_state
	demand_state = new_state

	print(
		"Demand changed: ",
		get_demand_name(previous_state),
		" -> ",
		get_demand_name(demand_state)
	)

	# Apply the new rate to the very next spawn without touching existing NPCs.
	if is_node_ready():
		schedule_next_customer()
		save_game()


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

	if not get_building_data(building_type).is_empty():
		print(
			"Selected business: ",
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
# BUILD BUSINESS
# =========================================================

func build_business(plot: Button, building_type: String) -> void:
	if not is_instance_valid(plot):
		return
	if plot.get_meta("state", "empty") != "empty":
		return
	if plot.get_meta("building_type", "") != "":
		return

	var data := get_building_data(building_type)
	if data.is_empty():
		return

	var build_cost := int(data["build_cost"])
	if money < build_cost:
		print("Not enough money")
		return

	money -= build_cost
	plot.set_meta("building_type", building_type)
	plot.set_meta("level", 1)
	plot.set_meta("state", "active")
	plot.set_meta("customers", [])
	plot.set_meta("waiting_customers", [])
	plot.text = get_building_name(plot).to_upper() + "\nLv.1"
	plot.modulate = Color.WHITE
	update_money_label()
	print("Built ", get_building_name(plot), ": ", plot.name)
	if selected_plot == plot:
		selected_plot = null
	update_action_buttons()
	save_game()

# =========================================================
# UPGRADE BUSINESS
# =========================================================

func upgrade_business(business_plot: Button) -> void:
	if not is_active_business(business_plot):
		return

	var current_level: int = int(
		business_plot.get_meta(
			"level",
			1
		)
	)

	if current_level >= get_building_max_level(business_plot):
		print("Business already max level")
		return

	var upgrade_price := get_building_upgrade_cost(business_plot)

	if money < upgrade_price:
		print("Not enough money")
		return

	money -= upgrade_price

	update_money_label()

	# Close the business before rerouting customers.
	business_plot.set_meta(
		"state",
		"upgrading"
	)

	# Đuổi toàn bộ khách.
	evict_customers(
		business_plot
	)

	business_plot.set_meta(
		"upgrade_target_level",
		current_level + 1
	)

	var upgrade_time := get_building_upgrade_time(business_plot)

	business_plot.set_meta(
		"upgrade_remaining",
		upgrade_time
	)

	business_plot.modulate = Color.WHITE

	selected_plot = null

	update_action_buttons()

	print(
		"Started upgrading ",
		business_plot.name,
		" for ",
		upgrade_time,
		" seconds"
	)

	save_game()
	await run_upgrade_timer(
		business_plot
	)


func run_upgrade_timer(
	plot: Button
) -> void:
	if not is_instance_valid(plot) or plot.get_meta("state", "") != "upgrading":
		return
	var generation := simulation_generation
	if int(plot.get_meta("upgrade_timer_generation", -1)) == generation:
		return
	plot.set_meta("upgrade_timer_generation", generation)
	while true:
		if generation != simulation_generation:
			return
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
			get_building_name(plot).to_upper() + "\n"
			+ "UPGRADING\n"
			+ str(remaining)
			+ "s"
		)

		await get_tree().create_timer(
			1.0
		).timeout

		if generation != simulation_generation:
			return
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

	plot.set_meta("upgrade_timer_generation", -1)
	finish_business_upgrade(
		plot
	)


func finish_business_upgrade(
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
		get_building_name(plot).to_upper() + "\nLv."
		+ str(target_level)
	)

	print(
		"Business upgrade complete: ",
		plot.name,
		" Lv.",
		target_level
	)
	save_game()


# =========================================================
# BUSINESS DATA HELPERS
# =========================================================

func get_building_data(building_type: String) -> Dictionary:
	return BUILDING_DATA.get(building_type, {})


func get_building_level_data(plot: Button) -> Dictionary:
	if not is_instance_valid(plot):
		return {}
	var data := get_building_data(str(plot.get_meta("building_type", "")))
	var levels: Dictionary = data.get("levels", {})
	return levels.get(int(plot.get_meta("level", 0)), {})


func is_active_business(plot: Button) -> bool:
	return (
		is_instance_valid(plot)
		and plot.get_meta("state", "") == "active"
		and not get_building_level_data(plot).is_empty()
	)


func get_building_name(plot: Button) -> String:
	var building_type := str(plot.get_meta("building_type", ""))
	return str(get_building_data(building_type).get("display_name", building_type.capitalize()))


func get_building_capacity(plot: Button) -> int:
	return int(get_building_level_data(plot).get("capacity", 0))


func get_building_queue_capacity(plot: Button) -> int:
	return int(get_building_level_data(plot).get("queue_capacity", 0))


func get_building_max_level(plot: Button) -> int:
	var data := get_building_data(str(plot.get_meta("building_type", "")))
	return int(data.get("max_level", 0))


func get_building_upgrade_cost(plot: Button) -> int:
	return int(get_building_level_data(plot).get("upgrade_cost", 0))


func get_building_upgrade_time(plot: Button) -> int:
	return int(get_building_level_data(plot).get("upgrade_time", 0))

# =========================================================
# OFFERINGS
# =========================================================

func get_offering_data(offering_id: String) -> Dictionary:
	return OFFERING_DATA.get(offering_id, {})


func is_offering_supported(offering_id: String, plot: Button) -> bool:
	if not is_instance_valid(plot):
		return false
	var offering := get_offering_data(offering_id)
	return not offering.is_empty() and offering["building_type"] == plot.get_meta("building_type", "")


func get_offering_selection_weight(offering_id: String, npc: Node2D = null) -> float:
	# Profile preferences are expressed as desired baseline weights. Converting
	# them to a modifier keeps the calculation base * profile * trend.
	var base_weight := float(get_offering_data(offering_id).get("weight", 0.0))
	var profile_modifier := 1.0
	if is_instance_valid(npc):
		var profile := get_customer_profile_data(str(npc.get_meta("customer_profile_id", "")))
		var preferences: Dictionary = profile.get("offering_preferences", {})
		if preferences.has(offering_id) and base_weight > 0.0:
			profile_modifier = float(preferences[offering_id]) / base_weight
	var trend_modifier := get_trend_modifier("offering_weight_modifiers", offering_id)
	return maxf(base_weight * profile_modifier * trend_modifier, 0.0)


func get_available_offering_ids(plot: Button, npc: Node2D = null) -> Array[String]:
	var ids: Array[String] = []
	for offering_id in OFFERING_DATA:
		if is_offering_supported(offering_id, plot) and get_offering_selection_weight(offering_id, npc) > 0.0:
			ids.append(offering_id)
	return ids


func choose_offering(plot: Button, npc: Node2D = null) -> String:
	var ids := get_available_offering_ids(plot, npc)
	if ids.is_empty():
		return ""
	var total := 0.0
	for offering_id in ids:
		total += get_offering_selection_weight(offering_id, npc)
	var roll := randf() * total
	for offering_id in ids:
		roll -= get_offering_selection_weight(offering_id, npc)
		if roll < 0.0:
			return offering_id
	return ids.back()


func assign_customer_offering(npc: Node2D, plot: Button) -> bool:
	var offering_id := str(npc.get_meta("offering_id", ""))
	if not is_offering_supported(offering_id, plot):
		offering_id = choose_offering(plot, npc)
	npc.set_meta("offering_id", offering_id)
	return not offering_id.is_empty()


func get_offering_service_time(plot: Button, offering_id: String) -> float:
	if not is_offering_supported(offering_id, plot):
		return 0.0
	var speed := float(get_building_level_data(plot).get("service_speed_multiplier", 1.0))
	if speed <= 0.0:
		return 0.0
	return float(get_offering_data(offering_id)["base_service_time"]) / speed


func get_offering_income(plot: Button, offering_id: String) -> int:
	if not is_offering_supported(offering_id, plot):
		return 0
	return int(get_offering_data(offering_id)["base_price"]) + int(get_building_level_data(plot).get("income_bonus", 0))

# =========================================================
# SERVICE SLOT SYSTEM
# =========================================================

func get_free_service_slot_index(
	business_plot: Button
) -> int:
	var capacity := get_building_capacity(
		business_plot
	)

	var customers: Array = business_plot.get_meta(
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
	business_plot: Button,
	slot_index: int
) -> Vector2:
	var center := (
		business_plot.global_position
		+ business_plot.size / 2.0
	)

	var capacity := get_building_capacity(
		business_plot
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


func get_queue_slot_position(
	business_plot: Button,
	queue_index: int
) -> Vector2:
	var center := (
		business_plot.global_position
		+ business_plot.size / 2.0
	)

	return center + Vector2(
		0,
		55 + queue_index * 35
	)


# =========================================================
# CUSTOMER SPAWNING
# =========================================================

func try_spawn_customer() -> void:
	var profile_id := choose_customer_profile()
	var trip_plan := generate_trip_plan(profile_id)
	if trip_plan.is_empty():
		return
	var business := choose_available_business_for_type(trip_plan[0])
	if business == null:
		return
	spawn_customer_for_business(business, profile_id, trip_plan)


func get_active_business_types() -> Array[String]:
	var business_types: Array[String] = []
	for plot in plot_grid.get_children():
		if not (plot is Button):
			continue
		if not is_active_business(plot) or get_available_offering_ids(plot).is_empty():
			continue
		var building_type := str(plot.get_meta("building_type", ""))
		if not building_type.is_empty() and not business_types.has(building_type):
			business_types.append(building_type)
	return business_types


func get_customer_profile_data(profile_id: String) -> Dictionary:
	return CUSTOMER_PROFILE_DATA.get(profile_id, {})


func get_customer_profile_name(profile_id: String) -> String:
	return str(get_customer_profile_data(profile_id).get("display_name", profile_id.capitalize()))


func choose_weighted_id(ids: Array[String], weights: Dictionary) -> String:
	var total := 0.0
	for id in ids:
		total += maxf(float(weights.get(id, 0.0)), 0.0)
	if total <= 0.0:
		return ids.pick_random() if not ids.is_empty() else ""
	var roll := randf() * total
	for id in ids:
		roll -= maxf(float(weights.get(id, 0.0)), 0.0)
		if roll < 0.0:
			return id
	return ids.back()


func choose_customer_profile() -> String:
	var profile_ids: Array[String] = []
	var weights := {}
	for profile_id in CUSTOMER_PROFILE_DATA:
		profile_ids.append(profile_id)
		weights[profile_id] = (
			float(CUSTOMER_PROFILE_DATA[profile_id]["spawn_weight"])
			* get_trend_modifier("customer_profile_spawn_modifiers", profile_id)
		)
	return choose_weighted_id(profile_ids, weights)


func generate_trip_plan(profile_id: String, forced_first_type: String = "") -> Array[String]:
	var available_types := get_active_business_types()
	if available_types.is_empty():
		return []
	var profile := get_customer_profile_data(profile_id)
	if profile.is_empty():
		return []
	var preferences: Dictionary = profile.get("business_preferences", {})
	var first_type := forced_first_type
	if first_type.is_empty() or not available_types.has(first_type):
		first_type = choose_weighted_id(available_types, preferences)
	if first_type.is_empty():
		return []
	var trip_plan: Array[String] = [first_type]
	var remaining_types := available_types.duplicate()
	remaining_types.erase(first_type)
	var trip_probabilities: Dictionary = profile.get("trip_probabilities", {})
	if not remaining_types.is_empty() and randf() < float(trip_probabilities.get(2, 0.0)):
		trip_plan.append(choose_weighted_id(remaining_types, preferences))
	return trip_plan


func choose_available_business_for_type(building_type: String) -> Button:
	var immediate: Array[Button] = []
	var queued: Array[Button] = []
	for plot in plot_grid.get_children():
		if not (plot is Button) or not is_active_business(plot):
			continue
		if str(plot.get_meta("building_type", "")) != building_type:
			continue
		if get_available_offering_ids(plot).is_empty():
			continue
		cleanup_customer_lists(plot)
		if get_free_service_slot_index(plot) != -1:
			immediate.append(plot)
		elif plot.get_meta("waiting_customers", []).size() < get_building_queue_capacity(plot):
			queued.append(plot)
	if not immediate.is_empty():
		return immediate.pick_random()
	if not queued.is_empty():
		return queued.pick_random()
	return null


func get_current_trip_business_type(npc: Node2D) -> String:
	if not is_instance_valid(npc):
		return ""
	var trip_plan: Array = npc.get_meta("trip_plan", [])
	var trip_index := int(npc.get_meta("trip_index", 0))
	if trip_index < 0 or trip_index >= trip_plan.size():
		return ""
	return str(trip_plan[trip_index])


func get_trip_display_name(building_type: String) -> String:
	return str(get_building_data(building_type).get("display_name", building_type.capitalize()))


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
	build_minimart_button.hide()
	build_photobooth_button.hide()
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

	if state == "empty":
		build_cafe_button.show()
		build_minimart_button.show()
		build_photobooth_button.show()
		return

	if is_active_business(selected_plot):
		var level: int = int(
			selected_plot.get_meta(
				"level",
				1
			)
		)

		upgrade_cafe_button.show()

		if level >= get_building_max_level(selected_plot):
			upgrade_cafe_button.text = (
				get_building_name(selected_plot) + " MAX LEVEL"
			)

			upgrade_cafe_button.disabled = true

		else:
			var upgrade_price := get_building_upgrade_cost(selected_plot)

			upgrade_cafe_button.text = (
				"Upgrade " + get_building_name(selected_plot) + " - $"
				+ str(upgrade_price)
			)

			upgrade_cafe_button.disabled = false


func _on_build_cafe_button_pressed() -> void:
	build_business(selected_plot, "cafe")


func _on_build_minimart_button_pressed() -> void:
	build_business(selected_plot, "minimart")


func _on_build_photobooth_button_pressed() -> void:
	build_business(selected_plot, "photobooth")


func _on_upgrade_cafe_button_pressed() -> void:
	upgrade_business(selected_plot)


# =========================================================
# INCOME POPUP
# =========================================================

func show_income_popup(
	plot: Button,
	amount: int
) -> void:
	var popup := Label.new()
	popup.add_to_group("income_popups")

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

	var tween := popup.create_tween()

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

func cleanup_customer_lists(
	business_plot: Button
) -> void:
	if not is_instance_valid(business_plot):
		return

	var customers: Array = business_plot.get_meta(
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

	business_plot.set_meta(
		"customers",
		valid_customers
	)

	var waiting_customers: Array = business_plot.get_meta(
		"waiting_customers",
		[]
	)
	var valid_waiting_customers: Array = []

	for customer in waiting_customers:
		if not is_instance_valid(customer):
			continue

		if bool(customer.get_meta("leaving", false)):
			continue

		if valid_customers.has(customer):
			continue

		valid_waiting_customers.append(customer)

	business_plot.set_meta(
		"waiting_customers",
		valid_waiting_customers
	)
	check_queue_threadz_reaction(business_plot)


func register_customer(
	business_plot: Button,
	npc: Node2D
) -> void:
	if not is_instance_valid(business_plot):
		return

	if not is_instance_valid(npc):
		return

	var waiting_customers: Array = business_plot.get_meta(
		"waiting_customers",
		[]
	)
	waiting_customers.erase(npc)
	business_plot.set_meta("waiting_customers", waiting_customers)
	check_queue_threadz_reaction(business_plot)

	var customers: Array = business_plot.get_meta(
		"customers",
		[]
	)

	if not customers.has(npc):
		customers.append(
			npc
		)

	business_plot.set_meta(
		"customers",
		customers
	)


func register_waiting_customer(
	business_plot: Button,
	npc: Node2D
) -> void:
	if not is_instance_valid(business_plot) or not is_instance_valid(npc):
		return

	var customers: Array = business_plot.get_meta("customers", [])
	customers.erase(npc)
	business_plot.set_meta("customers", customers)

	var waiting_customers: Array = business_plot.get_meta(
		"waiting_customers",
		[]
	)

	if not waiting_customers.has(npc):
		waiting_customers.append(npc)

	business_plot.set_meta("waiting_customers", waiting_customers)
	check_queue_threadz_reaction(business_plot)


func unregister_customer(
	business_plot: Button,
	npc: Node2D
) -> void:
	if not is_instance_valid(business_plot):
		return

	var customers: Array = business_plot.get_meta(
		"customers",
		[]
	)

	customers.erase(
		npc
	)

	business_plot.set_meta(
		"customers",
		customers
	)

	cleanup_customer_lists(
		business_plot
	)


func unregister_waiting_customer(
	business_plot: Button,
	npc: Node2D
) -> void:
	if not is_instance_valid(business_plot):
		return

	var waiting_customers: Array = business_plot.get_meta(
		"waiting_customers",
		[]
	)
	waiting_customers.erase(npc)
	business_plot.set_meta("waiting_customers", waiting_customers)
	check_queue_threadz_reaction(business_plot)


func refresh_queue_positions(
	business_plot: Button
) -> void:
	if not is_instance_valid(business_plot):
		return

	cleanup_customer_lists(business_plot)
	var waiting_customers: Array = business_plot.get_meta(
		"waiting_customers",
		[]
	)

	for index in range(waiting_customers.size()):
		var npc = waiting_customers[index]

		if not is_instance_valid(npc):
			continue

		var previous_index := int(npc.get_meta("queue_index", -1))
		npc.set_meta("queue_index", index)

		if previous_index == -1:
			npc.set_meta("customer_state", "going_to_queue")
		elif npc.get_meta("customer_state", "") != "going_to_queue":
			npc.set_meta("customer_state", "waiting")

		npc.walk_to(
			get_queue_slot_position(business_plot, index),
			2.0 if previous_index == -1 else 0.35
		)


func evict_customers(
	business_plot: Button
) -> void:
	if not is_instance_valid(business_plot):
		return

	var customers: Array = business_plot.get_meta(
		"customers",
		[]
	)
	var waiting_customers: Array = business_plot.get_meta(
		"waiting_customers",
		[]
	)
	var all_customers := customers.duplicate()

	for npc in waiting_customers:
		if not all_customers.has(npc):
			all_customers.append(npc)

	for npc in all_customers:
		if not is_instance_valid(npc):
			continue

		reassign_customer_from_upgrading_business(npc, business_plot)

	business_plot.set_meta("customers", [])
	business_plot.set_meta("waiting_customers", [])
	check_queue_threadz_reaction(business_plot)


func reassign_customer_from_upgrading_business(
	npc: Node2D,
	old_business: Button
) -> void:
	if not is_instance_valid(npc) or not is_instance_valid(old_business):
		return

	# Invalidate the old movement/service coroutine before assigning a new business.
	var assignment_id := int(npc.get_meta("assignment_id", 0)) + 1
	npc.set_meta("assignment_id", assignment_id)
	npc.set_meta("customer_state", "rerouting")
	npc.set_meta("current_business", null)
	npc.cancel_movement()
	unregister_customer(old_business, npc)
	unregister_waiting_customer(old_business, npc)
	npc.set_meta("service_slot_index", -1)
	npc.set_meta("queue_index", -1)
	npc.set_meta("leaving", false)

	var required_type := get_current_trip_business_type(npc)
	if assign_customer_to_available_business(npc, required_type, assignment_id, true, old_business):
		print(npc.name, " rerouted from ", old_business.name, " to ", npc.get_meta("current_business").name)
		return

	# No active business with a valid offering can accept this customer.
	print(
		npc.name,
		" could not reroute from ",
		old_business.name,
		": no available business has room"
	)
	npc.set_meta("current_business", old_business)
	send_customer_out(npc, old_business)


func assign_customer_to_available_business(
	npc: Node2D,
	required_type: String,
	assignment_id: int,
	preserve_offering: bool,
	excluded_business: Button = null
) -> bool:
	if not is_instance_valid(npc) or required_type.is_empty():
		return false
	var immediate: Array[Button] = []
	var queued: Array[Button] = []
	for plot in plot_grid.get_children():
		if not (plot is Button) or plot == excluded_business:
			continue
		if not is_active_business(plot):
			continue
		if str(plot.get_meta("building_type", "")) != required_type:
			continue
		if get_available_offering_ids(plot).is_empty():
			continue
		cleanup_customer_lists(plot)
		if get_free_service_slot_index(plot) != -1:
			immediate.append(plot)
		elif plot.get_meta("waiting_customers", []).size() < get_building_queue_capacity(plot):
			queued.append(plot)

	var business: Button = null
	if not immediate.is_empty():
		business = immediate.pick_random()
	elif not queued.is_empty():
		business = queued.pick_random()
	if business == null:
		return false

	if not preserve_offering:
		npc.set_meta("offering_id", "")
	if not assign_customer_offering(npc, business):
		return false
	npc.set_meta("current_business", business)
	var slot_index := get_free_service_slot_index(business)
	if slot_index != -1:
		npc.set_meta("service_slot_index", slot_index)
		npc.set_meta("customer_state", "going_to_service")
		register_customer(business, npc)
		start_customer_service(npc, business, slot_index, assignment_id)
	else:
		npc.set_meta("customer_state", "waiting")
		register_waiting_customer(business, npc)
		refresh_queue_positions(business)
		start_customer_patience(npc, business, assignment_id)
	return true


# =========================================================
# CUSTOMER BEHAVIOUR
# =========================================================

func spawn_customer_for_business(
	business_plot: Button,
	profile_id: String = "",
	trip_plan_override: Array[String] = []
) -> void:
	if not is_instance_valid(business_plot):
		return

	if not is_active_business(business_plot):
		return

	cleanup_customer_lists(business_plot)
	var slot_index := get_free_service_slot_index(business_plot)
	var waiting_customers: Array = business_plot.get_meta(
		"waiting_customers",
		[]
	)

	if (
		slot_index == -1
		and waiting_customers.size() >= get_building_queue_capacity(business_plot)
	):
		return

	if get_customer_profile_data(profile_id).is_empty():
		profile_id = choose_customer_profile()
	var npc = OFFICE_WORKER_SCENE.instantiate()
	npc.set_meta("customer_profile_id", profile_id)
	var offering_id := choose_offering(business_plot, npc)
	if offering_id.is_empty():
		npc.free()
		return

	var first_business_type := str(business_plot.get_meta("building_type", ""))
	var trip_plan := trip_plan_override.duplicate()
	if trip_plan.is_empty():
		trip_plan = generate_trip_plan(profile_id, first_business_type)
	npc.set_meta("offering_id", offering_id)
	npc.set_meta("trip_plan", trip_plan)
	npc.set_meta("trip_index", 0)
	npc.set_meta("visited_businesses", [])
	npc.add_to_group("district_customers")
	add_child(npc)
	npc.global_position = Vector2(50, 350)
	npc.set_meta("leaving", false)
	npc.set_meta("service_slot_index", -1)
	npc.set_meta("queue_index", -1)
	npc.set_meta("customer_state", "waiting")
	npc.set_meta("assignment_id", 1)
	npc.set_meta("current_business", business_plot)
	var patience_range: Vector2 = get_customer_profile_data(profile_id)["patience_range"]
	var patience_max := randf_range(patience_range.x, patience_range.y)
	npc.set_meta("patience_max", patience_max)
	npc.set_meta("patience_remaining", patience_max)
	npc.set_meta("patience_run_id", 0)
	var trip_names: Array[String] = []
	for business_type in trip_plan:
		trip_names.append(get_trip_display_name(str(business_type)))
	print(
		"Customer spawned: ", get_customer_profile_name(profile_id),
		" | trip: ", " -> ".join(trip_names),
		" | patience: ", snapped(patience_max, 0.1), "s"
	)

	if slot_index != -1:
		# Reserve before any await so nearby spawns cannot claim the same slot.
		npc.set_meta("service_slot_index", slot_index)
		npc.set_meta("customer_state", "going_to_service")
		register_customer(business_plot, npc)
		start_customer_service(npc, business_plot, slot_index, 1)
		return

	register_waiting_customer(business_plot, npc)
	refresh_queue_positions(business_plot)
	start_customer_patience(npc, business_plot, 1)


func is_customer_assignment_current(
	npc: Node2D,
	business_plot: Button,
	assignment_id: int
) -> bool:
	if not is_instance_valid(npc) or not is_instance_valid(business_plot):
		return false

	if int(npc.get_meta("assignment_id", 0)) != assignment_id:
		return false

	if npc.get_meta("current_business", null) != business_plot:
		return false

	var customer_state := str(npc.get_meta("customer_state", ""))

	return customer_state != "rerouting" and customer_state != "leaving"


func start_customer_patience(
	npc: Node2D,
	business_plot: Button,
	assignment_id: int
) -> void:
	if not is_customer_assignment_current(npc, business_plot, assignment_id):
		return

	var patience_run_id := int(npc.get_meta("patience_run_id", 0)) + 1
	npc.set_meta("patience_run_id", patience_run_id)
	var waiting_announced := false

	while true:
		await get_tree().process_frame

		if not is_instance_valid(npc) or not is_instance_valid(business_plot):
			return

		if not is_customer_assignment_current(npc, business_plot, assignment_id):
			return

		if int(npc.get_meta("patience_run_id", 0)) != patience_run_id:
			return

		var waiting_customers: Array = business_plot.get_meta(
			"waiting_customers",
			[]
		)

		if not waiting_customers.has(npc):
			return

		var customer_state := str(npc.get_meta("customer_state", ""))

		if customer_state == "going_to_queue":
			var queue_index := int(npc.get_meta("queue_index", -1))

			if queue_index < 0:
				return

			var queue_position := get_queue_slot_position(
				business_plot,
				queue_index
			)

			if npc.global_position.distance_to(queue_position) <= 1.0:
				npc.set_meta("customer_state", "waiting")
				customer_state = "waiting"

		if customer_state != "waiting":
			continue

		if not waiting_announced:
			waiting_announced = true
			print(
				npc.name,
				" waiting | patience: ",
				snapped(
					float(npc.get_meta("patience_remaining", 0.0)),
					0.1
				),
				"s"
			)

		var patience_remaining := float(
			npc.get_meta("patience_remaining", 0.0)
		)
		patience_remaining -= get_process_delta_time()
		npc.set_meta(
			"patience_remaining",
			max(patience_remaining, 0.0)
		)

		if patience_remaining <= 0.0:
			print(npc.name, " left queue: patience expired")
			send_customer_out(npc, business_plot)
			return


func start_customer_service(
	npc: Node2D,
	business_plot: Button,
	slot_index: int,
	assignment_id: int
) -> void:
	if not is_instance_valid(npc) or not is_instance_valid(business_plot):
		return

	if not is_customer_assignment_current(npc, business_plot, assignment_id):
		return

	if not is_active_business(business_plot):
		send_customer_out(npc, business_plot)
		return

	var service_position := get_service_slot_position(business_plot, slot_index)
	var walk_in: Tween = npc.walk_to(service_position, 2.0)

	while (
		is_instance_valid(npc)
		and walk_in.is_valid()
		and walk_in.is_running()
	):
		await get_tree().process_frame

		if not is_instance_valid(npc):
			return

		if not is_customer_assignment_current(npc, business_plot, assignment_id):
			return

		if bool(
			npc.get_meta(
				"leaving",
				false
			)
		):
			return

		if not is_active_business(business_plot):
			send_customer_out(
				npc,
				business_plot
			)

			return

	if not is_instance_valid(npc):
		return

	if not is_customer_assignment_current(npc, business_plot, assignment_id):
		return

	if bool(
		npc.get_meta(
			"leaving",
			false
		)
	):
		return

	if not is_active_business(business_plot):
		send_customer_out(
			npc,
			business_plot
		)

		return

	npc.set_meta("customer_state", "serving")

	# =====================================================
	# SERVICE
	# =====================================================

	var offering_id := str(npc.get_meta("offering_id", ""))
	var service_time := get_offering_service_time(business_plot, offering_id)
	if service_time <= 0.0:
		push_warning("Customer has no valid offering for this business.")
		send_customer_out(npc, business_plot)
		return
	var offering := get_offering_data(offering_id)
	var elapsed := 0.0
	var profile_name := get_customer_profile_name(str(npc.get_meta("customer_profile_id", "")))

	print(
		profile_name, " -> ", get_building_name(business_plot),
		" | ", offering["display_name"], " | ",
		snapped(service_time, 0.01), "s | $",
		get_offering_income(business_plot, offering_id)
	)

	while elapsed < service_time:
		await get_tree().process_frame

		if not is_instance_valid(npc):
			return

		if not is_customer_assignment_current(npc, business_plot, assignment_id):
			return

		if bool(
			npc.get_meta(
				"leaving",
				false
			)
		):
			return

		if not is_active_business(business_plot):
			send_customer_out(
				npc,
				business_plot
			)

			return

		elapsed += get_process_delta_time()

	# =====================================================
	# PAYMENT
	# =====================================================

	if not is_instance_valid(npc):
		return

	if not is_customer_assignment_current(npc, business_plot, assignment_id):
		return

	if bool(
		npc.get_meta(
			"leaving",
			false
		)
	):
		return

	if not is_active_business(business_plot):
		send_customer_out(
			npc,
			business_plot
		)

		return

	var income := get_offering_income(business_plot, offering_id)

	money += income

	update_money_label()

	show_income_popup(
		business_plot,
		income
	)

	print(
		npc.name,
		" paid $",
		income,
		" at ",
		business_plot.name
	)

	complete_customer_trip_stop(npc, business_plot)


func complete_customer_trip_stop(npc: Node2D, business_plot: Button) -> void:
	if not is_instance_valid(npc) or npc.get_meta("current_business", null) != business_plot:
		return
	var completed_type := get_current_trip_business_type(npc)
	var visited: Array = npc.get_meta("visited_businesses", [])
	visited.append(str(business_plot.name))
	npc.set_meta("visited_businesses", visited)
	npc.set_meta("trip_index", int(npc.get_meta("trip_index", 0)) + 1)

	var released_service_slot := int(npc.get_meta("service_slot_index", -1)) >= 0
	npc.set_meta("assignment_id", int(npc.get_meta("assignment_id", 0)) + 1)
	var assignment_id := int(npc.get_meta("assignment_id", 0))
	npc.set_meta("current_business", null)
	npc.set_meta("service_slot_index", -1)
	npc.set_meta("queue_index", -1)
	npc.set_meta("offering_id", "")
	unregister_customer(business_plot, npc)
	unregister_waiting_customer(business_plot, npc)
	npc.cancel_movement()
	if is_active_business(business_plot):
		refresh_queue_positions(business_plot)
		if released_service_slot:
			promote_next_waiting_customer(business_plot)

	var next_type := get_current_trip_business_type(npc)
	if next_type.is_empty():
		print(npc.name, " completed trip")
		begin_customer_exit(npc)
		return

	print(npc.name, " completed ", get_trip_display_name(completed_type), ", next stop: ", get_trip_display_name(next_type))
	npc.set_meta("patience_remaining", float(npc.get_meta("patience_max", 0.0)))
	npc.set_meta("leaving", false)
	if not assign_customer_to_available_business(npc, next_type, assignment_id, false):
		print(npc.name, " skipped ", get_trip_display_name(next_type), ": no available business")
		begin_customer_exit(npc)


func promote_next_waiting_customer(
	business_plot: Button
) -> void:
	if not is_instance_valid(business_plot):
		return

	if not is_active_business(business_plot):
		return

	cleanup_customer_lists(business_plot)
	var slot_index := get_free_service_slot_index(business_plot)

	if slot_index == -1:
		return

	var waiting_customers: Array = business_plot.get_meta(
		"waiting_customers",
		[]
	)

	if waiting_customers.is_empty():
		return

	var npc = waiting_customers.pop_front()
	business_plot.set_meta("waiting_customers", waiting_customers)
	check_queue_threadz_reaction(business_plot)

	if not is_instance_valid(npc):
		promote_next_waiting_customer(business_plot)
		return

	# Move between collections and reserve the released slot atomically.
	npc.set_meta("queue_index", -1)
	npc.set_meta("service_slot_index", slot_index)
	npc.set_meta("customer_state", "moving_from_queue_to_service")
	var assignment_id := int(npc.get_meta("assignment_id", 0)) + 1
	npc.set_meta("assignment_id", assignment_id)
	npc.set_meta("current_business", business_plot)
	register_customer(business_plot, npc)
	refresh_queue_positions(business_plot)
	start_customer_service(npc, business_plot, slot_index, assignment_id)


# =========================================================
# CUSTOMER EXIT
# =========================================================

func send_customer_out(
	npc: Node2D,
	business_plot: Button
) -> void:
	if not is_instance_valid(npc):
		return

	# Ignore stale exit calls from a coroutine that no longer owns this NPC.
	if npc.get_meta("current_business", null) != business_plot:
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
	npc.set_meta("customer_state", "leaving")
	npc.set_meta(
		"assignment_id",
		int(npc.get_meta("assignment_id", 0)) + 1
	)
	npc.set_meta("current_business", null)

	var released_service_slot := int(
		npc.get_meta("service_slot_index", -1)
	) >= 0

	# Giải phóng slot ngay khi khách bắt đầu rời đi.
	npc.set_meta(
		"service_slot_index",
		-1
	)
	npc.set_meta("queue_index", -1)

	unregister_customer(
		business_plot,
		npc
	)
	unregister_waiting_customer(business_plot, npc)

	npc.cancel_movement()

	if is_active_business(business_plot):
		refresh_queue_positions(business_plot)

		if released_service_slot:
			promote_next_waiting_customer(business_plot)

	begin_customer_exit(npc, true)


func begin_customer_exit(npc: Node2D, already_marked_leaving: bool = false) -> void:
	if not is_instance_valid(npc):
		return
	if not already_marked_leaving:
		if bool(npc.get_meta("leaving", false)):
			return
		npc.set_meta("leaving", true)
		npc.set_meta("customer_state", "leaving")
		npc.set_meta("assignment_id", int(npc.get_meta("assignment_id", 0)) + 1)
		npc.set_meta("current_business", null)
		npc.set_meta("service_slot_index", -1)
		npc.set_meta("queue_index", -1)
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


# =========================================================
# LOCAL PERSISTENCE
# =========================================================

func has_save_game() -> bool:
	return FileAccess.file_exists(save_path)


func save_game() -> bool:
	var plots: Array = []
	for plot in plot_grid.get_children():
		if not (plot is Button):
			continue
		# Explicit whitelist: no NPCs, assignments, tweens or Node references.
		plots.append({
			"name": str(plot.name),
			"building_type": str(plot.get_meta("building_type", "")),
			"level": int(plot.get_meta("level", 0)),
			"state": str(plot.get_meta("state", "empty")),
			"upgrade_remaining": int(plot.get_meta("upgrade_remaining", 0)),
			"upgrade_target_level": int(plot.get_meta("upgrade_target_level", 0))
		})
	var data := {
		"version": SAVE_VERSION,
		"money": money,
		"demand_state": demand_state,
		"plots": plots
	}
	# Write alongside the destination, then replace it only after a successful write.
	var temporary_path := save_path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_warning("Save failed: cannot open " + temporary_path + ": " + error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "	"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_warning("Save failed while writing: " + error_string(write_error))
		return false
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(save_path)
	)
	if rename_error != OK:
		push_warning("Save failed while replacing file: " + error_string(rename_error))
		return false
	return true


func load_game() -> bool:
	reset_transient_and_district_state()
	var data: Dictionary = {}
	if has_save_game():
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file == null:
			push_warning("Cannot read save; starting fresh: " + error_string(FileAccess.get_open_error()))
		else:
			var parser := JSON.new()
			var parse_error := parser.parse(file.get_as_text())
			file.close()
			if parse_error != OK:
				push_warning("Invalid save JSON; starting fresh: " + parser.get_error_message())
			elif not (parser.data is Dictionary):
				push_warning("Invalid save root; starting fresh.")
			else:
				data = validate_save_data(parser.data)
				if data.is_empty():
					push_warning("Invalid or unsupported save data; starting fresh.")

	if not data.is_empty():
		money = data["money"]
		demand_state = data["demand_state"]
		for record in data["plots"]:
			var plot := plot_grid.get_node_or_null(NodePath(record["name"])) as Button
			if plot == null or plot.get_parent() != plot_grid:
				continue
			for key in ["building_type", "level", "state", "upgrade_remaining", "upgrade_target_level"]:
				plot.set_meta(key, record[key])
			if record["state"] == "active":
				plot.text = get_building_name(plot).to_upper() + "
Lv." + str(record["level"])

	update_money_label()
	update_action_buttons()
	schedule_next_customer()
	# Apply every plot before resuming timers (completion may save the district).
	for plot in plot_grid.get_children():
		if plot is Button and plot.get_meta("state") == "upgrading":
			run_upgrade_timer(plot)
	return not data.is_empty()


func reset_transient_and_district_state() -> void:
	end_trend(active_trend_id)
	threadz_posts.clear()
	threadz_queue_cooldown_remaining = 0.0
	last_threadz_trend_text = ""
	threadz_post_order = 0
	threadz_panel.hide()
	refresh_threadz_feed()
	# Invalidate old countdowns before restoring even the same plot/state.
	simulation_generation += 1
	for child in get_children():
		if child.is_in_group("district_customers"):
			child.set_meta("assignment_id", int(child.get_meta("assignment_id", 0)) + 1)
			child.set_meta("current_business", null)
			child.set_meta("customer_state", "leaving")
			child.cancel_movement()
			child.free()
		elif child.is_in_group("income_popups"):
			child.free()
	selected_plot = null
	money = 1000
	demand_state = DemandState.NORMAL
	autosave_elapsed = 0.0
	for plot in plot_grid.get_children():
		if not (plot is Button):
			continue
		plot.set_meta("building_type", "")
		plot.set_meta("level", 0)
		plot.set_meta("state", "empty")
		plot.set_meta("customers", [])
		plot.set_meta("waiting_customers", [])
		plot.set_meta("upgrade_remaining", 0)
		plot.set_meta("upgrade_target_level", 0)
		plot.set_meta("queue_threadz_posted", false)
		plot.set_meta("upgrade_timer_generation", -1)
		plot.text = "EMPTY"
		plot.modulate = Color.WHITE


func is_save_integer(value: Variant) -> bool:
	if not (value is int or value is float):
		return false
	# JSON numbers are doubles; keep conversion within their exact integer range.
	return is_finite(float(value)) and absf(float(value)) <= 9007199254740991.0 and float(value) == floor(float(value))


func validate_save_data(raw: Dictionary) -> Dictionary:
	# Missing optional fields default safely; malformed present values reject the
	# whole snapshot so loading never leaves a partially restored district.
	if not is_save_integer(raw.get("version")) or int(raw["version"]) != SAVE_VERSION:
		return {}
	var saved_money: Variant = raw.get("money", 1000)
	var saved_demand: Variant = raw.get("demand_state", DemandState.NORMAL)
	var records: Variant = raw.get("plots", [])
	if not is_save_integer(saved_money) or int(saved_money) < 0:
		return {}
	if not is_save_integer(saved_demand) or not DEMAND_NAMES.has(int(saved_demand)):
		return {}
	if not (records is Array):
		return {}
	var plots: Array = []
	var seen := {}
	for record in records:
		if not (record is Dictionary):
			return {}
		var plot_name: Variant = record.get("name", "")
		if not (plot_name is String) or plot_name.is_empty() or seen.has(plot_name):
			return {}
		seen[plot_name] = true
		# Match direct plot names only; never interpret save data as a scene path.
		var known_plot := false
		for plot in plot_grid.get_children():
			if plot is Button and str(plot.name) == plot_name:
				known_plot = true
				break
		if not known_plot:
			continue
		var kind: Variant = record.get("building_type", "")
		if not (kind is String):
			return {}
		var level: Variant = record.get("level", 0 if kind == "" else 1)
		var state: Variant = record.get("state", "empty" if kind == "" else "active")
		if not is_save_integer(level) or not (state is String):
			return {}
		var remaining := 0
		var target := 0
		if kind == "":
			if int(level) != 0 or state != "empty":
				return {}
		else:
			var building := get_building_data(kind)
			if building.is_empty() or not building["levels"].has(int(level)):
				return {}
			if state != "active" and state != "upgrading":
				return {}
			if state == "upgrading":
				var level_data: Dictionary = building["levels"][int(level)]
				var saved_remaining: Variant = record.get("upgrade_remaining", level_data.get("upgrade_time", 0))
				var saved_target: Variant = record.get("upgrade_target_level", int(level) + 1)
				if not is_save_integer(saved_remaining) or not is_save_integer(saved_target):
					return {}
				remaining = int(saved_remaining)
				target = int(saved_target)
				if target != int(level) + 1 or not building["levels"].has(target):
					return {}
				if remaining < 0 or remaining > int(level_data.get("upgrade_time", 0)):
					return {}
		plots.append({
			"name": plot_name, "building_type": kind, "level": int(level),
			"state": state, "upgrade_remaining": remaining, "upgrade_target_level": target
		})
	return {"money": int(saved_money), "demand_state": int(saved_demand), "plots": plots}


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready():
		save_game()

# =========================================================
# MINIMAL TRENDS (TRANSIENT, NOT SAVED)
# =========================================================

func is_trend_active(trend_id: String) -> bool:
	return not trend_id.is_empty() and active_trend_id == trend_id


func get_active_trend() -> Dictionary:
	return TREND_DATA.get(active_trend_id, {})


func get_trend_modifier(section: String, target_id: String, default_value: float = 1.0) -> float:
	var trend := get_active_trend()
	var modifiers: Dictionary = trend.get(section, {})
	return maxf(float(modifiers.get(target_id, default_value)), 0.0)


func publish_trend_message(message_key: String) -> void:
	var trend := get_active_trend()
	var messages: Array = trend.get(message_key, [])
	if messages.is_empty():
		return
	var candidates: Array[String] = []
	for message in messages:
		if str(message) != last_threadz_trend_text:
			candidates.append(str(message))
	if candidates.is_empty():
		return
	last_threadz_trend_text = candidates[threadz_rng.randi_range(0, candidates.size() - 1)]
	add_threadz_post(last_threadz_trend_text, "trend")


func start_trend(trend_id: String) -> void:
	if not TREND_DATA.has(trend_id):
		push_warning("Unknown trend: " + trend_id)
		return
	# Repeating the same trend remains a no-op; a different trend cleanly replaces it.
	if active_trend_id == trend_id:
		return
	if not active_trend_id.is_empty():
		end_active_trend()
	active_trend_id = trend_id
	trend_remaining = float(TREND_DATA[trend_id]["duration"])
	trend_label.text = "TREND: " + str(TREND_DATA[trend_id]["display_name"])
	trend_label.show()
	print("Trend started: ", TREND_DATA[trend_id]["display_name"])
	publish_trend_message("threadz_start_posts")


func end_active_trend() -> void:
	if active_trend_id.is_empty():
		return
	var display_name := str(get_active_trend().get("display_name", active_trend_id))
	publish_trend_message("threadz_end_posts")
	active_trend_id = ""
	trend_remaining = 0.0
	trend_label.hide()
	trend_label.text = ""
	print("Trend ended: ", display_name)


func end_trend(trend_id: String) -> void:
	if not is_trend_active(trend_id):
		return
	end_active_trend()


func update_trend(delta: float) -> void:
	if active_trend_id.is_empty():
		return
	# One countdown in the existing game loop: no asynchronous timers to duplicate.
	trend_remaining = maxf(trend_remaining - delta, 0.0)
	if trend_remaining <= 0.0:
		end_active_trend()


# DEBUG ONLY: select the running game window and press T (no auto-start).
func debug_start_matcha_wave() -> void:
	start_trend("matcha_wave")


func debug_start_lunch_rush() -> void:
	start_trend("lunch_rush")


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_T:
		debug_start_matcha_wave()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Y:
		debug_start_lunch_rush()
		get_viewport().set_input_as_handled()

# =========================================================
# THREADZ — BOUNDED, TRANSIENT PRESENTATION
# =========================================================

func add_threadz_post(text: String, type: String = "system") -> void:
	if text.strip_edges().is_empty():
		return
	threadz_post_order += 1
	threadz_posts.push_front({"text": text, "order": threadz_post_order, "type": type})
	if threadz_posts.size() > THREADZ_POST_LIMIT:
		threadz_posts.pop_back()
	refresh_threadz_feed()


func refresh_threadz_feed() -> void:
	if threadz_posts.is_empty():
		threadz_feed.text = "Chưa có bài đăng. Khu phố đang yên ắng."
		return
	var entries := PackedStringArray()
	for post in threadz_posts:
		entries.append(str(post["text"]))
	threadz_feed.text = "

———

".join(entries)
	threadz_feed.scroll_to_line(0)


func _on_threadz_button_pressed() -> void:
	threadz_panel.visible = not threadz_panel.visible


func _on_threadz_close_pressed() -> void:
	threadz_panel.hide()


func check_queue_threadz_reaction(plot: Button) -> void:
	if not is_instance_valid(plot):
		return
	var data := get_building_data(str(plot.get_meta("building_type", "")))
	var reaction: Dictionary = data.get("queue_reaction", {})
	if reaction.is_empty():
		return
	var waiting: Array = plot.get_meta("waiting_customers", [])
	# Hysteresis: 3+ posts once, <=1 rearms. Oscillation between 2 and 3
	# remains the same congestion episode. This is event-driven, not per-frame.
	if not is_active_business(plot) or waiting.size() < int(reaction["reset_below"]):
		plot.set_meta("queue_threadz_posted", false)
	elif waiting.size() >= int(reaction["threshold"]) and not bool(plot.get_meta("queue_threadz_posted", false)):
		# Consume this episode even when suppressed: no delayed backlog of complaints.
		plot.set_meta("queue_threadz_posted", true)
		if threadz_queue_cooldown_remaining > 0.0:
			return
		threadz_queue_cooldown_remaining = THREADZ_QUEUE_COOLDOWN
		add_threadz_post(str(reaction["text"]), "local")
