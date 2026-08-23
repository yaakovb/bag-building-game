class_name AdventurerInstance

enum InjuryState {
	HEALTHY,
	INJURED,
}

static var _next_id: int = 0

var instance_id: int
var template_id: String
var level: int = 1
var injury_state: int = InjuryState.HEALTHY


func _init(id: String) -> void:
	instance_id = _next_id
	_next_id += 1
	template_id = id


static func reset_ids() -> void:
	_next_id = 0


func is_injured() -> bool:
	return injury_state == InjuryState.INJURED


func is_assignable() -> bool:
	return injury_state == InjuryState.HEALTHY


func injury_label() -> String:
	if injury_state == InjuryState.INJURED:
		return "Injured"
	return "Healthy"
