extends Node

signal assets_updated(total_assets: int, current_level: int)
signal level_up_reached(new_level: int)

const LEVEL_REQUIREMENTS = {
	1: 0,
	2: 1_800_000,
	3: 3_000_000,
	4: 5_000_000,
	5: 8_000_000,
	6: 12_000_000,
	7: 20_000_000,
	8: 35_000_000,
	9: 60_000_000,
	10: 100_000_000
}

var current_level: int = 1
var total_assets: int = 0
var highest_total_assets: int = 0

func _ready() -> void:
	GameManager.player_wallet_changed.connect(_on_economy_changed)
	GameManager.restaurant_funds_changed.connect(_on_economy_changed)
	GameManager.inventory_changed.connect(_on_economy_changed)
	call_deferred("calculate_total_assets")

func _on_economy_changed(_value_dump = null) -> void:
	calculate_total_assets()

func calculate_total_assets() -> void:
	var new_total = 0
	
	new_total += GameManager.player_wallet
	new_total += GameManager.restaurant_funds
	
	for item_id in GameManager.inventory:
		var qty = GameManager.inventory[item_id]
		var base_value = 0
		if GameManager.items_data.has(item_id):
			base_value = GameManager.items_data[item_id].get("base_value_vnd", 0)
		new_total += (qty * base_value)
		
	for bld in GameManager.buildings_data:
		new_total += bld.get("asset_value", 0)
		
	# 4. Giá trị Động vật đang sống
	if has_node("/root/LivestockManager"):
		new_total += LivestockManager.get_total_livestock_value()
		
	# 5. Giá trị Thủy sản trong ao
	if has_node("/root/AquacultureManager"):
		new_total += AquacultureManager.get_total_aquaculture_value()
		
	total_assets = new_total
	if total_assets > highest_total_assets:
		highest_total_assets = total_assets
		_check_level_up()
		
	emit_signal("assets_updated", total_assets, current_level)

func _check_level_up() -> void:
	var next_lv = current_level + 1
	if LEVEL_REQUIREMENTS.has(next_lv):
		if highest_total_assets >= LEVEL_REQUIREMENTS[next_lv]:
			current_level = next_lv
			emit_signal("level_up_reached", current_level)
			print("🌟 LÊN CẤP! Level hiện tại: ", current_level)
			_check_level_up()

# Trả về số tiền cần thiết để lên level tiếp theo (nếu max cấp thì trả về mốc hiện tại)
func get_next_level_requirement() -> int:
	var next_lv = current_level + 1
	if LEVEL_REQUIREMENTS.has(next_lv):
		return LEVEL_REQUIREMENTS[next_lv]
	else:
		return LEVEL_REQUIREMENTS[current_level] # Đã đạt cấp tối đa
