extends Node

enum Phase {
	SETUP,
	ACQUIRE,
	RETIRE,
	ACT,
	GAME_OVER,
}

enum GameResult {
	NONE,
	WIN,
	LOSE,
}

const MAX_TURNS := 10
const MAX_ROSTER := 5
const RETIRE_DRAW_BASE := 4
const STARTING_TOKENS_PER_TYPE := 2
const STARTER_IDS := [
	"starter_fighter",
	"starter_cleric",
	"starter_ranger",
]
const RECRUIT_IDS := [
	"recruit_squire",
	"recruit_acolyte",
	"recruit_bard",
	"recruit_knight",
	"recruit_mage",
	"recruit_captain",
]
const CONTRACT_IDS := [
	"contract_undead",
	"contract_escort",
	"contract_bandits",
	"contract_ritual",
]

var turn: int = 0
var phase: int = Phase.SETUP
var result: int = GameResult.NONE

var guild_coin: int = 5
var roster: Array = []
var drawn_tokens: Dictionary = ActionToken.empty_pool()
var assigned_this_turn: Array = []
var contracts: Array = []
var resolved_contracts: Array = []
var offer: Array = []
var discovered_rewards: Dictionary = {}
var contract_results: Dictionary = {}

var bag: Bag = Bag.new()
var needs_retire_first: bool = false
var acquired_this_turn: bool = false
var retired_this_turn: bool = false
var extra_basic_offer: bool = false
var pending_fail_injury: bool = false
var did_contract_this_turn: bool = false
var did_guild_action_this_turn: bool = false

var adventurer_templates: Dictionary = {}
var contract_templates: Dictionary = {}
var guild_action_templates: Dictionary = {}
var matchup_rows: Array = []
var retire_effects: Dictionary = {}

signal state_changed
signal message_posted(text: String)


func _ready() -> void:
	randomize()
	_load_data()


func new_run() -> void:
	AdventurerInstance.reset_ids()
	DiscoveryJournal.clear()

	turn = 0
	phase = Phase.SETUP
	result = GameResult.NONE
	guild_coin = 5
	roster.clear()
	drawn_tokens = ActionToken.empty_pool()
	assigned_this_turn.clear()
	contracts.clear()
	resolved_contracts.clear()
	offer.clear()
	discovered_rewards.clear()
	contract_results.clear()
	needs_retire_first = false
	acquired_this_turn = false
	retired_this_turn = false
	extra_basic_offer = false
	pending_fail_injury = false
	did_contract_this_turn = false
	did_guild_action_this_turn = false

	bag.clear()
	for token_type in ActionToken.ALL_TYPES:
		bag.add_to_bag(token_type, STARTING_TOKENS_PER_TYPE)
	bag.shuffle()

	for starter_id in STARTER_IDS:
		roster.append(AdventurerInstance.new(starter_id))

	_start_turn()


func get_living_roster() -> Array:
	return roster.duplicate()


func get_template(template_id: String) -> Dictionary:
	return adventurer_templates[template_id]


func get_adventurer_by_id(instance_id: int) -> AdventurerInstance:
	for adventurer in roster:
		if adventurer.instance_id == instance_id:
			return adventurer
	return null


func phase_name() -> String:
	match phase:
		Phase.ACQUIRE:
			return "Acquire — hire one adventurer"
		Phase.RETIRE:
			return "Retire — remove one adventurer and draw tokens"
		Phase.ACT:
			return "Act — spend tokens on contracts and guild actions"
		Phase.GAME_OVER:
			return "Game Over"
		_:
			return ""


func can_acquire(template_id: String) -> bool:
	if phase != Phase.ACQUIRE:
		return false
	if not offer.has(template_id):
		return false
	var template: Dictionary = adventurer_templates[template_id]
	return guild_coin >= int(template.get("cost", 0))


