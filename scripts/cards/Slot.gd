extends AspectRatioContainer
class_name Slot

@onready var lock_overlay = $LockOverlay

var zone_manager: Node 
var is_locked: bool = false
func _ready():
	# ... 你原有的其他初始化代码 ...
	
	# 🌟 新增：让槽位自己监听屏幕变化并立刻执行一次
	get_tree().get_root().size_changed.connect(_update_responsive_size)
	call_deferred("_update_responsive_size")
# ================= 🌟 自治响应式引擎 (完美比例版) =================
func _update_responsive_size():
	var screen_width = get_viewport().size.x
	
	# 【修改系数】：让它稍微大一点，接近你原本的 100 宽度
	# 在 1920 分辨率下，卡牌大约是 105 像素宽；最低不会低于 80 像素！
	var base_width = clamp(screen_width * 0.079, 80.0, 130.0)
	
	# 【核心修复：绝对尊重你的 0.75 比例！】
	# 因为你编辑器里设了 ratio = 0.75 (宽度/高度 = 0.75)，所以 高度 = 宽度 / 0.75
	# 这样算出来的框，和你的节点比例严丝合缝，卡牌再也不会被挤压变小了！
	var target_size = Vector2(base_width, base_width / 0.75)
	
	self.custom_minimum_size = target_size
	self.size = target_size
func set_locked(locked: bool):
	is_locked = locked
	if lock_overlay:
		lock_overlay.visible = is_locked
		
	if is_locked:
		for child in get_children():
			if child is Card:
				var ground_zone = get_tree().get_first_node_in_group("ground_zone")
				if ground_zone and ground_zone.has_method("add_item"):
					# 🌟 重构：逐个吐出状态，确保堆叠的异质物品落地时不丢失数据
					for state in child.stacked_states:
						ground_zone.add_item(child.data, 1, state)
					print("🎒 空间失效，物品掉落至地面: [", child.data.get("名称", "未知"), " x", child.stacked_states.size(), "]")
				
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
	var max_stack = target_card.data.get("最大堆叠", 99)
	if max_stack <= 1: return false
		
	var space_left = max_stack - target_card.stacked_states.size()
	if space_left > 0:
		# 🌟 重构：精准切片拖拽过来的状态数组
		var transfer_count = min(dropped_card.stacked_states.size(), space_left)
		var transfer_states = dropped_card.stacked_states.slice(0, transfer_count)
		
		# 追加给目标
		target_card.stacked_states.append_array(transfer_states)
		target_card.update_display()
		
		# 削减拖拽源
		for i in range(transfer_count):
			dropped_card.stacked_states.pop_front()
			
		dropped_card.update_display()
		
		if dropped_card.stacked_states.is_empty():
			var parent_slot = dropped_card.get_parent()
			if parent_slot: parent_slot.remove_child(dropped_card)
			dropped_card.queue_free()
			return true 
	return false

# --- 辅助方法：处理工具消耗/耐久度 ---
func _consume_tool_card(tool_card: Card) -> void:
	var tool_data = tool_card.data
	var is_destroyed = false
	
	if tool_card.stacked_states.is_empty(): return
	var top_state = tool_card.stacked_states[0]
	
	if tool_data.has("最大耐久") and tool_data["最大耐久"] > 0:
		var cur_dur = top_state.get("durability", tool_data["最大耐久"])
		cur_dur -= 1
		top_state["durability"] = cur_dur
		print("【", tool_data.get("名称", "未知"), "】消耗了1点耐久，剩余：", cur_dur)
		
		if cur_dur <= 0:
			is_destroyed = true
			
	elif tool_data.get("最大堆叠", 99) > 1:
		is_destroyed = true # 资源被当做材料消耗了一次
			
	if is_destroyed:
		print("【", tool_data.get("名称", "未知"), "】已损坏或消耗！")
		# 🌟 重构：损坏/消耗等同于剥离数组顶层
		tool_card.stacked_states.pop_front()
			
		var broken_item_id = tool_data.get("破损产物", "")
		if broken_item_id != "":
			var ground_zone = get_tree().get_first_node_in_group("ground_zone")
			if ground_zone and ground_zone.has_method("add_item"):
				ground_zone.add_item(ItemDB.get_item_base(broken_item_id), 1)
				
		if tool_card.stacked_states.is_empty():
			var tool_slot = tool_card.get_parent()
			if tool_slot: tool_slot.remove_child(tool_card) 
			tool_card.queue_free()
			if tool_slot is Slot and tool_slot.zone_manager:
				tool_slot.zone_manager.reorganize_cards()
		else:
			tool_card.update_display()
			
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
