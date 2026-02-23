# ================= res://scripts/utils/node_utils.gd =================
class_name NodeUtils
extends Object

## 深度递归查找：在父节点下寻找第一个包含指定属性的子节点/孙节点
static func find_child_with_property(parent: Node, property_name: String) -> Node:
	for child in parent.get_children():
		# 检查当前节点是否具有该属性
		if property_name in child:
			return child
		
		# 如果没有，递归往它的肚子里找
		var found = find_child_with_property(child, property_name)
		if found:
			return found
			
	return null
## 递归查找：在节点深处寻找类型为 Card 的节点
static func find_card_in_node(parent: Node) -> Node:
	for child in parent.get_children():
		print(parent,'child',child)
		# 【关键！】直接判断它是不是 Card 类型
		if child is Card:
			return child
		
		# 如果不是，去这个子节点的肚子里继续递归找
		var found = find_card_in_node(child)
		print('found',found)
		if found:
			return found
			
	return null
## （预留扩展）深度递归查找：寻找特定类型的节点
static func find_child_of_type(parent: Node, type_class) -> Node:
	for child in parent.get_children():
		if is_instance_of(child, type_class):
			return child
			
		var found = find_child_of_type(child, type_class)
		if found:
			return found
			
	return null
