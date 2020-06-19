class_name GameID
extends Resource


export(String) var game_name: String
export(int) var game_id: int = -1


func _init(new_name: String = "") -> void:
	if !new_name.empty():
		game_name = new_name


func get_game_id() -> int:
	if game_id < 0:
		game_id = ScumDB.get_new_game_id()

	return game_id

