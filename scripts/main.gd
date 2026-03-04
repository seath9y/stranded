extends Node

@onready var area_zone = $UI/MainUI/MainHBox/MarginContainer/RightPanel/SpecialRow/PanelContainer/VBoxContainer/PanelContainer/AreaZone 
@onready var ground_zone = $UI/MainUI/MainHBox/MarginContainer/RightPanel/SpecialRow/PanelContainer3/VBoxContainer/PanelContainer/GroundZone  
@onready var player_zone = $UI/MainUI/MainHBox/MarginContainer/RightPanel/TabContainer3/ScrollContainer/player/PlayerZone   

func _ready():
	call_deferred("spawn_initial_items")

func spawn_initial_items():
	print("--- 开始生成测试物品 ---")
	
	# 【终极清爽】：直接向大管家要数据字典来生成！
	area_zone.add_item(ItemDB.get_item_base("木头"))
	#area_zone.add_item(ItemDB.get_item_base("营火"))
	#area_zone.add_item(ItemDB.get_item_base("火堆"))
	
	ground_zone.add_item(ItemDB.get_item_base("椰子"))
	ground_zone.add_item(ItemDB.get_item_base("椰子"))
	ground_zone.add_item(ItemDB.get_item_base("生肉"))
	ground_zone.add_item(ItemDB.get_item_base("草编背篓"))
	
	ground_zone.add_item(ItemDB.get_item_base("石斧"))
	ground_zone.add_item(ItemDB.get_item_base("石斧"))
	ground_zone.add_item(ItemDB.get_item_base("石斧"))
	ground_zone.add_item(ItemDB.get_item_base("石斧"))
		
	print("--- 测试物品生成完毕 ---")
