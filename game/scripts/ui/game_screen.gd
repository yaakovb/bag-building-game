extends Control

const AdventurerCardScript := preload("res://scripts/ui/adventurer_card.gd")
const TokenChipScript := preload("res://scripts/ui/token_chip.gd")
const DropZoneScript := preload("res://scripts/ui/drop_zone.gd")
const JobCardScript := preload("res://scripts/ui/job_card.gd")

const TEXT := Color("1c2430")
const TEXT_DIM := Color("5c6778")
const ACCENT := Color("2563eb")
const PANEL_BG := Color("e8edf4")
const CARD_BG := Color("eceff3")
const INK_LINE := Color("1e3a5f")
const DRAWN_CHIP_SIZE := 40.0
const COST_CHIP_SIZE := 26.0
const DRAG_SCROLL_EDGE := 72.0
const DRAG_SCROLL_SPEED := 620.0

@onready var _header: Label = %Header
@onready var _phase_label: Label = %PhaseLabel
@onready var _message_label: Label = %MessageLabel
@onready var _message_panel: PanelContainer = %MessagePanel
@onready var _token_section: PanelContainer = %TokenSection
@onready var _token_label: Label = %TokenLabel
@onready var _drawn_box: HBoxContainer = %DrawnBox
@onready var _convert_label: Label = %ConvertLabel
@onready var _convert_box: HBoxContainer = %ConvertBox
@onready var _roster_label: Label = %RosterLabel
@onready var _roster_box: HFlowContainer = %RosterBox
@onready var _offer_label: Label = %OfferLabel
@onready var _offer_box: HFlowContainer = %OfferBox
@onready var _board_row: HBoxContainer = %BoardRow
@onready var _contracts_box: HFlowContainer = %ContractsBox
@onready var _actions_box: VBoxContainer = %ActionsBox
@onready var _journal_list: RichTextLabel = %JournalList
@onready var _end_turn_button: Button = %EndTurnButton
@onready var _game_over_panel: PanelContainer = %GameOverPanel
@onready var _game_over_label: Label = %GameOverLabel
@onready var _new_run_button: Button = %NewRunButton
@onready var _scroll: ScrollContainer = %Scroll

var _selected_contract_id: String = ""
var _selected_assignees: Array = []
var _contract_tokens: Dictionary = ActionToken.empty_pool()
var _facility_id: String = ""
var _facility_tokens: Dictionary = ActionToken.empty_pool()


func _ready() -> void:
	_apply_chrome()
	GameState.state_changed.connect(_refresh)
	GameState.message_posted.connect(_on_message)
	_end_turn_button.pressed.connect(_on_end_turn)
	_new_run_button.pressed.connect(_on_new_run)
	GameState.new_run()
	set_process(true)


func _process(delta: float) -> void:
	if _scroll == null or not get_viewport().gui_is_dragging():
		return
	var mouse := _scroll.get_local_mouse_position()
	var view_h := _scroll.size.y
	var speed := 0.0
	if mouse.y < DRAG_SCROLL_EDGE:
		speed = -DRAG_SCROLL_SPEED * (1.0 - clampf(mouse.y / DRAG_SCROLL_EDGE, 0.0, 1.0))
	elif mouse.y > view_h - DRAG_SCROLL_EDGE:
		speed = DRAG_SCROLL_SPEED * (1.0 - clampf((view_h - mouse.y) / DRAG_SCROLL_EDGE, 0.0, 1.0))
	if speed != 0.0:
		_scroll.scroll_vertical = int(round(_scroll.scroll_vertical + speed * delta))


func _apply_chrome() -> void:
	_message_panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, ACCENT, 6, 3))
	_game_over_panel.add_theme_stylebox_override("panel", _panel_style(CARD_BG, ACCENT, 4, 4))
	_style_label(_header, 16, TEXT)
	_style_label(_phase_label, 15, ACCENT)
	_style_label(_message_label, 14, TEXT)
	_style_label(_token_label, 15, ACCENT)
	_style_label(_convert_label, 12, TEXT_DIM)
	_token_section.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, ACCENT, 6, 3))
	_style_label(_roster_label, 15, ACCENT)
	_style_label(_offer_label, 15, ACCENT)
	_style_label(%ContractsLabel, 15, ACCENT)
	_style_label(%ActionsLabel, 15, ACCENT)
	_style_label(_game_over_label, 18, TEXT)
	_journal_list.add_theme_color_override("default_color", TEXT)
	_journal_list.add_theme_font_size_override("normal_font_size", 13)
	_journal_list.add_theme_stylebox_override("normal", _panel_style(PANEL_BG, INK_LINE, 6, 3))
	for button in [_end_turn_button, _new_run_button]:
		_style_button(button)


