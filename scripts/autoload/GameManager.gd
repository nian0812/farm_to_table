extends Node

signal player_wallet_changed(new_amount: int)
signal restaurant_funds_changed(new_amount: int)
signal inventory_changed()
signal day_time_updated(current_seconds: float)
signal day_phase_changed(phase_name: String)

const DAY_DURATION: float = 240.0
const PHASE_OPEN_END: float = 180.0
const PHASE_CLEANUP_END: float = 210.0

var player_wallet: int = 1_000_000
var restaurant_funds: int = 0
var current_day: int = 1
var day_timer: float = 0.0
var is_timer_running: bool = false
var current_phase: String = "OPEN"

# Data Caches
var items_data: Dictionary = {} 
var buildings_data: Array = []
var crops_data: Array = []
var inventory: Dictionary = {} 

func _ready() -> void:
	load_all_data()
	start_day()

func _process(delta: float) -> void:
	if not is_timer_running: return
	
	# --- TUA NHANH THỜI GIAN KHI GIỮ PHÍM BACKSPACE ---
	if Input.is_key_pressed(KEY_BACKSPACE):
		day_timer += 5.0 # Tua nhanh 5 giây mỗi khung hình khi giữ phím
	# -------------------------------------------------
	
	day_timer += delta
	emit_signal("day_time_updated", day_timer)
	_handle_day_phases()

func _handle_day_phases() -> void:
	if day_timer < PHASE_OPEN_END and current_phase != "OPEN":
		current_phase = "OPEN"
		emit_signal("day_phase_changed", current_phase)
	elif day_timer >= PHASE_OPEN_END and day_timer < PHASE_CLEANUP_END and current_phase != "CLEANUP":
		current_phase = "CLEANUP"
		emit_signal("day_phase_changed", current_phase)
	elif day_timer >= PHASE_CLEANUP_END and current_phase != "REPORT":
		current_phase = "REPORT"
		emit_signal("day_phase_changed", current_phase)
		trigger_end_of_day()

func start_day() -> void:
	day_timer = 0.0
	current_phase = "OPEN"
	is_timer_running = true
	emit_signal("day_phase_changed", current_phase)

func trigger_end_of_day() -> void:
	is_timer_running = false
	print("--- HẾT NGÀY %d: REPORT ---" % current_day)
	await get_tree().create_timer(5.0).timeout
	if is_inside_tree():
		current_day += 1
		print("--- BẮT ĐẦU NGÀY MỚI: %d ---" % current_day)
		start_day()

# --- FINANCE LOGIC ---
func modify_player_wallet(amount: int) -> bool:
	if amount < 0 and player_wallet < abs(amount): return false
	player_wallet += amount
	emit_signal("player_wallet_changed", player_wallet)
	return true

func modify_restaurant_funds(amount: int) -> bool:
	if amount < 0 and restaurant_funds < abs(amount): return false
	restaurant_funds += amount
	emit_signal("restaurant_funds_changed", restaurant_funds)
	return true

# --- INVENTORY LOGIC ---
func add_to_inventory(item_id: String, qty: int) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + qty
	emit_signal("inventory_changed")

func remove_from_inventory(item_id: String, qty: int) -> bool:
	if inventory.get(item_id, 0) >= qty:
		inventory[item_id] -= qty
		if inventory[item_id] == 0:
			inventory.erase(item_id)
		emit_signal("inventory_changed")
		return true
	return false

func clear_inventory() -> void:
	inventory.clear()
	emit_signal("inventory_changed")

# --- DATA LOADER ---
func load_all_data() -> void:
	crops_data = _read_json_array("res://data/crops.json")
	buildings_data = _read_json_array("res://data/buildings.json")
	
	var raw_items = _read_json_array("res://data/items.json")
	for item in raw_items:
		items_data[item["item_id"]] = item

func _read_json_array(file_path: String) -> Array:
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			return json.get_data()
	print("Lỗi: Không đọc được file %s" % file_path)
	return []
