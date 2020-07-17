tool
extends Node2D


signal dragged(dragged_node, drag_event)

enum MODIFIER_KEYS {
	NONE = 0,
	SHIFT = KEY_SHIFT,
	ALT = KEY_ALT,
	CONTROL = KEY_CONTROL,
	SPACE = KEY_SPACE
}

enum DRAG_EVENTS {
	STARTED,
	DRAGGING,
	ENDED
}

export(NodePath) var handle_path: NodePath setget _set_handle_path
export(NodePath) var target_path: NodePath setget _set_target_path
export(Rect2) var handle_area: Rect2 = Rect2(0, 0, 16, 16) setget _set_handle_area
export(MODIFIER_KEYS) var hold_key_to_drag: int = MODIFIER_KEYS.NONE

var _handle: Node2D
var _target: Node2D

var _is_dragging: bool
var _mouse_to_origin_offset: Vector2


func _ready() -> void:
	update_configuration_warning()


func _input(event: InputEvent) -> void:
	_update_handle()
	_update_target()

	if !_handle || !_target:
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		var can_drag: bool = !hold_key_to_drag || Input.is_key_pressed(hold_key_to_drag)

		if can_drag && mouse_event.pressed && mouse_event.button_index == BUTTON_LEFT:
			var draggable_area: Rect2 = (_handle as Sprite).get_rect() if _handle is Sprite else handle_area

			#	CollisionObject2D feeds input through a signal, so we handle it elsewhere.
			if !(_handle is CollisionObject2D):
				if draggable_area.has_point(_handle.get_local_mouse_position()):
					_is_dragging = true
					_mouse_to_origin_offset = _handle.global_position - get_global_mouse_position()

					emit_signal("dragged", DRAG_EVENTS.STARTED)
					get_tree().set_input_as_handled()

		else:
			var was_dragging: bool = _is_dragging
			_is_dragging = false
			_mouse_to_origin_offset = Vector2.ZERO

			if was_dragging:
				emit_signal("dragged", DRAG_EVENTS.ENDED)

	elif event is InputEventMouseMotion:
		if _is_dragging:
			_target.global_position = get_global_mouse_position() + _mouse_to_origin_offset

			emit_signal("dragged", DRAG_EVENTS.DRAGGING)
			get_tree().set_input_as_handled()


func _draw() -> void:
	_update_handle()

	if Engine.editor_hint && _handle != null && !(_handle is Sprite || _handle is CollisionObject2D):
		draw_rect(handle_area, Color.violet, false, 1.0, true)


func _get_configuration_warning() -> String:
	_update_handle()
	_update_target()

	if !_handle && !_target:
		return "Both the handle and target must be a child of Node2D or a class that extends Node2D."

	if !_handle:
		return "The handle must be a child of Node2D or a class that extends Node2D."

	if !_target:
		return "The target must be a child of Node2D or a class that extends Node2D."

	return ""


func _on_parent_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		_is_dragging = mouse_event.pressed && mouse_event.button_index == BUTTON_LEFT


func _update_handle() -> void:
	if _handle == null && !handle_path.is_empty():
		_handle = get_node(handle_path)

		if !(_handle is Node2D):
			_handle = null
		elif _handle is CollisionObject2D:
# warning-ignore:return_value_discarded
			_handle.connect("input_event", self, "_on_handle_input_event")

		if Engine.editor_hint:
			update()


func _update_target() -> void:
	if _target == null && !target_path.is_empty():
		_target = get_node(target_path)

		if !(_target is Node2D):
			_target = null


func _set_handle_path(value: NodePath) -> void:
	handle_path = value

	if _handle && _handle is CollisionObject2D:
		_handle.disconnect("input_event", self, "_on_handle_input_event")

	_handle = null
	update_configuration_warning()


func _set_target_path(value: NodePath) -> void:
	target_path = value

	_target = null
	update_configuration_warning()


func _set_handle_area(value: Rect2) -> void:
	handle_area = value
	update()

