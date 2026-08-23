class_name ActionToken

enum Type {
	ATTACK,
	DEFENSE,
	MAGIC,
	SUPPORT,
	LEADERSHIP,
}

const SYMBOLS: Dictionary = {
	Type.ATTACK: "A",
	Type.DEFENSE: "D",
	Type.MAGIC: "M",
	Type.SUPPORT: "S",
	Type.LEADERSHIP: "L",
}

const NAMES: Dictionary = {
	Type.ATTACK: "Attack",
	Type.DEFENSE: "Defense",
	Type.MAGIC: "Magic",
	Type.SUPPORT: "Support",
	Type.LEADERSHIP: "Leadership",
}

const ALL_TYPES: Array = [
	Type.ATTACK,
	Type.DEFENSE,
	Type.MAGIC,
	Type.SUPPORT,
	Type.LEADERSHIP,
]


static func from_string(value: String) -> int:
	var key := value.to_lower()
	match key:
		"attack":
			return Type.ATTACK
		"defense":
			return Type.DEFENSE
		"magic":
			return Type.MAGIC
		"support":
			return Type.SUPPORT
		"leadership":
			return Type.LEADERSHIP
		_:
			push_error("Unknown action token: %s" % value)
			return Type.ATTACK


static func parse_cost_map(data: Dictionary) -> Dictionary:
	var costs: Dictionary = {}
	for key in data.keys():
		var token_type := from_string(key)
		costs[token_type] = int(data[key])
	return costs


static func empty_pool() -> Dictionary:
	var pool: Dictionary = {}
	for token_type in ALL_TYPES:
		pool[token_type] = 0
	return pool


static func add_tokens(pool: Dictionary, token_type: int, amount: int) -> void:
	pool[token_type] = pool.get(token_type, 0) + amount


static func can_pay(pool: Dictionary, costs: Dictionary) -> bool:
	for token_type in costs.keys():
		if pool.get(token_type, 0) < costs[token_type]:
			return false
	return true


static func pay(pool: Dictionary, costs: Dictionary) -> void:
	for token_type in costs.keys():
		pool[token_type] = pool.get(token_type, 0) - costs[token_type]


static func pool_to_string(pool: Dictionary) -> String:
	var parts: PackedStringArray = []
	for token_type in ALL_TYPES:
		var count: int = pool.get(token_type, 0)
		if count > 0:
			parts.append("%s×%d" % [SYMBOLS[token_type], count])
	return ", ".join(parts)
