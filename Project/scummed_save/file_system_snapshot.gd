class_name FileSystemSnapshot
extends Resource


export(Dictionary) var directory_paths: Dictionary
export(Dictionary) var file_paths: Dictionary

export(String) var snapshot_of_path: String


func _init() -> void:
	directory_paths = {}
	file_paths = {}


func take_snapshot(of_path: String) -> int:
	snapshot_of_path = of_path
	return _find_sub_directories(of_path)


func files_missing_in(compare_to: FileSystemSnapshot) -> Array:
	if !_can_compare_snapshots(compare_to):
		Log.error("Can only compare hierarchies with the same root path.")
		return []

	var new_files: Array = []
	for file in file_paths:
		if !compare_to.file_paths.has(file):
			new_files.append(file)

	return new_files


func files_modified_from(compare_to: FileSystemSnapshot) -> Array:
	if !_can_compare_snapshots(compare_to):
		Log.error("Can only compare hierarchies with the same root path.")
		return []

	var modified_files: Array = []
	for file in file_paths:
		if compare_to.file_paths.has(file) && file_paths[file] != compare_to.file_paths[file]:
			modified_files.append(file)

	return modified_files


func directories_missing_in(compare_to: FileSystemSnapshot) -> Array:
	if !_can_compare_snapshots(compare_to):
		Log.error("Can only compare hierarchies with the same root path.")
		return []

	var new_dirs: Array = []
	for dir_path in directory_paths:
		if !compare_to.directory_paths.has(dir_path):
			new_dirs.append(dir_path)

	return new_dirs


func _find_sub_directories(root_path: String) -> int:
	var file_helper: File = File.new()
	var dir: Directory = Directory.new()

	var error: int = dir.open(root_path)
	if error:
		Log.error("Failed to open directory %s. Encountered error: %s", [root_path, Log.get_error_description(error)])
		return error

	directory_paths[root_path] = 0

	error = dir.list_dir_begin(true, false)
	if error:
		Log.error("Failed to list contents of directory %s. Encountered error: %s", \
				[root_path, Log.get_error_description(error)])
		return error

	var file_name = dir.get_next()
	while file_name != "":
		var abs_item_path: String = dir.get_current_dir().plus_file(file_name)

		if dir.current_is_dir():
			error = _find_sub_directories(abs_item_path)

#			If we encounter an error when iterating through sub-directories, we should go ahead and exit, as we can
#			no longer use this resource to actually keep track of the directory structure.
			if error:
				dir.list_dir_end()
				return error
		else:
			file_paths[abs_item_path] = file_helper.get_sha256(abs_item_path)

		file_name = dir.get_next()

	return OK


func _can_compare_snapshots(compare_to: FileSystemSnapshot) -> bool:
	return !snapshot_of_path.empty() && snapshot_of_path == compare_to.snapshot_of_path

