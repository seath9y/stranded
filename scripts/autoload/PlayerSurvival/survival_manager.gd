# ================= res://scripts/autoload/survival_manager.gd =================
extends Node

# ==========================================
# 1. 核心信号区 (UI 全靠听这些信号来工作)
# ==========================================
signal stats_updated  # 每当数值变化时发射（通知 UI 刷新进度条）
signal pinned_stats_changed # 每当玩家在详情页勾选/取消勾选时发射（通知主界面增删 UI）

# ==========================================
# 2. 状态百科全书 (UI 生成指南，完全为你的属性定制)
# ==========================================
var all_stats_info: Dictionary = {
	"hydration": {
		"name": "水分",
		"is_core": true, # 【核心】永远在左下角显示
		"max_val": 2000.0,
		"icon": preload("res://assets/icons/ui/口渴.png"), # 手动摆放的条不需要在这里填，保持 null 即可,
		"description": "维持生命的核心指标。脱水会导致移动迟缓，最终导致死亡。", # 【新增】
		"top_color": Color("7ac8d4"), 
		"bottom_color": Color("5e9bb7"),
	},
	"stomach": {
		"name": "饥饿",
		"is_core": true, 
		"max_val": 100.0,
		"icon": preload("res://assets/icons/ui/饥饿.png"),
		"top_color": Color("f2b544"), 
		"bottom_color": Color("d58745"),
		"description": "能量的终极储备。当胃里没有食物消化时，身体将燃烧体脂供能。可以通过进食高热量食物积累。" # 【新增】
	},
	"wakefulness": {
		"name": "清醒度",
		"is_core": true, 
		"max_val": 100.0,
		"icon": null,
		"top_color": Color("897ccc"),
		"bottom_color": Color("655a94")
	},
	"body_fat": {
		"name": "体脂储备",
		"is_core": false, # 【次要】默认隐藏，打勾才显示
		"max_val": 5000.0,
		"icon": null,
		"top_color": Color("f2b544"), 
		"bottom_color": Color("d58745"),
	}
}

# 记录哪些【次要属性】要在主界面左下角显示 (测试期默认把体脂设为 true)
var pinned_stats: Dictionary = {
	"body_fat": true
}

# ==========================================
# 3. 核心生理数值池 (完全保留你的原始数据！)
# ==========================================
var max_stomach: float = 100.0
var current_stomach: float = 0.0

var max_body_fat: float = 5000.0
var current_body_fat: float = 4000.0

var max_hydration: float = 2000.0
var current_hydration: float = 1500.0

var max_immunity: float = 100.0
var current_immunity: float = 100.0

var max_morale: float = 100.0
var current_morale: float = 80.0

var max_wakefulness: float = 100.0
var current_wakefulness: float = 100.0

# ==========================================
# 4. 基础转化率配置 (完全保留！)
# ==========================================
const STOMACH_DIGEST_PER_MIN: float = 0.2     
const FAT_GAIN_PER_DIGESTED_FOOD: float = 5.0 
const FAT_BURN_PER_MIN: float = 0.5           
const HYDRATION_DRAIN_PER_MIN: float = 1.0    

func _ready():
	pass

# ==========================================
# 5. UI 获取数据的专属接口 (新增)
# ==========================================
func get_current_stat_value(stat_key: String) -> float:
	match stat_key:
		"hydration": return current_hydration
		"stomach": return current_stomach
		"wakefulness": return current_wakefulness
		"body_fat": return current_body_fat
		_: return 0.0

func toggle_stat_pin(stat_key: String, is_pinned: bool) -> void:
	if pinned_stats.has(stat_key):
		pinned_stats[stat_key] = is_pinned
		emit_signal("pinned_stats_changed")

# ==========================================
# 6. 核心代谢引擎 (完全保留你的逻辑与 StatusManager 联动！)
# ==========================================
func process_metabolism(minutes_passed: int) -> void:
	if minutes_passed <= 0: return
	
	var water_drain_mult = StatusManager.get_multiplier("water_drain_multiplier")
	var fat_burn_mult = StatusManager.get_multiplier("fat_burn_multiplier")
	
	for i in range(minutes_passed):
		_tick_one_minute(water_drain_mult, fat_burn_mult)
		
	_check_survival_thresholds()
	
	print("========================================")
	print("⏳ 动作执行完毕，时间流逝了 %d 分钟。" % minutes_passed)
	print("🍖 胃容量: %.1f / %.1f" % [current_stomach, max_stomach])
	print("🩸 体脂储备: %.1f / %.1f" % [current_body_fat, max_body_fat])
	print("💧 水分剩余: %.1f / %.1f" % [current_hydration, max_hydration])
	print("🥱 清醒度: %.1f / %.1f" % [current_wakefulness, max_wakefulness])
	print("========================================")
	
	# 【核心】：每次代谢算完，向 UI 喊话让进度条更新！
	emit_signal("stats_updated")

func _tick_one_minute(water_mult: float, fat_mult: float) -> void:
	if current_stomach > 0:
		var digested = min(current_stomach, STOMACH_DIGEST_PER_MIN)
		current_stomach -= digested
		current_body_fat = clamp(current_body_fat + (digested * FAT_GAIN_PER_DIGESTED_FOOD), 0, max_body_fat)
	
	current_body_fat = clamp(current_body_fat - (FAT_BURN_PER_MIN * fat_mult), 0, max_body_fat)
	current_hydration = clamp(current_hydration - (HYDRATION_DRAIN_PER_MIN * water_mult), 0, max_hydration)
	current_wakefulness = clamp(current_wakefulness - 0.05, 0, max_wakefulness)

func _check_survival_thresholds() -> void:
	if current_body_fat <= 0:
		print("💀 玩家因体脂耗尽而死亡！") 
	elif current_body_fat <= 500:
		StatusManager.add_status("starving") 
	else:
		StatusManager.remove_status("starving")
		
	if current_hydration <= 0:
		print("💀 玩家因严重脱水而死亡！")
	elif current_hydration <= 300:
		StatusManager.add_status("dehydrated") 
	elif current_hydration <= 500:
		StatusManager.add_status("thirsty")
		StatusManager.remove_status("dehydrated") 
	else:
		StatusManager.remove_status("thirsty")
		StatusManager.remove_status("dehydrated")
