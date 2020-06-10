class_name FileLocker
extends Resource


const COMPRESSION_METHOD: int = File.COMPRESSION_ZSTD

export(PoolByteArray) var stored_data: PoolByteArray
export(bool) var is_compressed: bool

export(String) var file_path: String
export(String) var file_md5: String
export(int) var file_size: int


func store_file(path: String) -> bool:
	var file_to_store: File = File.new()

	var error: int = file_to_store.open(path, File.READ)
	if error:
		Log.error("Failed to open file %s for storage. Encountered error: %s", [path, Log.get_error_description(error)])
		return false

	file_path = path
	file_md5 = file_to_store.get_md5(file_path)
	file_size = file_to_store.get_len()

	var raw_data: PoolByteArray = file_to_store.get_buffer(file_size)
	file_to_store.close()

	stored_data = raw_data.compress(COMPRESSION_METHOD)

	if stored_data.size() >= file_size:
		stored_data = raw_data
		is_compressed = false
	else:
		is_compressed = true

	return true


func retrieve_file() -> PoolByteArray:
	if !stored_data:
		Log.warning("Attempted to retrieve stored file from an empty FileLocker.")
		return PoolByteArray()

	if is_compressed:
		return stored_data.decompress(file_size, COMPRESSION_METHOD)
	else:
		return stored_data

