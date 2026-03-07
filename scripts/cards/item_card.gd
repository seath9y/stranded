extends PanelContainer 
class_name Card 

var data: Dictionary = {}
# 🌟 核心重构：彻底取代 current_count 和 current_durability
# 存储该卡牌叠放的每一个实体的独立状态（如 {"durability": 8}, {"durability": 10}）
# 索引 0 永远是最上面的一张！
var stacked_states: Array[Dictionary] = []
var is_drag_preview: bool = false
var hover_timer: Timer

@onready var icon_rect: TextureRect = $VBox/ContentMargin/Overlay/Icon
@onready var name_label: Label = $VBox/HeaderMargin/HeaderHBox/NameLabel
@onready var number_label: Label = $VBox/HeaderMargin/HeaderHBox/Number
@onready var status_container: VBoxContainer = $VBox/ContentMargin/Overlay/Stats/RightGroup

func _ready():
	if not data.is_empty():
		update_display()
	hover_timer = Timer.new()
	hover_timer.wait_time = 0.5 
	hover_timer.one_shot = true
	hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(hover_timer)
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	get_tree().get_root().size_changed.connect(_update_responsive_size)
	_update_responsive_size()

func _update_responsive_size():
	# 🌟 核心拦截：如果是拖拽预览卡牌，禁止引擎重算尺寸！
	if is_drag_preview: return 
	
	var screen_width = get_viewport().size.x
	var base_width = clamp(screen_width * 0.045, 60.0, 100.0)
	var target_size = Vector2(base_width, base_width * 1.2) - Vector2(4, 4)
	
	self.custom_minimum_size = target_size
	self.size = target_size
	
	if has_method("update_display"):
		update_display()

func _on_mouse_entered(): hover_timer.start()
func _on_mouse_exited(): 
	hover_timer.stop()
	TooltipManager.hide_tooltip()

func _on_hover_timer_timeout():
	if not is_instance_valid(self) or data.is_empty() or is_queued_for_deletion(): return
	TooltipManager.show_tooltip(self)

#func set_data(new_data: Dictionary, amount: int = 1):
	#data = new_data.duplicate() 
	#
	## 兼容旧系统：如果只传了数量，就自动生成基础状态数组
	#stacked_states.clear()
	#for i in range(amount):
		#var base_state = {}
		#if data.has("最大耐久") and data["最大耐久"] > 0:
			#base_state["durability"] = data["最大耐久"]
		#stacked_states.append(base_state)
			#
	#if not is_node_ready(): await ready
	#update_display()
func set_data(new_data: Dictionary, amount: int = 1):
	data = new_data.duplicate() 
	stacked_states.clear()
	
	# 如果外部调用传了数量，则填充默认状态（会被后续的 add_item 覆盖）
	if amount > 0:
		add_count(amount)
			
	# 核心修复：彻底删除 await ready！
	# 我们靠 _ready() 里的 update_display 来处理初始渲染
	if is_node_ready():
		update_display()
func update_display():
	if not is_node_ready() or data.is_empty() or stacked_states.is_empty(): return
	self.modulate.a = 1.0
	
	name_label.text = data.get("名称", "未知物品")
	if data.has("图标") and data["图标"] != null:
		icon_rect.texture = data["图标"]
		
	var max_stack = data.get("最大堆叠", 99)
	var current_count = stacked_states.size()
	
	if max_stack <= 1:
		number_label.visible = false
	else:
		number_label.text = "x" + str(current_count) if current_count > 1 else ""
		number_label.visible = current_count > 1

	_update_status_indicators()

