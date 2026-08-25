extends Control

@onready var _header: Label = $Margin/VBox/Header
@onready var _phase_label: Label = $Margin/VBox/PhaseLabel
@onready var _message_label: Label = $Margin/VBox/MessageLabel
@onready var _drawn_label: Label = $Margin/VBox/DrawnLabel
@onready var _roster_box: HBoxContainer = $Margin/VBox/RosterBox
@onready var _contracts_box: VBoxContainer = $Margin/VBox/ContractsBox
@onready var _actions_box: HBoxContainer = $Margin/VBox/ActionsBox
@onready var _offer_box: HBoxContainer = $Margin/VBox/OfferBox
@onready var _journal_list: RichTextLabel = $Margin/VBox/JournalList
@onready var _end_turn_button: Button = $Margin/VBox/EndTurnButton
@onready var _game_over_panel: PanelContainer = $GameOverPanel
@onready var _game_over_label: Label = $GameOverPanel/Margin/VBox/GameOverLabel
@onready var _new_run_button: Button = $GameOverPanel/Margin/VBox/NewRunButton
@onready var _confirm_contract_button: Button = $Margin/VBox/ConfirmContractButton

var _selected_contract_id: String = ""
var _selected_assignees: Array = []


func _ready() -> void:
	GameState.state_changed.connect(_refresh)
	GameState.message_posted.connect(_on_message)
	_end_turn_button.pressed.connect(_on_end_turn)
	_confirm_contract_button.pressed.connect(_on_confirm_contract)
	_new_run_button.pressed.connect(_on_new_run)
	GameState.new_run()


func _on_message(text: String) -> void:
	_message_label.text = text


func _on_end_turn() -> void:
	GameState.end_turn()


func _on_new_run() -> void:
	_game_over_panel.visible = false
	GameState.new_run()


func _on_confirm_contract() -> void:
	if _selected_contract_id.is_empty():
		return
	GameState.try_resolve_contract(_selected_contract_id, _selected_assignees.duplicate())
	_selected_contract_id = ""
	_selected_assignees.clear()
	_refresh()


func _refresh() -> void:
	_header.text = "Turn %d/%d | Guild coin: %d | Bag: %d | Discard: %d" % [
		GameState.turn,
		GameState.MAX_TURNS,
		GameState.guild_coin,
		GameState.bag.bag_count(),
		GameState.bag.discard_count(),
	]
	_phase_label.text = GameState.phase_name()
	_drawn_label.text = "Drawn tokens: %s" % ActionToken.pool_to_string(GameState.drawn_tokens)
	_message_label.text = _message_label.text if _message_label.text != "" else "Select actions for this turn."

	_clear_container(_roster_box)
	_clear_container(_contracts_box)
	_clear_container(_actions_box)
	_clear_container(_offer_box)

	if GameState.phase == GameState.Phase.GAME_OVER:
		_show_game_over()
		return

	_game_over_panel.visible = false
	_end_turn_button.visible = GameState.phase == GameState.Phase.ACT
	_confirm_contract_button.visible = GameState.phase == GameState.Phase.ACT
	_offer_box.visible = GameState.phase == GameState.Phase.ACQUIRE

	_build_roster()
	_build_contracts()
	_build_guild_actions()
	_build_offer()
	_build_journal()


func _show_game_over() -> void:
	_game_over_panel.visible = true
	_end_turn_button.visible = false
	_confirm_contract_button.visible = false
	_offer_box.visible = false
	match GameState.result:
		GameState.GameResult.WIN:
			_game_over_label.text = "Victory! The guild survived the season."
		GameState.GameResult.LOSE:
			_game_over_label.text = "Defeat! The guild collapsed."
		_:
			_game_over_label.text = "Game Over"


func _build_roster() -> void:
	for adventurer in GameState.roster:
		var template: Dictionary = GameState.get_template(adventurer.template_id)
		var button := Button.new()
		var attrs: Dictionary = template.get("attributes", {})
		button.text = "%s %s L%d [%s] A%d D%d M%d S%d L%d" % [
			template.get("name", ""),
			template.get("class", ""),
			adventurer.level,
			adventurer.injury_label(),
			int(attrs.get("attack", 0)),
			int(attrs.get("defense", 0)),
			int(attrs.get("magic", 0)),
			int(attrs.get("support", 0)),
			int(attrs.get("leadership", 0)),
		]
		button.toggle_mode = GameState.phase == GameState.Phase.ACT
		button.button_pressed = _selected_assignees.has(adventurer.instance_id)

		if GameState.phase == GameState.Phase.RETIRE:
			button.pressed.connect(func(): GameState.retire(adventurer.instance_id))
			if not GameState.can_retire(adventurer.instance_id):
				button.disabled = true
		if GameState.phase == GameState.Phase.ACT:
			var can_toggle := not assigned_this_turn_blocked(adventurer.instance_id)
			button.pressed.connect(func(): _toggle_assignee(adventurer.instance_id, button))
			button.disabled = not can_toggle
		else:
			button.disabled = true

		_roster_box.add_child(button)


