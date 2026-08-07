class_name FarmTile
extends Area2D

# Trạng thái ô đất: 0: Trống, 1: Đã gieo hạt, 2: Đã sẵn sàng thu hoạch
enum TileState { EMPTY, PLANTED, READY }

var current_state: TileState = TileState.EMPTY
var current_crop_data: Dictionary = {}
var growth_timer: float = 0.0

@onready var color_rect: ColorRect = $ColorRect # Dùng khối màu làm Placeholder

func _ready() -> void:
	update_visual()

func _process(delta: float) -> void:
	if current_state == TileState.PLANTED:
		growth_timer += delta
		if growth_timer >= current_crop_data.get("growth_time_seconds", 10):
			current_state = TileState.READY
			update_visual()

# Trồng cây
func plant_crop(crop_id: String) -> bool:
	if current_state != TileState.EMPTY:
		return false
		
	# Tìm dữ liệu hạt giống từ GameManager
	for crop in GameManager.crops_data:
		if crop["crop_id"] == crop_id:
			# Kiểm tra đủ tiền mua hạt giống không (chi từ ngân sách nhà hàng)
			if GameManager.modify_restaurant_funds(-crop["seed_price_vnd"]):
				current_crop_data = crop
				growth_timer = 0.0
				current_state = TileState.PLANTED
				update_visual()
				print("Đã trồng: ", crop["name"])
				return true
			else:
				print("Không đủ tiền mua hạt giống!")
				return false
	return false

# Thu hoạch
func harvest() -> void:
	if current_state == TileState.READY:
		var item_id = current_crop_data["harvest_item_id"]
		var qty = current_crop_data["harvest_yield_qty"]
		
		# Thêm vào kho
		GameManager.inventory[item_id] = GameManager.inventory.get(item_id, 0) + qty
		print("Thu hoạch thành công! Cột kho hiện tại: ", GameManager.inventory)
		
		# Reset ô đất
		current_state = TileState.EMPTY
		current_crop_data = {}
		update_visual()

# Đổi màu khối Placeholder để dễ test logic
func update_visual() -> void:
	if not color_rect:
		return
	match current_state:
		TileState.EMPTY:
			color_rect.color = Color(0.4, 0.25, 0.1) # Màu đất nâu
		TileState.PLANTED:
			color_rect.color = Color(0.2, 0.8, 0.2) # Màu mầm xanh
		TileState.READY:
			color_rect.color = Color(0.9, 0.8, 0.1) # Màu lúa vàng vọt

# Thêm vào cuối script FarmTile.gd

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match current_state:
			TileState.EMPTY:
				# Lấy hạt giống đang được chọn từ HUD (truy xuất qua node HUD)
				var hud = get_tree().root.find_child("HUD", true, false)
				var crop_to_plant = "crop_rice"
				if hud:
					crop_to_plant = hud.selected_crop_id
				
				plant_crop(crop_to_plant)
				
			TileState.PLANTED:
				print("Cây đang lớn... Vui lòng đợi!")
				
			TileState.READY:
				harvest()
