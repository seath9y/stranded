# ================= res://scripts/data/StatusData.gd =================
extends Resource
class_name StatusData

enum StatusType { 增益_BUFF, 减益_DEBUFF, 中性_NEUTRAL }

@export_group("基础信息 (Base Info)")
## 状态的唯一标识符（例如 "wet_1", "overweight", "fracture_2"）
@export var id: String = ""
## 显示给玩家看的名称（例如 "微湿", "骨折"）
@export var name: String = ""
## 状态在 UI 上显示的图标
@export var icon: Texture2D
## 状态的文字描述（悬停提示框用）
@export_multiline var description: String = ""
## 状态的类型（决定 UI 边框是红色、绿色还是灰色）
@export var type: StatusType = StatusType.减益_DEBUFF

@export_group("被动修饰乘区 (Passive Modifiers)")
## 这些属性会直接影响其他系统的计算（1.0 表示正常，2.0 表示翻倍，0.5 表示减半）
@export var travel_time_multiplier: float = 1.0    # 跨区域时间消耗倍率
@export var stamina_cost_multiplier: float = 1.0   # 耐力消耗倍率
@export var move_speed_multiplier: float = 1.0     # 移动速度倍率

@export_group("硬性限制开关 (Hard Flags)")
## 勾选后，玩家将被禁止做某些动作
@export var is_immobilized: bool = false # 是否彻底瘫痪（无法移动）
@export var prevent_crafting: bool = false # 比如手部骨折，禁止手工合成

@export_group("持续触发效果 (Tick Effects)")
## 结合“行动推进时间”机制，每经过 1 小时（60分钟）游戏时间自动改变的数值
@export var health_change_per_hour: float = 0.0    # 例如流血可填 -10.0，休息可填 +5.0
@export var sanity_change_per_hour: float = 0.0    # 理智值/心情值的持续增减
