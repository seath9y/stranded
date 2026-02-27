extends PanelContainer

# === 节点引用 ===
# ⚠️ 注意：请确保这里的路径和你实际的节点名字一模一样
@onready var explore_btn: Button = $MarginContainer/ActionList/ExploreButton
@onready var rest_btn: Button = $MarginContainer/ActionList/RestButton  # 新增的休息按钮
@onready var sleep_btn: Button = $MarginContainer/ActionList/SleepButton
@onready var craft_btn: Button = $MarginContainer/ActionList/CraftButton
@onready var move_btn: Button = $MarginContainer/ActionList/MoveButton

# 🌟 极其重要：导出一个变量插槽，用来接收中央的那个大面板！
@export var crafting_panel: Control

# 记录当前手册是不是打开的状态
var is_crafting_open: bool = false

func _ready() -> void:
	# 绑定点击事件
	explore_btn.pressed.connect(_on_explore_pressed)
	rest_btn.pressed.connect(_on_rest_pressed)
	sleep_btn.pressed.connect(_on_sleep_pressed)
	craft_btn.pressed.connect(_on_craft_pressed)
	move_btn.pressed.connect(_on_move_pressed)
	
	# 游戏刚开始时，确保制作面板是完全透明且隐藏的
	if crafting_panel:
		crafting_panel.hide()
		crafting_panel.modulate.a = 0.0

# === 基础按钮交互 ===
func _on_explore_pressed() -> void:
	TimeManager.advance_time(30)
	print("【探索】按钮被点击")

func _on_rest_pressed() -> void:
	print("【休息】按钮被点击：原地休息，消耗时间恢复体力！")

func _on_sleep_pressed() -> void:
	print("【睡觉】按钮被点击：准备弹出睡眠确认框！")
	
func _on_move_pressed() -> void:
	print("【睡觉】按钮被点击：准备弹出睡眠确认框！")

# === 🌟 核心动画：丝滑展开生存手册 ===
func _on_craft_pressed() -> void:
	# 防错机制：如果没有在检查器里连接面板，就在控制台报错提醒你
	if not crafting_panel:
		printerr("⚠️ 警告：你还没有把 CraftingPanel 拖进 ActionPanel 的右侧检查器里！")
		return
		
	# 切换开关状态
	is_crafting_open = !is_crafting_open
	
	# 创建一个补间动画 (Tween)
	var tween = create_tween()
	# 设置缓动曲线，让动画看起来有“呼吸感”而不是机械的匀速
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	if is_crafting_open:
		# 【打开动作】
		crafting_panel.show() # 先把节点显示出来
		# 用 0.25 秒的时间，把透明度 (modulate:a) 从 0.0 变到 1.0
		tween.tween_property(crafting_panel, "modulate:a", 1.0, 0.25)
	else:
		# 【关闭动作】
		# 用 0.2 秒的时间，把透明度降回 0.0
		tween.tween_property(crafting_panel, "modulate:a", 0.0, 0.2)
		# 透明度降完之后，彻底隐藏节点（防止挡住后面的鼠标点击）
		tween.tween_callback(crafting_panel.hide)
