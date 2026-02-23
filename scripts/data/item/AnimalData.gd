# ================= res://scripts/data/AnimalData.gd =================
extends ItemData
class_name AnimalData

enum AnimalType { 野生, 家畜, 宠物 }

@export_group("生物基础 (Living Base)")
@export var animal_type: AnimalType = AnimalType.野生
@export var max_health: int = 100
@export var hunger_rate: float = 1.0 # 饥饿消耗速度

@export_group("饮食与驯养 (Diet & Taming)")
## 动物能吃什么？(填入对应食物的 TagData，例如“食草”、“食肉”)
@export var diet_tags: Array[TagData] = []
## 是否可以被驯服
@export var is_tameable: bool = false
## 驯服需要的特定物品 (可选)
@export var taming_item: ItemData 

@export_group("产出 (Production)")
## 比如鸡产鸡蛋，牛产牛奶
@export var produce_item: ItemData
## 产出周期 (秒)
@export var produce_interval: float = 600.0
