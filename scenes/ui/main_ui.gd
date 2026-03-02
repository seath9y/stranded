# MainUI.gd (补充这部分代码)
extends Control
@export_group("生存手册面板")
@export var journal_panel: Control     # 拖入你刚安放的 SurvivalJournal 根节点
@export var status_area_btn: Button    # 拖入你刚建的透明按钮 StatusAreaButton
@export var close_journal_btn: Button

var is_journal_open: bool = false

func _ready():
	# ... 你原有的其他初始化代码 ...
	
	# 绑定左下角透明按钮的点击事件
	if status_area_btn:
		status_area_btn.pressed.connect(toggle_survival_journal)
	if close_journal_btn:
		close_journal_btn.pressed.connect(toggle_survival_journal)
# 监听全局快捷键
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_journal"):
		toggle_survival_journal()

# 核心呼出/关闭逻辑 (复用你最爱的 Tween 丝滑动画)
func toggle_survival_journal() -> void:
	if not journal_panel:
		printerr("致命错误：journal_panel 未赋值！")
		return

	is_journal_open = !is_journal_open
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if is_journal_open:
		journal_panel.show()
		# 用 0.25 秒淡入，体现像素风的干脆与现代 UI 的丝滑
		tween.tween_property(journal_panel, "modulate:a", 1.0, 0.25)
		# 如果你需要时间暂停，在这里加上：get_tree().paused = true
	else:
		tween.tween_property(journal_panel, "modulate:a", 0.0, 0.2)
		tween.tween_callback(journal_panel.hide)
		# 如果你有时间暂停，在这里恢复：get_tree().paused = false
