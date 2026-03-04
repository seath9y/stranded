#BuildingData
extends ItemData
class_name BuildingData
#建筑容器
enum StorageType { 无, 内部中栏, 弹窗UI, 液体容器, 装备包 }

@export_group("建筑与存储 (Building & Storage)")
@export var storage_capacity: int = 0
@export var storage_behavior: StorageType = StorageType.无
@export var can_enter: bool = false
@export var is_furniture_attachment: bool = false

@export_group("便携容器 (Portable Vessel)")
## 能装多少单位的液体/食物
@export var max_capacity: int = 3
## 这个容器是否可以被放在火上加热 (比如锅可以，木碗不行)
@export var can_be_heated: bool = false
## 是否只能装特定的东西 (比如只能装“液体”标签的物品)
@export var allowed_content_tags: Array[TagData] = []

@export_group("被动增益 (Passive Modifiers)")
## 只要装备在身上（或放置在家里），就会生效的全局属性
@export var passive_modifiers: Array[ModifierData] = []

@export_group("设施与加工 (Facility & Processing)")
