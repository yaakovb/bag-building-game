class_name JobCard
extends PanelContainer

signal token_dropped(token_type: int)

var drop_enabled: bool = false
var _hovering: bool = false
var _bg: Color = Color("eceff3")
var _border: Color = Color("8a93a0")
var _width: int = 4


func apply_look(bg: Color, border: Color, selected: bool) -> void:
	_bg = bg
	_border = border
	_width = 6 if selected else 4
	custom_minimum_size = Vector2(260, 0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_style()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ok := drop_enabled and typeof(data) == TYPE_DICTIONARY and String(data.get("kind", "")) == "token"
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
	style.bg_color = _bg
	style.border_color = Color("3b82f6") if _hovering else _border
	style.set_border_width_all(_width + (1 if _hovering else 0))
	style.set_corner_radius_all(0)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color("1e3a5f")
	style.shadow_offset = Vector2(0, 3)
	style.shadow_size = 0
	add_theme_stylebox_override("panel", style)
