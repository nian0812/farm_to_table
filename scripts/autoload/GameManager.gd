extends Node

# --- SIGNALS ---
signal restaurant_funds_changed(new_amount: int)
signal player_wallet_changed(new_amount: int)
signal level_up(new_level: int)
signal day_time_updated(current_seconds: float)
signal day_phase_changed(phase_name: String)

# --- CONSTANTS ---
const DAY_DURATION: float = 240.0
const PHASE_OPEN_END: float = 180.0
const PHASE_CLEANUP_END: float = 210.0

# --- PROGRESSION MATRIX (Dựa trên player_wallet) ---
const LEVEL_REQUIREMENTS = {
	1: {"wallet": 0, "rep": 0.0},
	2: {"wallet": 15_000_000, "rep": 0.0},
	3: {"wallet": 89_000_000, "rep": 3.5},
	4: {"wallet": 200_000_000, "rep": 4.0},
	5: {"wallet": 1_000_000_000, "rep": 4.8}
}

# --- DUAL CURRENCY SYSTEM ---
var restaurant_funds: int = 10_000_000  # Ngân sách kinh doanh ban đầu
var player_wallet: int = 0               # Ví cá nhân chủ sở hữu

# --- GAME STATE ---
var current_level: int = 1
var reputation_stars: float = 1.0
var current_day: int = 1
var day_timer: float = 0.0
var is_timer_running: bool = false
var current_phase: String = "OPEN" # OPEN, CLEANUP, REPORT

# --- DATA CACHES & INVENTORY ---
var crops_data: Array = []
var recipes_data: Array = []
var imports_data: Array = []
var inventory: Dictionary = {} # {"item_id": quantity}

func _ready() -> void:
	load_game_data_json()
	start_day()

func _process(delta: float) -> void:
	if not is_timer_running:
		return
		
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
	save_game()
	print("--- HẾT NGÀY %d: AUTOSAVE VÀ BÁO CÁO TÀI CHÍNH HOÀN TẤT ---" % current_day)

func next_day() -> void:
	current_day += 1
	start_day()

# --- HÀM TÀI CHÍNH & CHUYỂN TIỀN (DUAL CURRENCY LOGIC) ---

# Rút lương / Chia cổ tức từ Nhà hàng -> Ví cá nhân
func withdraw_to_wallet(amount: int) -> bool:
	if amount <= 0:
		return false
	if restaurant_funds >= amount:
		restaurant_funds -= amount
		player_wallet += amount
		emit_signal("restaurant_funds_changed", restaurant_funds)
		emit_signal("player_wallet_changed", player_wallet)
		check_level_up()
		print("Đã rút %d VNĐ từ Nhà hàng về Ví cá nhân." % amount)
		return true
	print("Nhà hàng không đủ ngân sách để rút!")
	return false

# Rót vốn cá nhân ngược lại cho Nhà hàng
func inject_capital_to_restaurant(amount: int) -> bool:
	if amount <= 0:
		return false
	if player_wallet >= amount:
		player_wallet -= amount
		restaurant_funds += amount
		emit_signal("player_wallet_changed", player_wallet)
		emit_signal("restaurant_funds_changed", restaurant_funds)
		print("Đã rót %d VNĐ từ Ví cá nhân vào Ngân sách Nhà hàng." % amount)
		return true
	print("Ví cá nhân không đủ tiền để rót vốn!")
	return false

# Cộng/Trừ ngân sách Nhà hàng (Bán đồ, mua hạt giống, trả lương)
func modify_restaurant_funds(amount: int) -> bool:
	if amount < 0 and restaurant_funds < abs(amount):
		return false # Không đủ tiền chi trả
	restaurant_funds += amount
	emit_signal("restaurant_funds_changed", restaurant_funds)
	return true

# Kiểm tra Level Up dựa trên player_wallet và reputation_stars
func check_level_up() -> void:
	var next_lv = current_level + 1
	if LEVEL_REQUIREMENTS.has(next_lv):
		var req = LEVEL_REQUIREMENTS[next_lv]
		if player_wallet >= req["wallet"] and reputation_stars >= req["rep"]:
			current_level = next_lv
			emit_signal("level_up", current_level)
			print("Chúc mừng! Bạn đã đạt Level: %d" % current_level)

# --- JSON LOADER & SAVE/LOAD ---
func load_game_data_json() -> void:
	crops_data = _read_json("res://data/crops.json")
	recipes_data = _read_json("res://data/recipes.json")
	imports_data = _read_json("res://data/imports.json")

func _read_json(file_path: String) -> Array:
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			return json.get_data()
	print("Lỗi: Không đọc được file %s" % file_path)
	return []

func save_game() -> void:
	var save_data = {
		"finance": {
			"restaurant_funds": restaurant_funds,
			"player_wallet": player_wallet
		},
		"progression": {
			"level": current_level,
			"reputation": reputation_stars,
			"day": current_day
		},
		"inventory": inventory,
		"staff_list": StaffManager.get_save_data()
	}
	
	var save_file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data, "\t"))
		save_file.close()
		print("Autosave thành công vào user://save_game.json")

func load_game() -> void:
	if not FileAccess.file_exists("user://save_game.json"):
		return
	var save_file = FileAccess.open("user://save_game.json", FileAccess.READ)
	var json = JSON.new()
	if json.parse(save_file.get_as_text()) == OK:
		var data = json.get_data()
		restaurant_funds = data["finance"]["restaurant_funds"]
		player_wallet = data["finance"]["player_wallet"]
		current_level = data["progression"]["level"]
		reputation_stars = data["progression"]["reputation"]
		current_day = data["progression"]["day"]
		inventory = data["inventory"]
		StaffManager.load_save_data(data["staff_list"])
		
		emit_signal("restaurant_funds_changed", restaurant_funds)
		emit_signal("player_wallet_changed", player_wallet)
