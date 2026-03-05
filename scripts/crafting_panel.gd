extends Control
class_name CraftingPanel

@onready var left_list_panel = $LeftListPanel
@onready var right_detail_panel = $RightDetailPanel

@onready var close_btn = $LeftListPanel/MarginContainer/VBoxContainer/HeaderHBox/CloseBtn
@onready var tab_container = $LeftListPanel/MarginContainer/VBoxContainer/CategoryTabs
@onready var recipe_list = $LeftListPanel/MarginContainer/VBoxContainer/RecipeListScroll/RecipeList

@onready var item_icon = $RightDetailPanel/MarginContainer/VBoxContainer/InfoHBox/ItemIcon
@onready var item_name = $RightDetailPanel/MarginContainer/VBoxContainer/InfoHBox/TextVBox/ItemName
@onready var item_desc = $RightDetailPanel/MarginContainer/VBoxContainer/InfoHBox/TextVBox/ItemDesc
@onready var requirement_slots = $RightDetailPanel/MarginContainer/VBoxContainer/RequirementSlots
@onready var auto_fill_btn = $RightDetailPanel/MarginContainer/VBoxContainer/ActionHBox/AutoFillBtn
@onready var clear_btn = $RightDetailPanel/MarginContainer/VBoxContainer/ActionHBox/ClearBtn
@onready var craft_btn = $RightDetailPanel/MarginContainer/VBoxContainer/ActionHBox/CraftBtn

var current_selected_recipe: Dictionary = {}	

