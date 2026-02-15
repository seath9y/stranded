extends Node
# 负责所有数据的保存和加载
# 定义存档文件的存储位置（user://saves/）。
# 提供 save_game(slot_name) 和 load_game(slot_name) 函数，供游戏内存档/读档按钮调用。
# 获取所有存档槽列表（get_save_slots()），用于存档选择界面。
# 内部使用 Godot 的 Resource 系统，将游戏状态打包成 SaveData 资源并写入文件。

const SAVE_DIR = "user://saves/"

func _ready():
	# 确保存档目录存在
	DirAccess.make_dir_absolute(SAVE_DIR)

func save_game(slot_name: String) -> bool:
	# TODO: 实现保存逻辑
	print("保存到槽位: ", slot_name)
	return true

func load_game(slot_name: String) -> bool:
	# TODO: 实现加载逻辑
	print("加载槽位: ", slot_name)
	return true

func get_save_slots() -> Array:
	var slots = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				slots.append(file_name.trim_suffix(".tres"))
			file_name = dir.get_next()
	return slots
