extends AspectRatioContainer
class_name Slot

var my_zone_type: ItemData.Zone
var zone_manager: Node 

func _can_drop_data(at_position: Vector2, drag_data: Variant) -> bool:
	var dropped_card = drag_data as Card
	if not dropped_card:
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

	# 2. 如果无互动（或是空格子），再判断当前卡牌是否允许“放置”在这个区域
	return my_zone_type in dropped_card.data.allowed_zones

func _drop_data(at_position: Vector2, drag_data: Variant) -> void:
	var dropped_card = drag_data as Card
	
	# 【修改 2】：把这里的 get_child(0) 也替换成安全遍历！
	var current_card: Card = null
	for child in get_children():
		if child is Card:
			current_card = child
			break
			
	# 如果拖到自己身上，什么都不做
	if current_card == dropped_card:
		return

	# 1. 优先判定并触发互动
	if current_card != null:
		var interacted = _handle_interaction(dropped_card, current_card)
		if interacted:
			return # 互动成功，流程结束！

	# 2. 无互动触发：判断是否能放在该区域
	if not (my_zone_type in dropped_card.data.allowed_zones):
		return # 不能放在这里，拖拽无效，卡牌自动弹回原位
		
	# 3. 能放的话，处理堆叠与插队逻辑
	if dropped_card.data.stack_type != ItemData.StackType.不可堆叠:
		var grid = self.get_parent()
		for other_slot in grid.get_children():
			for child in other_slot.get_children():
				if child is Card and child != dropped_card and child.data.id == dropped_card.data.id:
					var is_fully_stacked = _handle_stacking(child, dropped_card)
					if is_fully_stacked:
						return # 堆叠完毕，手里没卡了，直接结束

	# 放到这一格，把其他物品后移
	var my_index = self.get_index() 
	zone_manager.reorganize_cards(dropped_card, my_index)
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
			# 匹配成功！执行交互与产出逻辑
			# ==========================================
			
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
				
			# C. 处理工具卡牌消耗
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
func _consume_tool_card(tool_card: Card) -> void:
	var tool_data = tool_card.data
	var is_destroyed = false
	
	# 检查耐久度/数量扣除
	# 注意：你提供的 Card 脚本里没看到 current_durability，如果有耐久系统，请在 Card 加上此变量
	if tool_data.max_durability > 0 and "current_durability" in tool_card:
		tool_card.current_durability -= 1
		if tool_card.current_durability <= 0:
			is_destroyed = true
	else:
		# 如果没有耐久度系统（或者当前工具无耐久设定），则作为普通材料扣除数量
		tool_card.current_count -= 1
		if tool_card.current_count <= 0:
			is_destroyed = true
			
	# 如果工具耗尽（耐久归零 或 数量归零）
	if is_destroyed:
		var tool_slot = tool_card.get_parent()
		if tool_slot:
			tool_slot.remove_child(tool_card) # 同样先剥离
			
		# 检查是否需要生成损坏后的替代物 (例如：铁斧 -> 损坏的铁斧)
		if not tool_data.destroy_on_break and tool_data.broken_item != null:
			var ground_zone = get_tree().get_first_node_in_group("ground_zone")
			if ground_zone and ground_zone.has_method("add_item"):
				ground_zone.add_item(tool_data.broken_item, 1)
				
		tool_card.queue_free()
		
		# 整理工具卡牌原先所在的区域 (填补空隙)
		if tool_slot is Slot and tool_slot.zone_manager:
			tool_slot.zone_manager.reorganize_cards()
	else:
		# 如果没销毁，仅仅是扣了耐久或数量，刷新 UI
		tool_card.update_display()
