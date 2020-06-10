class_name DirectoryBranch
extends Resource


export(Array) var directory_paths: Array


func _init() -> void:
	directory_paths = []


func store_branch(root_path: String) -> int:
	return _find_sub_directories(root_path)


func _find_sub_directories(root_path: String) -> int:
	var dir: Directory = Directory.new()

	var error: int = dir.open(root_path)
	if error:
		Log.error("Failed to find directory %s. Encountered error: %s", [root_path, Log.get_error_description(error)])
		return error

	directory_paths.append(root_path)

	error = dir.list_dir_begin(true, false)
	if error:
		Log.error("Failed to list contents of directory %s. Encountered error: %s", [root_path, Log.get_error_description(error)])
		return error

	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			error = _find_sub_directories(dir.get_current_dir().plus_file(file_name))

#			If we encounter an error when iterating through sub-directories, we should go ahead and exit, as we can
#			no longer use this resource to actually keep track of the directory structure.
			if error:
				dir.list_dir_end()
				return error

		file_name = dir.get_next()

	return OK

