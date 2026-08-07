extends Node

signal event_triggered(event_type: String, data: Dictionary)

var event_check_timer: float = 0.0
const CHECK_INTERVAL: float = 15.0

func _process(delta: float) -> void:
	if not GameManager.is_timer_running or GameManager.current_phase != "OPEN":
		return
		
	event_check_timer += delta
	if event_check_timer >= CHECK_INTERVAL:
		event_check_timer = 0.0
		_roll_random_events()

func _roll_random_events() -> void:
	# Check Bùng việc
	for staff in StaffManager.staff_list:
		if staff["responsibility"] < 30 and staff["morale"] < 50:
			if randf() < 0.2:
				trigger_absenteeism_event(staff)
				return

	# Check Tiktoker
	if randf() < 0.05:
		trigger_tiktoker_event()

# Khách Karen
func check_karen_event(customer_strictness: int, customer_friendliness: int) -> void:
	if customer_strictness > 80 and customer_friendliness < 40:
		var data = {
			"title": "SỰ KIỆN: KHÁCH HÀNG KAREN",
			"message": "Khách khó tính đang nổi giận! Bạn muốn đền Voucher (200.000 VNĐ) hay chịu mất Uy tín?",
			"voucher_cost_vnd": 200_000,
			"rep_loss": 0.3
		}
		emit_signal("event_triggered", "KAREN_CUSTOMER", data)

# Rớt đĩa
func check_drop_plate_event(staff_skill: int, tile_position: Vector2) -> bool:
	var drop_chance = (100 - staff_skill) / 200.0
	if randf() < drop_chance:
		var data = {
			"tile_position": tile_position,
			"patience_penalty": 15
		}
		emit_signal("event_triggered", "DROP_PLATE", data)
		return true
	return false

# Bùng việc
func trigger_absenteeism_event(staff: Dictionary) -> void:
	var data = {
		"title": "SỰ KIỆN: BÙNG VIỆC NGHỈ ỐM",
		"message": "Nhân viên " + staff["name"] + " đã bùng việc hôm nay! Bắt buộc thuê làm theo giờ giá x3.",
		"staff_id": staff["id"]
	}
	emit_signal("event_triggered", "STAFF_ABSENT", data)

# Tiktoker
func trigger_tiktoker_event() -> void:
	var data = {
		"title": "SỰ KIỆN: TIKTOKER REVIEWER",
		"message": "Tiktoker ghé thăm! Phục vụ món ngon để tăng 50% lượng khách vào ngày mai.",
		"buff_spawn_rate": 0.5
	}
	emit_signal("event_triggered", "TIKTOKER_VISIT", data)
