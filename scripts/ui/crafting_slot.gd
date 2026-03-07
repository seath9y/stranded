extends PanelContainer
class_name CraftingSlot

var req_tag: String = ""
var req_amount: int = 0
var display_name: String = ""

signal state_changed

@onready var info_label = Label.new()
@onready var status_label = Label.new()
@onready var card_container = HBoxContainer.new()

func _ready():
	# 🌟 核心修改 1：不再扩展填充水平空间，而是由内容决定大小
	self.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	var screen_width = get_viewport().size.x
	var base_width = clamp(screen_width * 0.055, 80.0, 130.0) # 回归全局基准比例
	
	# 🌟 核心修改 2：固定槽位宽度，高度为（卡牌高度 + 文字高度 + 间距）
	# 这样一行就能塞下多个需求槽位
	self.custom_minimum_size = Vector2(base_width + 20, (base_width / 0.75) + 50)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.6)
	style.set_corner_radius_all(8)
	self.add_theme_stylebox_override("panel", style)

	# 🌟 核心修改 3：改为纵向布局 VBox
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 5)
	add_child(main_vbox)

	# 顶部文字区 (缩小字号以适应紧凑排版)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	main_vbox.add_child(info_label)

	# 中间卡牌区 (居中放置)
	var card_center = CenterContainer.new()
	card_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# 容器只容纳单张卡牌的大小
	card_container.custom_minimum_size = Vector2(base_width, base_width / 0.75)
	card_center.add_child(card_container)
	main_vbox.add_child(card_center)

	# 底部状态图标 (打钩/叉)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(status_label)
	# 🌟 核心修复：监听子节点变动（如拖出卡牌），自动同步 UI 和面板按钮状态
	card_container.child_order_changed.connect(func():
		if is_node_ready():
			update_ui()
			state_changed.emit()
	)
func setup(tag: String, amount: int, name_desc: String):
	req_tag = tag
	req_amount = amount
	display_name = name_desc
	# 🌟 核心修改 4：移除原来的 needed_width 计算，保持固定宽度
	if is_node_ready(): 
		update_ui()
func get_current_amount() -> int:
	var total = 0
	for c in card_container.get_children():
		if c is Card: total += c.stacked_states.size()
	return total

func update_ui():
	var current = get_current_amount()
	info_label.text = "需 %d个 [%s] (已放: %d)" % [req_amount, display_name, current]
	if current >= req_amount:
		status_label.text = "✔️"
		status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		status_label.text = "❌"
		status_label.add_theme_color_override("font_color", Color.RED)

# --- 核心：接收玩家的拖拽 ---
func _can_drop_data(at_position: Vector2, drag_data: Variant) -> bool:
	var card = drag_data as Card
	if not card: return false
	# 满了就不要了
	if get_current_amount() >= req_amount: return false
	# 检查标签是否符合！
	if req_tag not in card.data.get("标签", []): return false
	return true

# 🌟 核心重构：支持槽位内的自动堆叠，确保只显示“一摞”卡牌
func _drop_data(at_position: Vector2, drag_data: Variant) -> void:
	var card = drag_data as Card
	var needed = req_amount - get_current_amount()
	var transfer = min(card.stacked_states.size(), needed)

	var old_parent = card.get_parent()
	var source_zone = null
	if old_parent and "zone_manager" in old_parent:
		source_zone = old_parent.zone_manager

	# 检查槽位里是否已经有同类卡牌，有则合并状态，无则放入
	var existing_card = null
	for c in card_container.get_children():
		if c is Card:
			existing_card = c
			break

	if existing_card:
		# 情况 A：槽位已有卡，执行状态合并
		var transfer_states: Array[Dictionary] = []
		for i in range(transfer):
			transfer_states.append(card.stacked_states.pop_front())
		
		existing_card.stacked_states.append_array(transfer_states)
		existing_card.update_display()
		
		# 如果拖过来的卡被抽干了，销毁它；否则更新显示
		if card.stacked_states.is_empty():
			if old_parent: old_parent.remove_child(card)
			card.queue_free()
		else:
			card.update_display()
	else:
		# 情况 B：槽位为空，执行原来的放入逻辑
		if transfer == card.stacked_states.size():
			if old_parent: old_parent.remove_child(card)
			card_container.add_child(card)
		else:
			var transfer_states: Array[Dictionary] = []
			for i in range(transfer):
				transfer_states.append(card.stacked_states.pop_front())
			card.update_display()
			
			var new_card = load("res://scenes/cards/card.tscn").instantiate()
			new_card.set_data(card.data, 0)
			new_card.stacked_states = transfer_states 
			card_container.add_child(new_card)

	# 勒令老家整理
	if source_zone and source_zone.has_method("reorganize_cards"):
		source_zone.reorganize_cards()

	update_ui()
	state_changed.emit()
