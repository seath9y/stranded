extends Node
# facility_db.gd (挂载到 Autoload)

const TEMPLATES: Dictionary = {
	
	"campfire_basic": {
		"name": "简易营火",
		"icon": "res://assets/icons/设施/营火.png", # 填入你的实际路径
		
		# --- 核心物理规则 ---
		"is_permanent": true,
		"max_temperature_limit": 400.0,
		"process_slots_count": 2,
		"max_ash_capacity": 100.0,
		
		# --- 极其清爽的蓝图阶段配置 ---
		"construction_stages": [
			{
				"stage_name": "隔热石圈",
				"requirements": [ {"type": "tag", "id": "石料", "amount": 4} ]
			},
			{
				"stage_name": "引火木架",
				"requirements": [ {"type": "tag", "id": "木材", "amount": 2} ]
			}
		]
	},
	
	"leaf_shelter": {
		"name": "简易叶棚",
		"icon": "res://assets/icons/设施/叶棚.png",
		"is_permanent": false, # 暴雨后可能会被摧毁
		"max_temperature_limit": 0.0,
		"process_slots_count": 0, # 只是用来睡觉和避雨的，不能烤肉
		"max_ash_capacity": 0.0,
		"construction_stages": [
			{
				"stage_name": "打入木桩",
				"requirements": [ {"type": "tag", "id": "木材", "amount": 4} ]
			},
			{
				"stage_name": "搭建框架",
				"requirements": [ {"type": "tag", "id": "木材", "amount": 6}, {"type": "tag", "id": "绳索", "amount": 4} ]
			},
			{
				"stage_name": "铺设防水叶",
				"requirements": [ {"type": "tag", "id": "大叶片", "amount": 10} ]
			}
		]
	}
	
	# 未来新增设施，直接往下无脑复制粘贴即可！
}

# 提供一个便捷的查询接口
func get_template(id: String) -> Dictionary:
	return TEMPLATES.get(id, {})
