# item_state.gd
class_name ItemState extends RefCounted

# 核心绑定
var id: String = ""

# 运行时动态数据 (比如耐久度、当前重量、里面装了什么)
var current_durability: int = -1

# 快捷获取静态数据的方法，不用每次都去查字典
func get_base_data() -> Dictionary:
	return ItemDB.get_item_base(id)

# 获取带动态数据的展示用字典（UI 读这个最方便）
func get_display_data() -> Dictionary:
	var data = get_base_data()
	# 把动态耐久也塞进展示字典，一把抓
	data["当前耐久"] = current_durability 
	return data

# 方便创建物品的静态工厂方法
static func create(item_id: String) -> ItemState:
	var new_item = ItemState.new()
	new_item.id = item_id
	
	var base = new_item.get_base_data()
	
	# 【彻底洗净】：纯字典判断！如果它配了最大耐久，就给它肉体注入耐久度！
	if base.has("最大耐久") and base["最大耐久"] > 0:
		new_item.current_durability = base["最大耐久"]
		
	return new_item
