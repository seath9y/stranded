extends Control
# 拖拽引用
@onready var slot_container = $MarginContainer.get_child(0)
@export var columns: int = 4
@export var min_rows: int = 2

# 预加载格子的场景
var slot_scene = preload("res://scenes/ui/components/slot.tscn")
# 预加载物品的场景（或者是你的卡牌场景）
var item_scene = preload("res://scenes/ui/components/card.tscn")

# 配置参数
var current_slot_count = 0

func _ready():
	
	# 【关键新增】：强制让底层的 GridContainer 的列数，等于你在面板里设置的列数！
	if slot_container is GridContainer:
		slot_container.columns = self.columns
	# 1. 初始化：一开始只有两排8个槽位
	create_slots(columns * min_rows)
# 创建指定数量的空槽位
func create_slots(count: int):
	for i in range(count):
		var new_slot = slot_scene.instantiate()
		# 【新增】告诉格子，我是你的管家
		new_slot.zone_manager = self 
		
		slot_container.add_child(new_slot)
		current_slot_count += 1

# 修改 add_item，让它返回【没放进去的数量】 (int)
func add_item(item_data: ItemData, amount: int = 1, state: Dictionary = {}) -> int:
	var leftover = amount
	
	# 1. 尝试同类堆叠
	if item_data.stack_type != ItemData.StackType.不可堆叠:
		for slot in slot_container.get_children():
			# 🛑 【核心防御 1】：直接无视被锁定的格子！
			if slot is Slot and slot.is_locked:
				continue 
				
			for child in slot.get_children():
				if child is Card and child.data.id == item_data.id:
					leftover = child.add_count(leftover) 
					if leftover <= 0:
						return 0 # 全部塞完，返回 0

	# 2. 如果还需要新格子生成卡牌
	if leftover > 0:
		# 🛑 【核心防御 2 修复】：准确判断是否有“未锁定且没有卡牌”的合法格子
		var empty_valid_slots = 0
		for slot in slot_container.get_children():
			if slot is Slot and not slot.is_locked:
				# 必须遍历里面看看有没有 Card，不能只看子节点数量！
				var has_card = false
				for child in slot.get_children():
					if child is Card:
						has_card = true
						break
				
				# 如果没有发现卡牌，说明这个格子是真的空着
				if not has_card:
					empty_valid_slots += 1
					
		# 只有存在合法空位时，才允许生成新卡牌
		if empty_valid_slots > 0:
			var new_item = item_scene.instantiate()
			new_item.set_data(item_data, leftover)
			
			if not state.is_empty():
				new_item.apply_dynamic_state(state)
				
			reorganize_cards(new_item, 9999)
			return 0 # 成功放入新格子，返回 0
		else:
			print("❌ 目标区域已满或被锁定，拒绝放入！")
			return leftover # 没有位置了，把原数退回！
			
	return leftover

# 修改：寻找第一个空的槽位
func find_first_empty_slot():
	for slot in slot_container.get_children():
		# 稳健做法：遍历槽位的子节点，看看有没有卡牌 (Card)
		var has_card = false
		for child in slot.get_children():
			# 假设你卡牌根节点的 class_name 是 Card
			if child is Card: 
				has_card = true
				break
				
		# 如果没有找到卡牌，说明这个槽位是空的（里面只有底色 Panel）
		if not has_card:
			return slot
			
	return null

# 扩展背包（增加一行）
func expand_inventory():
	# 你的图是一行4个，所以每次满的时候增加4个新槽位
	create_slots(columns)
	# 此时 ScrollContainer 会自动计算大小，
	# 因为内容超过了设定的高度，滚动条会自动出现。

# ==========================================
# 新增：重新整理卡牌（自动往前排，并处理插队）
# ==========================================
func reorganize_cards(inserted_card: Card = null, target_index: int = 9999):
	var all_cards = []
	
	# 1. 收集当前所有的卡牌（排除掉正在手里拖拽/准备插队的那张，防止重复）
	for slot in slot_container.get_children():
		for child in slot.get_children():
			if child is Card and child != inserted_card:
				all_cards.append(child)
				# 暂时从原槽位中剥离
				slot.remove_child(child)
				
	# 2. 处理插队：如果有新卡牌要放入
	if inserted_card != null:
		target_index = clamp(target_index, 0, all_cards.size())
		all_cards.insert(target_index, inserted_card)
		
		# 【重点修复在这里 👇】
		var old_parent = inserted_card.get_parent()
		if old_parent:
			var old_zone = null
			# 看看这牌原来是不是呆在某个格子里
			if old_parent is Slot:
				old_zone = old_parent.zone_manager
				
			# 把牌从原来的格子里拔出来
			old_parent.remove_child(inserted_card)
			
			# 如果这张牌是从别的区（比如2区）跨区过来的，立刻通知它的“老家”也洗牌补齐空缺！
			if old_zone != null and old_zone != self:
				old_zone.reorganize_cards()
			
	# 3. 按顺序重新放回槽位（不留空隙）
	for i in range(all_cards.size()):
		# 如果槽位不够了，自动扩容
		if i >= slot_container.get_child_count():
			expand_inventory()
			
		var slot = slot_container.get_child(i)
		slot.add_child(all_cards[i])
# 测试
#func _on_button_2_pressed() -> void:
	#expand_inventory()
	#pass # Replace with function body.
