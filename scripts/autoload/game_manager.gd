#game_manager
extends Node
# 游戏全局状态管理,协调其他管理器
# 记录当前在玩的存档槽位。
# 持有玩家对象的引用（player 变量），方便其他系统访问玩家状态。
# 持有当前地点的引用（current_location）。
# 处理“新游戏”、“继续游戏”、“退出游戏”等顶层逻辑。
# 在存档/读档时，协调其他管理器收集或恢复数据。
var current_save_slot: String = ""
var current_location: Node = null
var player: Node = null  # 将在玩家场景实例化后设置

func _ready():
	# 初始化时可以先加载默认存档或进入新游戏
	pass

func new_game():
	# 开始新游戏逻辑
	pass

func quit_game():
	get_tree().quit()
