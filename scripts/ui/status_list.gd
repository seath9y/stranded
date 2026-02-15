extends VBoxContainer

# 添加一个新状态条目
#func add_status(status_id: String, icon: Texture2D, name: String, initial_value: float, max_value: float):
	# 实例化状态条目场景（我们稍后可以创建一个 status_item.tscn）
	#var item = preload("res://scenes/ui/status_item.tscn").instantiate()
	#item.setup(status_id, icon, name, initial_value, max_value)
	#add_child(item)

# 移除一个状态条目
func remove_status(status_id: String):
	for child in get_children():
		if child.has_method("get_status_id") and child.get_status_id() == status_id:
			child.queue_free()
			break
