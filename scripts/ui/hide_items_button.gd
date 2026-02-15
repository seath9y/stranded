extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	var scroll = get_node("../ItemsScroll")  # 注意路径：按钮的父节点是 ItemsTitleBar，所以需要向上再向下
	# 实际路径可能是：../../ItemsScroll，取决于节点结构，我们使用绝对路径更稳妥
	# 为了简单，我们在脚本中通过 get_parent().get_parent().get_node("ItemsScroll") 获取
	# 但更好的方式是在编辑器中把 ItemsScroll 拖拽到脚本变量里。这里先演示路径方法
	var items_scroll = get_parent().get_node("ItemsScroll")
	if items_scroll:
		items_scroll.visible = not items_scroll.visible
		text = "显示" if items_scroll.visible else "隐藏"
