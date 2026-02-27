# res://scripts/autoload/status_manager.gd
extends Node

signal status_changed(active_status_ids: Array)
var active_effects: Dictionary = {}

# 状态效果数据库
const EFFECTS_DATABASE: Dictionary = {
	"overweight": {
		"name": "超重",
		"group": "weight_group", # 【新增】：互斥组标签
		"description": "负重过高，移动和行动消耗的耐力增加。",
		"icon": "res://assets/icons/status/overweight.png", 
		"travel_time_multiplier": 2.0,    
		"stamina_cost_multiplier": 2.0,   
	},
	"immobilized": {
		"name": "瘫痪",
		"group": "weight_group", # 【新增】：同属负重互斥组
		"description": "极度超载！你现在寸步难行，必须丢弃一些物品。",
		"icon": "res://assets/icons/status/immobilized.png", 
		"is_immobilized": true            
	}
	# 未来扩展示例：
	# "wet": { "name": "潮湿", "group": "wet_group" }
	# "drenched": { "name": "湿透", "group": "wet_group" }
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
	if not EFFECTS_DATABASE.has(effect_id): 
		return
		
	var new_effect = EFFECTS_DATABASE[effect_id]
	var has_changed = false
	
	# 1. 互斥组检查：如果这个新状态有 group，找出并干掉同 group 的其他老状态
	if new_effect.has("group"):
		var target_group = new_effect["group"]
		var keys_to_remove = []
		
		for active_id in active_effects:
			var active_data = active_effects[active_id]
			# 发现同组的，且不是它自己的状态，标记为待删除
			if active_data.has("group") and active_data["group"] == target_group and active_id != effect_id:
				keys_to_remove.append(active_id)
				
		# 执行清理
		for k in keys_to_remove:
			active_effects.erase(k)
			has_changed = true
			
	# 2. 挂载新状态
	if not active_effects.has(effect_id):
		active_effects[effect_id] = new_effect
		has_changed = true
		
	# 3. 只有发生实质性变化时，才通知 UI 刷新，节省性能
	if has_changed:
		_update_ui()

# 移除状态
func remove_status(effect_id: String) -> void:
	if active_effects.erase(effect_id):
		_update_ui()

func _update_ui() -> void:
	emit_signal("status_changed", active_effects.keys())
