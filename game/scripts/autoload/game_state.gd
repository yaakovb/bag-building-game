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
var extra_basic_offer: bool = false
var contract_failed_this_turn: bool = false

var adventurer_templates: Dictionary = {}
var contract_templates: Dictionary = {}
var guild_action_templates: Dictionary = {}
var matchup_rows: Array = []
var retire_effects: Dictionary = {}

signal state_changed
signal message_posted(text: String)


func _ready() -> void:
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
	extra_basic_offer = false
	contract_failed_this_turn = false

	bag.clear()
	for token_type in ActionToken.ALL_TYPES:
		bag.add_to_bag(token_type, 2)

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
	phase = Phase.RETIRE
	_emit_message("Hired %s." % template.get("name", template_id))
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
	var draw_count := 2 + adventurer.level + int(template.get("retire_bonus", 0))
	var drawn: Array = bag.draw(draw_count)
	drawn_tokens = ActionToken.empty_pool()
	for token_type in drawn:
		ActionToken.add_tokens(drawn_tokens, token_type, 1)

	var effect_id: String = template.get("retire_effect_id", "")
	if not effect_id.is_empty():
		var effect_message := EffectResolver.apply(effect_id, retire_effects, self)
		var tag: String = template.get("retire_tag", "")
		DiscoveryJournal.log_once(
			"retire_%s" % effect_id,
			"Retire (%s): %s" % [tag, effect_message]
		)

	roster.erase(adventurer)
	_emit_message("Retired %s. Drew %d tokens." % [template.get("name", ""), drawn.size()])

	if needs_retire_first and not acquired_this_turn:
		needs_retire_first = false
		phase = Phase.ACQUIRE
	else:
		phase = Phase.ACT

	state_changed.emit()
	return true


func can_resolve_contract(contract_id: String) -> bool:
	if phase != Phase.ACT:
		return false
	if resolved_contracts.has(contract_id):
		return false
	return contracts.has(contract_id)


func try_resolve_contract(contract_id: String, assignee_ids: Array) -> bool:
	if not can_resolve_contract(contract_id):
		return false

	var contract: Dictionary = contract_templates[contract_id]
	var min_send: int = int(contract.get("min_adventurers", 1))
	var max_send: int = int(contract.get("max_adventurers", 1))
	if assignee_ids.size() < min_send or assignee_ids.size() > max_send:
		_emit_message("Select %d-%d adventurers." % [min_send, max_send])
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
	if not ActionToken.can_pay(drawn_tokens, costs):
		_emit_message("Not enough drawn tokens for this contract.")
		return false

	ActionToken.pay(drawn_tokens, costs)
	for instance_id in assignee_ids:
		assigned_this_turn.append(instance_id)

	var matchup_result: Dictionary = MatchupResolver.resolve(
		contract_id,
		assignees,
		matchup_rows,
		adventurer_templates
	)

	guild_coin += matchup_result.guild_coin_delta
	if matchup_result.guild_coin_delta <= 0:
		contract_failed_this_turn = true

	for instance_id in matchup_result.injure_instance_ids:
		var adventurer := get_adventurer_by_id(instance_id)
		if adventurer != null:
			adventurer.injury_state = AdventurerInstance.InjuryState.INJURED

	for instance_id in matchup_result.remove_instance_ids:
		var adventurer := get_adventurer_by_id(instance_id)
		if adventurer != null:
			roster.erase(adventurer)
			_emit_message("%s died on the contract." % adventurer_templates[adventurer.template_id].get("name", ""))

	for entry in matchup_result.journal_entries:
		DiscoveryJournal.log_once(entry.key, entry.message)

	if not matchup_result.discovered_reward.is_empty():
		discovered_rewards[contract_id] = matchup_result.discovered_reward

	_record_contract_result(contract_id, assignees, matchup_result)

	resolved_contracts.append(contract_id)
	_emit_message(
		"Resolved %s (%+d coin)." % [contract.get("name", ""), matchup_result.guild_coin_delta]
	)
	state_changed.emit()
	_check_lose()
	return true


func can_perform_guild_action(action_id: String) -> bool:
	return phase == Phase.ACT and guild_action_templates.has(action_id)


func try_guild_action(action_id: String, assignee_ids: Array) -> bool:
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

	match action_id:
		"action_rest":
			if randf() < 0.7:
				adventurer.injury_state = AdventurerInstance.InjuryState.HEALTHY
				_emit_message("%s recovered." % adventurer_templates[adventurer.template_id].get("name", ""))
			else:
				_emit_message("Rest failed — still injured.")
		"action_train":
			if randf() < 0.7:
				if adventurer.level < 3:
					adventurer.level += 1
				_emit_message("%s trained to level %d." % [
					adventurer_templates[adventurer.template_id].get("name", ""),
					adventurer.level,
				])
			else:
				adventurer.injury_state = AdventurerInstance.InjuryState.INJURED
				_emit_message("Training accident — adventurer injured.")

	state_changed.emit()
	return true


func end_turn() -> void:
	if phase != Phase.ACT:
		return

	drawn_tokens = ActionToken.empty_pool()
	assigned_this_turn.clear()
	contract_failed_this_turn = false

	if _check_lose():
		return
	if _check_win():
		return

	_start_turn()


func _start_turn() -> void:
	turn += 1
	acquired_this_turn = false
	needs_retire_first = roster.size() >= MAX_ROSTER
	extra_basic_offer = false
	resolved_contracts.clear()
	contract_results.clear()
	assigned_this_turn.clear()
	contract_failed_this_turn = false

	_refresh_contracts()
	offer = OfferGenerator.generate_offer(
		adventurer_templates,
		RECRUIT_IDS,
		extra_basic_offer
	)

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


func _emit_message(text: String) -> void:
	message_posted.emit(text)


func _record_contract_result(
	contract_id: String,
	assignees: Array,
	matchup_result: Dictionary
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
		"guild_coin_delta": int(matchup_result.guild_coin_delta),
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