# 🌟 重构：现在永远只读取数组最上方 [0] 的耐久度
func _update_status_indicators():
	for child in status_container.get_children():
		child.queue_free()
		
	if stacked_states.is_empty(): return
	
	var top_state = stacked_states[0]
	if data.has("最大耐久") and data["最大耐久"] > 0:
		var current_dur = top_state.get("durability", data["最大耐久"])
		var pct = (float(current_dur) / float(data["最大耐久"])) * 100.0
		pct = clamp(pct, 0.0, 100.0) 
		var color = Color.RED if pct <= 30.0 else Color.WHITE
		
		var label = Label.new()
		label.text = "⚙️ %d%%" % int(pct)
		label.add_theme_color_override("font_color", color)
		label.add_theme_font_size_override("font_size", 12) 
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		status_container.add_child(label)
	if data.has("最大新鲜度") and data["最大新鲜度"] > 0:
		var cur_fresh = top_state.get("freshness", data["最大新鲜度"])
		var pct = (float(cur_fresh) / float(data["最大新鲜度"])) * 100.0
		pct = clamp(pct, 0.0, 100.0) 
		# 越不新鲜越红
		var color = Color.RED if pct <= 30.0 else Color.GREEN
		
		var label = Label.new()
		label.text = "🥩 %d%%" % int(pct)
		label.add_theme_color_override("font_color", color)
		label.add_theme_font_size_override("font_size", 12) 
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		status_container.add_child(label)
# 🌟 重构：允许在增加数量时，直接注入特定的状态字典
func add_count(amount: int, state: Dictionary = {}) -> int:
	var max_stack = data.get("最大堆叠", 99)
	var space_left = max_stack - stacked_states.size()
	var added = min(amount, space_left)
	
	for i in range(added):
		var new_state = state.duplicate(true) if not state.is_empty() else {}
		if new_state.is_empty():
			if data.has("最大耐久") and data["最大耐久"] > 0:
				new_state["durability"] = data["最大耐久"]
			if data.has("最大新鲜度") and data["最大新鲜度"] > 0:
				new_state["freshness"] = data["最大新鲜度"]
		stacked_states.append(new_state)
	# 🌟 注入后立刻排序
	sort_stacked_states()
	# 只有在节点准备好时才更新 UI，防止空指针
	if is_node_ready():
		update_display()
	return amount - added
		
	update_display()
	return amount - added

func _get_drag_data(at_position: Vector2) -> Variant:
	if data.is_empty(): return null
	hover_timer.stop() 
	TooltipManager.hide_tooltip()
	
	var preview_control = Control.new()
	var preview_card = load("res://scenes/cards/card.tscn").instantiate() 
	preview_control.add_child(preview_card)
	# 🌟 开启防缩小护盾，必须在赋值前开启！
	preview_card.is_drag_preview = true
	preview_card.set_data(self.data, stacked_states.size())
	# 复制自己当前的所有状态给预览图
	preview_card.stacked_states = self.stacked_states.duplicate(true)
	preview_card.modulate.a = 0.6 
	preview_card.custom_minimum_size = self.size 
	preview_card.size = self.size
	preview_card.position = -self.size / 2 
	preview_control.z_index = 999
	set_drag_preview(preview_control)
	self.modulate.a = 0.3
	return self

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		self.modulate.a = 1.0 

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_handle_right_click_transfer(event.shift_pressed)

# 🌟 重构核心：基于数组的出栈（Pop Front）与全转移
#func _handle_right_click_transfer(is_shift_pressed: bool = false):
	#var current_slot = get_parent()
	#if not current_slot is Slot: return
	#var source_zone = current_slot.zone_manager
	#if source_zone == null or source_zone.is_in_group("area_zone"): return
		#
	#var targets: Array = []
	#if source_zone.is_in_group("ground_zone"):
		#var player_zone = get_tree().get_first_node_in_group("group_player_zone")
		#var equip_zone = get_tree().get_first_node_in_group("group_equip_zone")
		#if player_zone and player_zone.is_visible_in_tree():
			#targets.append(player_zone)
			#targets.append(get_tree().get_first_node_in_group("group_backpack_zone"))
		#elif equip_zone and equip_zone.is_visible_in_tree():
			#targets.append(equip_zone)
	#else:
		#targets.append(get_tree().get_first_node_in_group("ground_zone"))
#
	## 决定要转移的状态列表
	#var states_to_move: Array[Dictionary] = []
	#if is_shift_pressed:
		#states_to_move = stacked_states.duplicate(true) # 连锅端
	#else:
		#states_to_move.append(stacked_states[0].duplicate(true)) # 单抽最上面
#
	#for target in targets:
		#if target == null or not target.visible: continue
		#if states_to_move.is_empty(): break
		#
		#var next_round_states: Array[Dictionary] = []
		## 为了兼容 zone_manager 的接口，我们拆成单份循环投递
		#for state in states_to_move:
			#var leftover = target.add_item(self.data, 1, state)
			#if leftover > 0:
				#next_round_states.append(state)
		#states_to_move = next_round_states 
			#
	#var success_count = (stacked_states.size() if is_shift_pressed else 1) - states_to_move.size()
	#
	#if success_count > 0:
		#if is_shift_pressed:
			#stacked_states = states_to_move # 剩下没投成功的保留
		#else:
			#stacked_states.pop_front() # 单体投递成功，弹出顶部
#
		#self.update_display()
		#if stacked_states.is_empty():
			#if current_slot: current_slot.remove_child(self)
			#self.queue_free()
			#if source_zone and source_zone.has_method("reorganize_cards"): 
				#source_zone.reorganize_cards()
				#
		#EnvironmentManager.call_deferred("recalculate_environment")
		#InventoryManager.call_deferred("recalculate_player_stats")