func acquire(template_id: String) -> bool:
	if not can_acquire(template_id):
		return false

	var template: Dictionary = adventurer_templates[template_id]
	guild_coin -= int(template.get("cost", 0))
	var adventurer := AdventurerInstance.new(template_id)
	roster.append(adventurer)

	var contribution: Dictionary = ActionToken.parse_cost_map(template.get("bag_contribution", {}))
	bag.add_contribution(contribution)

	acquired_this_turn = true
	offer.clear()
	phase = Phase.ACT if retired_this_turn else Phase.RETIRE
	var hire_name: String = String(template.get("name", template_id))
	DiscoveryJournal.add_entry("Turn %d — Hired %s." % [turn, hire_name])
	_emit_message("Hired %s." % hire_name)
	state_changed.emit()
	return true


func can_retire(instance_id: int) -> bool:
	if phase != Phase.RETIRE:
		return false
	var adventurer := get_adventurer_by_id(instance_id)
	if adventurer == null:
		return false
	if get_living_roster().size() <= 1:
		return false
	return true


func retire(instance_id: int) -> bool:
	if not can_retire(instance_id):
		return false

	var adventurer := get_adventurer_by_id(instance_id)
	var template: Dictionary = adventurer_templates[adventurer.template_id]
	var draw_count := get_retire_draw(adventurer)
	var drawn: Array = bag.draw(draw_count)
	drawn_tokens = ActionToken.empty_pool()
	for token_type in drawn:
		ActionToken.add_tokens(drawn_tokens, token_type, 1)

	var effect_id: String = String(template.get("retire_effect_id", ""))
	var effect_message := ""
	if not effect_id.is_empty():
		effect_message = EffectResolver.apply(effect_id, retire_effects, self)

	roster.erase(adventurer)
	var summary := "Retired %s. Drew %d tokens." % [template.get("name", ""), drawn.size()]
	if not effect_message.is_empty():
		summary += " %s" % effect_message
	DiscoveryJournal.add_entry("Turn %d — %s" % [turn, summary])
	_emit_message(summary)

	retired_this_turn = true
	if needs_retire_first and not acquired_this_turn:
		needs_retire_first = false
		phase = Phase.ACQUIRE
	else:
		phase = Phase.ACT

	state_changed.emit()
	_check_lose()
	return true


func get_retire_draw(adventurer: AdventurerInstance) -> int:
	var template: Dictionary = adventurer_templates[adventurer.template_id]
	return RETIRE_DRAW_BASE + adventurer.level + int(template.get("retire_bonus", 0))


func can_resolve_contract(contract_id: String) -> bool:
	if phase != Phase.ACT:
		return false
	if did_contract_this_turn:
		return false
	if resolved_contracts.has(contract_id):
		return false
	return contracts.has(contract_id)


