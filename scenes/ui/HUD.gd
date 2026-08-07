extends CanvasLayer

@onready var restaurant_funds_label: Label = $TopBar/RestaurantFundsLabel
@onready var player_wallet_label: Label = $TopBar/PlayerWalletLabel
@onready var timer_label: Label = $TopBar/TimerLabel

# Node Kho đồ & Xe tải mới thêm
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var item_list_label: Label = $InventoryPanel/VBoxContainer/ItemListLabel
@onready var send_truck_btn: Button = $InventoryPanel/VBoxContainer/SendTruckBtn

var selected_crop_id: String = "crop_rice"
var is_truck_busy: bool = false # Trạng thái xe tải đang chạy

func _ready() -> void:
	GameManager.restaurant_funds_changed.connect(_on_restaurant_funds_changed)
	GameManager.player_wallet_changed.connect(_on_player_wallet_changed)
	GameManager.day_time_updated.connect(_on_day_time_updated)
	GameManager.day_phase_changed.connect(_on_day_phase_changed)
	
	_on_restaurant_funds_changed(GameManager.restaurant_funds)
	_on_player_wallet_changed(GameManager.player_wallet)
	
	inventory_panel.visible = false # Mặc định ẩn kho đồ

func _on_restaurant_funds_changed(new_amount: int) -> void:
	restaurant_funds_label.text = "Nhà hàng: %s VNĐ" % _format_number(new_amount)

func _on_player_wallet_changed(new_amount: int) -> void:
	player_wallet_label.text = "Ví cá nhân: %s VNĐ" % _format_number(new_amount)

func _on_day_time_updated(seconds: float) -> void:
	var remaining = int(GameManager.DAY_DURATION - seconds)
	var mins = remaining / 60
	var secs = remaining % 60
	timer_label.text = "Thời gian: %02d:%02d [%s]" % [mins, secs, GameManager.current_phase]

func _on_day_phase_changed(phase: String) -> void:
	print("Chuyển pha sang: ", phase)

func _format_number(number: int) -> String:
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	for i in range(string.length()):
		if i != 0 and i % 3 == mod:
			res += "."
		res += string[i]
	return res

# --- BẮT SỰ KIỆN NÚT BẤM KHO ĐỒ & XE TẢI ---

func _on_inventory_btn_pressed() -> void:
	update_inventory_ui()
	inventory_panel.visible = true

func _on_close_panel_btn_pressed() -> void:
	inventory_panel.visible = false

# Cập nhật văn bản trong kho
func update_inventory_ui() -> void:
	var rice_qty = GameManager.inventory.get("item_rice_grain", 0)
	var tomato_qty = GameManager.inventory.get("item_tomato", 0)
	item_list_label.text = "Lúa tẻ: %d kg | Cà chua: %d kg" % [rice_qty, tomato_qty]

# Gửi xe tải chở nông sản đi bán
func _on_send_truck_btn_pressed() -> void:
	if is_truck_busy:
		print("Xe tải đang trên đường vận chuyển! Vui lòng đợi...")
		return
		
	var rice_qty = GameManager.inventory.get("item_rice_grain", 0)
	var tomato_qty = GameManager.inventory.get("item_tomato", 0)
	
	if rice_qty == 0 and tomato_qty == 0:
		print("Kho trống, không có nông sản để xuất hàng!")
		return
		
	# Tính tổng giá trị nông sản xuất đi (Lúa: 8.000đ/kg, Cà chua: 18.000đ/kg)
	var total_revenue = (rice_qty * 8_000) + (tomato_qty * 18_000)
	
	# Reset kho nông sản đã bán
	GameManager.inventory["item_rice_grain"] = 0
	GameManager.inventory["item_tomato"] = 0
	update_inventory_ui()
	
	# Bắt đầu đếm ngược chuyến xe (mô phỏng chạy 5 giây)
	is_truck_busy = true
	send_truck_btn.text = "🚚 Xe đang chở hàng (Đợi 5s)..."
	print("Xe tải xuất bến! Dự kiến thu về: ", total_revenue, " VNĐ")
	
	await get_tree().create_timer(5.0).timeout # Đợi 5 giây
	
	# Chuyến xe hoàn tất
	GameManager.modify_restaurant_funds(total_revenue)
	is_truck_busy = false
	send_truck_btn.text = "🚚 Bán tất cả nông sản qua Xe tải"
	print("Xe tải trở về! Đã cộng vào Ngân sách Nhà hàng: ", total_revenue, " VNĐ")

# --- BẮT SỰ KIỆN KHÁC ---
func _on_withdraw_btn_pressed() -> void:
	GameManager.withdraw_to_wallet(1_000_000)

func _on_rice_btn_pressed() -> void:
	selected_crop_id = "crop_rice"

func _on_tomato_btn_pressed() -> void:
	selected_crop_id = "crop_tomato"
