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
	# 1. 强制让整个槽位在水平方向撑满面板！
	self.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	self.custom_minimum_size = Vector2(0, 60) # 稍微加高一点，留出卡牌的呼吸空间

	# 2. 给槽位加一个半透明黑底，这样玩家才知道“这是一个可以拖入的框”
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.6) # 半透明黑底
	style.set_corner_radius_all(8) # 圆角
	self.add_theme_stylebox_override("panel", style)

	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 10)
	# 给内部留一点边距，不让文字贴边
	main_hbox.set_deferred("custom_minimum_size", Vector2(0, 50))
	add_child(main_hbox)

	# 3. 左侧文字信息
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.size_flags_stretch_ratio = 1.0 # 占据一半的宽度
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART # 防止文字太长撑爆
	# 稍微给文字加点左边距
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_child(info_label)
	main_hbox.add_child(margin)

	# 4. 中间放卡牌的容器 (核心修复！)
	# 给它一个最小宽度，这样即使里面没卡，它也是一个宽敞的“停机坪”！
	card_container.custom_minimum_size = Vector2(120, 45) 
	card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_container.size_flags_stretch_ratio = 1.0 # 占据另一半的宽度
	main_hbox.add_child(card_container)

	# 5. 右侧打钩/打叉状态
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size = Vector2(40, 0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_hbox.add_child(status_label)

func setup(tag: String, amount: int, name_desc: String):
	req_tag = tag
	req_amount = amount
	display_name = name_desc
	if is_node_ready(): update_ui()

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
		_shrink_card(card)
	else:
		# 如果卡牌太多了，撕下一半放进去！
		card.current_count -= transfer
		card.update_display()
		
		var new_card = load("res://scenes/cards/card.tscn").instantiate()
		new_card.set_data(card.data, transfer)
		if card.data.has("最大耐久"): 
			new_card.current_durability = card.current_durability
		card_container.add_child(new_card)
		_shrink_card(new_card)

	update_ui()
	state_changed.emit()

func _shrink_card(card: Card):
	card.custom_minimum_size = Vector2(40, 40)
	card.size = Vector2(40, 40)
	# 提示框在制作槽里不需要
	if card.hover_timer: card.hover_timer.queue_free()
