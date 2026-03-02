# stat_list_item.gd
extends PanelContainer

signal item_selected(stat_key: String)
signal pin_toggled(stat_key: String, is_pinned: bool)

@onready var pin_toggle = $MarginContainer/HBoxContainer/PinToggle
@onready var stat_widget = $MarginContainer/HBoxContainer/StatWidget # 抓取刚嵌进来的组件
@onready var select_btn = $MarginContainer/HBoxContainer/SelectButton

var current_stat_key: String = ""

func _ready():
	pin_toggle.toggled.connect(_on_pin_toggled)
	select_btn.pressed.connect(func(): emit_signal("item_selected", current_stat_key))

# 初始化配置
func setup(stat_key: String, info: Dictionary, is_pinned: bool):
	current_stat_key = stat_key
	
	var c1 = info.get("top_color", Color("f2b544"))
	var c2 = info.get("bottom_color", Color("d58745"))
	var icon = info.get("icon", null)
	
	# 透传数据让进度条自己初始化
	stat_widget.setup(info["name"], stat_key, icon, c1, c2)
	
	# ==========================================
	# 【核心解封】：强行打开这个实例内部的文字显示！
	# ==========================================
	stat_widget.title_label.show()
	stat_widget.percent_label.show()
	
	# 处理复选框锁定逻辑
	if info["is_core"]:
		pin_toggle.button_pressed = true
		pin_toggle.disabled = true
	else:
		pin_toggle.button_pressed = is_pinned
		pin_toggle.disabled = false

# 【极度舒适】：你甚至可以把原来的 update_value() 函数整个删掉！
# 因为 StatWidget 内部已经在 _ready() 里监听了 SurvivalManager.stats_updated 信号，它会自己刷新数值！

func _on_pin_toggled(button_pressed: bool):
	emit_signal("pin_toggled", current_stat_key, button_pressed)
