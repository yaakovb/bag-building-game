class_name TokenChip
extends PanelContainer

signal chip_pressed

const FILL := Color("3b82f6")
const FILL_SELECTED := Color("60a5fa")
const OUTLINE := Color("1e3a5f")
const OUTLINE_SELECTED := Color("f5d76e")

var token_type: int = ActionToken.Type.ATTACK
var selected: bool = false
var interactable: bool = false
var draggable: bool = false

var _chip_size: float = 44.0
var _hovered: bool = false
var _did_drag: bool = false


func setup(p_type: int, p_size: float, p_selected: bool, p_interactable: bool, p_draggable: bool = false) -> void:
	token_type = p_type
	_chip_size = p_size
	selected = p_selected
	interactable = p_interactable
	draggable = p_draggable
	custom_minimum_size = Vector2(_chip_size, _chip_size)
	size = Vector2(_chip_size, _chip_size)
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP if (interactable or draggable) else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_MOVE if draggable else (Control.CURSOR_POINTING_HAND if interactable else Control.CURSOR_ARROW)
	tooltip_text = ActionToken.NAMES[token_type]
	update_minimum_size()

	for child in get_children():
		child.free()

	var label := Label.new()
	label.text = ActionToken.EMOJI[token_type]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.custom_minimum_size = Vector2.ZERO
	label.add_theme_font_size_override("font_size", int(_chip_size * 0.5))
	add_child(label)
	_apply_style()


func _get_minimum_size() -> Vector2:
	return Vector2(_chip_size, _chip_size)


func set_selected(value: bool) -> void:
	selected = value
	_apply_style()


func _ready() -> void:
	mouse_entered.connect(func(): _hovered = true; _apply_style())
	mouse_exited.connect(func(): _hovered = false; _apply_style())


func _gui_input(event: InputEvent) -> void:
	if not interactable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_did_drag = false
		elif not _did_drag:
			chip_pressed.emit()
			accept_event()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable:
		return null
	_did_drag = true
	var preview := Label.new()
	preview.text = ActionToken.EMOJI[token_type]
	preview.add_theme_font_size_override("font_size", 28)
	set_drag_preview(preview)
	return {"kind": "token", "token_type": token_type}


static func add_pool(container: Node, pool: Dictionary, chip_size: float) -> void:
	for token_type in ActionToken.ALL_TYPES:
		for _i in int(pool.get(token_type, 0)):
			var chip := new()
			chip.setup(token_type, chip_size, false, false)
			container.add_child(chip)


func _apply_style() -> void:
	var radius := int(_chip_size * 0.5)
	var fill := FILL_SELECTED if selected else FILL
	var border := OUTLINE_SELECTED if selected else OUTLINE
	if _hovered and interactable and not selected:
		fill = fill.lightened(0.12)
		border = Color("16325c")
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color("1e3a5f")
	style.shadow_offset = Vector2(0, 2)
	style.shadow_size = 0
	add_theme_stylebox_override("panel", style)
