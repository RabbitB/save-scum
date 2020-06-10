class_name SaveSnapshot
extends Resource


enum FILE_CHANGE_TYPE { ADDED, DELETED, MODIFIED }

var _changed_files: Dictionary


func _init() -> void:
	_changed_files = {}


func add_file_change(file_path: String, change_type: int) -> void:
	_changed_files[file_path] = change_type

