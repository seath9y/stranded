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
	# 1. 强制撑开水平
	self.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# 【修改】：按照全尺寸大卡牌的高度 (大概 120 + 上下边距 20) 来撑开槽位！
	var screen_width = get_viewport().size.x
	var base_width = clamp(screen_width * 0.079, 80.0, 130.0)
	# 高度同样使用除以 0.75，加上 20 像素的上下边距
	self.custom_minimum_size = Vector2(350, (base_width / 0.75) + 20)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.6)
	style.set_corner_radius_all(8)
	self.add_theme_stylebox_override("panel", style)

	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 10)
	add_child(main_hbox)

	# 🌟 核心修复 2：彻底删掉 autowrap_mode，并给文字区强制分配空间！
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	# 给文字区一个硬性保底宽度（比如150像素），它绝不可能再缩成1个字！
	margin.custom_minimum_size = Vector2(150, 0)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(info_label)
	main_hbox.add_child(margin)

	# 中间放卡牌的容器 (等待卡牌降落的停机坪)
	card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	
	var screen_width = get_viewport().size.x
	# ⚠️ 同样，这里的小数请和你 Slot.gd 里的保持一致
	var base_width = clamp(screen_width * 0.079, 80.0, 130.0)
	
	# 算好卡牌需要的宽度，给停机坪占好位置
	var needed_width = amount * base_width + (amount * 5) 
	card_container.custom_minimum_size = Vector2(needed_width, base_width / 0.75)
	
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

func _drop_data(at_position: Vector2, drag_data: Variant) -> void:
	var card = drag_data as Card
	var needed = req_amount - get_current_amount()
	var transfer = min(card.stacked_states.size(), needed)

	# 🌟 新增：记住卡牌老家的引用
	var old_parent = card.get_parent()
	var source_zone = null
	if old_parent and "zone_manager" in old_parent:
		source_zone = old_parent.zone_manager

	# 如果卡牌数量刚刚好，或者我们全吞了
	if transfer == card.stacked_states.size():
		if old_parent: old_parent.remove_child(card)
		card_container.add_child(card)
		
		# 🌟 新增：勒令老家重新整理队列！
		if source_zone and source_zone.has_method("reorganize_cards"):
			source_zone.reorganize_cards()
	else:
		# 如果卡牌太多了，精准撕下上面几张的状态！
		var transfer_states: Array[Dictionary] = []
		for i in range(transfer):
			transfer_states.append(card.stacked_states.pop_front())
		card.update_display()
		
		var new_card = load("res://scenes/cards/card.tscn").instantiate()
		new_card.set_data(card.data, transfer)
		new_card.stacked_states = transfer_states 
		card_container.add_child(new_card)

	update_ui()
	state_changed.emit()
