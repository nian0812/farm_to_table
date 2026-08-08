extends Node

signal aquaculture_changed()

var fish_data: Dictionary = {}
var active_fishes: Array = []

func _ready() -> void:
	_load_data()
	_init_default_fishes()
	GameManager.day_phase_changed.connect(_on_day_phase_changed)

func _load_data() -> void:
	if FileAccess.file_exists("res://data/fish.json"):
		var file = FileAccess.open("res://data/fish.json", FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var raw_array = json.get_data()
			for f in raw_array:
				fish_data[f["fish_id"]] = f

# Khởi tạo 5 con cá lóc có sẵn đầu game
func _init_default_fishes() -> void:
	for i in range(5):
		add_fish("fish_snakehead")

func add_fish(fish_id: String) -> void:
	if fish_data.has(fish_id):
		var new_fish = {
			"uid": randi(),
			"fish_id": fish_id,
			"age_days": 0
		}
		active_fishes.append(new_fish)
		emit_signal("aquaculture_changed")

# Xử lý cá lớn lên khi qua ngày
func _on_day_phase_changed(phase: String) -> void:
	if phase == "REPORT":
		_process_daily_aquaculture()

func _process_daily_aquaculture() -> void:
	print("--- XỬ LÝ AO CÁ HÀNG NGÀY ---")
	for i in range(active_fishes.size() - 1, -1, -1):
		var fish = active_fishes[i]
		var f_info = fish_data[fish["fish_id"]]
		
		fish["age_days"] += 1
		
		# Tới hạn thu hoạch -> Chuyển thành vật phẩm trong kho và xóa khỏi ao
		if fish["age_days"] >= f_info["growth_time_days"]:
			var harvest_item = f_info.get("harvest_item_id", "")
			if harvest_item != "":
				GameManager.add_to_inventory(harvest_item, f_info["harvest_yield"])
				print("🐟 Thu hoạch ao! Bắt được %s" % f_info["name"])
			
			active_fishes.remove_at(i)
			
	emit_signal("aquaculture_changed")

# Tính tổng tài sản cá đang bơi trong ao
func get_total_aquaculture_value() -> int:
	var total = 0
	for fish in active_fishes:
		if fish_data.has(fish["fish_id"]):
			total += fish_data[fish["fish_id"]].get("asset_value_vnd", 0)
	return total