func assigned_this_turn_blocked(instance_id: int) -> bool:
	return GameState.assigned_this_turn.has(instance_id)


func _toggle_assignee(instance_id: int, button: Button) -> void:
	if _selected_contract_id.is_empty():
		_message_label.text = "Select a contract first, then toggle adventurers."
		return
	if button.button_pressed:
		if not _selected_assignees.has(instance_id):
			_selected_assignees.append(instance_id)
	else:
		_selected_assignees.erase(instance_id)


func _build_contracts() -> void:
	if GameState.phase != GameState.Phase.ACT:
		return

	for contract_id in GameState.contracts:
		var contract: Dictionary = GameState.contract_templates[contract_id]
		var panel := VBoxContainer.new()
		var title := Label.new()
		var costs: Dictionary = ActionToken.parse_cost_map(contract.get("token_cost", {}))
		var cost_text := ActionToken.pool_to_string(costs)
		var reward_text: String = String(GameState.discovered_rewards.get(contract_id, "???"))
		title.text = "%s | Cost: %s | Send: %d-%d | Risk: %s | Reward: %s" % [
			contract.get("name", ""),
			cost_text,
			int(contract.get("min_adventurers", 1)),
			int(contract.get("max_adventurers", 1)),
			contract.get("risk_tag", ""),
			reward_text,
		]
		panel.add_child(title)

		var hint := Label.new()
		hint.text = contract.get("hint", "")
		panel.add_child(hint)

		var select_button := Button.new()
		var resolved: bool = GameState.resolved_contracts.has(contract_id)
		select_button.text = "Select for assignment" if not resolved else "Contract completed"
		select_button.disabled = resolved
		if not resolved:
			select_button.pressed.connect(func(): _select_contract(contract_id))
		panel.add_child(select_button)

		if resolved:
			var result_label := Label.new()
			result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			result_label.text = _format_contract_result(GameState.get_contract_result(contract_id))
			panel.add_child(result_label)

		if _selected_contract_id == contract_id:
			var marker := Label.new()
			marker.text = ">> Selected. Toggle adventurers, then Confirm Contract."
			panel.add_child(marker)

		_contracts_box.add_child(panel)


func _select_contract(contract_id: String) -> void:
	_selected_contract_id = contract_id
	_selected_assignees.clear()
	_refresh()


func _format_contract_result(result: Dictionary) -> String:
	if result.is_empty():
		return "Result: Contract completed."

	var parts: PackedStringArray = []
	var assignees: Array = result.get("assignees", [])
	if assignees.is_empty():
		parts.append("Sent: (none)")
	else:
		parts.append("Sent: %s" % ", ".join(assignees))

	var coin_delta: int = int(result.get("guild_coin_delta", 0))
	if coin_delta > 0:
		parts.append("+%d guild coin" % coin_delta)
	elif coin_delta < 0:
		parts.append("%d guild coin" % coin_delta)
	else:
		parts.append("No coin reward")

	var reward_label: String = String(result.get("reward_label", ""))
	if not reward_label.is_empty():
		parts.append("Reward tier: %s" % reward_label)

	var injured: Array = result.get("injured", [])
	if not injured.is_empty():
		parts.append("Injured: %s" % ", ".join(injured))

	var killed: Array = result.get("killed", [])
	if not killed.is_empty():
		parts.append("Killed: %s" % ", ".join(killed))

	return "Result: " + " | ".join(parts)


func _build_guild_actions() -> void:
	if GameState.phase != GameState.Phase.ACT:
		return

	for action_id in GameState.guild_action_templates.keys():
		var action: Dictionary = GameState.guild_action_templates[action_id]
		var button := Button.new()
		var costs: Dictionary = ActionToken.parse_cost_map(action.get("token_cost", {}))
		button.text = "%s (%s) — select one adventurer first" % [
			action.get("name", ""),
			ActionToken.pool_to_string(costs),
		]
		button.pressed.connect(func(): _perform_guild_action(action_id))
		_actions_box.add_child(button)


func _perform_guild_action(action_id: String) -> void:
	if _selected_assignees.size() != 1:
		_message_label.text = "Select exactly one adventurer for guild actions."
		return
	GameState.try_guild_action(action_id, _selected_assignees.duplicate())
	_selected_assignees.clear()
	_selected_contract_id = ""


func _build_offer() -> void:
	if GameState.phase != GameState.Phase.ACQUIRE:
		return

	for template_id in GameState.offer:
		var template: Dictionary = GameState.get_template(template_id)
		var button := Button.new()
		button.text = "Hire %s (%s) — %d coin" % [
			template.get("name", ""),
			template.get("class", ""),
			int(template.get("cost", 0)),
		]
		button.pressed.connect(func(): GameState.acquire(template_id))
		if not GameState.can_acquire(template_id):
			button.disabled = true
		_offer_box.add_child(button)


func _build_journal() -> void:
	var entries: Array = DiscoveryJournal.get_entries()
	if entries.is_empty():
		_journal_list.text = "Discovery journal: (empty)"
	else:
		_journal_list.text = "Discovery journal:\n" + "\n".join(entries)


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
