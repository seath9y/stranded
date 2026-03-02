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
@export var weight_progress_bar: ProgressBar     # 底部背包进度条
@export var weight_value_label: Label            # 底部背包数字 Label

# 定义左侧状态栏需要动态染色的几种颜色
const COLOR_NORMAL = Color("e0a652")    # 正常的黄色
const COLOR_WARNING = Color("d95763")   # 快满时的警告色 (橙红)
const COLOR_OVERLOAD = Color("ac3232")  # 溢出超重时的危险色 (深红)

func _ready():
	# 1. 监听大管家发出的负重数据
	InventoryManager.weight_changed.connect(_on_weight_changed)
	
	# 【核心修复】：2. 游戏启动时，主动去大管家那里拉取一次最新数据，保证初始不为空！
	var initial_data = {
		"total_current": InventoryManager.current_weight,
		"total_max": InventoryManager.max_weight_capacity + InventoryManager.current_strength_bonus,
		"status": "normal",
		"backpack_current": InventoryManager._current_backpack_weight,
		"backpack_max": InventoryManager.backpack_capacity
	}
	_on_weight_changed(initial_data)

func _on_weight_changed(data: Dictionary):
	# ==========================================
	# A. 更新左侧总状态栏 (包含动态变色与平滑动画)
	# ==========================================
	if total_weight_bar and total_weight_label:
		total_weight_bar.max_value = data.total_max
		
		# 【优化】：加入丝滑的过渡动画！
		var tween = create_tween()
		tween.tween_property(total_weight_bar, "value", data.total_current, 0.3).set_trans(Tween.TRANS_SINE)
		
		total_weight_label.text = "%d / %d" % [data.total_current, data.total_max]
		
		# 根据总负重比例进行动态染色
		var ratio = float(data.total_current) / float(data.total_max)
		
		if ratio > 1.0:
			total_weight_bar.tint_progress = COLOR_OVERLOAD
			total_weight_label.add_theme_color_override("font_color", Color.WHITE)
		elif ratio >= 0.8:
			total_weight_bar.tint_progress = COLOR_WARNING
			total_weight_label.add_theme_color_override("font_color", Color.WHITE) 
		else:
			total_weight_bar.tint_progress = COLOR_NORMAL
			total_weight_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		# 【防呆提示】：如果你忘了在编辑器里赋值，这里会疯狂报错提醒你！
		printerr("⚠️ 警告：左侧负重 UI 节点为空！请点击 MainUI 节点，在右侧检查器中拖入对应节点！")

	# ==========================================
	# B. 更新底部背包状态栏
	# ==========================================
	if bottom_weight_panel and weight_progress_bar and weight_value_label:
		if data.backpack_max <= 0:
			bottom_weight_panel.visible = false
		else:
			bottom_weight_panel.visible = true
			weight_progress_bar.max_value = data.backpack_max
			
			var target_val = min(data.backpack_current, data.backpack_max)
			# 【优化】：底部背包也加入平滑动画
			var bp_tween = create_tween()
			bp_tween.tween_property(weight_progress_bar, "value", target_val, 0.3).set_trans(Tween.TRANS_SINE)
			
			weight_value_label.text = "%d / %d" % [data.backpack_current, data.backpack_max]
			weight_value_label.add_theme_color_override("font_color", Color.WHITE)
