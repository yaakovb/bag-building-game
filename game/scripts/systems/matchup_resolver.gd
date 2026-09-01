class_name MatchupResolver


static func combined_power(assignees: Array, templates: Dictionary, spent: Dictionary) -> Dictionary:
	var power: Dictionary = ActionToken.empty_pool()
	for token_type in ActionToken.ALL_TYPES:
		power[token_type] = int(spent.get(token_type, 0))
	for adventurer in assignees:
		var attrs: Dictionary = templates[adventurer.template_id].get("attributes", {})
		for key in attrs.keys():
			ActionToken.add_tokens(power, ActionToken.from_string(String(key)), int(attrs[key]))
	return power


static func meets_need(power: Dictionary, need: Dictionary) -> bool:
	for token_type in ActionToken.ALL_TYPES:
		if int(power.get(token_type, 0)) < int(need.get(token_type, 0)):
			return false
	return true


static func forces_success(
	contract_id: String,
	assignees: Array,
	matchup_rows: Array,
	templates: Dictionary
) -> bool:
	for row in matchup_rows:
		if row.get("contract_id", "") != contract_id:
			continue
		if not bool(row.get("outcomes", {}).get("force_success", false)):
			continue
		if _conditions_match(row.get("conditions", {}), assignees, templates):
			return true
	return false


static func resolve(
	contract_id: String,
	assignees: Array,
	matchup_rows: Array,
	templates: Dictionary,
	success: bool
) -> Dictionary:
	var result := {
		"guild_coin_delta": 0,
		"injure_instance_ids": [],
		"remove_instance_ids": [],
		"heal_instance_ids": [],
		"journal_entries": [],
		"discovered_reward": "",
		"stories": [],
	}

	var applicable: Array = []
	for row in matchup_rows:
		if row.get("contract_id", "") != contract_id:
			continue
		var when: String = String(row.get("on", "always"))
		if when == "success" and not success:
			continue
		if when == "fail" and success:
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

		var story: String = String(outcomes.get("story", ""))
		if not story.is_empty():
			result.stories.append(story)

		var journal_key: String = String(row.get("journal_key", ""))
		var journal_message: String = String(outcomes.get("journal_message", ""))
		if not journal_key.is_empty() and not journal_message.is_empty():
			result.journal_entries.append({"key": journal_key, "message": journal_message})

		if bool(row.get("stop_after_match", true)):
			break

	return result


static func adventure_log(
	turn: int,
	contract: Dictionary,
	assignees: Array,
	templates: Dictionary,
	success: bool,
	forced_success: bool,
	power: Dictionary,
	need: Dictionary,
	extras: Dictionary,
	dead_names: PackedStringArray,
	injured_names: PackedStringArray,
	special_stories: Array
) -> String:
	var job: String = String(contract.get("name", "the job"))
	var header := "Turn %d — %s %s." % [turn, "Succeeded" if success else "Failed", job]
	var party := _party_label(assignees, templates)
	var lines: PackedStringArray = PackedStringArray()
	lines.append(header)

	if not special_stories.is_empty():
		for story in special_stories:
			var text := String(story)
			if not text.is_empty():
				lines.append(text)
		if not success:
			var special_shortfall := _shortfall_line(power, need, party)
			if not special_shortfall.is_empty():
				lines.append(special_shortfall)
	elif forced_success:
		var blessing: String = String(contract.get("log_blessing", ""))
		if blessing.is_empty():
			blessing = "%s had an edge this work does not advertise." % party
		lines.append(blessing)
	elif success:
		var success_flavor: String = String(contract.get("log_success", ""))
		if not success_flavor.is_empty():
			lines.append(success_flavor)
		var extras_line := _extras_line(extras)
		var strength_line := _strength_line(assignees, templates, need)
		if not extras_line.is_empty():
			lines.append(extras_line)
		elif not strength_line.is_empty():
			lines.append(strength_line)
		elif success_flavor.is_empty():
			lines.append("%s met what the job quietly demanded." % party)
	else:
		var fail_flavor: String = String(contract.get("log_fail", ""))
		if not fail_flavor.is_empty():
			lines.append(fail_flavor)
		var shortfall := _shortfall_line(power, need, party)
		if not shortfall.is_empty():
			lines.append(shortfall)

	if not dead_names.is_empty():
		lines.append("%s did not come back." % _join_list(dead_names))
	elif not injured_names.is_empty():
		lines.append("%s came home hurt." % _join_list(injured_names))

	return "\n".join(lines)


static func _party_label(assignees: Array, templates: Dictionary) -> String:
	var names: PackedStringArray = PackedStringArray()
	for adventurer in assignees:
		names.append(String(templates[adventurer.template_id].get("name", "Someone")))
	if names.is_empty():
		return "The party"
	return _join_list(names)


static func _shortfall_line(power: Dictionary, need: Dictionary, party: String) -> String:
	var missing: PackedStringArray = PackedStringArray()
	for token_type in ActionToken.ALL_TYPES:
		if int(power.get(token_type, 0)) < int(need.get(token_type, 0)):
			missing.append(String(ActionToken.NAMES[token_type]))
	if missing.is_empty():
		return ""
	return "The job asked for more %s than %s could bring." % [_join_list(missing), party]


static func _extras_line(extras: Dictionary) -> String:
	var spent: PackedStringArray = PackedStringArray()
	for token_type in ActionToken.ALL_TYPES:
		if int(extras.get(token_type, 0)) > 0:
			spent.append(String(ActionToken.NAMES[token_type]))
	if spent.is_empty():
		return ""
	return "Tokens spent beyond the fee — especially %s — helped close the gap." % _join_list(spent)


static func _strength_line(assignees: Array, templates: Dictionary, need: Dictionary) -> String:
	var bits: PackedStringArray = PackedStringArray()
	for adventurer in assignees:
		var template: Dictionary = templates[adventurer.template_id]
		var name: String = String(template.get("name", ""))
		var attrs: Dictionary = template.get("attributes", {})
		for token_type in ActionToken.ALL_TYPES:
			if int(need.get(token_type, 0)) <= 0:
				continue
			var key := String(ActionToken.NAMES[token_type]).to_lower()
			if int(attrs.get(key, 0)) > 0:
				bits.append("%s's %s" % [name, ActionToken.NAMES[token_type]])
	if bits.is_empty():
		return ""
	return "The work was carried by %s." % _join_list(bits)


static func _join_list(parts: PackedStringArray) -> String:
	if parts.is_empty():
		return ""
	if parts.size() == 1:
		return parts[0]
	if parts.size() == 2:
		return "%s and %s" % [parts[0], parts[1]]
	var head := ", ".join(parts.slice(0, parts.size() - 1))
	return "%s, and %s" % [head, parts[parts.size() - 1]]


static func _conditions_match(
	conditions: Dictionary,
	assignees: Array,
	templates: Dictionary
) -> bool:
	if conditions.is_empty():
		return true

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
