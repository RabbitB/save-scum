extends Node


signal state_switched(new_state, prev_state)

var _states: Dictionary
var _current_state: String = ""


func _init() -> void:
	_states = {}


func add_state(name: String) -> void:
	assert(!_states.has(name))
	_states[name] = []


func remove_state(name: String) -> void:
	assert(_states.has(name))
	assert(name != _current_state)

# warning-ignore:return_value_discarded
	_states.erase(name)


func switch_state(name: String) -> void:
	assert(_states.has(name))
	var old_state: String = _current_state
	_current_state = name

	for task in _states[name]:
		_perform_task(task)

	emit_signal("state_switched", _current_state, old_state)


func get_current_state() -> String:
	return _current_state


func add_task_to_state(name: String, target: Object, method_name: String) -> void:
	assert(_states.has(name))
	_states[name].append(_create_task(target, method_name))


func remove_task_from_state(name: String, target: Object, method_name: String) -> void:
	assert(_states.has(name))
	var tasks: Array = _states[name]

	var remove_idx: int = -1
	for task_idx in tasks.size():
		if tasks[task_idx].target == target && tasks[task_idx].method_name == method_name:
			remove_idx = task_idx
			break

	if remove_idx != -1:
		tasks.remove(remove_idx)


func _create_task(target: Object, method_name: String) -> Dictionary:
	return { "target": target, "method_name": method_name }


func _perform_task(task: Dictionary) -> void:
	(task.target as Object).call(task.method_name)

