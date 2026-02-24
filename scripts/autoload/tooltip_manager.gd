# ================= res://scripts/autoload/tooltip_manager.gd =================
extends CanvasLayer

var tooltip_scene = preload("res://scenes/ui/tooltip.tscn") # 替换为你的路径
var tooltip_instance: Control

# 内部节点引用
var name_label: Label
var desc_label: Label
var stats_label: Label

# 状态追踪
var is_showing: bool = false
var current_card: Card = null

func _ready():
	# 设定 CanvasLayer 的层级极高，确保遮盖所有 UI
	layer = 100 
	
	# 实例化并隐藏
	tooltip_instance = tooltip_scene.instantiate()
	add_child(tooltip_instance)
	tooltip_instance.hide()
	
	# 获取内部节点引用
	name_label = tooltip_instance.get_node("MarginContainer/VBoxContainer/NameLabel")
	desc_label = tooltip_instance.get_node("MarginContainer/VBoxContainer/DescLabel")
	stats_label = tooltip_instance.get_node("MarginContainer/VBoxContainer/StatsLabel")
	
	# 确保不阻挡鼠标事件
	tooltip_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta):
	# 如果正在显示，执行“智能避让”跟随逻辑
	if is_showing and is_instance_valid(tooltip_instance):
		_update_position()

func show_tooltip(card: Card):
	if card == null or card.data == null: return
	
	current_card = card
	var data = card.data
	
	# 1. 填充基础信息
	name_label.text = data.name
	desc_label.text = data.description
	
	# 2. 动态拼装属性信息 (Stats)
	var stats_text = ""
	
	# 检查耐久度
	if "has_durability" in data and data.has_durability:
		stats_text += "耐久度: %d / %d\n" % [card.current_durability, data.max_durability]
		
	# 检查重量 (你之前加的)
	if "weight" in data and data.weight > 0:
		stats_text += "重量: %d\n" % data.weight
		
	# 检查修饰器加成 (比如桌椅提供点数)
	if "passive_modifiers" in data:
		for mod in data.passive_modifiers:
			stats_text += "提供加成: %s +%d\n" % [ModifierData.StatType.keys()[mod.stat_type], mod.points]
			
	# 如果有属性才显示，没有就清空
	stats_label.text = stats_text
	stats_label.visible = stats_text.length() > 0
	
	# 3. 显示出来
	is_showing = true
	tooltip_instance.show()
	
	# 立即更新一次位置，防止闪烁
	_update_position()

func hide_tooltip():
	is_showing = false
	current_card = null
	if is_instance_valid(tooltip_instance):
		tooltip_instance.hide()

# --- 核心：智能避让定位逻辑 ---
func _update_position():
	var mouse_pos = tooltip_instance.get_global_mouse_position()
	var screen_size = tooltip_instance.get_viewport_rect().size
	var tip_size = tooltip_instance.size
	
	# 固定右侧边距
	var margin_x = 20
	var margin_y = 20
	var target_x = screen_size.x - tip_size.x - margin_x
	var target_y = margin_y # 默认在右上角
	
	# 智能判定：如果鼠标位于右上角区域，面板避让到右下角
	if mouse_pos.x > (screen_size.x / 2.0) and mouse_pos.y < (screen_size.y / 2.0):
		target_y = screen_size.y - tip_size.y - margin_y
		
	# 平滑移动过去 (用 lerp 会显得很有高级感)
	var current_pos = tooltip_instance.global_position
	# 如果是刚刚显示，直接传过去不带动画
	if current_pos == Vector2.ZERO: 
		tooltip_instance.global_position = Vector2(target_x, target_y)
	else:
		# 0.2 是平滑系数，可以自己调
		tooltip_instance.global_position = current_pos.lerp(Vector2(target_x, target_y), 0.2)
