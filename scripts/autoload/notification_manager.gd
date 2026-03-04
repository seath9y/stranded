# ================= notification_manager.gd =================
extends CanvasLayer

enum MsgType { NORMAL, WARNING, DANGER }

# 【修改 1】：默认文字改成深棕黑色，在浅色底上极其舒适且不刺眼
const COLOR_NORMAL = Color("#2c2724") 
# 【修改 2】：警告色改成沉稳的暗焦橙色，去掉了原本黄色的廉价荧光感
const COLOR_WARNING = Color("#b85d19") 
# 【修改 3】：危险色稍微调暗，变成深邃的暗血红，压迫感更强
const COLOR_DANGER = Color("#a32828")

var toast_scene = preload("res://scenes/ui/toast_message.tscn")
var toast_container: VBoxContainer

func _ready():
	# 将自己设为最高层级，永远盖在最上面
	layer = 100 
	
	# 代码动态创建一个 VBoxContainer 作为右下角的排队容器
	toast_container = VBoxContainer.new()
	add_child(toast_container)
	
	# 设置锚点为右下角 (Bottom Right)
	toast_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	# 偏移量，离屏幕边缘留点空隙，别贴太死 (根据你的画面比例微调)
	toast_container.offset_right = -20 
	toast_container.offset_bottom = -20
	
	# 让新出的消息从下往上顶
	toast_container.alignment = BoxContainer.ALIGNMENT_END 
	# 鼠标穿透，绝对不能挡住玩家的点击
	toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

# ==========================================
# 🌟 全局调用的超级接口
# ==========================================
func show_toast(text: String, icon: Texture2D = null, type: MsgType = MsgType.NORMAL) -> void:
	if not is_instance_valid(toast_container): return
	
	var toast = toast_scene.instantiate()
	toast_container.add_child(toast)
	
	# 判定颜色
	var text_color = COLOR_NORMAL
	if type == MsgType.WARNING:
		text_color = COLOR_WARNING
	elif type == MsgType.DANGER:
		text_color = COLOR_DANGER
		
	# 如果同时涌入太多消息，防止霸屏（最多保留 5 条，老的直接杀掉）
	if toast_container.get_child_count() > 5:
		toast_container.get_child(0).queue_free()
		
	toast.setup(text, icon, text_color)
