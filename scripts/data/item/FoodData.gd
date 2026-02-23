extends ItemData
class_name FoodData
#专门处理腐烂系统，以后还可以加上“恢复多少饱食度/水分”。
@export_group("腐烂系统 (Spoilage)")
@export var has_spoilage: bool = true
@export var spoil_time: int = 300
@export var rot_product: ItemData

@export_group("食用效果 (Consumption)")
@export var hunger_restore: float = 10.0 # 举个例子
