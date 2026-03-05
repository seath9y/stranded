extends AspectRatioContainer
class_name Slot

@onready var lock_overlay = $LockOverlay

var zone_manager: Node 
var is_locked: bool = false
func _ready():
	# ... 你原有的其他初始化代码 ...
	
	# 🌟 新增：让槽位自己监听屏幕变化并立刻执行一次
	get_tree().get_root().size_changed.connect(_update_responsive_size)
	_update_responsive_size()
func _update_responsive_size():
	var screen_width = get_viewport().size.x
	var base_width = clamp(screen_width * 0.045, 60.0, 100.0)
	var target_size = Vector2(base_width, base_width * 1.2)
	
	self.custom_minimum_size = target_size
	self.size = target_size
func set_locked(locked: bool):
	is_locked = locked
	if lock_overlay:
		lock_overlay.visible = is_locked
		
	# 格子被上锁了，直接找亲儿子 Card 弹射
	if is_locked:
		for child in get_children():
			if child is Card:
				var ground_zone = get_tree().get_first_node_in_group("ground_zone")
				if ground_zone and ground_zone.has_method("add_item"):
					var state = {}
					if child.has_method("get_dynamic_state"):
						state = child.get_dynamic_state()
					# 【修正】：读取字典里的名称
					ground_zone.add_item(child.data, child.current_count, state)
					print("🎒 空间失效，物品掉落至地面: [", child.data.get("名称", "未知"), " x", child.current_count, "]")
				
				child.queue_free()

func _can_drop_data(at_position: Vector2, drag_data: Variant) -> bool:
	var dropped_card = drag_data as Card
	if not dropped_card: return false
	if is_locked: return false	

	var current_card: Card = null
	for child in get_children():
		if child is Card:
			current_card = child
			break 
			
	if current_card != null and current_card != dropped_card:
		# 交互重构中，暂时屏蔽
		# if _is_interaction_possible(dropped_card, current_card): return true
			
		# 【修正】：纯字典同名与堆叠判定
		if dropped_card.data.get("id") == current_card.data.get("id") and current_card.data.get("最大堆叠", 99) > 1:
			return true
	return true

func _drop_data(at_position: Vector2, drag_data: Variant) -> void:
	var dropped_card = drag_data as Card
	var current_card: Card = null
	
	for child in get_children():
		if child is Card:
			current_card = child
			break
			
	if current_card == dropped_card: return

	if current_card != null:
		# 交互重构中，暂时屏蔽
		pass
		
	# 【修正】：纯字典全局寻找同类堆叠
	if dropped_card.data.get("最大堆叠", 99) > 1:
		var grid = self.get_parent()
		for other_slot in grid.get_children():
			for child in other_slot.get_children():
				if child is Card and child != dropped_card and child.data.get("id") == dropped_card.data.get("id"):
					var is_fully_stacked = _handle_stacking(child, dropped_card)
					if is_fully_stacked:
						if InventoryManager.has_method("recalculate_player_stats"):
							InventoryManager.call_deferred("recalculate_player_stats") 
						return 

	# 放到这一格，把其他物品后移
	var my_index = self.get_index() 
	if zone_manager and zone_manager.has_method("reorganize_cards"):
		zone_manager.reorganize_cards(dropped_card, my_index)
	
	if EnvironmentManager.has_method("recalculate_environment"):
		EnvironmentManager.call_deferred("recalculate_environment")
	if InventoryManager.has_method("recalculate_player_stats"):
		InventoryManager.call_deferred("recalculate_player_stats") 

# --- 辅助方法：处理同类堆叠 ---
func _handle_stacking(target_card: Card, dropped_card: Card) -> bool:
	# 【修正】：直接读取最大堆叠数
	var max_stack = target_card.data.get("最大堆叠", 99)
	if max_stack <= 1: return false
		
	var space_left = max_stack - target_card.current_count
	if space_left > 0:
		var transfer_amount = min(dropped_card.current_count, space_left)
		target_card.add_count(transfer_amount)
		dropped_card.current_count -= transfer_amount
		dropped_card.update_display()
		
		if dropped_card.current_count <= 0:
			var parent_slot = dropped_card.get_parent()
			if parent_slot: parent_slot.remove_child(dropped_card)
			dropped_card.queue_free()
			return true 
	return false 

# --- 辅助方法：处理工具消耗/耐久度 ---
func _consume_tool_card(tool_card: Card) -> void:
	var tool_data = tool_card.data
	var is_destroyed = false
	
	# 【修正】：纯字典读取耐久
	if tool_data.has("最大耐久") and tool_data["最大耐久"] > 0:
		tool_card.current_durability -= 1
		print("【", tool_data.get("名称", "未知"), "】消耗了1点耐久，剩余：", tool_card.current_durability)
		if tool_card.current_durability <= 0:
			is_destroyed = true
			
	# 【修正】：纯字典读取堆叠消耗
	elif tool_data.get("最大堆叠", 99) > 1:
		tool_card.current_count -= 1
		if tool_card.current_count <= 0:
			is_destroyed = true
			
	if is_destroyed:
		print("【", tool_data.get("名称", "未知"), "】已损坏！")
		var tool_slot = tool_card.get_parent()
		if tool_slot: tool_slot.remove_child(tool_card) 
			
		# 【修正】：如果你以后在字典里配了 "破损产物": "wood"
		var broken_item_id = tool_data.get("破损产物", "")
		if broken_item_id != "":
			var ground_zone = get_tree().get_first_node_in_group("ground_zone")
			if ground_zone and ground_zone.has_method("add_item"):
				# 向 ItemDB 索要新字典
				ground_zone.add_item(ItemDB.get_item_base(broken_item_id), 1)
				
		tool_card.queue_free()
		if tool_slot is Slot and tool_slot.zone_manager:
			tool_slot.zone_manager.reorganize_cards()
			
		if EnvironmentManager.has_method("recalculate_environment"):
			EnvironmentManager.call_deferred("recalculate_environment")
	else:
		tool_card.update_display()

# ==========================================
# 废弃的互动系统（等待下一阶段重写）
# ==========================================
func _is_interaction_possible(tool_card: Card, target_card: Card) -> bool:
	return false

func _handle_interaction(tool_card: Card, target_card: Card) -> bool:
	return false
