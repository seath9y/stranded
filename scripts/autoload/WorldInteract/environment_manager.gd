# ================= res://scripts/autoload/environment_manager.gd =================
extends Node

# --- 存放所有环境点数的变量 ---
var current_crafting_points: int = 0
var current_cooking_points: int = 0 
var current_shelter_points: int = 0
# 以后有新的点数类型直接往这里加...

# --- 重新计算所有点数 ---
func recalculate_environment():
	# 1. 每次计算前，先全部清零归位
	current_crafting_points = 0
	current_cooking_points = 0
	current_shelter_points = 0
	
	# 2. 安全获取地区栏节点
	var area_zone = get_tree().get_first_node_in_group("area_zone") 
	if area_zone == null:
		return
		
	# 3. 【核心修复】：直接访问 CardZone 脚本里的 slot_container 属性！
	# 这样以后不管你在 UI 里给格子套多少层边框或滚动条，只要脚本变量没丢，这里就不会报错。
	if "slot_container" in area_zone and area_zone.slot_container != null:
		var grid = area_zone.slot_container
		for slot in grid.get_children():
			for child in slot.get_children():
				if child is Card and typeof(child.data) == TYPE_DICTIONARY and not child.data.is_empty():
					# 只要字典里配了对应的点数就直接累加！没配默认就是加 0
					current_crafting_points += child.data.get("手工辅助点数", 0)
					current_cooking_points += child.data.get("烹饪点数", 0)
					
	print("环境重算完成！手工辅助点数: ", current_crafting_points, " 烹饪点数: ", current_cooking_points)
