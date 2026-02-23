# ================= res://scripts/data/BlueprintData.gd =================
extends ItemData
class_name BlueprintData

@export_group("蓝图建造 (Blueprint)")
## 这一阶段建造完成后的目标产物 (如果是最终阶段，这里就是真正的建筑)
@export var target_result: ItemData
## 如果是多段建造，完成这个后变成下一个阶段的蓝图 (比如 荒地 -> 松土蓝图)
@export var next_stage_blueprint: BlueprintData
## 需要花费的工作时间 (秒)
@export var build_time: float = 10.0

@export_group("所需材料 (Required Materials)")
## 这里推荐使用字典来配置所需材料，比如 {"木头ID": 5, "石头ID": 3}
## (Godot 4.3 以后支持强类型字典，如果是旧版本可以用 Array[BlueprintRequirement] 自定义资源)
@export var required_materials_dict: Dictionary = {}
