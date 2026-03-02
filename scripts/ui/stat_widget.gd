extends Control 

@export var current_stat_key: String = ""
@export var custom_icon: Texture2D = null

# 【新增】：暴露上下两部分的颜色！
@export var top_color: Color = Color(1, 1, 1, 1)    # 颜色 0
@export var bottom_color: Color = Color(0.8, 0.8, 0.8, 1) # 颜色 1

@onready var icon_rect = $TextureRect
@onready var progress_bar = $TextureProgressBar
@onready var title_label = $TextureProgressBar/Label
@onready var percent_label = $TextureProgressBar/Label2

func _ready():
	SurvivalManager.connect("stats_updated", _on_stats_updated)
	
	if current_stat_key != "" and SurvivalManager.all_stats_info.has(current_stat_key):
		title_label.text = SurvivalManager.all_stats_info[current_stat_key]["name"]
	
	if custom_icon != null and icon_rect != null:
		icon_rect.texture = custom_icon
		
	# 【执行渐变色渲染】
	_apply_gradient_colors(top_color, bottom_color)
		
	_on_stats_updated()

# 供代码动态生成的条使用 (接收两个颜色)
func setup(display_name: String, stat_key: String, dynamic_icon: Texture2D = null, c1: Color = Color(1, 0.725, 0.294), c2: Color = Color(0.835, 0.529, 0.271)):
	title_label.text = display_name
	current_stat_key = stat_key
	
	if dynamic_icon != null and icon_rect != null:
		icon_rect.texture = dynamic_icon
		
	# 【执行渐变色渲染】
	_apply_gradient_colors(c1, c2)
		
	_on_stats_updated()

# 【核心黑科技】：安全修改渐变颜色
func _apply_gradient_colors(c1: Color, c2: Color):
	if progress_bar == null or progress_bar.texture_progress == null:
		return
		
	# 1. 克隆纹理和渐变对象 (Duplicate)，防止所有进度条变成同一个颜色
	var new_tex = progress_bar.texture_progress.duplicate()
	if "gradient" in new_tex and new_tex.gradient != null:
		var new_grad = new_tex.gradient.duplicate()
		
		# 2. 修改你截图里 Gradient 的那两个颜色 (索引 0 和 1)
		if new_grad.colors.size() >= 2:
			new_grad.set_color(0, c1)
			new_grad.set_color(1, c2)
			
		new_tex.gradient = new_grad
		
	# 3. 把新纹理重新贴给进度条
	progress_bar.texture_progress = new_tex

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