func _on_message(text: String) -> void:
	_message_label.text = text


func _on_end_turn() -> void:
	_contract_tokens = ActionToken.empty_pool()
	_facility_tokens = ActionToken.empty_pool()
	_facility_id = ""
	_selected_assignees.clear()
	_selected_contract_id = ""
	GameState.end_turn()


func _on_new_run() -> void:
	_game_over_panel.visible = false
	_contract_tokens = ActionToken.empty_pool()
	_facility_tokens = ActionToken.empty_pool()
	_facility_id = ""
	_selected_assignees.clear()
	_selected_contract_id = ""
	GameState.new_run()


func _refresh() -> void:
	_clamp_spent_tokens()
	_header.text = "Turn %d / %d    Coin %d    Bag %d    Discard %d" % [
		GameState.turn,
		GameState.MAX_TURNS,
		GameState.guild_coin,
		GameState.bag.bag_count(),
		GameState.bag.discard_count(),
	]
	_phase_label.text = GameState.phase_name()
	if _message_label.text.is_empty():
		_message_label.text = "Select actions for this turn."

	_roster_label.text = "Roster  %d / %d" % [GameState.roster.size(), GameState.MAX_ROSTER]

	_clear_container(_roster_box)
	_clear_container(_contracts_box)
	_clear_container(_actions_box)
	_clear_container(_offer_box)
	_clear_container(_drawn_box)
	_clear_container(_convert_box)

	if GameState.phase == GameState.Phase.GAME_OVER:
		_show_game_over()
		return

	_game_over_panel.visible = false
	var is_act := GameState.phase == GameState.Phase.ACT
	var is_acquire := GameState.phase == GameState.Phase.ACQUIRE
	_end_turn_button.visible = is_act
	_offer_label.visible = is_acquire
	_offer_box.visible = is_acquire
	_board_row.visible = is_act
	_token_section.visible = is_act

	_build_tokens()
	_build_offer()
	_build_roster()
	_build_contracts()
	_build_guild_actions()
	_build_journal()


func _show_game_over() -> void:
	_game_over_panel.visible = true
	_end_turn_button.visible = false
	_offer_label.visible = false
	_offer_box.visible = false
	_board_row.visible = false
	_token_section.visible = false
	match GameState.result:
		GameState.GameResult.WIN:
			_game_over_label.text = "Victory! The guild survived the season."
		GameState.GameResult.LOSE:
			_game_over_label.text = "Defeat! The guild collapsed."
		_:
			_game_over_label.text = "Game Over"


func _available_tokens() -> Dictionary:
	return ActionToken.subtract_pool(
		ActionToken.subtract_pool(GameState.drawn_tokens, _contract_tokens),
		_facility_tokens
	)


func _clamp_spent_tokens() -> void:
	_contract_tokens = _clamp_pool(_contract_tokens, GameState.drawn_tokens)
	_facility_tokens = _clamp_pool(
		_facility_tokens,
		ActionToken.subtract_pool(GameState.drawn_tokens, _contract_tokens)
	)


func _clamp_pool(spent: Dictionary, available: Dictionary) -> Dictionary:
	var clamped: Dictionary = ActionToken.empty_pool()
	for token_type in ActionToken.ALL_TYPES:
		clamped[token_type] = mini(int(spent.get(token_type, 0)), int(available.get(token_type, 0)))
	return clamped


