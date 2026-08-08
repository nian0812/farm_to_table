extends CanvasLayer

@onready var restaurant_funds_label: Label = $TopBar/RestaurantFundsLabel
@onready var player_wallet_label: Label = $TopBar/PlayerWalletLabel
@onready var timer_label: Label = $TopBar/TimerLabel

@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var item_list_label: Label = $InventoryPanel/VBoxContainer/ItemListLabel
@onready var send_truck_btn: Button = $InventoryPanel/VBoxContainer/SendTruckBtn

var selected_crop_id: String = "crop_rice"
var is_truck_busy: bool = false 

func _ready() -> void:
	# Lắng nghe Signal từ GameManager
	GameManager.player_wallet_changed.connect(_on_player_wallet_changed)
	GameManager.restaurant_funds_changed.connect(_on_restaurant_funds_changed)
	GameManager.inventory_changed.connect(update_inventory_ui)
	GameManager.day_time_updated.connect(_on_day_time_updated)
	GameManager.day_phase_changed.connect(_on_day_phase_changed)
	
	# Lắng nghe Signal từ ProgressionManager (Tổng Tài Sản & Level)
	ProgressionManager.assets_updated.connect(_on_assets_updated)
	ProgressionManager.level_up_reached.connect(_on_level_up)
	
	# Init UI
	_on_player_wallet_changed(GameManager.player_wallet)
	_on_restaurant_funds_changed(GameManager.restaurant_funds)
	inventory_panel.visible = false 

# --- CẬP NHẬT UI KINH TẾ ---
func _on_player_wallet_changed(new_amount: int) -> void:
	player_wallet_label.text = "Ví: %s VNĐ" % _format_number(new_amount)

func _on_restaurant_funds_changed(new_amount: int) -> void:
	restaurant_funds_label.text = "Nhà hàng: %s VNĐ" % _format_number(new_amount)

func _on_assets_updated(total_assets: int, current_level: int) -> void:
	# Tạm thời log ra Console để theo dõi. Ở Giai đoạn B sẽ tạo ProgressBar trên màn hình.
	var next_req = ProgressionManager.get_next_level_requirement()
	print("[KIỂM TOÁN TÀI SẢN] LV%d | Tổng: %s VNĐ / %s VNĐ" % [current_level, _format_number(total_assets), _format_number(next_req)])

func _on_level_up(new_level: int) -> void:
	print("🎉 MỞ KHÓA LEVEL MỚI: BẠN ĐÃ ĐẠT LEVEL ", new_level)

# --- THỜI GIAN ---
func _on_day_time_updated(seconds: float) -> void:
	var remaining = int(GameManager.DAY_DURATION - seconds)
	var mins = remaining / 60
	var secs = remaining % 60
	timer_label.text = "Thời gian: %02d:%02d [%s]" % [mins, secs, GameManager.current_phase]

func _on_day_phase_changed(phase: String) -> void:
	pass

func _format_number(number: int) -> String:
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	for i in range(string.length()):
		if i != 0 and i % 3 == mod:
			res += "."
		res += string[i]
	return res

# --- KHO ĐỒ & XE TẢI (Dynamic Data) ---
func _on_inventory_btn_pressed() -> void:
	update_inventory_ui()
	inventory_panel.visible = true

func _on_close_panel_btn_pressed() -> void:
	inventory_panel.visible = false

func update_inventory_ui() -> void:
	var display_text = ""
	if GameManager.inventory.is_empty():
		display_text = "Kho đang trống!"
	else:
		for item_id in GameManager.inventory:
			var qty = GameManager.inventory[item_id]
			if qty > 0:
				var item_name = item_id
				# Đọc Tên hiển thị từ items_data
				if GameManager.items_data.has(item_id):
					item_name = GameManager.items_data[item_id].get("name", item_id)
				display_text += "%s: %d kg\n" % [item_name, qty]
				
	item_list_label.text = display_text

func _on_send_truck_btn_pressed() -> void:
	if is_truck_busy or GameManager.inventory.is_empty(): return
	
	var total_revenue = 0
	for item_id in GameManager.inventory:
		var qty = GameManager.inventory[item_id]
		var price = 0
		if GameManager.items_data.has(item_id):
			# CHỈ ĐẠO: Dùng sell_price_vnd để bán hàng
			price = GameManager.items_data[item_id].get("sell_price_vnd", 0)
		total_revenue += qty * price
	
	GameManager.clear_inventory()
	
	is_truck_busy = true
	send_truck_btn.text = "🚚 Xe đang chở hàng (Đợi 5s)..."
	
	await get_tree().create_timer(5.0).timeout 
	if not is_inside_tree(): return 
	
	GameManager.modify_restaurant_funds(total_revenue)
	is_truck_busy = false
	send_truck_btn.text = "🚚 Bán tất cả nông sản qua Xe tải"
	print("Xe tải trở về! Doanh thu: ", _format_number(total_revenue), " VNĐ")

# --- NÚT BẤM HUD ---
func _on_withdraw_btn_pressed() -> void:
	GameManager.withdraw_to_wallet(1_000_000)

func _on_rice_btn_pressed() -> void:
	selected_crop_id = "crop_rice"
func _on_tomato_btn_pressed() -> void:
	selected_crop_id = "crop_tomato"
# Nút mới (Nhớ kết nối Signal pressed() của nút này trên Scene Hub nhé)
func _on_cabbage_btn_pressed() -> void:
	selected_crop_id = "crop_cabbage"
