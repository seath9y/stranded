#ItemData
extends Resource
class_name ItemData

# --- 基础信息 ---
@export_group("基础信息 (Base Info)")
@export var id: String = "" # 唯一ID，用于代码查找
@export var name: String = ""
@export var icon: Texture2D # 物品图片
@export_multiline var description: String = ""
@export var weight: int = 0

# --- 分类与栏位限制 ---
enum ItemType { 地区资源, 建筑, 容器, 家具, 蓝图, 装备, 动物, 材料, 食物 }

@export_group("类型与位置 (Type & Placement)")
@export var type: ItemType = ItemType.材料

# --- 堆叠与交互 ---
@export_group("交互属性 (Interaction)")
enum StackType { 不可堆叠 = 0, 无限堆叠 = 1, 固定数量 = 2 }
@export var stack_type: StackType = StackType.不可堆叠
@export var max_stack_limit: int = 99
@export var action_tags: Array[TagData] = [] # 工具标签

@export_group("耐久与消耗 (Durability)")
@export var has_durability: bool = false
@export var max_durability: int = 100
#@export var destroy_on_break: bool = true
#@export var broken_item: ItemData

@export_group("目标产出 (Target Interactions)")
@export var interactions: Array[InteractionRule] = [] # 被交互的配方
