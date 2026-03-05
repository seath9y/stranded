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
	self.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 【修改】：按照全尺寸大卡牌的高度 (大概 120 + 上下边距 20) 来撑开槽位！
	var screen_width = get_viewport().size.x
	var base_width = clamp(screen_width * 0.045, 60.0, 100.0)
	self.custom_minimum_size = Vector2(0, base_width * 1.2 + 20) 

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.6)
	style.set_corner_radius_all(8)
	self.add_theme_stylebox_override("panel", style)

	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 10)
	add_child(main_hbox)

	# 左侧信息
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.size_flags_stretch_ratio = 1.0 
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_child(info_label)
	main_hbox.add_child(margin)

	# 中间放卡牌的容器
	card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_container.size_flags_stretch_ratio = 1.0 
	main_hbox.add_child(card_container)

	# 右侧打钩/打叉
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size = Vector2(40, 0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_hbox.add_child(status_label)

func setup(tag: String, amount: int, name_desc: String):
	req_tag = tag
	req_amount = amount
	display_name = name_desc
	
	# 【修改】：动态计算真实大卡牌的占地宽度！
	var screen_width = get_viewport().size.x
	var base_width = clamp(screen_width * 0.045, 60.0, 100.0)
	# 需要的宽度 = 卡牌数量 * 基础宽度 + 卡牌之间的间隙
	var needed_width = amount * base_width + (amount * 5) 
	
	card_container.custom_minimum_size = Vector2(needed_width, base_width * 1.2)
	
	if is_node_ready(): 
		update_ui()

func get_current_amount() -> int:
	var total = 0
	for c in card_container.get_children():
		if c is Card: total += c.current_count
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

func _drop_data(at_position: Vector2, drag_data: Variant) -> void:
	var card = drag_data as Card
	var needed = req_amount - get_current_amount()
	var transfer = min(card.current_count, needed)

	# 如果卡牌数量刚刚好，或者我们全吞了
	if transfer == card.current_count:
		var p = card.get_parent()
		if p: p.remove_child(card)
		card_container.add_child(card)
	else:
		# 如果卡牌太多了，撕下一半放进去！
		card.current_count -= transfer
		card.update_display()
		
		var new_card = load("res://scenes/cards/card.tscn").instantiate()
		new_card.set_data(card.data, transfer)
		if card.data.has("最大耐久"): 
			new_card.current_durability = card.current_durability
		card_container.add_child(new_card)

	update_ui()
	state_changed.emit()
