extends Node
# 管理游戏内时间的流逝。
# 记录当前时间（以分钟为单位）、天数、季节。
# 提供 advance_time(minutes) 函数，每当玩家执行行动时调用，推进时间。
# 发射 time_advanced 信号，通知其他系统（如状态更新、随机事件检查）时间已变化。
# 提供格式化时间字符串的函数 get_time_string()，用于 UI 显示。

signal time_advanced(new_time)  # 时间推进后发射

var current_time: float = 360  # 分钟，6:00 = 360
var current_day: int = 1
var current_season: String = "spring"

#func spawn_enemy(type: String = "normal", count: int = 1) -> void:
	#for i in range(count):
		#print("生成一个 ", type, " 敌人")

# type类型,分m,时h
func advance_time(time: float, type: String = "m"):
	if type == "m":
		current_time += time
	elif type == "h":
		current_time += time * 60
	else:
		print("时间错误")
		pass
	var day_changed = false
	while current_time >= 1440:
		current_time -= 1440
		current_day += 1
		day_changed = true
		# 这里可以添加季节变化检查
	emit_signal("time_advanced", current_time, current_day, current_season)

func get_time_string() -> String:
	var hours = int(current_time / 60)
	var mins = int(current_time) % 60
	return "%02d:%02d" % [hours, mins]
