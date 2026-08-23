class_name MatchupResolver


static func resolve(
	contract_id: String,
	assignees: Array,
	matchup_rows: Array,
	templates: Dictionary
) -> Dictionary:
	var result := {
		"guild_coin_delta": 0,
		"injure_instance_ids": [],
		"remove_instance_ids": [],
		"heal_instance_ids": [],
		"journal_entries": [],
		"discovered_reward": "",
	}

	var applicable: Array = []
	for row in matchup_rows:
		if row.get("contract_id", "") != contract_id:
			continue
		if _conditions_match(row.get("conditions", {}), assignees, templates):
			applicable.append(row)

	applicable.sort_custom(func(a, b): return int(a.get("priority", 0)) > int(b.get("priority", 0)))

	for row in applicable:
		var outcomes: Dictionary = row.get("outcomes", {})
		result.guild_coin_delta += int(outcomes.get("guild_coin", 0))

		if outcomes.has("injure_class"):
			var hero_class: String = outcomes["injure_class"]
			for adventurer in assignees:
				var template: Dictionary = templates[adventurer.template_id]
				if template.get("class", "") == hero_class:
					result.injure_instance_ids.append(adventurer.instance_id)

		if outcomes.has("grave_injury_class"):
			var hero_class: String = outcomes["grave_injury_class"]
			for adventurer in assignees:
				var template: Dictionary = templates[adventurer.template_id]
				if template.get("class", "") == hero_class:
					result.remove_instance_ids.append(adventurer.instance_id)

		if outcomes.has("injure_all_assignees"):
			for adventurer in assignees:
				result.injure_instance_ids.append(adventurer.instance_id)

		if outcomes.has("discovered_reward"):
			result.discovered_reward = outcomes["discovered_reward"]

		var journal_key: String = row.get("journal_key", "")
		var journal_message: String = outcomes.get("journal_message", "")
		if not journal_key.is_empty() and not journal_message.is_empty():
			result.journal_entries.append({"key": journal_key, "message": journal_message})

		if bool(row.get("stop_after_match", true)):
			break

	return result


static func _conditions_match(
	conditions: Dictionary,
	assignees: Array,
	templates: Dictionary
) -> bool:
	if conditions.is_empty():
		return false

	for key in conditions.keys():
		if not _check_condition(key, conditions[key], assignees, templates):
			return false
	return true


static func _check_condition(
	key: String,
	value: Variant,
	assignees: Array,
	templates: Dictionary
) -> bool:
	match key:
		"has_class":
			for adventurer in assignees:
				if templates[adventurer.template_id].get("class", "") == value:
					return true
			return false
		"not_has_class":
			for adventurer in assignees:
				if templates[adventurer.template_id].get("class", "") == value:
					return false
			return true
		"only_class":
			if assignees.is_empty():
				return false
			for adventurer in assignees:
				if templates[adventurer.template_id].get("class", "") != value:
					return false
			return true
		"any_attribute_at_least":
			var attr: String = value.get("attribute", "")
			var min_value: int = int(value.get("value", 0))
			for adventurer in assignees:
				var template: Dictionary = templates[adventurer.template_id]
				if int(template.get("attributes", {}).get(attr, 0)) >= min_value:
					return true
			return false
		"any_attribute_zero":
			for adventurer in assignees:
				var template: Dictionary = templates[adventurer.template_id]
				if int(template.get("attributes", {}).get(value, 0)) == 0:
					return true
			return false
		"no_support_in_party":
			for adventurer in assignees:
				var template: Dictionary = templates[adventurer.template_id]
				if int(template.get("attributes", {}).get("support", 0)) > 0:
					return false
			return assignees.size() > 0
		_:
			return false
