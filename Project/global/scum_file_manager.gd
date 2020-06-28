extends Node
#	ScummedFileManager is responsible for both saving and restoring files that the user wants to scum.


const ROOT_STORAGE_PATH: String = "user://"
const GAME_DIR_NAME: String = "games"


var _dir_tool: Directory = Directory.new()


func get_path_for_game(for_game: GameID) -> String:
	return ROOT_STORAGE_PATH.plus_file(GAME_DIR_NAME).plus_file(for_game.to_string())


func get_path_for_file(for_game: GameID, file_hash: String) -> String:
	return get_path_for_game(for_game).plus_file("%s.lkr.res" % file_hash)


func create_path_for_game(for_game: GameID) -> void:
	var error: int = _dir_tool.make_dir_recursive(get_path_for_game(for_game))

	if error:
		Log.error("Could not create directory for game: %s" % [for_game.game_name])
		get_tree().quit(1)


func backup_exists(for_game: GameID, file_hash: String) -> bool:
	return _dir_tool.file_exists(get_path_for_file(for_game, file_hash))


func backup_snapshot(for_game: GameID, for_snapshot: FileSystemSnapshot) -> void:
	var files_to_backup: Dictionary = for_snapshot.file_paths
	for file in files_to_backup:
		if !backup_exists(for_game, files_to_backup[file]):
			backup_file(for_game, file)


func restore_to_snapshot(for_game: GameID, to_snapshot: FileSystemSnapshot) -> void:
	var current_snapshot: FileSystemSnapshot = FileSystemSnapshot.new()
	var error: int = current_snapshot.take_snapshot(to_snapshot.snapshot_of_path)
	if error:
		Log.error(
				"Failed to create a snapshot of the save files at '%s'. Encountered error '%s'. Must exit to preserve saves.",
				[to_snapshot.snapshot_of_path, Log.get_error_description(error)]
		)
		get_tree().quit(FAILED)

	# Directories to remove
	for dir in current_snapshot.directories_missing_in(to_snapshot):
		if _dir_tool.dir_exists(dir):
			_delete_non_empty_directory(dir)

	#	Directories to add
	for dir in to_snapshot.directories_missing_in(current_snapshot):
		error = _dir_tool.make_dir_recursive(dir)
		if error:
			Log.error(
					"Failed to create directory '%s'. Encountered error '%s'. Must exit to preserve saves.",
					[dir, Log.get_error_description(error)]
			)
			get_tree().quit(FAILED)

	#	Files to remove
	for file in current_snapshot.files_missing_in(to_snapshot):
		if _dir_tool.file_exists(file):
			error = _dir_tool.remove(file)
			if error:
				Log.error(
						"Failed to delete file '%s'. Encountered error '%s'. Must exit to preserve saves.",
						[file, Log.get_error_description(error)]
				)
				get_tree().quit(FAILED)

	#	Files to add
	for file in to_snapshot.files_missing_in(current_snapshot):
		restore_file(for_game, to_snapshot.file_paths[file])

	#	Files to replace
	for file in to_snapshot.files_modified_from(current_snapshot):
		restore_file(for_game, to_snapshot.file_paths[file])


func backup_file(for_game: GameID, file_path: String) -> void:
	var file_locker: FileLocker = FileLocker.new()
	if !file_locker.store_file(file_path):
		Log.error("Failed to backup the file at %s. Must exit to prevent damage to saves.")
		get_tree().quit(FAILED)

	var error: int = ResourceSaver.save(
			get_path_for_file(for_game, file_locker.file_hash), file_locker, ResourceSaver.FLAG_CHANGE_PATH)
	if error:
		Log.error(
				"Encountered error '%s' when attempting to save a backed-up file. Must exit to prevent damage to saves.",
				[Log.get_error_description(error)]
		)
		get_tree().quit(FAILED)


func restore_file(for_game: GameID, file_hash: String) -> void:
	var file_locker: FileLocker = load(get_path_for_file(for_game, file_hash)) as FileLocker
	var file: File = File.new()

	var error: int = file.open(file_locker.file_path, File.WRITE)
	if error:
		Log.error(
				"Encountered error '%s' when attempting to restore a backup to '%s'. Must exit to prevent corrupted saves.",
				[Log.get_error_description(error), file_locker.file_path]
		)
		get_tree().quit(FAILED)

	file.store_buffer(file_locker.retrieve_file())
	file.close()


func _delete_non_empty_directory(path: String) -> void:
	var dir: Directory = Directory.new()
	var error: int = dir.open(path)
	if error:
		Log.error(
				"Encountered error '%s' when attempting to list contents of dir '%s'. Must exit to prevent corrupted saves.",
				[Log.get_error_description(error), path]
		)
		get_tree().quit(FAILED)

	error = dir.list_dir_begin()
	if error:
		Log.error(
				"Encountered error '%s' when attempting to open directory '%s'. Must exit to prevent corrupted saves.",
				[Log.get_error_description(error), path]
		)
		get_tree().quit(FAILED)

	var current_file_name: String = dir.get_next()
	while !current_file_name.empty():
		var full_file_path: String = path.plus_file(current_file_name)

		if dir.current_is_dir():
			_delete_non_empty_directory(full_file_path)
		else:
			error = dir.remove(full_file_path)
			if error:
				Log.error(
						"Failed to delete file '%s'. Encountered error '%s'. Must exit to prevent file damage.",
						[full_file_path, Log.get_error_description(error)]
				)
				get_tree().quit(FAILED)

		current_file_name = dir.get_next()

	error = dir.remove(path)
	if error:
		Log.error(
				"Failed to delete the directory '%s'. Encountered error '%s'. Must exit to prevent file damage.",
				[path, Log.get_error_description(error)]
		)
		get_tree().quit(FAILED)

