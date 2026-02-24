extends ItemData
class_name EquipmentData

# 定义装备可以穿在哪个部位
enum EquipSlot {
	主武器,   # 刀、剑、斧（作为武器装备时）
	副手,     # 盾牌、火把
	头部,     # 草帽、头盔
	身体,     # 藤甲、皮衣
	背部,     # 背篓、大背包
	饰品      # 护身符等
}

@export_group("装备部位 (Equip Slot)")
## 决定这张卡牌能拖进人物界面的哪个专用装备槽
@export var equip_requirement: EquipmentData.EquipSlot = EquipmentData.EquipSlot.头部

@export_group("战斗属性加成 (Combat Stats)")
## 在检视面板直接暴露具体变量，比字典 {"atk": 0} 更好填、更不容易打错字
@export var attack_bonus: float = 0.0
@export var defense_bonus: float = 0.0
@export var speed_bonus: float = 0.0

@export_group("背包与负重加成 (Bag Stats)")
## 装备后（如背篓）提供的额外负重
@export var bonus_weight_capacity: float = 0.0
## 装备后提供的额外格子数
@export var bonus_slots: int = 0
##  --- 特殊背包/挎包属性 ---
@export var weight_reduction_ratio: float = 1.0 # 减重乘区：1.0表示不减重，0.25表示重量变为25%，0.0表示完全无重量
@export var allowed_item_tags: Array[TagData] = [] # 限制放入物品的标签

@export_group("被动增益 (Passive Modifiers)")
## 只要装备在身上（或放置在家里），就会生效的全局属性
@export var passive_modifiers: Array[ModifierData] = []
