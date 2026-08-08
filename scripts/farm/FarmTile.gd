class_name FarmTile
extends Area2D

enum TileState { EMPTY, PLANTED, READY }

var current_state: TileState = TileState.EMPTY
var current_crop_data: Dictionary = {}
var growth_timer: float = 0.0

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	update_visual()

func _process(delta: float) -> void:
	if current_state == TileState.PLANTED:
		var current_delta = delta
		
		# Hỗ trợ tua nhanh thời gian khi giữ phím Backspace
		if Input.is_key_pressed(KEY_BACKSPACE):
			current_delta *= 50.0 
			
		growth_timer += current_delta
		if growth_timer >= current_crop_data.get("growth_time_seconds", 10):
			current_state = TileState.READY
			update_visual()

# --- TRỒNG CÂY (An toàn dữ liệu với .get()) ---
func plant_crop(crop_id: String) -> bool:
	if current_state != TileState.EMPTY: return false
	
	for crop in GameManager.crops_data:
		if crop.get("crop_id", "") == crop_id:
			# Dùng .get() để phòng hờ tên key trong crops.json có thể khác nhau
			var seed_price = crop.get("seed_price_vnd", crop.get("price", 0))
			
			# TRỪ TIỀN TỪ VÍ CÁ NHÂN (player_wallet)
			if GameManager.modify_player_wallet(-seed_price):
				current_crop_data = crop
				growth_timer = 0.0
				current_state = TileState.PLANTED
				update_visual()
				print("Đã trồng: ", crop.get("name", crop_id))
				return true
			else:
				print("Ví cá nhân không đủ tiền mua hạt giống!")
				return false
	return false

# --- THU HOẠCH ---
func harvest() -> void:
	if current_state == TileState.READY:
		var item_id = current_crop_data.get("harvest_item_id", "item_rice")
		var qty = current_crop_data.get("harvest_yield_qty", 1)
		
		GameManager.add_to_inventory(item_id, qty)
		print("Thu hoạch thành công! +%d %s" % [qty, item_id])
		
		if current_crop_data.get("repeat_harvest", false):
			current_state = TileState.PLANTED
			growth_timer = 0.0
		else:
			current_state = TileState.EMPTY
			current_crop_data = {}
			
		update_visual()

func update_visual() -> void:
	if not color_rect: return
	match current_state:
		TileState.EMPTY: color_rect.color = Color(0.4, 0.25, 0.1)
		TileState.PLANTED: color_rect.color = Color(0.2, 0.8, 0.2)
		TileState.READY: color_rect.color = Color(0.9, 0.8, 0.1)

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match current_state:
			TileState.EMPTY:
				var hud = get_tree().root.find_child("Hub", true, false)
				var crop_to_plant = "crop_rice"
				if hud: crop_to_plant = hud.selected_crop_id
				plant_crop(crop_to_plant)
			TileState.PLANTED:
				print("Cây đang lớn... Vui lòng đợi!")
			TileState.READY:
				harvest()
