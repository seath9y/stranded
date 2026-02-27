extends Control 

@export var current_stat_key: String = ""
@export var custom_icon: Texture2D = null # 【新增】：一个能在编辑器里塞图标的插槽！

@onready var icon_rect = $TextureRect
@onready var title_label = $Label
@onready var progress_bar = $ProgressBar
@onready var percent_label = $ProgressBar/Label

func _ready():
	SurvivalManager.connect("stats_updated", _on_stats_updated)
	
	# 【修复“Label”不改变的问题】：
	# 如果是你在编辑器里手动摆放的条，它开局会自动去大管家那里查真名
	if current_stat_key != "" and SurvivalManager.all_stats_info.has(current_stat_key):
		title_label.text = SurvivalManager.all_stats_info[current_stat_key]["name"]
	
	# 【新增图标支持】：如果你在编辑器里给它塞了图标，就显示出来
	if custom_icon != null and icon_rect != null:
		icon_rect.texture = custom_icon
		
	_on_stats_updated()

# 供代码动态生成的条使用 (加入了图标参数)
func setup(display_name: String, stat_key: String, dynamic_icon: Texture2D = null):
	title_label.text = display_name
	current_stat_key = stat_key
	
	if dynamic_icon != null and icon_rect != null:
		icon_rect.texture = dynamic_icon
		
	_on_stats_updated()

func _on_stats_updated():
	if current_stat_key == "" or not SurvivalManager.all_stats_info.has(current_stat_key):
		return
		
	var current_val = SurvivalManager.get_current_stat_value(current_stat_key)
	var max_val = SurvivalManager.all_stats_info[current_stat_key]["max_val"]
	
	progress_bar.max_value = max_val
	progress_bar.value = current_val
	
	if max_val > 0:
		var percent = int((current_val / max_val) * 100)
		percent_label.text = str(percent) + "%"
