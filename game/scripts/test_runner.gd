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

	var mixed_leadership := 0
	for _run in 6:
		var mixed := Bag.new()
		mixed.add_to_bag(ActionToken.Type.ATTACK, 20)
		mixed.add_to_bag(ActionToken.Type.LEADERSHIP, 20)
		var mixed_draw: Array = mixed.draw(10)
		var all_leadership := true
		for token_type in mixed_draw:
			if token_type != ActionToken.Type.LEADERSHIP:
				all_leadership = false
				break
		if all_leadership:
			mixed_leadership += 1
	if mixed_leadership == 6:
		errors.append("Bag draw is not randomized")

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
		gs.did_contract_this_turn = false
		gs.drawn_tokens = ActionToken.empty_pool()
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.ATTACK, 2)
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.MAGIC, 1)
		gs.assigned_this_turn.clear()
		var coin_before: int = gs.guild_coin
		if not gs.try_resolve_contract("contract_undead", [cleric_id]):
			errors.append("Failed to resolve undead contract with cleric")
		elif gs.guild_coin < coin_before + 4:
			errors.append("Cleric undead contract should succeed with extra gold")
		else:
			var result: Dictionary = gs.get_contract_result("contract_undead")
			if result.is_empty():
				errors.append("Expected contract result to be recorded")
			elif int(result.get("guild_coin_delta", 0)) != 4:
				errors.append("Contract result should show +4 coin")
			var journal: Node = root.get_node("DiscoveryJournal")
			var log_text := " ".join(journal.get_entries())
			if log_text.find("Succeeded") < 0 or log_text.find("Faith") < 0:
				errors.append("Guild log should explain why the cleric succeeded")

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
		gs.did_contract_this_turn = false
		gs.drawn_tokens = ActionToken.empty_pool()
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.ATTACK, 2)
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.MAGIC, 1)
		gs.assigned_this_turn.clear()
		var roster_before: int = gs.roster.size()
		gs.try_resolve_contract("contract_undead", [fighter_id])
		if gs.roster.size() >= roster_before:
			errors.append("Fighter on undead without enough magic should die")
		else:
			var journal: Node = root.get_node("DiscoveryJournal")
			var fail_log := " ".join(journal.get_entries())
			if fail_log.find("Failed") < 0 or fail_log.find("Magic") < 0:
				errors.append("Guild log should clue that the fighter lacked Magic")

	var fighter_extra_id: int = -1
	gs.new_run()
	for adventurer in gs.roster:
		var template: Dictionary = gs.get_template(adventurer.template_id)
		if template.get("class", "") == "Fighter":
			fighter_extra_id = adventurer.instance_id
			break
	if fighter_extra_id != -1:
		gs.phase = gs.Phase.ACT
		gs.contracts = ["contract_undead"]
		gs.resolved_contracts.clear()
		gs.did_contract_this_turn = false
		gs.drawn_tokens = ActionToken.empty_pool()
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.ATTACK, 2)
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.MAGIC, 2)
		gs.assigned_this_turn.clear()
		var extras: Dictionary = ActionToken.empty_pool()
		ActionToken.add_tokens(extras, ActionToken.Type.MAGIC, 1)
		var roster_alive: int = gs.roster.size()
		if not gs.try_resolve_contract("contract_undead", [fighter_extra_id], extras):
			errors.append("Fighter plus extra magic should be allowed to attempt undead")
		elif gs.roster.size() != roster_alive:
			errors.append("Fighter with extra magic should meet the crypt and survive")

	gs.new_run()
	gs.phase = gs.Phase.ACT
	gs.drawn_tokens = ActionToken.empty_pool()
	ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.ATTACK, 3)
	var pair: Dictionary = ActionToken.empty_pool()
	ActionToken.add_tokens(pair, ActionToken.Type.ATTACK, 2)
	if not gs.convert_tokens(pair, ActionToken.Type.MAGIC):
		errors.append("2 matching tokens should convert into 1")
	elif gs.drawn_tokens[ActionToken.Type.ATTACK] != 1 or gs.drawn_tokens[ActionToken.Type.MAGIC] != 1:
		errors.append("Pair convert should leave 1 attack and 1 magic")

	gs.drawn_tokens = ActionToken.empty_pool()
	ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.ATTACK, 1)
	ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.DEFENSE, 1)
	ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.MAGIC, 1)
	var mixed: Dictionary = ActionToken.empty_pool()
	ActionToken.add_tokens(mixed, ActionToken.Type.ATTACK, 1)
	ActionToken.add_tokens(mixed, ActionToken.Type.DEFENSE, 1)
	ActionToken.add_tokens(mixed, ActionToken.Type.MAGIC, 1)
	if not gs.convert_tokens(mixed, ActionToken.Type.SUPPORT):
		errors.append("Any 3 tokens should convert into 1")
	elif ActionToken.total(gs.drawn_tokens) != 1 or gs.drawn_tokens[ActionToken.Type.SUPPORT] != 1:
		errors.append("Mixed convert should leave a single support token")

	var ranger_id: int = -1
	var second_hero_id: int = -1
	gs.new_run()
	for adventurer in gs.roster:
		var template: Dictionary = gs.get_template(adventurer.template_id)
		if template.get("class", "") == "Ranger":
			ranger_id = adventurer.instance_id
		elif second_hero_id == -1:
			second_hero_id = adventurer.instance_id

	if ranger_id != -1 and second_hero_id != -1:
		gs.phase = gs.Phase.ACT
		gs.contracts = ["contract_escort", "contract_bandits"]
		gs.resolved_contracts.clear()
		gs.did_contract_this_turn = false
		gs.did_guild_action_this_turn = false
		gs.drawn_tokens = ActionToken.empty_pool()
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.DEFENSE, 1)
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.LEADERSHIP, 2)
		gs.assigned_this_turn.clear()
		if not gs.try_resolve_contract("contract_escort", [ranger_id]):
			errors.append("First contract of the round should succeed")
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.ATTACK, 2)
		if gs.try_resolve_contract("contract_bandits", [second_hero_id]):
			errors.append("Second contract in the same round should be blocked")
		if not gs.try_guild_action("action_train", [second_hero_id]):
			errors.append("One guild facility should still be allowed after a contract")
	if gs.try_guild_action("action_train", [second_hero_id]):
		errors.append("Second guild facility in the same round should be blocked")

	gs.new_run()
	var cleric_offer_id: int = -1
	for adventurer in gs.roster:
		if String(gs.get_template(adventurer.template_id).get("class", "")) == "Cleric":
			cleric_offer_id = adventurer.instance_id
			break
	var hired := false
	for template_id in gs.offer:
		if gs.can_acquire(template_id):
			hired = gs.acquire(template_id)
			break
	if not hired:
		errors.append("Could not hire to reach retire")
	elif not gs.retire(cleric_offer_id):
		errors.append("Could not retire cleric for extra-basic effect")
	elif not gs.extra_basic_offer:
		errors.append("Cleric retire should queue an extra basic recruit")
	else:
		gs.end_turn()
		if gs.offer.size() != 4:
			errors.append("Next offer should have 4 recruits after extra-basic retire")

	gs.new_run()
	var ranger_risk_id: int = -1
	for adventurer in gs.roster:
		if String(gs.get_template(adventurer.template_id).get("class", "")) == "Ranger":
			ranger_risk_id = adventurer.instance_id
			break
	if ranger_risk_id != -1:
		gs.phase = gs.Phase.ACT
		gs.contracts = ["contract_undead"]
		gs.resolved_contracts.clear()
		gs.did_contract_this_turn = false
		gs.pending_fail_injury = true
		gs.drawn_tokens = ActionToken.empty_pool()
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.ATTACK, 2)
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.MAGIC, 1)
		gs.assigned_this_turn.clear()
		gs.try_resolve_contract("contract_undead", [ranger_risk_id])
		if gs.pending_fail_injury:
			errors.append("Failed contract should consume lingering retire risk")
		var injured_count := 0
		for adventurer in gs.roster:
			if adventurer.is_injured():
				injured_count += 1
		if injured_count < 2:
			errors.append("Lingering retire risk should injure a second adventurer on fail")

	# A hero hurt on an earlier turn must not be blamed for a later contract.
	gs.new_run()
	var guild_journal: Node = root.get_node("DiscoveryJournal")
	var bystander_name := ""
	var sender_id: int = -1
	for adventurer in gs.roster:
		if bystander_name.is_empty():
			adventurer.injury_state = AdventurerInstance.InjuryState.INJURED
			bystander_name = String(gs.get_template(adventurer.template_id).get("name", ""))
		elif sender_id == -1:
			sender_id = adventurer.instance_id
	if sender_id != -1:
		gs.phase = gs.Phase.ACT
		gs.contracts = ["contract_bandits"]
		gs.resolved_contracts.clear()
		gs.did_contract_this_turn = false
		gs.pending_fail_injury = false
		gs.assigned_this_turn.clear()
		gs.drawn_tokens = ActionToken.empty_pool()
		ActionToken.add_tokens(gs.drawn_tokens, ActionToken.Type.ATTACK, 2)
		guild_journal.clear()
		gs.try_resolve_contract("contract_bandits", [sender_id])
		var log_text := "\n".join(guild_journal.get_entries())
		if log_text.contains(bystander_name):
			errors.append("Guild log should not blame a previously injured bystander")

	return errors
