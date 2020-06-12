class_name GameID
extends Resource


export(String) var name: String
export(int) var creation_time: int


func _init(new_name: String = "") -> void:
	if !new_name.empty():
		name = new_name

	creation_time = OS.get_unix_time()


func get_game_id(salt: int = 0) -> String:
	return ("%d.%d" % [salt, creation_time]).md5_text()

