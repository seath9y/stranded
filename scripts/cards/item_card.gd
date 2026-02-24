extends PanelContainer # 或者你的根节点类型
class_name Card # 定义类名，方便代码里引用

# 存储数据的引用
var data: ItemData 
var current_count: int = 1
# 【新增】：当前这张卡牌剩余的耐久度
var current_durability: int = -1
# 增加一个变量存放计时器
var hover_timer: Timer

# --- UI 节点获取 ---
@onready var icon_rect: TextureRect = $VBox/ContentMargin/Overlay/Icon
@onready var name_label: Label = $VBox/HeaderMargin/HeaderHBox/NameLabel
@onready var number_label: Label = $VBox/HeaderMargin/HeaderHBox/Number
@onready var status_container: VBoxContainer = $VBox/ContentMargin/Overlay/Stats/RightGroup

func _ready():
	# 防止在编辑器里报错，或者确保加载时刷新
	if data != null:
		update_display()
	# 1. 创建并配置延迟计时器
	hover_timer = Timer.new()
	hover_timer.wait_time = 0.5 # 悬停 0.5 秒后才显示（你可以自己调）
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(hover_timer)
	
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
# --- 鼠标事件 ---
func _on_mouse_entered():
	# 鼠标进来，开始倒计时
	hover_timer.start()

func _on_mouse_exited():
	# 鼠标离开，立刻停止倒计时（如果还没到0.5秒就不会触发显示了）
	hover_timer.stop()
	# 同时隐藏可能已经显示出来的面板
	TooltipManager.hide_tooltip()

func _on_hover_timer_timeout():
	# 【终极安全拦截】：如果倒计时结束的瞬间，卡牌已经被销毁，直接取消显示！
	if not is_instance_valid(self) or data == null or is_queued_for_deletion():
		return
	# 倒计时结束，说明玩家盯着这张卡牌看了 0.5 秒，显示信息！
	TooltipManager.show_tooltip(self)
# --- 核心交互方法 ---
## 外部生成卡牌时调用的初始化函数
func set_data(new_data: ItemData, amount: int = 1):
	data = new_data
	current_count = amount
	
	# 初始化耐久度（默认满血）
	if "has_durability" in data and data.has_durability:
		if "max_durability" in data: 
			current_durability = data.max_durability
			
	if not is_node_ready():
		await ready
		
	update_display()

## 刷新 UI 界面
func update_display():
	if not is_node_ready(): return
	if data == null: return
		
	# 【修复变黑 Bug】：每次刷新 UI 时，强行把卡牌恢复为完全不透明！
	self.modulate.a = 1.0
	# 1. 设置名称和图标
	name_label.text = data.name
	if data.icon != null:
		icon_rect.texture = data.icon
		
	# 2. 右下角的堆叠数量显示
	if data.stack_type == ItemData.StackType.不可堆叠:
		number_label.visible = false
	else:
		if current_count > 1:
			number_label.text = "x" + str(current_count)
			number_label.visible = true
		else:
			number_label.visible = false

	# 【新增】：3. 刷新动态属性状态列表
	_update_status_indicators()

# ==========================================
# 动态生成状态 UI 的逻辑
# ==========================================
func _update_status_indicators():
	# 1. 每次刷新前，先清空容器里的旧标签（防止叠加）
	for child in status_container.get_children():
		child.queue_free()
		
	# 2. 检查：耐久度
	if "has_durability" in data and data.has_durability:
		var pct = (float(current_durability) / float(data.max_durability)) * 100.0
		pct = clamp(pct, 0.0, 100.0) # 限制在 0-100 之间
		
		# 变色逻辑：耐久度低于 30% 变成红色警告
		var color = Color.WHITE
		if pct <= 30.0:
			color = Color.RED 
			
		_create_status_label("⚙️ %d%%" % int(pct), color)
		
	# 3. 检查：腐烂度（预留给你之后做的）
	# if "has_spoilage" in data and data.has_spoilage:
	# 	var rot_pct = ...
	# 	_create_status_label("🥩 %d%%" % int(rot_pct), Color.GREEN)

	# 4. 检查：动物饥饿（预留给你之后做的）
	# if "animal_type" in data:
	# 	_create_status_label("🍖 饿", Color.YELLOW)

