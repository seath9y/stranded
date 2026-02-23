# ================= res://scripts/data/ModifierData.gd =================
extends Resource
class_name ModifierData

# 定义所有的点数类型
enum StatType {
	手工辅助等级,  # 桌子、椅子提供的点数
	烹饪环境等级,  # 灶台、篝火提供的点数
	防雨等级,      # 雨衣、草棚提供的点数
	# 可以随时扩充...
}

@export var stat_type: StatType = StatType.手工辅助等级
## 这个物品能提供几点该属性？(通常是 1)
@export var points: int = 1