func try_resolve_contract(contract_id: String, assignee_ids: Array, extra_tokens: Variant = null) -> bool:
	if did_contract_this_turn:
		_emit_message("You already completed a contract this round.")
		return false
	if not can_resolve_contract(contract_id):
		return false

	var extras: Dictionary = extra_tokens if extra_tokens is Dictionary else ActionToken.empty_pool()
	var contract: Dictionary = contract_templates[contract_id]
	var min_send: int = int(contract.get("min_adventurers", 1))
	var max_send: int = int(contract.get("max_adventurers", 1))
	if assignee_ids.size() < min_send or assignee_ids.size() > max_send:
		_emit_message("Send %d–%d adventurers." % [min_send, max_send])
		return false

	var assignees: Array = []
	for instance_id in assignee_ids:
		if assigned_this_turn.has(instance_id):
			_emit_message("Adventurer already assigned this turn.")
			return false
		var adventurer := get_adventurer_by_id(instance_id)
		if adventurer == null or not adventurer.is_assignable():
			_emit_message("Selected adventurers must be healthy and available.")
			return false
		assignees.append(adventurer)

	var costs: Dictionary = ActionToken.parse_cost_map(contract.get("token_cost", {}))
	var payment: Dictionary = ActionToken.combined_pool(costs, extras)
	if not ActionToken.can_pay(drawn_tokens, payment):
		_emit_message("Not enough drawn tokens for this contract.")
		return false

	ActionToken.pay(drawn_tokens, payment)
	for instance_id in assignee_ids:
		assigned_this_turn.append(instance_id)

	var need: Dictionary = ActionToken.parse_cost_map(contract.get("success_need", {}))
	var power: Dictionary = MatchupResolver.combined_power(assignees, adventurer_templates, payment)
	var forced_success := MatchupResolver.forces_success(
		contract_id,
		assignees,
		matchup_rows,
		adventurer_templates
	)
	var success := forced_success or MatchupResolver.meets_need(power, need)
	var coin_delta: int = int(contract.get("base_reward", 0)) if success else 0

	var matchup_result: Dictionary = MatchupResolver.resolve(
		contract_id,
		assignees,
		matchup_rows,
		adventurer_templates,
		success
	)
	coin_delta += int(matchup_result.guild_coin_delta)
	guild_coin += coin_delta

	if not success:
		if matchup_result.injure_instance_ids.is_empty() and matchup_result.remove_instance_ids.is_empty():
			for adventurer in assignees:
				matchup_result.injure_instance_ids.append(adventurer.instance_id)

	for instance_id in matchup_result.injure_instance_ids:
		var injured := get_adventurer_by_id(instance_id)
		if injured != null and not matchup_result.remove_instance_ids.has(instance_id):
			injured.injury_state = AdventurerInstance.InjuryState.INJURED

	for instance_id in matchup_result.remove_instance_ids:
		var fallen := get_adventurer_by_id(instance_id)
		if fallen != null:
			roster.erase(fallen)
			_emit_message("%s died on the contract." % adventurer_templates[fallen.template_id].get("name", ""))

	for instance_id in matchup_result.heal_instance_ids:
		var healed := get_adventurer_by_id(instance_id)
		if healed != null:
			healed.injury_state = AdventurerInstance.InjuryState.HEALTHY

	var lingering_victim := ""
	if not success and pending_fail_injury:
		lingering_victim = _apply_pending_fail_injury(matchup_result.remove_instance_ids)
		pending_fail_injury = false

	var dead_names: PackedStringArray = PackedStringArray()
	for instance_id in matchup_result.remove_instance_ids:
		for adventurer in assignees:
			if adventurer.instance_id == instance_id:
				dead_names.append(String(adventurer_templates[adventurer.template_id].get("name", "")))
				break
	# Assignees must be healthy to be sent, so any injury here came from this contract.
	var injured_names: PackedStringArray = PackedStringArray()
	for adventurer in assignees:
		if matchup_result.remove_instance_ids.has(adventurer.instance_id):
			continue
		if adventurer.is_injured():
			injured_names.append(String(adventurer_templates[adventurer.template_id].get("name", "")))
	if not lingering_victim.is_empty() and not injured_names.has(lingering_victim):
		injured_names.append(lingering_victim)

	DiscoveryJournal.add_entry(MatchupResolver.adventure_log(
		turn,
		contract,
		assignees,
		adventurer_templates,
		success,
		forced_success,
		power,
		need,
		extras,
		dead_names,
		injured_names,
		matchup_result.stories
	))

	for entry in matchup_result.journal_entries:
		DiscoveryJournal.log_once(entry.key, "Learned: %s" % entry.message)

	if success:
		var reward_text: String = String(matchup_result.discovered_reward)
		if reward_text.is_empty():
			reward_text = "Success"
		discovered_rewards[contract_id] = reward_text
	elif not matchup_result.discovered_reward.is_empty():
		discovered_rewards[contract_id] = matchup_result.discovered_reward

	_record_contract_result(contract_id, assignees, matchup_result, coin_delta)

	resolved_contracts.append(contract_id)
	did_contract_this_turn = true
	if success:
		_emit_message("Success on %s (%+d coin)." % [contract.get("name", ""), coin_delta])
	else:
		_emit_message("Failed %s (%+d coin)." % [contract.get("name", ""), coin_delta])
	state_changed.emit()
	_check_lose()
	return true

