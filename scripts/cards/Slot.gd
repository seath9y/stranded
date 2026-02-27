extends AspectRatioContainer
class_name Slot

@onready var lock_overlay = $LockOverlay

var zone_manager: Node 
var is_locked: bool = false

func set_locked(locked: bool):
	is_locked = locked
	if lock_overlay:
		lock_overlay.visible = is_locked
		
	# 【核心修复】：格子被上锁了，直接找亲儿子 Card 弹射！
	if is_locked:
		for child in get_children():
			if child is Card:
				var ground_zone = get_tree().get_first_node_in_group("ground_zone")
				if ground_zone and ground_zone.has_method("add_item"):
					var state = {}
					if child.has_method("get_dynamic_state"):
						state = child.get_dynamic_state()
					ground_zone.add_item(child.data, child.current_count, state)
					print("🎒 空间失效，物品掉落至地面: [", child.data.name, " x", child.current_count, "]")
				
				child.queue_free()
func _can_drop_data(at_position: Vector2, drag_data: Variant) -> bool:
	var dropped_card = drag_data as Card
	if not dropped_card:
		return false
	# 【核心拦截】：如果格子未解锁，绝对禁止放东西！
	if is_locked:
		return false	
	# 【修改 1】：安全遍历获取当前格子里的卡牌（无视底图）
	var current_card: Card = null
	for child in get_children():
		if child is Card:
			current_card = child
			break # 找到了就停止遍历
	# 1. 首要判定：如果目标格子里有卡牌，先检查它们是否能互动
	if current_card != null and current_card != dropped_card:
		# 如果可以交互，必须允许放下（让鼠标显示可操作）
		if _is_interaction_possible(dropped_card, current_card):
			return true
			
		# 如果是同名卡牌且允许堆叠，也允许放下
		if dropped_card.data.id == current_card.data.id and current_card.data.stack_type != ItemData.StackType.不可堆叠:
			return true
	 #2. 如果无互动（或是空格子）
	return true

func _drop_data(at_position: Vector2, drag_data: Variant) -> void:
	var dropped_card = drag_data as Card
	
	var current_card: Card = null
	for child in get_children():
		if child is Card:
			current_card = child
			break
			
	if current_card == dropped_card:
		return

	if current_card != null:
		var interacted = _handle_interaction(dropped_card, current_card)
		if interacted:
			InventoryManager.call_deferred("recalculate_player_stats") # <--- 【新增1】
			return
		
	if dropped_card.data.stack_type != ItemData.StackType.不可堆叠:
		var grid = self.get_parent()
		for other_slot in grid.get_children():
			for child in other_slot.get_children():
				if child is Card and child != dropped_card and child.data.id == dropped_card.data.id:
					var is_fully_stacked = _handle_stacking(child, dropped_card)
					if is_fully_stacked:
						InventoryManager.call_deferred("recalculate_player_stats") # <--- 【新增2】
						return 

	# 放到这一格，把其他物品后移
	var my_index = self.get_index() 
	zone_manager.reorganize_cards(dropped_card, my_index)
	
	# 【补全系统】：卡牌成功移动/放下后，重算环境加成
	EnvironmentManager.call_deferred("recalculate_environment")
	InventoryManager.call_deferred("recalculate_player_stats") # <--- 【新增3】
# --- 修改后的互动判定（纯标签驱动） ---
func _is_interaction_possible(tool_card: Card, target_card: Card) -> bool:
	var tool_data = tool_card.data
	var target_data = target_card.data
	
	# 直接遍历目标卡牌支持的所有交互规则
	for rule in target_data.interactions:
		if rule != null and rule.required_tag != null:
			# 如果工具身上带有这个规则需要的标签，就说明可以互动！
			if _has_action_tag(tool_data.action_tags, rule.required_tag):
				return true
				
	return false

# --- 修改后的执行互动（纯标签驱动） ---
func _handle_interaction(tool_card: Card, target_card: Card) -> bool:
	var tool_data = tool_card.data
	var target_data = target_card.data
	
	for rule in target_data.interactions:
		if rule == null or rule.required_tag == null:
			continue
			
		if _has_action_tag(tool_data.action_tags, rule.required_tag):
			# ==========================================
			# 匹配成功！开始“扣血”逻辑
			# ==========================================
			
			# 1. 获取工具的破坏力 (如果没有设置 tool_power，默认威力是 1)
			var power: int = 1
			if "tool_power" in tool_data:
				power = tool_data.tool_power
				
			# 2. 扣除目标（比如树）的耐久度
			var is_target_destroyed = true # 假设目标没耐久系统，默认一击必杀
			
			if "has_durability" in target_data and target_data.has_durability:
				target_card.current_durability -= power
				print("【", target_data.name, "】被砍了一次，剩余耐久：", target_card.current_durability)
				
				if target_card.current_durability > 0:
					is_target_destroyed = false # 耐久没归零，树还没倒！
					target_card.update_display() # 刷新树的UI百分比
					
			# 3. 如果树倒了（或目标本身是一次性的）
			if is_target_destroyed:
				# A. 生成产出物
				if rule.result_item != null:
					var ground_zone = get_tree().get_first_node_in_group("ground_zone")
					if ground_zone and ground_zone.has_method("add_item"):
						ground_zone.add_item(rule.result_item, 1)
						
				# B. 处理目标卡牌销毁
				var target_slot = target_card.get_parent()
				if target_slot:
					target_slot.remove_child(target_card)
				target_card.queue_free()
				
				if target_slot is Slot and target_slot.zone_manager:
					target_slot.zone_manager.reorganize_cards()
					
				# 触发重算
				EnvironmentManager.call_deferred("recalculate_environment")
				
			# C. 无论树倒没倒，只要砍了，斧子就要消耗耐久
			_consume_tool_card(tool_card)
			
			return true 

	return false
