extends PanelContainer

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


# === 【新增】：真正的动态生成 Buff 图标 ===
func _on_status_changed(active_status_ids: Array) -> void:
	# 1. 每次更新前，无情地清空旧图标，防止无限叠加
	for child in buff_list.get_children():
		child.queue_free()
		
	# 2. 遍历大脑传过来的最新状态列表
	for status_id in active_status_ids:
		var effect_data = StatusManager.EFFECTS_DATABASE.get(status_id)
		if effect_data:
			var buff_icon = TextureRect.new()
			
			# 安全加载图标：如果你还没画好，就临时用天气图标顶替一下，防止报错黑块
			if "icon" in effect_data and ResourceLoader.exists(effect_data.icon):
				buff_icon.texture = load(effect_data.icon)
			else:
				buff_icon.texture = weather_icon.texture 
				buff_icon.modulate = Color(1, 0.5, 0.5) # 如果用占位图，稍微染点红色区分一下
				
			buff_icon.custom_minimum_size = Vector2(32, 32)
			buff_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			buff_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# 提取文本数据，准备给 Tooltip 用
			var buff_name = effect_data.get("name", "未知异常")
			var buff_desc = effect_data.get("description", "状态不明。")
			
			# 绑定动态生成的提示框事件
			buff_icon.mouse_entered.connect(func():
				TooltipManager.show_topbar_tooltip(buff_icon, buff_name, buff_desc)
			)
			buff_icon.mouse_exited.connect(_hide_tooltip)
			
			# 塞入列表！
			buff_list.add_child(buff_icon)

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
