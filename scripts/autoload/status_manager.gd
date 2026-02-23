# res://scripts/autoload/status_manager.gd
extends Node

# 存储当前活跃的状态效果：{"status_id": {配置数据}}
var active_effects: Dictionary = {}

# 状态效果数据库 (预留了扩展性)
const EFFECTS_DATABASE: Dictionary = {
	"overweight": {
		"name": "超重",
		"travel_time_multiplier": 2.0,    # 跨区域时间消耗翻倍
		"stamina_cost_multiplier": 2.0,   # 耐力消耗翻倍
	},
	"immobilized": {
		"name": "瘫痪",
		"is_immobilized": true            # 布尔值标记，用于彻底锁死跨区域旅行
	}
	# 未来可以在这里无缝添加 "wet" (潮湿)、"injured" (受伤) 等状态
}

# 【核心功能】：其他系统拉取特定属性的总乘率 (乘法叠加)
func get_multiplier(property_name: String) -> float:
	var total_multiplier: float = 1.0
	for effect_id in active_effects:
		var effect_data = EFFECTS_DATABASE.get(effect_id)
		if effect_data and effect_data.has(property_name):
			total_multiplier *= effect_data[property_name]
	return total_multiplier

# 【核心功能】：检查是否具有阻止行为的硬性状态
func has_flag(flag_name: String) -> bool:
	for effect_id in active_effects:
		var effect_data = EFFECTS_DATABASE.get(effect_id)
		if effect_data and effect_data.has(flag_name) and effect_data[flag_name] == true:
			return true
	return false

# 挂载状态
func add_status(effect_id: String) -> void:
	if not active_effects.has(effect_id) and EFFECTS_DATABASE.has(effect_id):
		active_effects[effect_id] = EFFECTS_DATABASE[effect_id]
		_update_ui()

# 移除状态
func remove_status(effect_id: String) -> void:
	if active_effects.erase(effect_id):
		_update_ui()

func _update_ui() -> void:
	# 这里可以发出信号，通知 UI 层刷新 Debuff 栏位图标
	print("[StatusManager] 当前状态更新: ", active_effects.keys())
