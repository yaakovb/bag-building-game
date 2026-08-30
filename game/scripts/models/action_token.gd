class_name ActionToken

enum Type {
	ATTACK,
	DEFENSE,
	MAGIC,
	SUPPORT,
	LEADERSHIP,
}

const EMOJI: Dictionary = {
	Type.ATTACK: "⚔️",
	Type.DEFENSE: "🛡️",
	Type.MAGIC: "🔮",
	Type.SUPPORT: "💚",
	Type.LEADERSHIP: "🚩",
}

const SYMBOLS: Dictionary = EMOJI

const NAMES: Dictionary = {
	Type.ATTACK: "Attack",
	Type.DEFENSE: "Defense",
	Type.MAGIC: "Magic",
	Type.SUPPORT: "Support",
	Type.LEADERSHIP: "Leadership",
}

const FILL: Dictionary = {
	Type.ATTACK: Color("3b82f6"),
	Type.DEFENSE: Color("3b82f6"),
	Type.MAGIC: Color("3b82f6"),
	Type.SUPPORT: Color("3b82f6"),
	Type.LEADERSHIP: Color("3b82f6"),
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


static func combined_pool(left: Dictionary, right: Dictionary) -> Dictionary:
	var out: Dictionary = empty_pool()
	for token_type in ALL_TYPES:
		out[token_type] = int(left.get(token_type, 0)) + int(right.get(token_type, 0))
	return out


static func subtract_pool(left: Dictionary, right: Dictionary) -> Dictionary:
	var out: Dictionary = empty_pool()
	for token_type in ALL_TYPES:
		out[token_type] = maxi(0, int(left.get(token_type, 0)) - int(right.get(token_type, 0)))
	return out


static func total(pool: Dictionary) -> int:
	var count := 0
	for token_type in ALL_TYPES:
		count += int(pool.get(token_type, 0))
	return count


static func can_pay(pool: Dictionary, costs: Dictionary) -> bool:
	for token_type in costs.keys():
		if pool.get(token_type, 0) < costs[token_type]:
			return false
	return true


static func pay(pool: Dictionary, costs: Dictionary) -> void:
	for token_type in costs.keys():
		pool[token_type] = pool.get(token_type, 0) - costs[token_type]


static func is_pair_payment(payment: Dictionary) -> bool:
	if total(payment) != 2:
		return false
	for token_type in ALL_TYPES:
		if int(payment.get(token_type, 0)) == 2:
			return true
	return false


static func is_valid_conversion(payment: Dictionary) -> bool:
	var paid := total(payment)
	if paid == 2:
		return is_pair_payment(payment)
	return paid == 3


static func pool_to_string(pool: Dictionary) -> String:
	var parts: PackedStringArray = []
	for token_type in ALL_TYPES:
		var count: int = pool.get(token_type, 0)
		if count > 0:
			parts.append("%s×%d" % [EMOJI[token_type], count])
	return ", ".join(parts)
