# status_tab.gd
extends VBoxContainer

@export var list_item_scene: PackedScene

# 去掉了所有 Filter 相关的节点引用
@onready var list_container = $Splitter/TopScroll/ListContainer
@onready var desc_label = $Splitter/BottomScroll/DescLabel

# 字典缓存：记录 stat_key 对应的 instantiated 节点，实现 O(1) 查找更新
var item_nodes: Dictionary = {}

func _ready():
	# 2. 初始构建对象池
	_build_list()
	# 3. 手动触发一次初始状态的文字描述刷新（默认选中第一个）
	if SurvivalManager.all_stats_info.keys().size() > 0:
		_on_item_selected(SurvivalManager.all_stats_info.keys()[0])

func _build_list():
	for stat_key in SurvivalManager.all_stats_info.keys():
		var info = SurvivalManager.all_stats_info[stat_key]
		var is_pinned = SurvivalManager.pinned_stats.get(stat_key, false)
		
		var item = list_item_scene.instantiate()
		list_container.add_child(item)
		item.setup(stat_key, info, is_pinned)
		
		# 监听来自子条目的信号
		item.item_selected.connect(_on_item_selected)
		item.pin_toggled.connect(_on_item_pin_toggled)
		
		item_nodes[stat_key] = item

# ==========================================
# 交互联动逻辑
# ==========================================
func _on_item_selected(stat_key: String):
	var info = SurvivalManager.all_stats_info.get(stat_key)
	if info:
		# 富文本支持颜色和粗体排版
		var bbcode = "[b][color=#e0a652]%s[/color][/b]\n\n" % info["name"]
		bbcode += info.get("description", "暂无描述。")
		desc_label.text = bbcode

func _on_item_pin_toggled(stat_key: String, is_pinned: bool):
	# 直接通知大管家修改数据，左下角 HUD 会自动响应销毁/生成
	SurvivalManager.toggle_stat_pin(stat_key, is_pinned)
