extends Resource
class_name FacilityState

# 记录自己对应的图纸 ID，加载存档时可以通过这个 ID 找回图标和规则
@export var template_id: String = "" 

# ==========================================
# 🔨 建造进度数据
# ==========================================
@export var current_build_stage: int = 0      # 当前处于第几个施工阶段
@export var invested_materials: Dictionary = {} # 当前阶段已塞入的材料 (例：{"wood": 4}) 

# ==========================================
# 🔥 核心运行状态
# ==========================================
@export var is_lit: bool = false                # 当前是否处于点燃/运作状态
@export var current_fuel_minutes: float = 0.0   # 【时间池】剩余可燃烧时间
@export var current_ash_amount: float = 0.0     # 当前积攒的灰烬量
@export var current_temperature: float = 0.0    # 当前炉温 

# ==========================================
# 🍖 加工槽位数据 (滞留区)
# ==========================================
# 数组长度将由 Template 里的 process_slots_count 决定。
# 存放字典，例如: {"item_id": "生肉", "progress": 85.0, "is_burnt": false}
@export var process_slots: Array = [] 

# 初始化槽位的方法
func init_slots(slot_count: int) -> void:
	process_slots.clear()
	for i in range(slot_count):
		process_slots.append(null) # 默认塞入 null 代表空槽位
