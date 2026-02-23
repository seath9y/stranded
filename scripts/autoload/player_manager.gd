# ================= res://scripts/autoload/player_manager.gd =================
extends Node

# --- 新增：向 UI 发送负重更新的信号 ---
signal weight_changed(current: int, max_cap: int, status: String)

var base_player_slots: int = 4
var current_strength_bonus: int = 0

var current_weight: int = 0
var max_weight_capacity: int = 2000 # 玩家自身的基础负重 2kg

# --- 独立容器容量追踪 ---
var backpack_capacity: int = 0
var special_capacity: int = 0

func _ready():
	call_deferred("recalculate_player_stats")

func recalculate_player_stats():
	var player_zone = get_tree().get_first_node_in_group("group_player_zone")
	var backpack_zone = get_tree().get_first_node_in_group("group_backpack_zone")
	var special_zone = get_tree().get_first_node_in_group("group_special_zone") # 记得打组！
	var equip_zone = get_tree().get_first_node_in_group("group_equip_zone")
	
	if player_zone == null or equip_zone == null:
		return
		
	# 1. 状态重置
	var backpack_slots = 0
	var special_slots = 0
	backpack_capacity = 0
	special_capacity = 0
	var has_backpack = false
	var has_special = false
	
	# 2. 扫描装备区，精准匹配部位
	for slot in equip_zone.get_children():
		if slot is EquipSlot:
			for child in slot.get_children():
				if child is Card and child.data is EquipmentData:
					var equip = child.data
					
					# A. 主背包判定
					if equip.equip_requirement == EquipmentData.EquipSlot.背部:
						has_backpack = true
						backpack_slots = equip.bonus_slots
						backpack_capacity = int(equip.bonus_weight_capacity)
						
					# B. 特殊背包/挎包判定（这里我假设你用“饰品”部位当挎包，你可以在 EquipmentData 里加一个新枚举比如“腰部”）
					elif equip.equip_requirement == EquipmentData.EquipSlot.饰品: 
						has_special = true
						special_slots = equip.bonus_slots
						special_capacity = int(equip.bonus_weight_capacity)
					break # 找到卡牌就跳出当前格子的循环
					
	# 3. 控制对应区域的显隐
	if backpack_zone: backpack_zone.visible = has_backpack
	if special_zone: special_zone.visible = has_special
	
	# 4. 执行重量计算与状态判定
	_calculate_total_weight(player_zone, backpack_zone, special_zone, equip_zone)
	_update_weight_status()
	
	# 5. 精准控制每个区域的格子锁死/解锁
	if player_zone and "slot_container" in player_zone:
		_lock_slots_in_grid(player_zone.slot_container, base_player_slots + current_strength_bonus)
		
	if backpack_zone and "slot_container" in backpack_zone:
		_lock_slots_in_grid(backpack_zone.slot_container, backpack_slots if has_backpack else 0)
		
	if special_zone and "slot_container" in special_zone:
		_lock_slots_in_grid(special_zone.slot_container, special_slots if has_special else 0)

# ================= 新版：分离式负重计算 =================
func _calculate_total_weight(player_zone, backpack_zone, special_zone, equip_zone) -> void:
	# 1. 直接压在人身上的重量
	var body_weight = _get_zone_weight(player_zone) + _get_zone_weight(equip_zone)
	
	# 2. 各个容器内部的真实重量
	var backpack_weight = _get_zone_weight(backpack_zone) if backpack_zone else 0
	var special_weight = _get_zone_weight(special_zone) if special_zone else 0
	
	# 3. 计算溢出（核心逻辑：内部重量减去减重容量，最小为0）
	var backpack_overflow = max(0, backpack_weight - backpack_capacity)
	var special_overflow = max(0, special_weight - special_capacity)
	
	# 4. 玩家最终负担的总重量
	current_weight = body_weight + backpack_overflow + special_overflow

# ================= 新增工具：安全提取任意区域的总重量 =================
func _get_zone_weight(zone: Node) -> int:
	if zone == null: return 0
	var total = 0
	
	# 兼容两种结构：有 slot_container 的 CardZone，和直接装 Slot 的 EquipZone
	var container = zone.slot_container if "slot_container" in zone else zone 
	
	for slot in container.get_children():
		if slot is Slot or slot is EquipSlot:
			for child in slot.get_children():
				if child is Card and child.data != null:
					total += child.data.weight * child.current_count
	return total

# ================= 状态更新与 UI 广播 =================
func _update_weight_status() -> void:
	var dynamic_max_weight = max_weight_capacity + current_strength_bonus
	var ratio: float = float(current_weight) / float(dynamic_max_weight)
	var current_status = "normal"
	
	if ratio >= 1.3:
		StatusManager.add_status("immobilized")
		StatusManager.add_status("overweight")
		current_status = "immobilized"
	elif ratio >= 1.0:
		StatusManager.remove_status("immobilized")
		StatusManager.add_status("overweight")
		current_status = "overweight"
	else:
		StatusManager.remove_status("overweight")
		StatusManager.remove_status("immobilized")
		
	# 广播给 UI 面板
	emit_signal("weight_changed", current_weight, dynamic_max_weight, current_status)

# 锁格子函数 _lock_slots_in_grid 保持你原来的不变即可
# 辅助函数：根据算出的上限，把多余的格子锁死
# ================= 需求 1：格子锁死与自动弹射 =================

func _lock_slots_in_grid(grid: Container, allowed_count: int):
	# 【防弹衣】：如果传进来的容器是空的，直接退出并报错，绝对不崩溃！
	if grid == null:
		print("⚠️ 警告：试图锁定的背包格子容器不存在！请检查节点。")
		return
		
	var index = 0
	for slot in grid.get_children():
		if slot is Slot:
			if index < allowed_count:
				slot.set_locked(false) # 解锁
			else:
				slot.set_locked(true)  # 锁死
			index += 1

#
## ================= 需求 2：负重计算与状态挂载 =================
#func _calculate_total_weight() -> void:
	#var total: int = 0
	#var zones = [
		#get_tree().get_first_node_in_group("group_player_zone"),
		#get_tree().get_first_node_in_group("group_backpack_zone"),
		#get_tree().get_first_node_in_group("group_equip_zone")
	#]
	#
	#for zone in zones:
		#if zone:
			#for slot in zone.get_children():
				#for child in slot.get_children():
					## 确保节点包含数据且能获取数量
					#if "data" in child and "current_count" in child:
						#total += child.data.weight * child.current_count
	#
	#current_weight = total
#
#func _update_weight_status() -> void:
	#var ratio: float = float(current_weight) / float(max_weight_capacity)
	#
	## 梯度判定：> 130% 瘫痪
	#if ratio >= 1.3:
		#StatusManager.add_status("immobilized")
		#StatusManager.add_status("overweight")
	## 梯度判定：100% - 130% 超重
	#elif ratio >= 1.0:
		#StatusManager.remove_status("immobilized")
		#StatusManager.add_status("overweight")
	## 正常状态
	#else:
		#StatusManager.remove_status("overweight")
		#StatusManager.remove_status("immobilized")
