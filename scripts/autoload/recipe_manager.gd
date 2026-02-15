extends Node
# 管理所有合成配方和研究解锁。
# 加载所有配方数据（从 data/recipes/ 下的 Resource 文件）。
# 记录玩家已解锁的配方（known_recipes）。
# 提供 try_craft_immediate(ingredients)：当玩家将物品 A 拖到物品 B 上时调用，检查是否可以直接合成。
# 提供 check_research(ingredients)：当玩家进行研究时调用，经过一段时间后检查该组合是否能解锁新配方。

var known_recipes: Array = []  # 存储已解锁的配方ID
var all_recipes: Dictionary = {}  # ID -> Recipe资源

func _ready():
	# 加载所有配方文件
	pass

func try_craft_immediate(ingredients: Array) -> bool:
	# 直接合成（拖拽时调用）
	# 如果有配方且已知，执行合成并返回true
	return false

func check_research(ingredients: Array) -> String:
	# 检查研究组合，返回发现的配方ID，否则返回空字符串
	return ""
