extends Node
#	ScummedFileManager is responsible for both saving and restoring files that the user wants to scum.


const ROOT_STORAGE_PATH: String = "user://"
const GAME_DIR_NAME: String = "games"


func _ready() -> void:
	pass


func get_path_for_game(for_game: GameID) -> String:
	return ROOT_STORAGE_PATH.plus_file(GAME_DIR_NAME).plus_file("%x" % [for_game.get_game_id()])


func get_path_for_file(for_game: GameID, file_md5: String) -> String:
	return get_path_for_game(for_game).plus_file("%s.lkr.res" % [file_md5])


func create_path_for_game(for_game: GameID) -> void:
	var dir: Directory = Directory.new()
	var error: int = dir.make_dir_recursive(get_path_for_game(for_game))

	if error:
		Log.error("Could not create directory for game: %s" % [for_game.game_name])
		get_tree().quit(1)


func backup_file(for_game: GameID, file_path: String) -> void:
	var file_locker: FileLocker = FileLocker.new()
	if !file_locker.store_file(file_path):
		Log.error("Failed to backup the file at %s. Must exit to prevent damage to saves.")
		get_tree().quit(FAILED)

	var error: int = ResourceSaver.save(
			get_path_for_file(for_game, file_locker.file_md5), file_locker, ResourceSaver.FLAG_CHANGE_PATH)
	if error:
		Log.error(
				"Encountered error '%s' when attempting to save a backed-up file. Must exit to prevent damage to saves.",
				[Log.get_error_description(error)]
		)
		get_tree().quit(FAILED)


func restore_file(for_game: GameID, file_md5, restore_to_path: String) -> void:
	var file_locker: FileLocker = load(get_path_for_file(for_game, file_md5)) as FileLocker
	var file: File = File.new()

	var error: int = file.open(restore_to_path, File.WRITE)
	if error:
		Log.error(
				"Encountered error '%s' when attempting to restore a backup to '%s'. Must exit to prevent corrupted saves.",
				[Log.get_error_description(error), restore_to_path]
		)
		get_tree().quit(FAILED)

	file.store_buffer(file_locker.retrieve_file())
	file.close()


func _detect_file_usage() -> void:
	pass

