extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var panel = get_node("StatusScroll")  # 根据实际路径调整
	# 创建一个 StyleBoxFlat
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.5)  # RGBA，最后一个参数0.5是透明度
	# 应用到 Panel 的覆盖样式
	panel.add_theme_stylebox_override("panel", style)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
