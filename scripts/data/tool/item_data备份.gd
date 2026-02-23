extends Resource
class_name ItemData备份

# --- 基础信息 ---
@export_group("基础信息 (Base Info)")
@export var id: String = "" # 唯一ID，用于代码查找
@export var name: String = ""
@export var icon: Texture2D # 物品图片
@export_multiline var description: String = ""
@export var weight: int = 0

# --- 分类与栏位限制 ---
enum ItemType { 地区资源, 建筑, 容器, 家具, 蓝图, 装备, 动物, 材料, 食物 }
enum Zone { 地区栏 = 1, 地面栏 = 2, 人物栏 = 3 }

@export_group("类型与位置 (Type & Placement)")
@export var type: ItemType = ItemType.材料
## 这个物品允许被放置在哪些栏位？(可多选)
@export var allowed_zones: Array[Zone] = [Zone.地面栏, Zone.人物栏]

# --- 堆叠与交互 ---
@export_group("交互属性 (Interaction)")
## 是否可堆叠
enum StackType {
	不可堆叠 = 0,
	无限堆叠 = 1,
	固定数量 = 2
}
## 物品堆叠行为类型
@export var stack_type: StackType = StackType.不可堆叠
## 仅在堆叠类型为“固定数量”时生效（例如：一组箭矢最大99）
@export var max_stack_limit: int = 99
## 标签系统
@export var action_tags: Array[TagData] = []

# --- 目标与产出属性 ---
@export_group("目标产出 (Target Interactions)")

## 核心交互表！（添加元素，分别拖入需要的 TagData 和 产出的 ItemData）
@export var interactions: Array[InteractionRule] = []
@export var required_tool_level: int = 1

# --- 耐久与消耗 (工具/多份食物) ---
@export_group("耐久度/使用次数 (Durability)")
## 是否有耐久度/使用次数限制
@export var has_durability: bool = false
## 最大耐久度 (或最大份数，比如一锅饭是3)
@export var max_durability: int = 10
## 耗尽后是否消失 (true=消失, false=变损坏状态)
@export var destroy_on_break: bool = true
## (可选) 损坏后变成什么物品
@export var broken_item: ItemData 

# --- 腐烂系统 ---
@export_group("腐烂系统 (Spoilage)")
## 是否会随时间腐烂
@export var has_spoilage: bool = false
## 多少秒后腐烂 (游戏内时间或现实时间由管理器决定)
@export var spoil_time: float = 300.0
## 腐烂后变成什么物品 (例如：腐烂物)
@export var rot_product: ItemData

# --- 建筑与存储 (针对 建筑/家具/容器) ---
@export_group("建筑与存储 (Building & Storage)")
## 是否是只有放在特定底座上的“家具”(如篝火配件)
@export var is_furniture_attachment: bool = false
## 内部存储容量 (0代表不可存储)
## 建筑=内部中栏容量; 箱子=UI格子数; 锅/瓶=液体容量
@export var storage_capacity: int = 0
## 存储类型：决定了如何交互
enum StorageType {
	无,
	内部中栏,
	弹窗UI,
	液体容器,
	装备包
}
@export var storage_behavior: StorageType = StorageType.无
## 是否可以进入 (像建筑那样点击弹窗)
@export var can_enter: bool = false

# --- 蓝图系统 ---
@export_group("蓝图 (Blueprint)")
## 这是蓝图完成后的目标物品 (例如：农田蓝图 -> 农田)
@export var blueprint_result: ItemData
## 建造需要的时间
@export var build_time: float = 10.0
## 下一阶段蓝图 (如果是分阶段建造，如 荒地->松土->农田)
@export var next_stage_blueprint: ItemData

# --- 属性加成 (装备/背包) ---
@export_group("属性加成 (Stats)")
## 装备提供的额外负重
@export var bonus_weight_capacity: float = 0.0
## 提供的格数 (背包)
@export var bonus_slots: int = 0
## 战斗属性 (攻击力/防御力等)
@export var combat_stats: Dictionary = {"atk": 0, "def": 0}

# --- 动物属性 ---
@export_group("生物属性 (Living)")
@export var max_health: int = 10
@export var hunger_rate: float = 1.0 # 饥饿速度
