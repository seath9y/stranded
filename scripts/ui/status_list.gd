extends VBoxContainer

@export var stat_widget_scene: PackedScene 

# 用一个数组来专门记录代码生成的节点
var dynamic_widgets: Array[Node] = []

func _ready():
	SurvivalManager.pinned_stats_changed.connect(_refresh_status_list)
	_refresh_status_list()

func _refresh_status_list():
	# 1. 清理工作：只清空之前用代码生成的“动态条”，绝对不碰你在编辑器里摆的负重和饥饿！
	for widget in dynamic_widgets:
		if is_instance_valid(widget):
			widget.queue_free()
	dynamic_widgets.clear()
	
	# 2. 遍历大管家，寻找需要动态生成的属性
	for stat_key in SurvivalManager.all_stats_info.keys():
		var info = SurvivalManager.all_stats_info[stat_key]
		
		# 【核心逻辑】：如果是核心属性(is_core)，说明你已经在编辑器里摆好了，跳过不生成！
		# 只生成：非核心 (is_core == false) 且 被打勾 (pinned) 的属性
		if not info["is_core"] and SurvivalManager.pinned_stats.get(stat_key, false):
			var widget = stat_widget_scene.instantiate()
			add_child(widget) # 会自动排在 VBoxContainer 的最下面
			dynamic_widgets.append(widget) # 记在小本本上，下次刷新好删掉
			
			var current_icon = info.get("icon", null) 
			widget.setup(info["name"], stat_key, current_icon)
