extends Node

func _ready():
	print("GameManager: ", GameManager)
	print("TimeManager: ", TimeManager)
	print("DataManager: ", DataManager)
	print("当前时间: ", TimeManager.get_time_string())