# 辅助方法：在代码里生成文字标签并塞进容器
func _create_status_label(text: String, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	# 如果你用了特殊的字体，可以在这里用代码给 label 赋予字体，或者直接给 StatusContainer 设置全局 Theme
	label.add_theme_font_size_override("font_size", 12) # 字号调小一点
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	status_container.add_child(label)

## 增加数量
func add_count(amount: int) -> int:
	var space_left = 999999 # 默认一个极大的数字，代表无限堆叠
	
	# 如果是固定数量堆叠，才计算剩余空间
	if data.stack_type == ItemData.StackType.固定数量:
		space_left = data.max_stack_limit - current_count
		
	var added = min(amount, space_left)
	current_count += added
	update_display()
	
	return amount - added # 返回溢出的数量

# 当玩家用鼠标按住并拖动这张卡牌时，引擎会自动调用这个函数
func _get_drag_data(at_position: Vector2) -> Variant:
	# 1. 确保没有数据的空卡牌不能被拖拽
	if data == null:
		return null
		
	print("抓起了: ", data.name) # 如果你之前改了中文，这里用 data.名称
	hover_timer.stop() # 抓起卡牌时，立刻停止计时
	TooltipManager.hide_tooltip()
	# 2. 准备要传递的数据（我们直接把整张卡牌节点本身传过去，方便后续获取数据）
	var drag_data = self
	
	# 3. 制作拖拽时的半透明“预览图” (Preview)
	var preview_control = Control.new()
	# ⚠️ 这里的路径请替换为你实际的 Card.tscn 的路径！
	var preview_card = load("res://scenes/ui/components/card.tscn").instantiate() 
	preview_control.add_child(preview_card)
	
	# 把当前卡牌的数据复制给预览图
	preview_card.set_data(self.data, self.current_count)
	# 【新增这行】：把当前卡牌的状态包裹也传给预览图！
	preview_card.apply_dynamic_state(self.get_dynamic_state())
	preview_card.modulate.a = 0.6 # 设置为半透明，显得很有质感
	# 👇【新增这两行核心代码】强制锁定预览图的尺寸
	preview_card.custom_minimum_size = self.size 
	preview_card.size = self.size
	# 调整中心点，让鼠标指针正好抓在卡牌中心处（提升手感）
	preview_card.position = -self.size / 2 
	
	# 4. 告诉引擎：用这个当做预览图
	set_drag_preview(preview_control)
	
	# 5. 可选：让原地原本的卡牌变暗，表示它正在被拖拽
	self.modulate.a = 0.3
	
	return drag_data

# 当拖拽结束时（不管有没有成功放下），恢复卡牌原状
func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		self.modulate.a = 1.0 # 恢复不透明

# ==========================================
# 鼠标输入检测 (右键快捷传送)
# ==========================================
func _gui_input(event: InputEvent) -> void:
	# 检查是否是鼠标点击事件，并且按下了【右键】
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# event.shift_pressed 会自动判断你按右键的同时有没有按住 Shift
		_handle_right_click_transfer(event.shift_pressed)
# 处理右键瞬间跨区传送的逻辑
func _handle_right_click_transfer(is_shift_pressed: bool = false):
	var current_slot = get_parent()
	if not current_slot is Slot: return
	
	var source_zone = current_slot.zone_manager
	if source_zone == null: return
	
	# ==========================================
	# 🧠 1. 源头拦截
	# ==========================================
	# 如果物品在地点栏，严禁右键移动！
	if source_zone.is_in_group("area_zone"):
		print("地点栏的物品无法通过右键移动！")
		return
		
	# ==========================================
	# 🧠 2. 组装目标传送队列 (严格按可见标签页划分)
	# ==========================================
	var targets: Array = []
	
	# 场景 A：从【地面】捡起 -> 严格检查哪个下半区标签页开着
	if source_zone.is_in_group("ground_zone"):
		var player_zone = get_tree().get_first_node_in_group("group_player_zone")
		var equip_zone = get_tree().get_first_node_in_group("group_equip_zone")
		
		# 1. 如果当前切在【标签 1：手牌区】
		if player_zone and player_zone.is_visible_in_tree():
			targets.append(player_zone)
			targets.append(get_tree().get_first_node_in_group("group_backpack_zone"))
			
		# 2. 如果当前切在【标签 2：装备区】
		elif equip_zone and equip_zone.is_visible_in_tree():
			targets.append(equip_zone)
			
	# 场景 B：从【手牌区/背包区】丢弃 -> 扔回地面
	elif source_zone.is_in_group("group_player_zone") or source_zone.is_in_group("group_backpack_zone"):
		targets.append(get_tree().get_first_node_in_group("ground_zone"))
		
	# 场景 C：从【装备区】脱下 -> 扔回地面
	elif source_zone.is_in_group("group_equip_zone"):
		targets.append(get_tree().get_first_node_in_group("ground_zone"))

	# ==========================================
	# 🧠 3. 开始执行瀑布流塞入
	# ==========================================
	# 【核心修改】：如果是 Shift+右键，移动全部；否则只移动 1 个
	var amount_to_move = self.current_count if is_shift_pressed else 1
	var leftover = amount_to_move 
	var my_state = self.get_dynamic_state()
	
	for target in targets:
		if target == null or not target.visible:
			continue
			
		leftover = target.add_item(self.data, leftover, my_state)
		
		# 如果计划移动的数量全塞进去了，结束循环！
		if leftover == 0:
			break 
			
	# ==========================================
	# 🧠 4. 结算与刷新UI
	# ==========================================
	var success_count = amount_to_move - leftover
	
	if success_count > 0:
		print("✅ 成功传送了 ", success_count, " 个物品！")
		self.current_count -= success_count # 从这堆物品里扣除成功移走的数量
		self.update_display()
		
		if self.current_count <= 0:
			if current_slot: current_slot.remove_child(self)
			self.queue_free()
			if source_zone and source_zone.has_method("reorganize_cards"): 
				source_zone.reorganize_cards()
			
		EnvironmentManager.call_deferred("recalculate_environment")
		if PlayerManager.has_method("recalculate_player_stats"):
			PlayerManager.call_deferred("recalculate_player_stats")
	else:
		print("⚠️ 右键传送失败：目标区域已满、不匹配或不可见！")
# ==========================================
# 动态状态管理 (State Dictionary)
# ==========================================

# 1. 打包：将这张卡牌当前的所有变动数据打包装箱
func get_dynamic_state() -> Dictionary:
	var state = {}
	
	# 如果有耐久度，把当前真实耐久装进包裹
	if "has_durability" in data and data.has_durability:
		state["durability"] = current_durability
		
	# 以后如果加了动物饥饿度，只需在这下面继续写 state["hunger"] = current_hunger
		
	return state

# 2. 拆包：新卡牌生成时，读取包裹里的数据并覆盖给自己
func apply_dynamic_state(state: Dictionary):
	if state.is_empty():
		return
		
	if state.has("durability"):
		current_durability = state["durability"]
		
	# 状态应用完毕后，刷新UI显示最新数值
	update_display()
## 拖拽事件穿透给父节点 (Slot)
## ==========================================
#
#func _can_drop_data(at_position: Vector2, drag_data: Variant) -> bool:
	#var parent = get_parent()
	#if parent and parent.has_method("_can_drop_data"):
		## 拦截到事件后，假装自己是格子，去问父节点（格子）能不能放
		#return parent._can_drop_data(at_position, drag_data)
	#return false
#
#func _drop_data(at_position: Vector2, drag_data: Variant) -> void:
	#var parent = get_parent()
	#if parent and parent.has_method("_drop_data"):
		## 松手时，通知父节点（格子）执行放下逻辑
		#parent._drop_data(at_position, drag_data)
