extends Node

signal staff_list_updated

const BASE_SALARY_VND: int = 4_000_000
const STAT_BONUS_MULTIPLIER: int = 25_000

var staff_list: Array = []

func calculate_salary(stamina: int, friendliness: int, skill: int, responsibility: int) -> int:
	var sum_stats = stamina + friendliness + skill + responsibility
	return BASE_SALARY_VND + (sum_stats * STAT_BONUS_MULTIPLIER)

func hire_staff(staff_name: String, stamina: int, friendliness: int, skill: int, responsibility: int) -> bool:
	var max_staff = 1 if GameManager.current_level == 1 else (2 if GameManager.current_level == 2 else 10)
	if staff_list.size() >= max_staff:
		print("Đã đạt giới hạn số lượng nhân viên tối đa (%d người)." % max_staff)
		return false

	var new_staff = {
		"id": "staff_" + str(randi()),
		"name": staff_name,
		"stamina": clamp(stamina, 1, 100),
		"friendliness": clamp(friendliness, 1, 100),
		"skill": clamp(skill, 1, 100),
		"responsibility": clamp(responsibility, 1, 100),
		"morale": 100,
		"salary_vnd": calculate_salary(stamina, friendliness, skill, responsibility)
	}
	
	staff_list.append(new_staff)
	emit_signal("staff_list_updated")
	return true

# Sa thải nhân viên: Phạt 1 tháng lương đền bù (trừ từ restaurant_funds) + trừ 10% morale đồng nghiệp
func fire_staff(staff_id: String) -> bool:
	for i in range(staff_list.size()):
		if staff_list[i]["id"] == staff_id:
			var target_staff = staff_list[i]
			var compensation = target_staff["salary_vnd"]
			
			if not GameManager.modify_restaurant_funds(-compensation):
				print("Ngân sách nhà hàng không đủ đền bù sa thải (%d VNĐ)!" % compensation)
				return false
				
			staff_list.remove_at(i)
			for remaining_staff in staff_list:
				remaining_staff["morale"] = max(0, remaining_staff["morale"] - 10)
				
			print("Đã sa thải %s. Phạt đền bù: %d VNĐ." % [target_staff["name"], compensation])
			emit_signal("staff_list_updated")
			return true
	return false

func pay_all_salaries() -> bool:
	var total_payroll = 0
	for staff in staff_list:
		total_payroll += staff["salary_vnd"]
		
	if GameManager.modify_restaurant_funds(-total_payroll):
		print("Đã thanh toán tổng lương nhân viên: %d VNĐ." % total_payroll)
		return true
	else:
		print("CẢNH BÁO: Nhà hàng vỡ nợ, không đủ tiền trả lương!")
		return false

func get_save_data() -> Array:
	return staff_list

func load_save_data(data: Array) -> void:
	staff_list = data
	emit_signal("staff_list_updated")
