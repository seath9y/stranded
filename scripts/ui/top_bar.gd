extends PanelContainer
# top_bar.gd (核心修改部分)
# === 节点引用更新 ===
@onready var season_icon: TextureRect = $MarginContainer/MainLayout/RightWing/SeasonIcon
@onready var weather_icon: TextureRect = $MarginContainer/MainLayout/RightWing/WeatherIcon
@onready var buff_list: HBoxContainer = $MarginContainer/MainLayout/BuffScroll/BuffList
@onready var date_label: Label = $MarginContainer/MainLayout/LeftWing/DateLabel
@onready var time_label: Label = $MarginContainer/MainLayout/LeftWing/TimeLabel
@onready var location_icon: TextureRect = $MarginContainer/MainLayout/LeftWing/LocationIcon
@onready var location_label: Label = $MarginContainer/MainLayout/LeftWing/LocationLabel

func _ready() -> void:
	TimeManager.time_advanced.connect(_on_time_advanced)
	
	season_icon.mouse_entered.connect(_on_season_hovered)
	season_icon.mouse_exited.connect(_hide_tooltip)
	weather_icon.mouse_entered.connect(_on_weather_hovered)
	weather_icon.mouse_exited.connect(_hide_tooltip)
	location_icon.mouse_entered.connect(_on_location_hovered)
	location_icon.mouse_exited.connect(_hide_tooltip)
	location_label.mouse_entered.connect(_on_location_hovered)
	location_label.mouse_exited.connect(_hide_tooltip)
	
	_on_time_advanced(TimeManager.current_time, TimeManager.current_day, TimeManager.current_season)
	location_label.text = "海滩"
	
	# === 【新增】：监听 StatusManager 的信号 ===
	StatusManager.status_changed.connect(_on_status_changed)
	# 游戏刚启动时，主动拉取一次当前状态（防止已经有状态但UI没更新）
	_on_status_changed(StatusManager.active_effects.keys())
var emergency_tweens: Dictionary = {}

func _on_status_changed(active_status_ids: Array) -> void:
	# 1. 每次更新前，无情地清空旧图标，防止无限叠加
	for child in buff_list.get_children():
		child.queue_free()
		
	# 【核心防御】：杀掉所有正在跑的旧动画，防止内存泄漏和鬼畜闪烁
	for t in emergency_tweens.values():
		if t and t.is_valid(): t.kill()
	emergency_tweens.clear()
		
	# 2. 遍历大脑传过来的最新状态列表
	for status_id in active_status_ids:
		var effect_data = StatusManager.EFFECTS_DATABASE.get(status_id)
		if effect_data:
			var buff_icon = TextureRect.new()
			
			# --- 视觉基础配置 ---
			if "icon" in effect_data and ResourceLoader.exists(effect_data.icon):
				buff_icon.texture = load(effect_data.icon)
			else:
				buff_icon.texture = weather_icon.texture 
				buff_icon.modulate = Color(1, 0.5, 0.5) 
				
			buff_icon.custom_minimum_size = Vector2(32, 32)
			buff_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			buff_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# 【必须添加的属性】：设置缩放中心点为 16x16 (即 32x32 的正中心)
			# 否则图标放大缩小时会以左上角为基准，看起来非常怪异
			buff_icon.pivot_offset = Vector2(16, 16)
			
			# --- 绑定 Tooltip 逻辑 (完全保留你的心血) ---
			var buff_name = effect_data.get("name", "未知异常")
			var buff_desc = effect_data.get("description", "状态不明。")
			
			buff_icon.mouse_entered.connect(func():
				TooltipManager.show_topbar_tooltip(buff_icon, buff_name, buff_desc)
			)
			buff_icon.mouse_exited.connect(_hide_tooltip)
			
			# 塞入列表！
			buff_list.add_child(buff_icon)
			
			# ==========================================
			# 🌟 动画分级调度中心 (新增)
			# ==========================================
			var is_emergency = effect_data.get("is_emergency", false)
			var tween = create_tween()
			
			if is_emergency:
				# 【极危状态：无限心跳放大缩小】
				tween.set_loops() # 无限循环
				tween.tween_property(buff_icon, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_SINE)
				tween.tween_property(buff_icon, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_SINE)
				tween.tween_interval(0.2) # 心跳停顿感
				emergency_tweens[status_id] = tween # 记录在案，方便随时销毁
			else:
				# 【普通状态：出现时只跳动 2 次】
				tween.set_loops(2) # 只循环 2 次
				# 向上跳起 5 个像素
				tween.tween_property(buff_icon, "position:y", -5.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				# 落地回正
				tween.tween_property(buff_icon, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

# === 【新增】：真正的动态生成 Buff 图标 ===
#func _on_status_changed(active_status_ids: Array) -> void:
	## 1. 每次更新前，无情地清空旧图标，防止无限叠加
	#for child in buff_list.get_children():
		#child.queue_free()
		#
	## 2. 遍历大脑传过来的最新状态列表
	#for status_id in active_status_ids:
		#var effect_data = StatusManager.EFFECTS_DATABASE.get(status_id)
		#if effect_data:
			#var buff_icon = TextureRect.new()
			#
			## 安全加载图标：如果你还没画好，就临时用天气图标顶替一下，防止报错黑块
			#if "icon" in effect_data and ResourceLoader.exists(effect_data.icon):
				#buff_icon.texture = load(effect_data.icon)
			#else:
				#buff_icon.texture = weather_icon.texture 
				#buff_icon.modulate = Color(1, 0.5, 0.5) # 如果用占位图，稍微染点红色区分一下
				#
			#buff_icon.custom_minimum_size = Vector2(32, 32)
			#buff_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			#buff_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			#
			## 提取文本数据，准备给 Tooltip 用
			#var buff_name = effect_data.get("name", "未知异常")
			#var buff_desc = effect_data.get("description", "状态不明。")
			#
			## 绑定动态生成的提示框事件
			#buff_icon.mouse_entered.connect(func():
				#TooltipManager.show_topbar_tooltip(buff_icon, buff_name, buff_desc)
			#)
			#buff_icon.mouse_exited.connect(_hide_tooltip)
			#
			## 塞入列表！
			#buff_list.add_child(buff_icon)

# === 时间系统回调 ===
func _on_time_advanced(current_time: float, current_day: int, current_season: String) -> void:
	var hours = int(current_time / 60)
	var mins = int(current_time) % 60
	date_label.text = "Day %d" % current_day
	time_label.text = "%02d:%02d" % [hours, mins]

# === 提示框触发方法 ===
func _on_season_hovered() -> void:
	TooltipManager.show_topbar_tooltip(season_icon, "春季", "万物复苏，体温下降速度减缓。")
func _on_weather_hovered() -> void:
	TooltipManager.show_topbar_tooltip(weather_icon, "晴朗", "微风和煦，此时外出非常安全。")
func _on_location_hovered() -> void:
	TooltipManager.show_topbar_tooltip(location_icon, "当前区域: 海滩", "可以捡到椰子和贝壳的初始区域。")
func _hide_tooltip() -> void:
	TooltipManager.hide_tooltip()
