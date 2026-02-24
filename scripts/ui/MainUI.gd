extends CanvasLayer

# ==========================================
# 1. 左侧总状态栏引用 (Total Weight)
# ==========================================
@export_group("左侧总状态栏")
@export var total_weight_bar: TextureProgressBar # 左侧总负重进度条
@export var total_weight_label: Label            # 左侧总负重文本

# ==========================================
# 2. 底部背包负重栏引用 (Bottom Backpack Weight)
# ==========================================
@export_group("底部背包状态栏")
@export var bottom_weight_panel: Container       # 底部负重栏 (HBoxContainer)
@export var weight_progress_bar: ProgressBar # 底部背包进度条
#@export var weight_progress_bar: TextureProgressBar # 底部背包进度条
@export var weight_value_label: Label            # 底部背包数字 Label

# 定义左侧状态栏需要动态染色的几种颜色
const COLOR_NORMAL = Color("e0a652")    # 正常的黄色
const COLOR_WARNING = Color("d95763")   # 快满时的警告色 (橙红)
const COLOR_OVERLOAD = Color("ac3232")  # 溢出超重时的危险色 (深红)

func _ready():
	# 监听大管家发出的负重数据
	PlayerManager.weight_changed.connect(_on_weight_changed)
	
	# 初始化：默认隐藏底部负重栏
	if bottom_weight_panel:
		bottom_weight_panel.visible = false

func _on_weight_changed(data: Dictionary):
	# ==========================================
	# A. 更新左侧总状态栏 (包含动态变色逻辑)
	# ==========================================
	if total_weight_bar and total_weight_label:
		total_weight_bar.max_value = data.total_max
		total_weight_bar.value = data.total_current
		total_weight_label.text = "%d / %d" % [data.total_current, data.total_max]
		
		# 根据总负重比例进行动态染色
		var ratio = float(data.total_current) / float(data.total_max)
		
		if ratio > 1.0:
			# 溢出：红色
			total_weight_bar.tint_progress = COLOR_OVERLOAD
			total_weight_label.add_theme_color_override("font_color", COLOR_OVERLOAD)
		elif ratio >= 0.8:
			# 警告：橙色
			total_weight_bar.tint_progress = COLOR_WARNING
			total_weight_label.add_theme_color_override("font_color", Color.WHITE) 
		else:
			# 正常：黄色
			total_weight_bar.tint_progress = COLOR_NORMAL
			total_weight_label.add_theme_color_override("font_color", Color.WHITE)

	# ==========================================
	# B. 更新底部背包状态栏 (固定颜色，进度条最高100%)
	# ==========================================
	if bottom_weight_panel and weight_progress_bar and weight_value_label:
		# 1. 控制显隐：如果没有装备背包，隐藏底部栏
		if data.backpack_max <= 0:
			bottom_weight_panel.visible = false
		else:
			# 2. 如果有背包，显示底部栏并更新数值
			bottom_weight_panel.visible = true
			weight_progress_bar.max_value = data.backpack_max
			
			# 【核心机制】：利用 min() 强制让进度条的值不会超过最大容量（视觉上最多满管）
			weight_progress_bar.value = min(data.backpack_current, data.backpack_max)
			
			# 【核心机制】：文本依然老老实实显示真实重量，让玩家知道装了多少
			weight_value_label.text = "%d / %d" % [data.backpack_current, data.backpack_max]
			
			# 【核心机制】：永远保持正常的颜色，不参与变色警告
			#weight_progress_bar.tint_progress = COLOR_NORMAL
			weight_value_label.add_theme_color_override("font_color", Color.WHITE)
