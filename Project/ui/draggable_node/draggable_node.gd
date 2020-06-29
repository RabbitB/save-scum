tool
extends Node2D


signal dragged(dragged_node, drag_event)

enum ParentTypes {
	CANVAS_ITEM,
	SPRITE,
	CONTROL,
	COLLISION_OBJ,
}

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

export(Rect2) var draggable_area: Rect2 = Rect2(0, 0, 16, 16) setget _set_draggable_area
export(MODIFIER_KEYS) var hold_key_to_drag: int = MODIFIER_KEYS.NONE

var _cached_parent: CanvasItem
var _parent_type: int
var _dragging_node: bool
var _drag_start_relative_to_position: Vector2


func _ready() -> void:
	update_configuration_warning()
	_parent_changed()


func _input(event: InputEvent) -> void:
	if !_cached_parent:
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		var can_drag: bool = !hold_key_to_drag || Input.is_key_pressed(hold_key_to_drag)

		if can_drag && mouse_event.pressed && mouse_event.button_index == BUTTON_LEFT:
			if _parent_type == ParentTypes.SPRITE:
				var sprite = _cached_parent as Sprite
				if sprite.get_rect().has_point(sprite.get_local_mouse_position()):
					_dragging_node = true
					_drag_start_relative_to_position = sprite.global_position - get_global_mouse_position()

					emit_signal("dragged", DRAG_EVENTS.STARTED)
					get_tree().set_input_as_handled()

			elif _parent_type == ParentTypes.CONTROL:
				var control = _cached_parent as Control
				if control.get_global_rect().has_point(get_global_mouse_position()):
					_dragging_node = true
					_drag_start_relative_to_position = control.rect_global_position - get_global_mouse_position()

					emit_signal("dragged", DRAG_EVENTS.STARTED)
					get_tree().set_input_as_handled()

			#	CollisionObject2D feeds input through a signal, so we handle it elsewhere.
			elif !_parent_type == ParentTypes.COLLISION_OBJ:
				if draggable_area.has_point(get_local_mouse_position()):
					_dragging_node = true
					_drag_start_relative_to_position = get_local_mouse_position()

					emit_signal("dragged", DRAG_EVENTS.STARTED)
					get_tree().set_input_as_handled()

		else:
			_dragging_node = false
			_drag_start_relative_to_position = Vector2.ZERO
			emit_signal("dragged", DRAG_EVENTS.ENDED)

	elif event is InputEventMouseMotion:
		if _dragging_node:
			if _parent_type == ParentTypes.CONTROL:
				_cached_parent.set_global_position(get_global_mouse_position() + _drag_start_relative_to_position)
			else:
				_cached_parent.global_position = get_global_mouse_position() + _drag_start_relative_to_position

			emit_signal("dragged", DRAG_EVENTS.DRAGGING)
			get_tree().set_input_as_handled()


func _draw() -> void:
	if Engine.editor_hint && _parent_type == ParentTypes.CANVAS_ITEM:
		draw_rect(draggable_area, Color.violet, false, 1.0, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED || what == NOTIFICATION_UNPARENTED:
		update_configuration_warning()
		_parent_changed()


func _get_configuration_warning() -> String:
	var parent: Node = get_parent()

	if !parent || !(parent is CanvasItem):
		return "DraggableNode must be a child of CanvasItem or a class that extends CanvasItem."

	return ""


func _on_parent_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		_dragging_node = mouse_event.pressed && mouse_event.button_index == BUTTON_LEFT


func _parent_changed() -> void:
	if _cached_parent && _parent_type == ParentTypes.COLLISION_OBJ:
		_cached_parent.disconnect("input_event", self, "_on_parent_input_event")

	var parent: Node = get_parent()
	if !parent or !(parent is CanvasItem):
		_cached_parent = null
		return

	_cached_parent = parent

	if _cached_parent is Sprite:
		_parent_type = ParentTypes.SPRITE
	elif _cached_parent is Control:
		_parent_type = ParentTypes.CONTROL
	elif _cached_parent is CollisionObject2D:
		_parent_type = ParentTypes.COLLISION_OBJ
# warning-ignore:return_value_discarded
		_cached_parent.connect("input_event", self, "_on_parent_input_event")
	else:
		_parent_type = ParentTypes.CANVAS_ITEM

	if Engine.editor_hint:
		update()


func _set_draggable_area(value: Rect2) -> void:
	draggable_area = value
	update()

