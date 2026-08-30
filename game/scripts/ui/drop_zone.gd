extends PanelContainer

signal token_dropped(token_type: int)

const TokenChipScript := preload("res://scripts/ui/token_chip.gd")

const WELL_BG := Color("c5d4ea")
const WELL_BORDER := Color("3b6ea8")
const ZONE_BG := Color("eef3f8")
const ZONE_BORDER := Color("5b7aa3")
const ZONE_HOVER := Color("3b82f6")

var enabled: bool = true
var chip_row: HBoxContainer
var slot_count: int = 0

var _hovering: bool = false
var _chip_size: float = 28.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	chip_row = HBoxContainer.new()
	chip_row.add_theme_constant_override("separation", 4)
	chip_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	chip_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(chip_row)
	_apply_style()


func configure(p_slot_count: int, chip_size: float, spent: Dictionary, on_return: Callable) -> void:
	slot_count = p_slot_count
	_chip_size = chip_size
	for child in chip_row.get_children():
		chip_row.remove_child(child)
		child.queue_free()
	var placed := 0
	for token_type in ActionToken.ALL_TYPES:
		for _i in int(spent.get(token_type, 0)):
			if placed >= slot_count:
				break
			var chip := TokenChipScript.new()
			chip.setup(token_type, chip_size, false, true, false)
			chip.tooltip_text = "Click to return this token"
			chip.chip_pressed.connect(on_return.bind(token_type))
			chip_row.add_child(chip)
			placed += 1
		if placed >= slot_count:
			break
	while placed < slot_count:
		chip_row.add_child(_empty_well())
		placed += 1
	_apply_style()


func _empty_well() -> PanelContainer:
	var well := PanelContainer.new()
	well.custom_minimum_size = Vector2(_chip_size, _chip_size)
	well.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	well.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = WELL_BG
	style.border_color = WELL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(_chip_size * 0.5))
	well.add_theme_stylebox_override("panel", style)
	return well


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ok := enabled and typeof(data) == TYPE_DICTIONARY and String(data.get("kind", "")) == "token"
	_hovering = ok
	_apply_style()
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_hovering = false
	_apply_style()
	token_dropped.emit(int(data.get("token_type", 0)))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END or what == NOTIFICATION_MOUSE_EXIT:
		_hovering = false
		_apply_style()


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = ZONE_BG
	style.border_color = ZONE_HOVER if _hovering else ZONE_BORDER
	style.set_border_width_all(3 if _hovering else 2)
	style.set_corner_radius_all(0)
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	add_theme_stylebox_override("panel", style)
