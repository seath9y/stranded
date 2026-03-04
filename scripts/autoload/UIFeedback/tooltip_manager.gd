# ================= res://scripts/autoload/tooltip_manager.gd =================
extends CanvasLayer

var tooltip_scene = preload("res://scenes/ui/tooltip.tscn")
var tooltip_instance: Control

var name_label: Label
var desc_label: Label
var stats_label: Label

var is_showing: bool = false
var current_card = null

# --- 新增：模式枚举与目标节点 ---
enum TooltipMode { CARD, TOPBAR }
var current_mode: TooltipMode = TooltipMode.CARD
var target_ui_node: Control = null

func _ready():
	layer = 100 
	tooltip_instance = tooltip_scene.instantiate()
	add_child(tooltip_instance)
	tooltip_instance.hide()
	
	name_label = tooltip_instance.get_node("MarginContainer/VBoxContainer/NameLabel")
	desc_label = tooltip_instance.get_node("MarginContainer/VBoxContainer/DescLabel")
	stats_label = tooltip_instance.get_node("MarginContainer/VBoxContainer/StatsLabel")
	tooltip_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta):
	if is_showing and is_instance_valid(tooltip_instance):
		_update_position()

# --- 模式 1：卡牌提示框 (保留你原有的逻辑) ---
func show_tooltip(card):
	# 【修正】：增加字典判空
	if card == null or card.data == null or typeof(card.data) != TYPE_DICTIONARY or card.data.is_empty(): 
		return
	
	current_card = card
	var data = card.data
	
	# 【修正】：直接读取字典里的中文名称和描述
	name_label.text = data.get("名称", "未知物品")
	desc_label.text = data.get("描述", "")
	
	var stats_text = ""
	
	# 1. 读取耐久度
	if data.has("最大耐久") and data["最大耐久"] > 0:
		stats_text += "耐久度: %d / %d\n" % [card.current_durability, data["最大耐久"]]
		
	# 2. 读取重量
	var weight = data.get("重量", 0)
	if weight > 0:
		stats_text += "重量: %d\n" % weight
		
	# 3. 读取背包加成（取代了以前臃肿的 ModifierData）
	var extra_weight = data.get("附加负重", 0)
	if extra_weight > 0:
		stats_text += "提供负重上限: +%d\n" % extra_weight
		
	var extra_slots = data.get("附加槽位", 0)
	if extra_slots > 0:
		stats_text += "提供额外储物格: +%d\n" % extra_slots
		
	# 4. 读取燃料属性（生存游戏硬核细节显示）
	var fuel = data.get("燃烧时长", 0.0)
	if fuel > 0:
		stats_text += "可燃烧时长: %d 分钟\n" % int(fuel)
			
	stats_label.text = stats_text
	stats_label.visible = stats_text.length() > 0
	
	current_mode = TooltipMode.CARD # 标记为卡牌模式
	is_showing = true
	tooltip_instance.show()
	_update_position()

# --- 模式 2：顶部栏专属提示框 (新增) ---
func show_topbar_tooltip(target: Control, title: String, desc: String):
	name_label.text = title
	desc_label.text = desc
	stats_label.hide() # 顶部提示框不需要显示卡牌属性
	
	target_ui_node = target
	current_mode = TooltipMode.TOPBAR # 标记为顶部栏模式
	is_showing = true
	tooltip_instance.show()
	# 瞬间更新位置，不用平滑移动
	_update_position(true)

func hide_tooltip():
	is_showing = false
	current_card = null
	target_ui_node = null
	if is_instance_valid(tooltip_instance):
		tooltip_instance.hide()

# --- 核心：智能位置计算 ---
func _update_position(instant: bool = false):
	var target_pos = Vector2.ZERO
	var screen_size = tooltip_instance.get_viewport_rect().size
	var tip_size = tooltip_instance.size
	
	if current_mode == TooltipMode.CARD:
		# 卡牌的跟随鼠标避让逻辑
		var mouse_pos = tooltip_instance.get_global_mouse_position()
		var margin_x = 20
		var margin_y = 20
		target_pos.x = screen_size.x - tip_size.x - margin_x
		target_pos.y = margin_y 
		if mouse_pos.x > (screen_size.x / 2.0) and mouse_pos.y < (screen_size.y / 2.0):
			target_pos.y = screen_size.y - tip_size.y - margin_y
			
	elif current_mode == TooltipMode.TOPBAR and is_instance_valid(target_ui_node):
		# 顶部栏的“吸附正下方”逻辑
		var node_pos = target_ui_node.global_position
		var node_size = target_ui_node.size
		# X 轴居中对齐目标节点
		target_pos.x = node_pos.x + (node_size.x / 2.0) - (tip_size.x / 2.0)
		# Y 轴紧贴目标节点下方 (10 是像素间距)
		target_pos.y = node_pos.y + node_size.y + 10
		
		# 防止提示框超出屏幕左右边缘
		target_pos.x = clamp(target_pos.x, 10, screen_size.x - tip_size.x - 10)

	var current_pos = tooltip_instance.global_position
	if current_pos == Vector2.ZERO or instant: 
		tooltip_instance.global_position = target_pos
	else:
		tooltip_instance.global_position = current_pos.lerp(target_pos, 0.2)
