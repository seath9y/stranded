# Main.gd (挂在Main节点上)
extends Node

@onready var time_label = $UI/MainUI/TopBarMargin/TopBarHBox/LeftGroup/TimeLabel
@onready var day_label = $UI/MainUI/TopBarMargin/TopBarHBox/LeftGroup/DayLabel   # 如果你分开显示
@onready var season_label = $UI/MainUI/TopBarMargin/TopBarHBox/LeftGroup/SeasonLabel
@onready var location_label = $UI/MainUI/TopBarMargin/TopBarHBox/CenterGroup/LocationLabel
@onready var weather_label = $UI/MainUI/TopBarMargin/TopBarHBox/CenterGroup/WeatherLabel

func _ready():
	TimeManager.time_advanced.connect(_on_time_advanced)
	# 初始化显示
	_on_time_advanced(TimeManager.current_time, TimeManager.current_day, TimeManager.current_season)

func _on_time_advanced(new_time: float, new_day: int, new_season: String):
	time_label.text = TimeManager.get_time_string()  # 复用之前写的格式化函数
	day_label.text = "Day " + str(new_day)
	season_label.text = new_season.capitalize()
	# 其他标签可以先不动

# 测试用
func _on_button_2_pressed() -> void:
	TimeManager.advance_time(24, "h")	
	pass # Replace with function body.


func _on_button_pressed() -> void:
	TimeManager.advance_time(60)
	pass # Replace with function body.
