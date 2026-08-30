class_name OfferGenerator


static func generate_offer(
	templates: Dictionary,
	recruit_ids: Array,
	extra_basic: bool
) -> Array:
	var basics: Array = []
	var priced: Array = []
	for id in recruit_ids:
		var template: Dictionary = templates[id]
		if int(template.get("tier", 0)) == 0:
			basics.append(id)
		else:
			priced.append(id)

	basics.shuffle()
	priced.shuffle()

	var offer: Array = []
	if not basics.is_empty():
		offer.append(basics[0])

	while offer.size() < 3 and not priced.is_empty():
		offer.append(priced.pop_back())

	while offer.size() < 3 and not basics.is_empty():
		var pick: String = basics[randi() % basics.size()]
		if not offer.has(pick):
			offer.append(pick)

	if extra_basic:
		for basic_id in basics:
			if not offer.has(basic_id):
				offer.append(basic_id)
				break

	return offer
