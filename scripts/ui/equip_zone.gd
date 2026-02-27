# ================= res://scripts/ui/equip_zone.gd =================
extends HBoxContainer # 【修改】：因为咱们把它变成了 HBoxContainer

var item_scene = preload("res://scenes/cards/card.tscn")
func _ready():
	for slot in self.get_children():
		if slot is EquipSlot:
			slot.zone_manager = self
			
func add_item(item_data: ItemData, amount: int = 1, state: Dictionary = {}) -> int:
	if not item_data is EquipmentData:
		return amount
		
	for slot in self.get_children():
		if slot is EquipSlot:
			
			# 【终极修复】：精准遍历，看看格子里到底有没有“卡牌(Card)”
			var has_card = false
			for child in slot.get_children():
				if child is Card:
					has_card = true
					break
			
			# 核心判定：部位对得上，且里面没有“卡牌”（无视遮罩和底板）
			if slot.equip_requirement == item_data.equip_requirement and not has_card:
				var new_item = item_scene.instantiate()
				new_item.set_data(item_data, 1)
				if not state.is_empty():
					new_item.apply_dynamic_state(state)
					
				slot.add_child(new_item)
				
				InventoryManager.call_deferred("recalculate_player_stats")
				print("✅ 成功快捷装备：", item_data.name)
				return 0 
				
	print("⚠️ 装备槽被占用或没有对应部位，无法快捷装备！")
	return amount
