extends Node


const CONFIG_FILE_PATH: String = "user://scum_db.cfg"

const GROUP_NAME_ID: String = "identifiers"
const KEY_GAMES: String = "games"
const KEY_RECYCLED_GAMES: String = "recycled_games"

var _config_file: ConfigFile = ConfigFile.new()
var _last_used_game_id: int
var _recycled_game_ids: Array


func _init() -> void:
	_recycled_game_ids = []


func _ready() -> void:
	load_scum_db()


func load_scum_db() -> void:
	var file_helper: File = File.new()
	if !file_helper.file_exists(CONFIG_FILE_PATH):
		_save_scum_db()

	var error: int = _config_file.load(CONFIG_FILE_PATH)
	if error:
		Log.error("Error loading the file db. Error code %s. To preserve existing saves, cannot continue." \
				 % [Log.get_error_description(error)])
		get_tree().quit(FAILED)
	else:
		_last_used_game_id = _config_file.get_value(GROUP_NAME_ID, KEY_GAMES, -1)
		_recycled_game_ids = _config_file.get_value(GROUP_NAME_ID, KEY_RECYCLED_GAMES, [])


func get_new_game_id() -> int:
	var new_game_id: int
	if _recycled_game_ids.size() > 0:
		new_game_id = _recycled_game_ids.pop_front()
		_config_file.set_value(GROUP_NAME_ID, KEY_RECYCLED_GAMES, _recycled_game_ids)
	else:
		_last_used_game_id += 1
		new_game_id = _last_used_game_id
		_config_file.set_value(GROUP_NAME_ID, KEY_GAMES, _last_used_game_id)

	_save_scum_db()
	return new_game_id


func recycle_game_id(recycle_id: int) -> void:
	_recycled_game_ids.append(recycle_id)
	_config_file.set_value(GROUP_NAME_ID, KEY_RECYCLED_GAMES, _recycled_game_ids)
	_save_scum_db()


func _save_scum_db() -> void:
	var error: int = _config_file.save(CONFIG_FILE_PATH)
	if error:
		Log.error("Error saving the file db. Error code %s. To preserve existing saves, cannot continue." \
				% [Log.get_error_description(error)])
		get_tree().quit(FAILED)

