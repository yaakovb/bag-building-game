class_name Bag

var _bag: Array = []
var _discard: Array = []


func clear() -> void:
	_bag.clear()
	_discard.clear()


func bag_count() -> int:
	return _bag.size()


func discard_count() -> int:
	return _discard.size()


func add_to_bag(token_type: int, amount: int) -> void:
	for _i in amount:
		_bag.append(token_type)


func add_to_discard(token_type: int, amount: int) -> void:
	for _i in amount:
		_discard.append(token_type)


func add_contribution(contribution: Dictionary) -> void:
	for token_type in contribution.keys():
		add_to_discard(token_type, contribution[token_type])


func shuffle_discard_into_bag() -> void:
	if _discard.is_empty():
		return
	_bag.append_array(_discard)
	_discard.clear()
	_bag.shuffle()


func draw(count: int) -> Array:
	var drawn: Array = []
	for _i in count:
		if _bag.is_empty():
			shuffle_discard_into_bag()
		if _bag.is_empty():
			break
		drawn.append(_bag.pop_back())
	return drawn


func discard_breakdown() -> Dictionary:
	var breakdown: Dictionary = ActionToken.empty_pool()
	for token_type in _discard:
		ActionToken.add_tokens(breakdown, token_type, 1)
	return breakdown