func can_perform_guild_action(action_id: String) -> bool:
	if phase != Phase.ACT or did_guild_action_this_turn:
		return false
	return guild_action_templates.has(action_id)


func try_guild_action(action_id: String, assignee_ids: Array) -> bool:
	if did_guild_action_this_turn:
		_emit_message("You already used a guild facility this round.")
		return false
	if not can_perform_guild_action(action_id):
		return false

	var action: Dictionary = guild_action_templates[action_id]
	if assignee_ids.size() != 1:
		_emit_message("Select exactly one adventurer.")
		return false

	var instance_id: int = assignee_ids[0]
	if assigned_this_turn.has(instance_id):
		_emit_message("Adventurer already assigned this turn.")
		return false

	var adventurer := get_adventurer_by_id(instance_id)
	if adventurer == null:
		return false

	var requires_injured: bool = bool(action.get("requires_injured", false))
	if requires_injured and not adventurer.is_injured():
		_emit_message("This action requires an injured adventurer.")
		return false
	if not requires_injured and not adventurer.is_assignable():
		_emit_message("This action requires a healthy adventurer.")
		return false

	var costs: Dictionary = ActionToken.parse_cost_map(action.get("token_cost", {}))
	if not ActionToken.can_pay(drawn_tokens, costs):
		_emit_message("Not enough drawn tokens.")
		return false

	ActionToken.pay(drawn_tokens, costs)
	assigned_this_turn.append(instance_id)
	did_guild_action_this_turn = true

	match action_id:
		"action_rest":
			if randf() < 0.7:
				adventurer.injury_state = AdventurerInstance.InjuryState.HEALTHY
				var recovered := "%s recovered at the hall." % adventurer_templates[adventurer.template_id].get("name", "")
				DiscoveryJournal.add_entry("Turn %d — %s" % [turn, recovered])
				_emit_message(recovered)
			else:
				var rest_fail := "%s rested, but the injury lingered." % adventurer_templates[adventurer.template_id].get("name", "")
				DiscoveryJournal.add_entry("Turn %d — %s" % [turn, rest_fail])
				_emit_message("Rest failed — still injured.")
		"action_train":
			if randf() < 0.7:
				if adventurer.level < 3:
					adventurer.level += 1
				var trained := "%s trained to level %d." % [
					adventurer_templates[adventurer.template_id].get("name", ""),
					adventurer.level,
				]
				DiscoveryJournal.add_entry("Turn %d — %s" % [turn, trained])
				_emit_message(trained)
			else:
				adventurer.injury_state = AdventurerInstance.InjuryState.INJURED
				var accident := "Training accident — %s was injured." % adventurer_templates[adventurer.template_id].get("name", "")
				DiscoveryJournal.add_entry("Turn %d — %s" % [turn, accident])
				_emit_message("Training accident — adventurer injured.")

	state_changed.emit()
	return true


func convert_tokens(payment: Dictionary, to_type: int) -> bool:
	if phase != Phase.ACT:
		return false
	if not (to_type in ActionToken.ALL_TYPES):
		return false
	if not ActionToken.is_valid_conversion(payment):
		_emit_message("Change 2 matching tokens, or any 3, into 1.")
		return false
	if not ActionToken.can_pay(drawn_tokens, payment):
		_emit_message("Not enough tokens to change.")
		return false

	ActionToken.pay(drawn_tokens, payment)
	ActionToken.add_tokens(drawn_tokens, to_type, 1)
	_emit_message("Changed tokens into %s." % ActionToken.NAMES[to_type])
	state_changed.emit()
	return true


func end_turn() -> void:
	if phase != Phase.ACT:
		return

	drawn_tokens = ActionToken.empty_pool()
	assigned_this_turn.clear()

	if _check_lose():
		return
	if _check_win():
		return

	_start_turn()