func _ready():
	right_detail_panel.hide()
	close_btn.pressed.connect(hide_panel)
	
	auto_fill_btn.pressed.connect(_on_auto_fill_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	craft_btn.pressed.connect(_on_craft_pressed)
	
	for tab_btn in tab_container.get_children():
		if tab_btn is Button:
			var category = tab_btn.text.right(tab_btn.text.length() - 2).strip_edges()
			tab_btn.pressed.connect(func(): _on_tab_pressed(category))

	_on_tab_pressed("工具")

func show_panel():
	self.show()
	right_detail_panel.hide()
	current_selected_recipe = {}
	# 每次打开自动点开“工具”分类
	if tab_container.get_child_count() > 0:
		tab_container.get_child(0).pressed.emit()

func hide_panel():
	_on_clear_pressed() # 关面板前，把里面没消耗的材料全吐出来！
	self.hide()

func _on_tab_pressed(category: String):
	right_detail_panel.hide()
	for child in recipe_list.get_children():
		child.queue_free()
		
	var recipes = RecipeManager.get_recipes_by_category(category)
	var first_button: Button = null 
	
	for recipe in recipes:
		var btn = Button.new()
		btn.text = recipe.get("名称", "未知")
		btn.custom_minimum_size.y = 40
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var output_id = recipe.get("产物", "")
		var item_base = ItemDB.get_item_base(output_id)
		if not item_base.is_empty() and item_base.has("图标"):
			btn.icon = item_base["图标"]
			btn.expand_icon = true
			
		btn.pressed.connect(func(): _on_recipe_selected(recipe, item_base))
		recipe_list.add_child(btn)
		if first_button == null: first_button = btn

	if first_button != null:
		first_button.pressed.emit()

func _on_recipe_selected(recipe: Dictionary, item_base: Dictionary):
	_on_clear_pressed() # 切配方前，吐出旧配方的材料
	
	current_selected_recipe = recipe
	right_detail_panel.show() 
	
	item_name.text = recipe.get("名称", "")
	item_desc.text = item_base.get("描述", "")
	if item_base.has("图标"): item_icon.texture = item_base["图标"]
		
	_generate_requirement_slots(recipe.get("需求", []))
	_check_craft_condition()

func _generate_requirement_slots(requirements: Array):
	for child in requirement_slots.get_children():
		child.queue_free()
		
	for req in requirements:
		var slot = CraftingSlot.new()
		requirement_slots.add_child(slot)
		slot.setup(req.get("标签", ""), req.get("数量", 1), req.get("显示名", ""))
		slot.state_changed.connect(_check_craft_condition)

# ================= 行动 1：检查是否满足制作条件 =================
func _check_craft_condition():
	var all_ready = true
	for slot in requirement_slots.get_children():
		if slot is CraftingSlot and slot.get_current_amount() < slot.req_amount:
			all_ready = false
			break
	craft_btn.disabled = not all_ready
	if all_ready:
		craft_btn.text = "🔨 确认制作 (条件满足)"
		craft_btn.add_theme_color_override("font_color", Color.GREEN)
	else:
		craft_btn.text = "🔨 确认制作"
		craft_btn.remove_theme_color_override("font_color")

# ================= 行动 2：清空退还材料 =================
func _on_clear_pressed():
	for slot in requirement_slots.get_children():
		if slot is CraftingSlot:
			for card in slot.card_container.get_children():
				if card is Card:
					# 安全地将卡牌扔回地面
					var ground = get_tree().get_first_node_in_group("ground_zone")
					if ground:
						var state = card.get_dynamic_state() if card.has_method("get_dynamic_state") else {}
						ground.add_item(card.data, card.current_count, state)
					card.queue_free()
			slot.update_ui()
			slot.state_changed.emit()

# ================= 行动 3：一键填入逻辑 =================
func _on_auto_fill_pressed():
	for slot in requirement_slots.get_children():
		if slot is CraftingSlot and slot.get_current_amount() < slot.req_amount:
			_fill_single_slot_from_inventory(slot)

func _fill_single_slot_from_inventory(slot: CraftingSlot):
	var needed = slot.req_amount - slot.get_current_amount()
	if needed <= 0: return

	# 搜索范围：玩家背包和地面
	var zones = [
		get_tree().get_first_node_in_group("group_player_zone"),
		get_tree().get_first_node_in_group("ground_zone")
	]
	
	var valid_cards = []
	for zone in zones:
		if not zone: continue
		var container = zone.slot_container if "slot_container" in zone else zone
		for s in container.get_children():
			if s is Slot or s is EquipSlot:
				for c in s.get_children():
					if c is Card and slot.req_tag in c.data.get("标签", []):
						valid_cards.append(c)
	
	# 智能排序：优先用快坏掉的，优先用便宜的
	valid_cards.sort_custom(func(a, b): 
		return a.current_durability < b.current_durability
	)

	# 自动吸附循环
	for card in valid_cards:
		if needed <= 0: break
		var transfer = min(card.current_count, needed)
		# 代码复用：调用槽位的原生放入逻辑！
		var temp_card = card
		# 如果是分裂，制造一张假卡喂给槽位
		if transfer < card.current_count:
			card.current_count -= transfer
			card.update_display()
			temp_card = load("res://scenes/cards/card.tscn").instantiate()
			temp_card.set_data(card.data, transfer)
			if card.data.has("最大耐久"): temp_card.current_durability = card.current_durability
			
		slot._drop_data(Vector2.ZERO, temp_card) 
		needed -= transfer

# ================= 行动 4：确认制作 =================
func _on_craft_pressed():
	if craft_btn.disabled: return
	
	# 1. 无情销毁槽位里的祭品卡牌
	for slot in requirement_slots.get_children():
		if slot is CraftingSlot:
			for card in slot.card_container.get_children():
				card.queue_free()
			slot.update_ui()

	# 2. 产出物品到地上！
	var output_id = current_selected_recipe.get("产物", "")
	var amount = current_selected_recipe.get("产出数量", 1)
	var item_base = ItemDB.get_item_base(output_id)
	
	var ground = get_tree().get_first_node_in_group("ground_zone")
	if ground:
		ground.add_item(item_base, amount)
		print("🔨 制作成功：[", item_base.get("名称"), "] x", amount)

	_check_craft_condition()
