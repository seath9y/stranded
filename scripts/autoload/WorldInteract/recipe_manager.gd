extends Node
# recipe_manager.gd (配置在 Autoload 中)

# 配方数据库
const RECIPES_DB: Dictionary = {
	"stone_axe": {
		"name": "石斧",
		"icon": "res://assets/icons/工具/石斧.png",
		"unlocked_by_default": true, # 是否一开始就解锁
		"time_cost": 15,             # 制作消耗时间 (分钟)
		"station": "hand",           # 需要的设施 (hand 代表徒手，campfire 代表营火等)
		# 需要消耗的材料 (分为具体的 item 和 泛用的 tag)
		"ingredients": [
			{"type": "item", "id": "大石块", "amount": 1}, 
			{"type": "item", "id": "长木棍", "amount": 1},
			{"type": "tag", "id": "rope_like", "amount": 1} # 只要带有 "rope_like" 标签的物品都可以！
		],
		# 需要用到的工具 (只扣耐久，不吞物品)
		"tools_required": [],
		# 产出物
		"output": {"id": "石斧", "amount": 1}
	},
	"roasted_meat": {
		"name": "烤肉",
		"icon": "res://assets/icons/食物/烤肉.png",
		"unlocked_by_default": false, 
		"time_cost": 30,             
		"station": "campfire",       # 必须在营火旁制作！
		"ingredients": [
			{"type": "tag", "id": "raw_meat", "amount": 1} # 任何生肉都可以
		],
		"tools_required": [
			# 比如切肉需要刀具，扣除 2 点耐久
			# {"tag": "sharp_tool", "durability_cost": 2} 
		],
		"output": {"id": "烤肉", "amount": 1}
	}
}
