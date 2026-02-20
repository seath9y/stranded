extends PanelContainer # 或者你的根节点类型
class_name Card # 定义类名，方便代码里引用

# 存储数据的引用
var data: ItemData 
var current_count: int = 1

# --- UI 节点获取 ---
@onready var icon_rect: TextureRect = $VBox/ContentMargin/Overlay/Icon
@onready var name_label: Label = $VBox/HeaderMargin/HeaderHBox/NameLabel
@onready var number_label: Label = $VBox/HeaderMargin/HeaderHBox/Number

func _ready():
	# 防止在编辑器里报错，或者确保加载时刷新
	if data != null:
		update_display()

# --- 核心交互方法 ---

## 外部生成卡牌时调用的初始化函数
func set_data(new_data: ItemData, amount: int = 1):
	data = new_data
	current_count = amount
	
	# 【关键防御】：如果是在代码里 instantiate() 后立刻调用此方法，
	# 此时子节点可能还没准备好（@onready 还没执行），所以要等待 ready。
	if not is_node_ready():
		await ready
		
	update_display()

## 刷新 UI 界面
func update_display():
	if data == null:
		return
		
	# 1. 设置名称和图标
	name_label.text = data.name
	
	if data.icon != null:
		icon_rect.texture = data.icon
		
	# 【修改：使用新的枚举判断是否显示数字】
	if data.stack_type == ItemData.StackType.不可堆叠:
		number_label.visible = false
	else:
		if current_count > 1:
			number_label.text = "x" + str(current_count)
			number_label.visible = true
		else:
			number_label.visible = false

# --- 辅助方法（为后续功能做准备） ---

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

	# 2. 准备要传递的数据（我们直接把整张卡牌节点本身传过去，方便后续获取数据）
	var drag_data = self
	
	# 3. 制作拖拽时的半透明“预览图” (Preview)
	var preview_control = Control.new()
	# ⚠️ 这里的路径请替换为你实际的 Card.tscn 的路径！
	var preview_card = load("res://scenes/ui/components/card.tscn").instantiate() 
	preview_control.add_child(preview_card)
	
	# 把当前卡牌的数据复制给预览图
	preview_card.set_data(self.data, self.current_count)
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
		_handle_right_click_transfer()

# 处理右键瞬间跨区传送的逻辑
func _handle_right_click_transfer():
	# 1. 搞清楚自己现在在哪个格子里，属于哪个区
	var current_slot = get_parent()
	if current_slot == null or not current_slot is Slot:
		return
		
	var my_zone = current_slot.my_zone_type
	var target_group = ""
	
	# 2. 决定要去对面的哪个区
	if my_zone == ItemData.Zone.地点栏:
		target_group = "player_zone" # 2区 去 3区
	elif my_zone == ItemData.Zone.人物栏:
		target_group = "ground_zone" # 3区 去 2区
	else:
		return # 如果在 1区(地区栏)，不允许右键传送，直接 return
		
	# 3. 呼叫对面的区
	var target_zone = get_tree().get_first_node_in_group(target_group)
	if target_zone == null:
		print("报错：找不到目标区域分组 " + target_group)
		return
		
	# 4. 执行“剥离 1 个”并传送的逻辑
	if current_count >= 1:
		print("右键快捷传送：从 [%s] 传送 1 个 [%s] 到对面！" % [my_zone, data.name])
		
		# 目标区生成 1 个（利用咱们写好的智能 add_item，它会自动找同类堆叠！）
		target_zone.add_item(self.data, 1)
		
		# 自己这边扣除 1 个
		self.current_count -= 1
		self.update_display()
		
		# 如果自己这边扣光了（比如原本只有1个，或者最后1个被点掉了）
		if self.current_count <= 0:
			var my_slot = get_parent()
			
			# 1. 必须先把自己从格子里强行剥离！
			# (因为 queue_free 是延迟销毁，如果不先剥离，管家洗牌时还会把它算进去)
			if my_slot:
				my_slot.remove_child(self)
				
			# 2. 彻底销毁自己
			self.queue_free()
			
			# 3. 通知管家：我没了，快把后面的牌往前挪！
			if my_slot and my_slot is Slot and my_slot.zone_manager:
				my_slot.zone_manager.reorganize_cards()

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