func _build_tokens() -> void:
	if GameState.phase != GameState.Phase.ACT:
		return

	var available: Dictionary = _available_tokens()
	var drawn_count := ActionToken.total(available)
	_token_label.text = "Drawn tokens  ·  %d" % drawn_count
	if drawn_count == 0:
		_drawn_box.add_child(_card_label("None available", 13, TEXT_DIM, false))
	else:
		for token_type in ActionToken.ALL_TYPES:
			for _i in int(available.get(token_type, 0)):
				var chip := TokenChipScript.new()
				chip.setup(token_type, DRAWN_CHIP_SIZE, false, true, true)
				chip.chip_pressed.connect(_on_drawn_chip_pressed.bind(chip))
				_drawn_box.add_child(chip)

	_convert_label.text = "Change: 2 matching → 1, or any 3 → 1. Click tokens to convert, or drag them onto a job."
	for token_type in ActionToken.ALL_TYPES:
		var chip := TokenChipScript.new()
		chip.setup(token_type, DRAWN_CHIP_SIZE, false, true)
		chip.tooltip_text = "Change into %s" % ActionToken.NAMES[token_type]
		chip.chip_pressed.connect(_on_convert_target_pressed.bind(token_type))
		_convert_box.add_child(chip)


func _on_drawn_chip_pressed(chip) -> void:
	chip.set_selected(not chip.selected)
	_update_convert_hint()


func _selected_payment() -> Dictionary:
	var payment: Dictionary = ActionToken.empty_pool()
	for child in _drawn_box.get_children():
		if child.has_method("set_selected") and child.selected:
			ActionToken.add_tokens(payment, child.token_type, 1)
	return payment


func _update_convert_hint() -> void:
	var payment: Dictionary = _selected_payment()
	if ActionToken.is_pair_payment(payment):
		_convert_label.text = "2 matching selected. Click a token to change into."
	elif ActionToken.total(payment) == 3:
		_convert_label.text = "Any 3 selected. Click a token to change into."
	elif ActionToken.total(payment) == 0:
		_convert_label.text = "Change: 2 matching → 1, or any 3 → 1. Click tokens to convert, or drag them onto a job."
	else:
		_convert_label.text = "Need 2 matching tokens, or any 3."


func _on_convert_target_pressed(token_type: int) -> void:
	var payment: Dictionary = _selected_payment()
	if not ActionToken.can_pay(_available_tokens(), payment):
		_message_label.text = "Those tokens are already committed to a job."
		return
	GameState.convert_tokens(payment, token_type)


func _add_chip_block(parent: Node, title: String, pool: Dictionary) -> void:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 4)
	var caption := _card_label(title, 12, TEXT_DIM, false)
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	block.add_child(caption)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_theme_constant_override("separation", 4)
	if ActionToken.total(pool) == 0:
		row.add_child(_card_label("none", 12, TEXT_DIM, false))
	else:
		TokenChipScript.add_pool(row, pool, COST_CHIP_SIZE)
	block.add_child(row)
	parent.add_child(block)


func _build_roster() -> void:
	for adventurer in GameState.roster:
		var card := AdventurerCardScript.new()
		var interactable := false
		var action_text := ""
		if GameState.phase == GameState.Phase.RETIRE:
			interactable = GameState.can_retire(adventurer.instance_id)
			action_text = "Click to retire"
		elif GameState.phase == GameState.Phase.ACT:
			interactable = not assigned_this_turn_blocked(adventurer.instance_id)
			action_text = "Click to assign"
		card.configure_roster(
			adventurer,
			_selected_assignees.has(adventurer.instance_id),
			interactable,
			action_text
		)
		var instance_id: int = adventurer.instance_id
		if GameState.phase == GameState.Phase.RETIRE:
			card.pressed.connect(_on_retire_pressed.bind(instance_id))
		elif GameState.phase == GameState.Phase.ACT:
			card.pressed.connect(_on_assignee_pressed.bind(instance_id, card))
		_roster_box.add_child(card)


func _on_retire_pressed(instance_id: int) -> void:
	GameState.retire(instance_id)


func assigned_this_turn_blocked(instance_id: int) -> bool:
	return GameState.assigned_this_turn.has(instance_id)


func _on_assignee_pressed(instance_id: int, card) -> void:
	if assigned_this_turn_blocked(instance_id):
		return
	if _selected_assignees.has(instance_id):
		_selected_assignees.erase(instance_id)
		card.set_selected(false)
		_refresh()
		return
	var max_send := _assignment_limit()
	if _selected_assignees.size() >= max_send:
		_message_label.text = "Already selected the heroes this action can take."
		return
	_selected_assignees.append(instance_id)
	_refresh()


func _assignment_limit() -> int:
	if not GameState.did_contract_this_turn:
		_ensure_contract_selected()
		if not _selected_contract_id.is_empty():
			return int(GameState.contract_templates[_selected_contract_id].get("max_adventurers", 1))
	return 1


