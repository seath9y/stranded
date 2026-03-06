extends Node

@onready var area_zone = $UI/MainUI/MainHBox/MarginContainer/RightPanel/SpecialRow/PanelContainer/VBoxContainer/PanelContainer/AreaZone 
@onready var ground_zone = $UI/MainUI/MainHBox/MarginContainer/RightPanel/SpecialRow/PanelContainer3/VBoxContainer/PanelContainer/GroundZone  
@onready var player_zone = $UI/MainUI/MainHBox/MarginContainer/RightPanel/TabContainer3/ScrollContainer/player/PlayerZone   

func _ready():
	call_deferred("spawn_initial_items")

func spawn_initial_items():
	print("--- 开始生成测试物品 ---")
	
	# 【终极清爽】：直接向大管家要数据字典来生成！
	#area_zone.add_item(ItemDB.get_item_base("营火"))
	#area_zone.add_item(ItemDB.get_item_base("火堆"))
	var fish_data = ItemDB.get_item_base("鱼")
	var axe_data = ItemDB.get_item_base("石斧")
	ground_zone.add_item(fish_data, 1, {"freshness": 10}) # 快发臭的鱼
	player_zone.add_item(fish_data, 1, {"freshness": 60}) # 正常的鱼
	ground_zone.add_item(fish_data, 1, {"freshness": 100}) # 刚钓上来的鱼
	ground_zone.add_item(ItemDB.get_item_base("木头"))
	ground_zone.add_item(ItemDB.get_item_base("大石块"))
	ground_zone.add_item(ItemDB.get_item_base("长木棍"))
	ground_zone.add_item(ItemDB.get_item_base("藤条"))
	ground_zone.add_item(ItemDB.get_item_base("木头"))
	
	ground_zone.add_item(ItemDB.get_item_base("小树枝"))
	ground_zone.add_item(ItemDB.get_item_base("小石头"))
	ground_zone.add_item(axe_data, 1, {"durability": 10}) # 破破烂烂的斧子
	ground_zone.add_item(axe_data, 1, {"durability": 23}) # 破破烂烂的斧子
	ground_zone.add_item(axe_data, 1, {"durability": 100}) # 破破烂烂的斧子
	player_zone.add_item(ItemDB.get_item_base("椰子"))
	player_zone.add_item(ItemDB.get_item_base("椰子"))
	player_zone.add_item(ItemDB.get_item_base("生肉"))
	player_zone.add_item(ItemDB.get_item_base("草编背篓"))
		
	print("--- 测试物品生成完毕 ---")
