class_name ItemState extends RefCounted

# 核心绑定
var id: String = ""

# 🌟 核心重构：用纯字典取代所有硬编码的单体变量（如 current_durability）
# 完美对接 Card 里的 stacked_states 数组里的单项字典
var dynamic_state: Dictionary = {}

# 快捷获取静态数据的方法
func get_base_data() -> Dictionary:
	return ItemDB.get_item_base(id)

# 获取带动态数据的展示用字典
func get_display_data() -> Dictionary:
	var data = get_base_data().duplicate() # 必须 duplicate，防止污染原始 DB
	
	# 将所有动态数据（耐久、腐烂等）一把抓，覆盖进展示字典
	for key in dynamic_state:
		# 兼容旧系统的中文 Key 映射（可选，根据你的 UI 读取习惯）
		if key == "durability":
			data["当前耐久"] = dynamic_state[key]
		else:
			data[key] = dynamic_state[key]
			
	return data

# 方便创建物品的静态工厂方法
static func create(item_id: String) -> ItemState:
	var new_item = ItemState.new()
	new_item.id = item_id
	
	var base = new_item.get_base_data()
	
	# 【彻底洗净】：纯字典判断！不再注入实体变量，而是写入动态字典
	if base.has("最大耐久") and base["最大耐久"] > 0:
		new_item.dynamic_state["durability"] = base["最大耐久"]
	if base.has("最大新鲜度") and base["最大新鲜度"] > 0:
		new_item.dynamic_state["freshness"] = base["最大新鲜度"]	
		
	return new_item
