class_name EffectResolver


static func apply(effect_id: String, effects_db: Dictionary, state: Node) -> String:
	if not effects_db.has(effect_id):
		return "Unknown retire effect."
	var effect: Dictionary = effects_db[effect_id]
	var message: String = effect.get("message", "")
	match effect.get("type", ""):
		"gain_guild_coin":
			state.guild_coin += int(effect.get("amount", 0))
		"lose_guild_coin":
			state.guild_coin -= int(effect.get("amount", 0))
		"extra_basic_offer":
			state.extra_basic_offer = true
		"draw_extra_token":
			var drawn: Array = state.bag.draw(1)
			for token_type in drawn:
				ActionToken.add_tokens(state.drawn_tokens, token_type, 1)
		"risk_injury_if_contract_failed":
			if state.contract_failed_this_turn:
				var living: Array = state.get_living_roster()
				if not living.is_empty():
					living[0].injury_state = AdventurerInstance.InjuryState.INJURED
					message = "A random adventurer was injured from retire risk."
	return message
