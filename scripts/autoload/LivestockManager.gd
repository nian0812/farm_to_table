extends Node

signal livestock_changed()

var livestock_data: Dictionary = {}
var active_animals: Array = [] # Danh sách các con vật đang sống

func _ready() -> void:
	_load_data()
	_init_default_animals()
	
	# Lắng nghe sự kiện Day Cycle từ GameManager
	GameManager.day_phase_changed.connect(_on_day_phase_changed)

func _load_data() -> void:
	if FileAccess.file_exists("res://data/livestock.json"):
		var file = FileAccess.open("res://data/livestock.json", FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var raw_array = json.get_data()
			for anim in raw_array:
				livestock_data[anim["anim_id"]] = anim
		else:
			print("Lỗi Parse livestock.json")

# Khởi tạo 3 Gà, 2 Bò đầu game
func _init_default_animals() -> void:
	for i in range(3):
		add_animal("anim_chicken")
	for i in range(2):
		add_animal("anim_cow")

func add_animal(anim_id: String) -> void:
	if livestock_data.has(anim_id):
		var new_animal = {
			"uid": randi(),
			"anim_id": anim_id,
			"age": 0
		}
		active_animals.append(new_animal)
		emit_signal("livestock_changed")

# Xử lý sinh học khi qua ngày
func _on_day_phase_changed(phase: String) -> void:
	if phase == "REPORT":
		_process_daily_livestock()

func _process_daily_livestock() -> void:
	print("--- XỬ LÝ CHĂN NUÔI HÀNG NGÀY ---")
	# Duyệt ngược mảng vì ta có thể xóa phần tử (con vật chết/làm thịt)
	for i in range(active_animals.size() - 1, -1, -1):
		var animal = active_animals[i]
		var anim_info = livestock_data[animal["anim_id"]]
		
		animal["age"] += 1
		
		# 1. Sinh sản hàng ngày (ví dụ: đẻ trứng)
		var daily_item = anim_info.get("daily_product_id", "")
		if daily_item != "" and animal["age"] < anim_info["lifespan_days"]:
			GameManager.add_to_inventory(daily_item, anim_info["daily_yield"])
			print("🐾 %s đẻ ra %s" % [anim_info["name"], daily_item])
		
		# 2. Hết tuổi thọ -> Lấy thịt & Xóa con vật
		if animal["age"] >= anim_info["lifespan_days"]:
			var meat_item = anim_info.get("meat_product_id", "")
			if meat_item != "":
				GameManager.add_to_inventory(meat_item, anim_info["meat_yield"])
				print("🥩 %s tới hạn xuất chuồng! Lấy được %s" % [anim_info["name"], meat_item])
			
			active_animals.remove_at(i)
	
	emit_signal("livestock_changed")

# Hàm cung cấp giá trị tài sản cho ProgressionManager
func get_total_livestock_value() -> int:
	var total = 0
	for animal in active_animals:
		if livestock_data.has(animal["anim_id"]):
			total += livestock_data[animal["anim_id"]].get("asset_value_vnd", 0)
	return total