func _ensure_contract_selected() -> void:
	if GameState.did_contract_this_turn:
		_selected_contract_id = ""
		return
	if not _selected_contract_id.is_empty() and GameState.contracts.has(_selected_contract_id):
		if not GameState.resolved_contracts.has(_selected_contract_id):
			return
	_selected_contract_id = ""
	for contract_id in GameState.contracts:
		if not GameState.resolved_contracts.has(contract_id):
			_selected_contract_id = contract_id
			return


func _build_contracts() -> void:
	if GameState.phase != GameState.Phase.ACT:
		return

	_ensure_contract_selected()
	for contract_id in GameState.contracts:
		var contract: Dictionary = GameState.contract_templates[contract_id]
		var selected: bool = _selected_contract_id == contract_id
		var resolved: bool = GameState.resolved_contracts.has(contract_id)
		var risk := _risk_color(String(contract.get("risk_tag", "")))
		if resolved:
			risk = Color("8a93a0")
		var can_prepare: bool = not resolved and not GameState.did_contract_this_turn
		var panel := _board_card(selected, risk, can_prepare)
		if can_prepare:
			panel.connect("token_dropped", _on_contract_token_dropped.bind(contract_id))
		var body: VBoxContainer = panel.get_node("Body")

		body.add_child(_card_label(String(contract.get("name", "")), 16, TEXT, true))
		var min_send: int = int(contract.get("min_adventurers", 1))
		var max_send: int = int(contract.get("max_adventurers", 1))
		var extra_heroes: int = max_send - min_send
		var hero_line := "Heroes: %d required" % min_send
		if extra_heroes > 0:
			hero_line += "  ·  up to %d optional" % extra_heroes
		body.add_child(_card_label(hero_line, 12, TEXT_DIM, false))

		var costs: Dictionary = ActionToken.parse_cost_map(contract.get("token_cost", {}))
		_add_chip_block(body, "Required tokens", costs)
		var max_tokens: int = GameState.get_contract_max_tokens(contract_id)
		body.add_child(_card_label(
			"Up to %d tokens on this contract" % max_tokens,
			12,
			TEXT_DIM,
			false
		))

		var reward_text: String = String(GameState.discovered_rewards.get(contract_id, "???"))
		body.add_child(_card_label(
			"Risk %s    Reward %s" % [contract.get("risk_tag", ""), reward_text],
			12,
			TEXT_DIM,
			false
		))
		var hint := _card_label("“%s”" % contract.get("hint", ""), 12, TEXT_DIM, false)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(hint)

		if can_prepare:
			if selected:
				body.add_child(_party_label(contract))
			_add_token_drop_section(
				body,
				"Drop to pay",
				_contract_tokens if selected else ActionToken.empty_pool(),
				can_prepare,
				_slot_limit_for_contract(contract_id),
				_on_contract_token_dropped.bind(contract_id),
				_on_contract_token_returned.bind(contract_id)
			)
		if selected and can_prepare:
			var send_button := Button.new()
			send_button.text = "Send party"
			send_button.pressed.connect(_on_send_contract.bind(contract_id))
			_style_button(send_button)
			body.add_child(send_button)
		elif not selected:
			var select_button := Button.new()
			if resolved:
				select_button.text = "Contract completed"
				select_button.disabled = true
			elif GameState.did_contract_this_turn:
				select_button.text = "Already took a contract this round"
				select_button.disabled = true
			else:
				select_button.text = "Prepare this contract"
				select_button.pressed.connect(_select_contract.bind(contract_id))
			_style_button(select_button)
			body.add_child(select_button)

		if resolved:
			var result_label := _card_label(
				_format_contract_result(GameState.get_contract_result(contract_id)),
				12,
				TEXT,
				false
			)
			result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.add_child(result_label)

		_contracts_box.add_child(panel)


func _party_label(contract: Dictionary) -> Label:
	var min_send: int = int(contract.get("min_adventurers", 1))
	var names: PackedStringArray = PackedStringArray()
	for instance_id in _selected_assignees:
		var adventurer := GameState.get_adventurer_by_id(instance_id)
		if adventurer == null:
			continue
		names.append(String(GameState.get_template(adventurer.template_id).get("name", "")))
	var text := "Party: click roster cards to add"
	if not names.is_empty():
		text = "Party (%d/%d required): %s" % [
			_selected_assignees.size(),
			min_send,
			", ".join(names),
		]
	var label := _card_label(text, 12, ACCENT, false)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _slot_limit_for_contract(contract_id: String) -> int:
	return GameState.get_contract_max_tokens(contract_id)


