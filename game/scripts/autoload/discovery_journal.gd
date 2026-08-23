extends Node

var _entries: Array = []
var _seen_keys: Dictionary = {}


func clear() -> void:
	_entries.clear()
	_seen_keys.clear()


func log_once(key: String, message: String) -> bool:
	if _seen_keys.has(key):
		return false
	_seen_keys[key] = true
	_entries.append(message)
	return true


func get_entries() -> Array:
	return _entries.duplicate()