func _start_turn() -> void:
	turn += 1
	acquired_this_turn = false
	retired_this_turn = false
	needs_retire_first = roster.size() >= MAX_ROSTER
	resolved_contracts.clear()
	contract_results.clear()
	assigned_this_turn.clear()
	pending_fail_injury = false
	did_contract_this_turn = false
	did_guild_action_this_turn = false

	_refresh_contracts()
	offer = OfferGenerator.generate_offer(
		adventurer_templates,
		RECRUIT_IDS,
		extra_basic_offer
	)
	extra_basic_offer = false

	if needs_retire_first:
		phase = Phase.RETIRE
	else:
		phase = Phase.ACQUIRE

	state_changed.emit()


func _refresh_contracts() -> void:
	var pool: Array = CONTRACT_IDS.duplicate()
	pool.shuffle()
	contracts = []
	for i in min(2, pool.size()):
		contracts.append(pool[i])


func _check_win() -> bool:
	if turn >= MAX_TURNS and guild_coin >= 5 and get_living_roster().size() >= 2:
		result = GameResult.WIN
		phase = Phase.GAME_OVER
		_emit_message("Victory! The guild survived the season.")
		state_changed.emit()
		return true
	return false


func _check_lose() -> bool:
	if guild_coin <= 0 or get_living_roster().is_empty():
		result = GameResult.LOSE
		phase = Phase.GAME_OVER
		_emit_message("Defeat! The guild collapsed.")
		state_changed.emit()
		return true
	return false


func _apply_pending_fail_injury(excluded_ids: Array) -> String:
	var candidates: Array = []
	for adventurer in roster:
		if excluded_ids.has(adventurer.instance_id):
			continue
		if adventurer.is_injured():
			continue
		candidates.append(adventurer)
	if candidates.is_empty():
		return ""
	var victim: AdventurerInstance = candidates[randi() % candidates.size()]
	victim.injury_state = AdventurerInstance.InjuryState.INJURED
	var victim_name: String = String(adventurer_templates[victim.template_id].get("name", ""))
	DiscoveryJournal.log_once(
		"retire_risk_fail",
		"Learned: a lingering retire risk can injure someone after a failed contract."
	)
	_emit_message("%s was hurt by lingering retire risk." % victim_name)
	return victim_name


func _emit_message(text: String) -> void:
	message_posted.emit(text)


func _record_contract_result(
	contract_id: String,
	assignees: Array,
	matchup_result: Dictionary,
	coin_delta: int
) -> void:
	var assignee_names: PackedStringArray = []
	var injured_names: PackedStringArray = []
	var killed_names: PackedStringArray = []

	for adventurer in assignees:
		var name: String = adventurer_templates[adventurer.template_id].get("name", "")
		assignee_names.append(name)
		if matchup_result.injure_instance_ids.has(adventurer.instance_id):
			injured_names.append(name)
		if matchup_result.remove_instance_ids.has(adventurer.instance_id):
			killed_names.append(name)

	contract_results[contract_id] = {
		"assignees": assignee_names,
		"guild_coin_delta": coin_delta,
		"injured": injured_names,
		"killed": killed_names,
		"reward_label": String(matchup_result.get("discovered_reward", "")),
	}


func get_contract_result(contract_id: String) -> Dictionary:
	return contract_results.get(contract_id, {})


func _load_data() -> void:
	adventurer_templates = _load_json_dict("res://data/adventurers/adventurers.json")
	contract_templates = _load_json_dict("res://data/contracts/contracts.json")
	guild_action_templates = _load_json_dict("res://data/guild_actions/guild_actions.json")
	retire_effects = _load_json_dict("res://data/retire_effects.json")
	matchup_rows = _load_json_array("res://data/matchups/matchups.json")


func _load_json_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON dictionary at %s" % path)
		return {}
	return parsed


func _load_json_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open %s" % path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Invalid JSON array at %s" % path)
		return []
	return parsed
