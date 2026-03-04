extends PanelContainer 
class_name Card 

# 【核心修改】：现在只存字典了！
var data: Dictionary = {}
var current_count: int = 1
var current_durability: int = -1
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

func _on_mouse_entered(): hover_timer.start()
func _on_mouse_exited(): 
	hover_timer.stop()
	TooltipManager.hide_tooltip()

func _on_hover_timer_timeout():
	if not is_instance_valid(self) or data.is_empty() or is_queued_for_deletion(): return
	TooltipManager.show_tooltip(self)

func set_data(new_data: Dictionary, amount: int = 1):
	data = new_data.duplicate() # 保持数据独立
	current_count = amount
	
	# 【修改】：直接读字典里的中文 Key
	if data.has("最大耐久") and data["最大耐久"] > 0:
		current_durability = data["最大耐久"]
			
	if not is_node_ready(): await ready
	update_display()

func update_display():
	if not is_node_ready() or data.is_empty(): return
	self.modulate.a = 1.0
	
	name_label.text = data.get("名称", "未知物品")
	if data.has("图标") and data["图标"] != null:
		icon_rect.texture = data["图标"]
		
	# 【修改】：堆叠逻辑简化，默认最大99，如果是1则不可堆叠
	var max_stack = data.get("最大堆叠", 99)
	if max_stack <= 1:
		number_label.visible = false
	else:
		number_label.text = "x" + str(current_count) if current_count > 1 else ""
		number_label.visible = current_count > 1

	_update_status_indicators()

func _update_status_indicators():
	for child in status_container.get_children():
		child.queue_free()
		
	if data.has("最大耐久") and data["最大耐久"] > 0:
		var pct = (float(current_durability) / float(data["最大耐久"])) * 100.0
		pct = clamp(pct, 0.0, 100.0) 
		var color = Color.RED if pct <= 30.0 else Color.WHITE
		_create_status_label("⚙️ %d%%" % int(pct), color)

func _create_status_label(text: String, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 12) 
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	status_container.add_child(label)

func add_count(amount: int) -> int:
	var space_left = data.get("最大堆叠", 99) - current_count
	var added = min(amount, space_left)
	current_count += added
	update_display()
	return amount - added 

func _get_drag_data(at_position: Vector2) -> Variant:
	if data.is_empty(): return null
	hover_timer.stop() 
	TooltipManager.hide_tooltip()
	
	var preview_control = Control.new()
	var preview_card = load("res://scenes/cards/card.tscn").instantiate() 
	preview_control.add_child(preview_card)
	
	preview_card.set_data(self.data, self.current_count)
	preview_card.apply_dynamic_state(self.get_dynamic_state())
	preview_card.modulate.a = 0.6 
	preview_card.custom_minimum_size = self.size 
	preview_card.size = self.size
	preview_card.position = -self.size / 2 
	
	set_drag_preview(preview_control)
	self.modulate.a = 0.3
	return self

func _notification(what):
	if what == NOTIFICATION_DRAG_END:
		self.modulate.a = 1.0 

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_handle_right_click_transfer(event.shift_pressed)

func _handle_right_click_transfer(is_shift_pressed: bool = false):
	var current_slot = get_parent()
	if not current_slot is Slot: return
	var source_zone = current_slot.zone_manager
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

	var amount_to_move = self.current_count if is_shift_pressed else 1
	var leftover = amount_to_move 
	var my_state = self.get_dynamic_state()
	
	for target in targets:
		if target == null or not target.visible: continue
		leftover = target.add_item(self.data, leftover, my_state)
		if leftover == 0: break 
			
	var success_count = amount_to_move - leftover
	if success_count > 0:
		self.current_count -= success_count 
		self.update_display()
		if self.current_count <= 0:
			if current_slot: current_slot.remove_child(self)
			self.queue_free()
			if source_zone and source_zone.has_method("reorganize_cards"): 
				source_zone.reorganize_cards()
		EnvironmentManager.call_deferred("recalculate_environment")
		InventoryManager.call_deferred("recalculate_player_stats")

func get_dynamic_state() -> Dictionary:
	var state = {}
	if data.has("最大耐久") and data["最大耐久"] > 0:
		state["durability"] = current_durability
	return state

func apply_dynamic_state(state: Dictionary):
	if state.is_empty(): return
	if state.has("durability"):
		current_durability = state["durability"]
	update_display()
