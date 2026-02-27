# ================= res://scripts/ui/equip_slot.gd =================
extends Slot # 【继承魔法】：它自动拥有了 Slot 的所有变量和函数
class_name EquipSlot

# 定义这个格子专属的装备部位（确保你的 EquipmentData 里有这个 Enum）
@export var equip_requirement: EquipmentData.EquipSlot = EquipmentData.EquipSlot.头部

# 【重写】：覆盖掉普通格子的判断逻辑
func _can_drop_data(at_position: Vector2, drag_data: Variant) -> bool:
	var dropped_card = drag_data as Card
	if not dropped_card: return false
		
	# 1. 严格审查：不是装备，不准放！
	if not dropped_card.data is EquipmentData:
		return false
		
	# 2. 部位审查：背包不能戴在头上！
	if dropped_card.data.equip_requirement != self.equip_requirement:
		return false
		
	return true

# 【重写】：覆盖掉普通格子的放下逻辑
func _drop_data(at_position: Vector2, drag_data: Variant) -> void:
	var dropped_card = drag_data as Card
	var current_card: Card = null
	
	for child in get_children():
		if child is Card:
			current_card = child
			break
			
	if current_card == dropped_card: return

	# 从原来的地方拔出来
	var dropped_parent = dropped_card.get_parent()
	if dropped_parent: dropped_parent.remove_child(dropped_card)

	# 【对调逻辑】：如果这个装备槽已经有东西了，脱下来，跟手里拿的对调
	if current_card != null:
		self.remove_child(current_card)
		if dropped_parent:
			dropped_parent.add_child(current_card) 
			
	# 穿上新装备
	self.add_child(dropped_card)
	
	# 通知老家洗牌（比如它是从背包拿出来的，背包要整理空隙）
	if dropped_parent is Slot and dropped_parent.zone_manager:
		dropped_parent.zone_manager.reorganize_cards()
		
	# 【关键触发】：穿上或换掉装备了！通知大脑重新计算背包上限！
	InventoryManager.call_deferred("recalculate_player_stats")