# scripts/cards/item_card.gd

# 🌟 统一右键逻辑：智能识别“窗口模式”与“常规互传模式”
func _handle_right_click_transfer(is_shift_pressed: bool = false):
	# 1. 探测当前是否有打开的接收窗口 (制作、烹饪、蓝图等)
	var active_window = null
	var receivers = get_tree().get_nodes_in_group("group_card_receiver")
	for r in receivers:
		if r.is_visible_in_tree():
			active_window = r
			break
			
	var current_parent = get_parent()
	
	# --- 情况 A: 当有功能窗口打开时 ---
	if active_window:
		# 逻辑 1: 如果卡牌在标准 Slot 里 (说明是在外面：地面、背包、装备栏)
		if current_parent is Slot:
			if active_window.try_receive_card(self):
				return # 成功填入，结束
			else:
				return # 即使标签不符没收下，也要拦截掉互传，防止误触
		# 逻辑 2: 如果已经在窗口容器里，右键则弹出到地面
		else:
			_move_to_ground_directly(is_shift_pressed)
			return

	# --- 情况 B: 常规状态 (无窗口打开)，执行你原有的互传逻辑 ---
	if not current_parent is Slot: return
	var source_zone = current_parent.zone_manager
	if source_zone == null or source_zone.is_in_group("area_zone"): return
		
	var targets: Array = []
	if source_zone.is_in_group("ground_zone"):
		var player_zone = get_tree().get_first_node_in_group("group_player_zone")
		var equip_zone = get_tree().get_first_node_in_group("group_equip_zone")
		if player_zone and player_zone.is_visible_in_tree():
			targets.append(player_zone)
			targets.append(get_tree().get_first_node_in_group("group_backpack_zone"))
		elif equip_zone and equip_zone.is_visible_in_tree():
			targets.append(equip_zone)
	else:
		targets.append(get_tree().get_first_node_in_group("ground_zone"))

	# 决定要转移的状态列表
	var states_to_move: Array[Dictionary] = []
	if is_shift_pressed:
		states_to_move = stacked_states.duplicate(true)
	else:
		states_to_move.append(stacked_states[0].duplicate(true))

	for target in targets:
		if target == null or not target.visible: continue
		if states_to_move.is_empty(): break
		
		var next_round_states: Array[Dictionary] = []
		for state in states_to_move:
			var leftover = target.add_item(self.data, 1, state)
			if leftover > 0:
				next_round_states.append(state)
		states_to_move = next_round_states 
			
	var success_count = (stacked_states.size() if is_shift_pressed else 1) - states_to_move.size()
	
	if success_count > 0:
		if is_shift_pressed:
			stacked_states = states_to_move
		else:
			stacked_states.pop_front()

		self.update_display()
		if stacked_states.is_empty():
			if current_parent: current_parent.remove_child(self)
			self.queue_free()
			if source_zone and source_zone.has_method("reorganize_cards"): 
				source_zone.reorganize_cards()
				
		EnvironmentManager.call_deferred("recalculate_environment")
		InventoryManager.call_deferred("recalculate_player_stats")

# 🌟 辅助函数：从窗口中快速弹出到地面
func _move_to_ground_directly(is_shift_pressed: bool):
	var ground = get_tree().get_first_node_in_group("ground_zone")
	if not ground: return
	
	var states_to_move = stacked_states.duplicate(true) if is_shift_pressed else [stacked_states[0].duplicate(true)]
	var success_count = 0
	
	for s in states_to_move:
		if ground.add_item(self.data, 1, s) == 0:
			success_count += 1
			
	if success_count > 0:
		if is_shift_pressed:
			stacked_states.clear()
		else:
			for i in range(success_count):
				stacked_states.pop_front()
		
		update_display()
		if stacked_states.is_empty():
			if get_parent(): get_parent().remove_child(self)
			queue_free()
func get_dynamic_state() -> Dictionary:
	if stacked_states.size() > 0:
		return stacked_states[0].duplicate()
	return {}

func apply_dynamic_state(state: Dictionary):
	if state.is_empty() or stacked_states.is_empty(): return
	stacked_states[0] = state.duplicate()
	update_display()
# 🌟 新增内部排序函数
func sort_stacked_states():
	if stacked_states.size() <= 1: return
	
	stacked_states.sort_custom(func(a, b):
		# 尝试获取耐久或新鲜度，若都没有则视为 99999（排在最后）
		var val_a = a.get("durability", a.get("freshness", 99999))
		var val_b = b.get("durability", b.get("freshness", 99999))
		return val_a < val_b # 升序：10新鲜度的排在索引 0 (最上面)
	)
