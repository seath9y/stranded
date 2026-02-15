extends Node
# 控制随机事件的触发。
# 维护一个事件列表（例如野兽入侵、风暴损坏），每个事件有触发条件、权重、冷却时间。
# 提供 trigger_random_event()，在时间推进或其他时机调用，根据当前状态（地点、季节、玩家状态）选择合适的事件。
# 记录上次触发事件的时间（天数），避免事件过于频繁（can_trigger_event）。
# 执行事件逻辑（弹窗提示、修改玩家状态、增减物品等）。

var last_event_time: Dictionary = {}  # 事件ID -> 触发的时间戳（天数）

func trigger_random_event():
	# TODO: 根据条件选择事件
	pass

func can_trigger_event(event_id: String, cooldown_days: int) -> bool:
	if not last_event_time.has(event_id):
		return true
	var last_day = last_event_time[event_id]
	return TimeManager.current_day - last_day >= cooldown_days