func _slot_limit_for_facility(action_id: String) -> int:
	var costs: Dictionary = ActionToken.parse_cost_map(
		GameState.guild_action_templates[action_id].get("token_cost", {})
	)
	return ActionToken.total(costs)


func _add_token_drop_section(
	parent: Node,
	caption: String,
	spent: Dictionary,
	enabled: bool,
	slot_count: int,
	on_drop: Callable,
	on_return: Callable
) -> void:
	parent.add_child(_card_label(caption, 11, TEXT_DIM, false))
	var zone := DropZoneScript.new()
	zone.enabled = enabled
	zone.token_dropped.connect(on_drop)
	zone.configure(slot_count, COST_CHIP_SIZE, spent, on_return)
	parent.add_child(zone)


func _on_contract_token_dropped(token_type: int, contract_id: String) -> void:
	if int(_available_tokens().get(token_type, 0)) <= 0:
		_message_label.text = "No spare token of that type."
		return
	if _selected_contract_id != contract_id:
		_contract_tokens = ActionToken.empty_pool()
		_selected_assignees.clear()
		_selected_contract_id = contract_id
	if ActionToken.total(_contract_tokens) >= _slot_limit_for_contract(contract_id):
		_message_label.text = "No empty token slots on this contract."
		return
	ActionToken.add_tokens(_contract_tokens, token_type, 1)
	_refresh()


func _on_contract_token_returned(contract_id: String, token_type: int) -> void:
	if _selected_contract_id != contract_id:
		return
	if int(_contract_tokens.get(token_type, 0)) <= 0:
		return
	_contract_tokens[token_type] = int(_contract_tokens[token_type]) - 1
	_refresh()


func _select_contract(contract_id: String) -> void:
	if _selected_contract_id != contract_id:
		_contract_tokens = ActionToken.empty_pool()
		_selected_assignees.clear()
	_selected_contract_id = contract_id
	_refresh()


func _on_send_contract(contract_id: String) -> void:
	var contract: Dictionary = GameState.contract_templates[contract_id]
	var costs: Dictionary = ActionToken.parse_cost_map(contract.get("token_cost", {}))
	if not ActionToken.can_pay(_contract_tokens, costs):
		_message_label.text = "Drop the required tokens on this contract first."
		return
	var min_send: int = int(contract.get("min_adventurers", 1))
	if _selected_assignees.size() < min_send:
		_message_label.text = "Click %d roster card%s to pick the party first." % [
			min_send,
			"" if min_send == 1 else "s",
		]
		return
	var extras: Dictionary = ActionToken.subtract_pool(_contract_tokens, costs)
	if not GameState.try_resolve_contract(contract_id, _selected_assignees.duplicate(), extras):
		_refresh()
		return
	_selected_contract_id = ""
	_selected_assignees.clear()
	_contract_tokens = ActionToken.empty_pool()
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
		var can_use: bool = not GameState.did_guild_action_this_turn
		var panel := _board_card(_facility_id == action_id, ACCENT, can_use)
		if can_use:
			panel.connect("token_dropped", _on_facility_token_dropped.bind(action_id))
		var body: VBoxContainer = panel.get_node("Body")
		body.add_child(_card_label(String(action.get("name", "")), 16, TEXT, true))
		var costs: Dictionary = ActionToken.parse_cost_map(action.get("token_cost", {}))
		_add_chip_block(body, "Required tokens", costs)
		var requires_injured: bool = bool(action.get("requires_injured", false))
		body.add_child(_card_label(
			"Needs an injured adventurer" if requires_injured else "Needs a healthy adventurer",
			12,
			TEXT_DIM,
			false
		))
		body.add_child(_card_label(String(action.get("description", "")), 12, TEXT_DIM, false))

		var spent: Dictionary = _facility_tokens if _facility_id == action_id else ActionToken.empty_pool()
		_add_token_drop_section(
			body,
			"Drop to pay",
			spent,
			can_use,
			_slot_limit_for_facility(action_id),
			_on_facility_token_dropped.bind(action_id),
			_on_facility_token_returned.bind(action_id)
		)

		var button := Button.new()
		if not can_use:
			button.text = "Already used a guild facility this round"
			button.disabled = true
		else:
			button.text = "Use with selected hero"
			button.pressed.connect(_perform_guild_action.bind(action_id))
		_style_button(button)
		body.add_child(button)
		_actions_box.add_child(panel)


