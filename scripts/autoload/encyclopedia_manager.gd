extends Node
# 管理游戏内的百科知识库。
# 加载所有百科条目（物品介绍、配方信息等）。
# 提供查询接口，按物品 ID、分类、标签获取条目信息。
# 当玩家解锁新物品或配方时，更新百科内容。
# 为百科 UI 提供数据支持。

var entries: Dictionary = {}  # 物品ID -> 百科条目

func get_entry(item_id: String) -> Dictionary:
	return entries.get(item_id, {})

func filter_by_category(category: String) -> Array:
	# 返回符合分类的物品ID列表
	return []
