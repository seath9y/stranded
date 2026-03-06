extends Control
# 拖拽引用
@onready var slot_container = $MarginContainer.get_child(0)
@export var columns: int = 4
@export var min_rows: int = 2

var slot_scene = preload("res://scenes/cards/slot.tscn")
var item_scene = preload("res://scenes/cards/card.tscn")

var current_slot_count = 0
# 🌟 新增：是否允许自动扩容（默认关，保护背包；仅在编辑器里给地面区打勾）
@export var auto_expand: bool = false

func _ready():
	create_slots(columns * min_rows)

func create_slots(count: int):
	for i in range(count):
		var new_slot = slot_scene.instantiate()
		new_slot.zone_manager = self 
		slot_container.add_child(new_slot)
		current_slot_count += 1

# 【核心修复】：完美支持字典状态的透传与克隆
func add_item(item_data: Dictionary, amount: int = 1, state: Dictionary = {}) -> int:
	var leftover = amount
	
	# 1. 寻找同类并堆叠
	if item_data.get("最大堆叠", 99) > 1:
		for slot in slot_container.get_children():
			if slot is Slot and slot.is_locked:
				continue 
				
			for child in slot.get_children():
				if child is Card and child.data.get("id") == item_data.get("id"):
					# 🌟 核心修复：把外来状态 (state) 直接传进数组，不再生成默认满状态！
					leftover = child.add_count(leftover, state) 
					if leftover <= 0:
						return 0 

	# 2. 如果没叠完，找空位生成新卡牌
	if leftover > 0:
		var empty_valid_slots = 0
		for slot in slot_container.get_children():
			if slot is Slot and not slot.is_locked:
				var has_card = false
				for child in slot.get_children():
					if child is Card:
						has_card = true
						break
				if not has_card:
					empty_valid_slots += 1
					
		if empty_valid_slots > 0 or auto_expand:
			var new_item = item_scene.instantiate()
			# 🌟 核心修复：抛弃不稳定的 apply_dynamic_state
			# 先生成一个0数量的空壳，然后用 add_count 把带状态的数据精准砸进去！
			new_item.set_data(item_data, 0)
			new_item.add_count(leftover, state)
				
			reorganize_cards(new_item, 9999)
			return 0 
		else:
			print("❌ 目标区域已满或被锁定，拒绝放入！")
			return leftover 
			
	return leftover
	
	
func find_first_empty_slot():
	for slot in slot_container.get_children():
		var has_card = false
		for child in slot.get_children():
			if child is Card: 
				has_card = true
				break
		if not has_card:
			return slot
	return null

func expand_inventory():
	if auto_expand: # 只有开启了扩容开关才真正创建新槽位
		create_slots(columns)

func reorganize_cards(inserted_card: Card = null, target_index: int = 9999):
	var all_cards = []
	
	for slot in slot_container.get_children():
		for child in slot.get_children():
			if child is Card and child != inserted_card:
				all_cards.append(child)
				slot.remove_child(child)
				
	if inserted_card != null:
		target_index = clamp(target_index, 0, all_cards.size())
		all_cards.insert(target_index, inserted_card)
		
		var old_parent = inserted_card.get_parent()
		if old_parent:
			var old_zone = null
			if old_parent is Slot:
				old_zone = old_parent.zone_manager
				
			old_parent.remove_child(inserted_card)
			
			if old_zone != null and old_zone != self and old_zone.has_method("reorganize_cards"):
				old_zone.reorganize_cards()
	# 🌟 核心修复：计算目标槽位数并执行收缩/扩张
	var min_slots = columns * min_rows 
	var target_slot_count = max(min_slots, all_cards.size())
	
	# 如果多于 12 格且卡牌变少了，删除多余的槽位节点
	while slot_container.get_child_count() > target_slot_count:
		var last_slot = slot_container.get_child(slot_container.get_child_count() - 1)
		slot_container.remove_child(last_slot)
		last_slot.queue_free()
		current_slot_count -= 1
		
	# 如果卡牌溢出了，创建新槽位
	while slot_container.get_child_count() < target_slot_count:
		expand_inventory()
	# 2. 重新按序放入卡牌
	for i in range(all_cards.size()):
		if i >= slot_container.get_child_count():
			expand_inventory()
		var slot = slot_container.get_child(i)
		slot.add_child(all_cards[i])
