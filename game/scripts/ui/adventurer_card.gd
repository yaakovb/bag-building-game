class_name AdventurerCard
extends PanelContainer

signal pressed

const TokenChipScript := preload("res://scripts/ui/token_chip.gd")

const INK := Color("1c2430")
const INK_DIM := Color("5c6778")
const CARD_BG := Color("dfe3ea")
const CARD_BG_INJURED := Color("e4d8d8")
const ACCENT := Color("2563eb")
const CARD_WIDTH := 188.0
const CLASS_COLORS := {
	"Fighter": Color("e85d04"),
	"Cleric": Color("e0a100"),
	"Ranger": Color("2d9a46"),
	"Bard": Color("9b4dca"),
	"Mage": Color("3b6ef5"),
	"Leader": Color("d97706"),
}

var instance_id: int = -1
var template_id: String = ""

var _selected: bool = false
var _interactable: bool = false
var _hovered: bool = false
var _injured: bool = false
var _class_name_text: String = ""


func _ready() -> void:
	mouse_entered.connect(func(): _hovered = true; _apply_style())
	mouse_exited.connect(func(): _hovered = false; _apply_style())


func _gui_input(event: InputEvent) -> void:
	if not _interactable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func set_selected(value: bool) -> void:
	_selected = value
	_apply_style()
	var footer := get_node_or_null("Body/Footer") as Label
	if footer != null and _interactable:
		footer.text = "Selected" if _selected else footer.get_meta("idle_text", "Click to select")


func configure_roster(adventurer: AdventurerInstance, selected: bool, interactable: bool, action_text: String) -> void:
	var template: Dictionary = GameState.get_template(adventurer.template_id)
	instance_id = adventurer.instance_id
	template_id = adventurer.template_id
	_injured = adventurer.is_injured()
	_configure(template, adventurer, selected, interactable, action_text, "")


func configure_offer(id: String, interactable: bool) -> void:
	var template: Dictionary = GameState.get_template(id)
	instance_id = -1
	template_id = id
	_injured = false
	var cost: int = int(template.get("cost", 0))
	var cost_text := "Free hire" if cost <= 0 else "Hire for %d coin" % cost
	_configure(template, null, false, interactable, "Hire", cost_text)


func _configure(
	template: Dictionary,
	adventurer: AdventurerInstance,
	selected: bool,
	interactable: bool,
	action_text: String,
	cost_text: String
) -> void:
	_selected = selected
	_interactable = interactable
	_class_name_text = String(template.get("class", ""))
	custom_minimum_size = Vector2(CARD_WIDTH, 0)
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactable else Control.CURSOR_ARROW

	for child in get_children():
		child.free()

	var body := VBoxContainer.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 3)
	add_child(body)

	var hero_name := _label(String(template.get("name", "Unknown")), 18, INK, true)
	body.add_child(hero_name)

	var level: int = adventurer.level if adventurer != null else 1
	var meta := _label("%s  ·  Level %d" % [_class_name_text, level], 13, INK_DIM, false)
	body.add_child(meta)

	if adventurer != null:
		var status_text := adventurer.injury_label()
		if GameState.assigned_this_turn.has(adventurer.instance_id):
			status_text += "  ·  Assigned"
		var status_color := Color("d64545") if adventurer.is_injured() else Color("2bb673")
		if GameState.assigned_this_turn.has(adventurer.instance_id):
			status_color = INK_DIM
		body.add_child(_label(status_text, 13, status_color, true))

	if not cost_text.is_empty():
		body.add_child(_label(cost_text, 14, ACCENT, true))

	body.add_child(_separator())
	body.add_child(_stats_grid(template.get("attributes", {})))
	body.add_child(_separator())

	var contribution: Dictionary = ActionToken.parse_cost_map(template.get("bag_contribution", {}))
	body.add_child(_label("Adds to bag", 12, INK_DIM, false))
	var bag_row := HBoxContainer.new()
	bag_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bag_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bag_row.add_theme_constant_override("separation", 4)
	if ActionToken.total(contribution) == 0:
		bag_row.add_child(_label("none", 12, INK_DIM, false))
	else:
		TokenChipScript.add_pool(bag_row, contribution, 20.0)
	body.add_child(bag_row)

	var retire_bonus: int = int(template.get("retire_bonus", 0))
	var retire_draw: int = GameState.RETIRE_DRAW_BASE + level + retire_bonus
	body.add_child(_label(
		"Retire: draw %d  ·  %s" % [retire_draw, template.get("retire_tag", "")],
		12,
		INK_DIM,
		false
	))

	var footer := _label("", 13, ACCENT, true)
	footer.name = "Footer"
	var idle_text := action_text
	if not interactable:
		if adventurer != null and GameState.assigned_this_turn.has(adventurer.instance_id):
			idle_text = "Already assigned"
		elif not cost_text.is_empty() and not GameState.can_acquire(template_id):
			idle_text = "Can't afford"
		elif GameState.phase == GameState.Phase.RETIRE:
			idle_text = "Cannot retire"
		else:
			idle_text = ""
	footer.text = "Selected" if selected and interactable else idle_text
	footer.set_meta("idle_text", action_text)
	body.add_child(footer)

	_apply_style()


func _apply_style() -> void:
	var bg := CARD_BG_INJURED if _injured else CARD_BG
	var accent: Color = CLASS_COLORS.get(_class_name_text, Color("4b5568"))
	var border := accent
	var width := 4
	if _injured:
		border = Color("d64545")
	if _selected:
		width = 6
	elif _hovered and _interactable:
		border = border.lightened(0.12)
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color("1c2430")
	style.shadow_offset = Vector2(0, 3)
	style.shadow_size = 0
	add_theme_stylebox_override("panel", style)


func _stats_grid(attrs: Dictionary) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 2)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows := [
		[ActionToken.Type.ATTACK, "attack"],
		[ActionToken.Type.DEFENSE, "defense"],
		[ActionToken.Type.MAGIC, "magic"],
		[ActionToken.Type.SUPPORT, "support"],
		[ActionToken.Type.LEADERSHIP, "leadership"],
	]
	for row in rows:
		var value: int = int(attrs.get(row[1], 0))
		var color := INK if value > 0 else Color("9aa3b2")
		var cell := _label("%s %d" % [ActionToken.EMOJI[row[0]], value], 13, color, value > 0)
		cell.autowrap_mode = TextServer.AUTOWRAP_OFF
		grid.add_child(cell)
	return grid


func _label(text: String, font_size: int, color: Color, bold: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.35))
		label.add_theme_constant_override("shadow_offset_x", 0)
		label.add_theme_constant_override("shadow_offset_y", 1)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _separator() -> HSeparator:
	var line := HSeparator.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sep := StyleBoxFlat.new()
	sep.bg_color = Color("b8c0cc")
	sep.set_content_margin_all(0)
	sep.content_margin_top = 1
	sep.content_margin_bottom = 1
	line.add_theme_stylebox_override("separator", sep)
	return line