# --- 辅助方法：处理同类堆叠 ---
# 返回值 bool: 如果 dropped_card 被彻底消耗完了，返回 true
func _handle_stacking(target_card: Card, dropped_card: Card) -> bool:
	# 1. 安全拦截：如果目标卡牌根本不可堆叠，直接拒绝合并
	if target_card.data.stack_type == ItemData.StackType.不可堆叠:
		return false
		
	var space_left: int = 0
	
	# 2. 根据堆叠类型，精准计算还能塞下多少个
	if target_card.data.stack_type == ItemData.StackType.无限堆叠:
		space_left = 9999999 # 给一个极大的数字代表无限空间
	elif target_card.data.stack_type == ItemData.StackType.固定数量:
		space_left = target_card.data.max_stack_limit - target_card.current_count
		
	# 3. 如果还有空间可以塞入
	if space_left > 0:
		# 实际转移的数量 = 自身拥有的数量 和 目标剩余空间 的最小值
		var transfer_amount = min(dropped_card.current_count, space_left)
		
		# 给目标卡牌增加数量
		target_card.add_count(transfer_amount)
		
		# 扣除手里卡牌的数量
		dropped_card.current_count -= transfer_amount
		dropped_card.update_display()
		
		# 4. 判断手里的卡牌是否被完全消耗殆尽
		if dropped_card.current_count <= 0:
			# 【关键修复】先强行剥离，防止后续执行 reorganize_cards 时把将死未死的节点算进去
			var parent_slot = dropped_card.get_parent()
			if parent_slot:
				parent_slot.remove_child(dropped_card)
				
			# 彻底销毁
			dropped_card.queue_free()
			return true # 彻底消耗完了，手里空了
			
	return false # 还没消耗完，手里还有剩余（比如拿了99个，只能塞进去50个）


# --- 辅助方法：检查工具标签集合中是否包含目标标签 ---
func _has_action_tag(action_tags: Array[TagData], required_tag: TagData) -> bool:
	for tag in action_tags:
		# 比较 Resource 中的 tag_name (StringName 比较效率很高)
		if tag != null and tag.tag_name == required_tag.tag_name:
			return true
	return false

# --- 辅助方法：处理工具消耗/耐久度 ---
# --- 辅助方法：处理工具消耗/耐久度 ---
func _consume_tool_card(tool_card: Card) -> void:
	var tool_data = tool_card.data
	var is_destroyed = false
	
	# 【修复Bug】：安全检查 has_durability
	if "has_durability" in tool_data and tool_data.has_durability:
		# 扣除卡牌实例的当前耐久
		tool_card.current_durability -= 1
		print("【", tool_data.name, "】消耗了1点耐久，剩余：", tool_card.current_durability)
		
		if tool_card.current_durability <= 0:
			is_destroyed = true
			
	# 2. 如果没启用耐久，但是它是可以堆叠的消耗材料
	elif tool_data.stack_type != ItemData.StackType.不可堆叠:
		tool_card.current_count -= 1
		if tool_card.current_count <= 0:
			is_destroyed = true
			
	# ==========================================
	# 销毁与破损逻辑
	# ==========================================
	if is_destroyed:
		print("【", tool_data.name, "】已损坏！")
		var tool_slot = tool_card.get_parent()
		if tool_slot:
			tool_slot.remove_child(tool_card) 
			
		# 【修复Bug】：安全检查 destroy_on_break 和 broken_item
		if "destroy_on_break" in tool_data and not tool_data.destroy_on_break and "broken_item" in tool_data and tool_data.broken_item != null:
			var ground_zone = get_tree().get_first_node_in_group("ground_zone")
			if ground_zone and ground_zone.has_method("add_item"):
				ground_zone.add_item(tool_data.broken_item, 1)
				
		tool_card.queue_free()
		
		# 整理卡牌
		if tool_slot is Slot and tool_slot.zone_manager:
			tool_slot.zone_manager.reorganize_cards()
			
		# 【补全系统】：工具损坏彻底消失后，重算环境加成
		EnvironmentManager.call_deferred("recalculate_environment")
	else:
		# 没损坏，刷新 UI
		tool_card.update_display()
