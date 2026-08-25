extends SceneTree

func _init() -> void:
	call_deferred("_run_tests_deferred")


func _run_tests_deferred() -> void:
	var errors: Array = _run_tests()
	if errors.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		for err in errors:
			push_error(err)
		quit(1)


func _run_tests() -> Array:
	var errors: Array = []
	var gs: Node = root.get_node("GameState")

	var bag := Bag.new()
	bag.add_to_bag(ActionToken.Type.ATTACK, 2)
	bag.add_to_discard(ActionToken.Type.DEFENSE, 3)
	var drawn: Array = bag.draw(2)
	if drawn.size() != 2:
		errors.append("Expected 2 draws from bag")
	drawn = bag.draw(1)
	if drawn.size() != 1:
		errors.append("Expected shuffle draw to work")

	gs.new_run()
	if gs.roster.size() != 3:
		errors.append("Expected 3 starter adventurers")
	if gs.phase != gs.Phase.ACQUIRE:
		errors.append("Expected ACQUIRE phase at turn start")

	var cleric_id: int = -1
	for adventurer in gs.roster:
		var template: Dictionary = gs.get_template(adventurer.template_id)
		if template.get("class", "") == "Cleric":
			cleric_id = adventurer.instance_id
			break

	if cleric_id == -1:
		errors.append("No cleric in starter roster")
	else:
		gs.phase = gs.Phase.ACT
		gs.contracts = ["contract_undead"]
		gs.resolved_contracts.clear()
		gs.drawn_tokens = ActionToken.empty_pool()
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.ATTACK, 2)
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.MAGIC, 1)
		gs.assigned_this_turn.clear()
		var coin_before: int = gs.guild_coin
		if not gs.try_resolve_contract("contract_undead", [cleric_id]):
			errors.append("Failed to resolve undead contract with cleric")
		elif gs.guild_coin < coin_before + 3:
			errors.append("Cleric undead contract should grant +3 coin")
		else:
			var result: Dictionary = gs.get_contract_result("contract_undead")
			if result.is_empty():
				errors.append("Expected contract result to be recorded")
			elif int(result.get("guild_coin_delta", 0)) != 3:
				errors.append("Contract result should show +3 coin")

	var fighter_id: int = -1
	gs.new_run()
	for adventurer in gs.roster:
		var template: Dictionary = gs.get_template(adventurer.template_id)
		if template.get("class", "") == "Fighter":
			fighter_id = adventurer.instance_id
			break

	if fighter_id != -1:
		gs.phase = gs.Phase.ACT
		gs.contracts = ["contract_undead"]
		gs.resolved_contracts.clear()
		gs.drawn_tokens = ActionToken.empty_pool()
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.ATTACK, 2)
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.MAGIC, 1)
		gs.assigned_this_turn.clear()
		var roster_before: int = gs.roster.size()
		gs.try_resolve_contract("contract_undead", [fighter_id])
		if gs.roster.size() >= roster_before:
			errors.append("Fighter on undead without cleric should die")

	return errors
