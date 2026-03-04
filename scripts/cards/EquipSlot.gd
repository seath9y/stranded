extends Slot 
class_name EquipSlot

# 【核心修改】：现在直接在检查器里填入允许的中文标签，比如 "背包"、"头部"
@export var allowed_tag: String = "背包"

func _can_drop_data(at_position: Vector2, drag_data: Variant) -> bool:
	var dropped_card = drag_data as Card
	if not dropped_card: return false
		
	# 检查目标卡牌的标签数组里，有没有包含这个槽位允许的标签
	var tags = dropped_card.data.get("标签", [])
	if allowed_tag not in tags:
		return false
		
	return true

func _drop_data(at_position: Vector2, drag_data: Variant) -> void:
	var dropped_card = drag_data as Card
	var current_card: Card = null
	for child in get_children():
		if child is Card:
			current_card = child
			break
			
	if current_card == dropped_card: return

	var dropped_parent = dropped_card.get_parent()
	if dropped_parent: dropped_parent.remove_child(dropped_card)

	if current_card != null:
		self.remove_child(current_card)
		if dropped_parent: dropped_parent.add_child(current_card) 
			
	self.add_child(dropped_card)
	
	if dropped_parent is Slot and dropped_parent.zone_manager:
		dropped_parent.zone_manager.reorganize_cards()
		
	InventoryManager.call_deferred("recalculate_player_stats")
