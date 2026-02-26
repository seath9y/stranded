extends PanelContainer

# === 节点引用更新 ===
@onready var season_icon: TextureRect = $MarginContainer/MainLayout/LeftWing/SeasonIcon
@onready var weather_icon: TextureRect = $MarginContainer/MainLayout/LeftWing/WeatherIcon

# 新增的 Buff 列表容器
@onready var buff_list: HBoxContainer = $MarginContainer/MainLayout/BuffScroll/BuffList

@onready var date_label: Label = $MarginContainer/MainLayout/RightWing/DateLabel
@onready var time_label: Label = $MarginContainer/MainLayout/RightWing/TimeLabel
@onready var location_icon: TextureRect = $MarginContainer/MainLayout/RightWing/LocationIcon
@onready var location_label: Label = $MarginContainer/MainLayout/RightWing/LocationLabel

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
	
	# 测试：生成 10 个测试 Buff 图标塞进列表，你可以用鼠标滚轮看看滚动效果！
	_test_spawn_buffs()

# === 新增：动态生成 Buff 图标测试 ===
func _test_spawn_buffs() -> void:
	for i in range(20):
		var test_icon = TextureRect.new()
		# 这里用天气图标临时充当 Buff 图标做测试
		test_icon.texture = weather_icon.texture 
		test_icon.custom_minimum_size = Vector2(32, 32) # 固定图标大小
		test_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		test_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# 绑定动态生成的提示框事件
		test_icon.mouse_entered.connect(func():
			TooltipManager.show_topbar_tooltip(test_icon, "测试状态 " + str(i+1), "这是一个被附加的持续性状态。")
		)
		test_icon.mouse_exited.connect(_hide_tooltip)
		
		buff_list.add_child(test_icon)
	for i in range(20):
		var test_icon = TextureRect.new()
		# 这里用天气图标临时充当 Buff 图标做测试
		test_icon.texture = season_icon.texture 
		test_icon.custom_minimum_size = Vector2(32, 32) # 固定图标大小
		test_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		test_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# 绑定动态生成的提示框事件
		test_icon.mouse_entered.connect(func():
			TooltipManager.show_topbar_tooltip(test_icon, "测试状态 " + str(i+1), "这是一个被附加的持续性状态。")
		)
		test_icon.mouse_exited.connect(_hide_tooltip)
		
		buff_list.add_child(test_icon)
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
	TooltipManager.show_topbar_tooltip(location_icon, "当前区域: 海滩", "海滩海滩海滩海滩海滩。")
func _hide_tooltip() -> void:
	TooltipManager.hide_tooltip()
