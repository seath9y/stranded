# Main.gd (挂在Main节点上)
extends Node

@onready var time_label = $UI/MainUI/TopBarMargin/TopBarHBox/LeftGroup/TimeLabel
@onready var day_label = $UI/MainUI/TopBarMargin/TopBarHBox/LeftGroup/DayLabel   # 如果你分开显示
@onready var season_label = $UI/MainUI/TopBarMargin/TopBarHBox/LeftGroup/SeasonLabel
@onready var location_label = $UI/MainUI/TopBarMargin/TopBarHBox/CenterGroup/LocationLabel
@onready var weather_label = $UI/MainUI/TopBarMargin/TopBarHBox/CenterGroup/WeatherLabel

# --- 1. 导出物品资源，方便在编辑器里拖拽赋值 ---
@export_group("测试物品")
@export var item_tree: ItemData
@export var item_box: ItemData
@export var item_i1: ItemData
@export var item_i2: ItemData
@export var item_i3: ItemData
@export var item_axe: ItemData
@export var item_i4: ItemData

# --- 2. 获取三个区域的节点引用 ---
# 注意：这里的路径 $VBoxContainer/RegionZone 需要改成你实际的节点路径！
@onready var area_zone = $UI/MainUI/MainHBox/MarginContainer/RightPanel/SpecialRow/PanelContainer/VBoxContainer/PanelContainer/AreaZone   # 1栏 地区
@onready var ground_zone = $UI/MainUI/MainHBox/MarginContainer/RightPanel/SpecialRow/PanelContainer2/TabContainer2/GroundZone   # 2栏 地点
@onready var player_zone = $UI/MainUI/MainHBox/MarginContainer/RightPanel/TabContainer3/ScrollContainer/player/PlayerZone   # 3栏 人物


func _ready():
	TimeManager.time_advanced.connect(_on_time_advanced)
	# 初始化显示
	_on_time_advanced(TimeManager.current_time, TimeManager.current_day, TimeManager.current_season)
	
	# 游戏开始时，稍微延迟一下等待 UI 节点全部加载完毕
	call_deferred("spawn_initial_items")

func spawn_initial_items():
	print("--- 开始生成测试物品 ---")
	
	# 1. 在地区栏生成：1棵树，1个箱子
	if item_tree:
		area_zone.add_item(item_tree)
	if item_box:
		area_zone.add_item(item_box)
		
	# 2. 在地点栏生成：2个椰子 (测试同类物品并排)
	if item_i1:
		ground_zone.add_item(item_i1)
		ground_zone.add_item(item_i1)
	if item_i2:
		ground_zone.add_item(item_i2)
		ground_zone.add_item(item_i2)
		player_zone.add_item(item_i2)
	if item_i3:
		ground_zone.add_item(item_i3)
		player_zone.add_item(item_i3)
	## 3. 在人物栏生成：1把石斧
	if item_axe:
		player_zone.add_item(item_axe)
		player_zone.add_item(item_axe)
		player_zone.add_item(item_axe)
		ground_zone.add_item(item_i4)
		
	print("--- 测试物品生成完毕 ---")


func _on_time_advanced(new_time: float, new_day: int, new_season: String):
	time_label.text = TimeManager.get_time_string()  # 复用之前写的格式化函数
	day_label.text = "Day " + str(new_day)
	season_label.text = new_season.capitalize()
	# 其他标签可以先不动


func _on_button_pressed() -> void:
	TimeManager.advance_time(60)
	pass # Replace with function body.
