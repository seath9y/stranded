extends HBoxContainer 

var item_scene = preload("res://scenes/cards/card.tscn")

func _ready():
	for slot in self.get_children():
		if slot is EquipSlot:
			slot.zone_manager = self
			
# 【核心修复 1】：参数类型改成 Dictionary！
func add_item(item_data: Dictionary, amount: int = 1, state: Dictionary = {}) -> int:
	# 【核心修复 2】：纯字典判断它是不是“装备”
	if item_data.get("类型", "") != "装备":
		return amount
		
	for slot in self.get_children():
		if slot is EquipSlot:
			
			var has_card = false
			for child in slot.get_children():
				if child is Card:
					has_card = true
					break
			
			# 【核心修复 3】：用标签判断装备部位！(比如这个格子允许"背包"，而物品的标签里正好有"背包")
			var tags = item_data.get("标签", [])
			if slot.allowed_tag in tags and not has_card:
				var new_item = item_scene.instantiate()
				new_item.set_data(item_data, 1)
				if not state.is_empty():
					new_item.apply_dynamic_state(state)
					
				slot.add_child(new_item)
				
				if InventoryManager.has_method("recalculate_player_stats"):
					InventoryManager.call_deferred("recalculate_player_stats")
				# 【修复名称读取】
				print("✅ 成功快捷装备：", item_data.get("名称", "未知"))
				return 0 
				
	print("⚠️ 装备槽被占用或没有对应部位，无法快捷装备！")
	return amount