func _on_facility_token_dropped(token_type: int, action_id: String) -> void:
	if int(_available_tokens().get(token_type, 0)) <= 0:
		_message_label.text = "No spare token of that type."
		return
	if _facility_id != action_id:
		_facility_id = action_id
		_facility_tokens = ActionToken.empty_pool()
	if ActionToken.total(_facility_tokens) >= _slot_limit_for_facility(action_id):
		_message_label.text = "No empty token slots on this facility."
		return
	ActionToken.add_tokens(_facility_tokens, token_type, 1)
	_refresh()


func _on_facility_token_returned(action_id: String, token_type: int) -> void:
	if _facility_id != action_id:
		return
	if int(_facility_tokens.get(token_type, 0)) <= 0:
		return
	_facility_tokens[token_type] = int(_facility_tokens[token_type]) - 1
	_refresh()


func _perform_guild_action(action_id: String) -> void:
	if _selected_assignees.size() != 1:
		_message_label.text = "Select exactly one adventurer, then use this guild facility."
		return
	var costs: Dictionary = ActionToken.parse_cost_map(GameState.guild_action_templates[action_id].get("token_cost", {}))
	var spent: Dictionary = _facility_tokens if _facility_id == action_id else ActionToken.empty_pool()
	if not ActionToken.can_pay(spent, costs):
		_message_label.text = "Drop the required tokens on this facility first."
		return
	if not GameState.try_guild_action(action_id, _selected_assignees.duplicate()):
		_refresh()
		return
	_selected_assignees.clear()
	_facility_id = ""
	_facility_tokens = ActionToken.empty_pool()
	_refresh()


func _build_offer() -> void:
	if GameState.phase != GameState.Phase.ACQUIRE:
		return

	for template_id in GameState.offer:
		var card := AdventurerCardScript.new()
		card.configure_offer(template_id, GameState.can_acquire(template_id))
		card.pressed.connect(_on_hire_pressed.bind(template_id))
		_offer_box.add_child(card)


func _on_hire_pressed(template_id: String) -> void:
	GameState.acquire(template_id)


func _build_journal() -> void:
	var entries: Array = DiscoveryJournal.get_entries()
	if entries.is_empty():
		_journal_list.text = "[b]Guild log[/b]\nNothing has happened yet."
	else:
		_journal_list.text = "[b]Guild log[/b]\n\n" + "\n\n".join(entries)


func _risk_color(tag: String) -> Color:
	match tag.to_lower():
		"low":
			return Color("2bb673")
		"high":
			return Color("e23d3d")
		_:
			return Color("f08c00")


func _board_card(selected: bool, border: Color, drop_enabled: bool) -> PanelContainer:
	var panel := JobCardScript.new()
	panel.apply_look(CARD_BG, border, selected)
	panel.drop_enabled = drop_enabled
	var body := VBoxContainer.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 5)
	panel.add_child(body)
	return panel


func _panel_style(bg: Color, border: Color, radius: int = 6, width: int = 3, pad: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = pad
	style.content_margin_top = pad
	style.content_margin_right = pad
	style.content_margin_bottom = pad
	style.shadow_color = Color("1e3a5f")
	style.shadow_offset = Vector2(0, 3)
	style.shadow_size = 0
	return style


func _card_label(text: String, font_size: int, color: Color, _bold: bool) -> Label:
	var label := Label.new()
	label.text = text
	_style_label(label, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)


func _style_button(button: Button) -> void:
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 30)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("3b82f6")
	normal.border_color = INK_LINE
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	var hover := normal.duplicate()
	hover.bg_color = Color("60a5fa")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("2563eb")
	var disabled := normal.duplicate()
	disabled.bg_color = Color("c5cedb")
	disabled.border_color = Color("8a93a0")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("ffffff"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("ffffff"))
	button.add_theme_color_override("font_disabled_color", Color("6b7280"))


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
