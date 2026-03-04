# ================= toast_message.gd =================
extends PanelContainer
class_name ToastMessage

@onready var icon_rect = $HBoxContainer/Icon
@onready var text_label = $HBoxContainer/TextLabel

# 供外部直接调用初始化
func setup(text: String, icon_tex: Texture2D, color: Color) -> void:
	# 确保节点已加载
	if not is_node_ready():
		await ready
		
	text_label.text = text
	text_label.add_theme_color_override("font_color", color)
	
	if icon_tex != null:
		icon_rect.texture = icon_tex
		icon_rect.show()
	else:
		icon_rect.hide()

	# 🌟 核心生命周期：淡入 -> 停留 -> 淡出 -> 销毁
	modulate.a = 0.0 # 初始透明
	var tween = create_tween()
	# 1. 0.2秒快速淡入
	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
	# 2. 停留 2.5 秒供玩家阅读
	tween.tween_interval(2.5)
	# 3. 0.3秒淡出
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	# 4. 彻底销毁节点，释放内存
	tween.tween_callback(self.queue_free)
