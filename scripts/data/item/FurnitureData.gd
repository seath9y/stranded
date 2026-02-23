# ================= res://scripts/data/FurnitureData.gd =================
extends BuildingData # 注意：它继承自 BuildingData，因为它通常也在1栏
class_name FurnitureData
#家具与工作台
@export_group("燃料与加工 (Fuel & Processing)")
## 是否需要燃料才能工作 (比如篝火、窑炉)
@export var requires_fuel: bool = true
## 最大可填充的燃料值
@export var max_fuel_capacity: float = 100.0
## 每秒消耗的燃料值
@export var fuel_burn_rate: float = 1.0
## 是否有温度设定 (比如窑炉炼矿需要高温)
@export var has_temperature: bool = false
