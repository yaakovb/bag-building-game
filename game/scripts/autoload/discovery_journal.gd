extends Node

var _entries: Array = []
var _seen_keys: Dictionary = {}


func clear() -> void:
	_entries.clear()
	_seen_keys.clear()


func add_entry(message: String) -> void:
	if message.is_empty():
		return
	_entries.insert(0, message)


func log_once(key: String, message: String) -> bool:
	if key.is_empty() or _seen_keys.has(key):
		return false
	_seen_keys[key] = true
	add_entry(message)
	return true


func get_entries() -> Array:
	return _entries.duplicate()
