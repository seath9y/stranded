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

# 【核心修复 1】：参数类型改成 Dictionary！
func add_item(item_data: Dictionary, amount: int = 1, state: Dictionary = {}) -> int:
	var leftover = amount
	
	# 【核心修复 2】：纯字典判断最大堆叠数
	if item_data.get("最大堆叠", 99) > 1:
		for slot in slot_container.get_children():
			if slot is Slot and slot.is_locked:
				continue 
				
			for child in slot.get_children():
				# 【核心修复 3】：纯字典比对 ID
				if child is Card and child.data.get("id") == item_data.get("id"):
					leftover = child.add_count(leftover) 
					if leftover <= 0:
						return 0 

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
			new_item.set_data(item_data, leftover)
			
			if not state.is_empty():
				new_item.apply_dynamic_state(state)
			
			# 这里会调用你写好的极其完美的重排机制，它发现格子不够会自动造新格子！	
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
			
	for i in range(all_cards.size()):
		if i >= slot_container.get_child_count():
			expand_inventory()
		var slot = slot_container.get_child(i)
		slot.add_child(all_cards[i])
