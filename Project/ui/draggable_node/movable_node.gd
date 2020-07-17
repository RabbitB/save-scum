extends Reference


var node_to_move: Node setget _set_node_to_move
var global_position: Vector2 setget _set_global_position, _get_global_position
var position: Vector2 setget _set_position, _get_position


func _init(node: Node) -> void:
	if node:
		self.node_to_move = node


func _set_global_position(new_pos: Vector2) -> void:
	if !node_to_move:
		return

	if node_to_move is Node2D:
		(node_to_move as Node2D).global_position = new_pos
	else:
		(node_to_move as Control).rect_global_position = new_pos


func _get_global_position() -> Vector2:
	if !node_to_move:
		return Vector2.INF

	if node_to_move is Node2D:
		return (node_to_move as Node2D).global_position

	# By this point, we've already filtered out every other alternative. So node_to_move must be a Control
	# if we reached this far into the method.
	return (node_to_move as Control).rect_global_position


func _set_position(new_pos: Vector2) -> void:
	if !node_to_move:
		return

	if node_to_move is Node2D:
		(node_to_move as Node2D).position = new_pos
	else:
		(node_to_move as Control).rect_position = new_pos


func _get_position() -> Vector2:
	if !node_to_move:
		return Vector2.INF

	if node_to_move is Node2D:
		return (node_to_move as Node2D).position

	# By this point, we've already filtered out every other alternative. So node_to_move must be a Control
	# if we reached this far into the method.
	return (node_to_move as Control).rect_position


func _set_node_to_move(value: Node) -> void:
	node_to_move = value if (value is Node2D || value is Control) else null

