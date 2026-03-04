# item_state.gd
class_name ItemState extends RefCounted

# 核心绑定
var id: String = ""

# 运行时动态数据 (比如耐久度、当前重量、里面装了什么)
var current_durability: int = -1

# 快捷获取静态数据的方法，不用每次都去查字典
func get_base_data() -> Dictionary:
	return ItemDB.get_item_base(id)

# 方便创建物品的静态工厂方法
static func create(item_id: String) -> ItemState:
	var new_item = ItemState.new()
	new_item.id = item_id
	
	# 如果这个物品有耐久，初始化它的耐久度
	var base = new_item.get_base_data()
	if base.get("has_durability", false):
		new_item.current_durability = base.get("max_durability", 100)
		
	return new_item
