extends Node

signal level_up(new_level: int)

func gain_xp(amount: int) -> void:
	if PlayerData.player_class == "erudit":
		amount = int(amount * 1.40)
	var meta_bonus = SaveManager.meta_upgrades.get("xp_multiplier", 0)
	amount = int(float(amount) * (1.0 + float(meta_bonus) * 0.10))
	PlayerData.current_xp += amount
	while PlayerData.current_xp >= PlayerData.xp_to_next_level:
		_level_up()

func _level_up() -> void:
	PlayerData.current_xp -= PlayerData.xp_to_next_level
	PlayerData.level += 1
	PlayerData.xp_to_next_level = int(100.0 * pow(1.15, float(PlayerData.level - 1)))
	_apply_level_bonus()
	emit_signal("level_up", PlayerData.level)

func _apply_level_bonus() -> void:
	match PlayerData.player_class:
		"civil":
			PlayerData.attack  += 2
			PlayerData.defense += 1
			PlayerData.max_hp  += 5
			PlayerData.current_hp = min(PlayerData.current_hp + 5, PlayerData.max_hp)
		"guerrier":
			PlayerData.attack  += 4
			PlayerData.defense += 3
			PlayerData.max_hp  += 8
			PlayerData.current_hp = min(PlayerData.current_hp + 8, PlayerData.max_hp)
		"voleur":
			PlayerData.attack  += 3
			PlayerData.evasion  = min(0.95, PlayerData.evasion + 0.01)
			PlayerData.max_hp  += 3
			PlayerData.current_hp = min(PlayerData.current_hp + 3, PlayerData.max_hp)
		"mage":
			PlayerData.max_mana    += 2
			PlayerData.current_mana = min(PlayerData.current_mana + 2, PlayerData.max_mana)
			PlayerData.attack      += 1
			PlayerData.max_hp      += 2
			PlayerData.current_hp  = min(PlayerData.current_hp + 2, PlayerData.max_hp)
		"chanceux":
			PlayerData.chance = min(1.0, PlayerData.chance + 0.02)
			PlayerData.attack  += 1
			PlayerData.max_hp  += 3
			PlayerData.current_hp = min(PlayerData.current_hp + 3, PlayerData.max_hp)
		"erudit":
			PlayerData.attack  += 2
			PlayerData.defense += 1
			PlayerData.max_hp  += 3
			PlayerData.current_hp = min(PlayerData.current_hp + 3, PlayerData.max_hp)
		"archer":
			PlayerData.precision = min(1.0, PlayerData.precision + 0.03)
			PlayerData.attack    += 3
			PlayerData.max_hp    += 4
			PlayerData.current_hp = min(PlayerData.current_hp + 4, PlayerData.max_hp)
		"berserker":
			PlayerData.attack  += 6
			PlayerData.max_hp  += 2
			PlayerData.current_hp = min(PlayerData.current_hp + 2, PlayerData.max_hp)
		"vampire":
			PlayerData.attack  += 3
			PlayerData.max_hp  += 4
			PlayerData.current_hp = min(PlayerData.current_hp + 4, PlayerData.max_hp)

func get_xp_progress() -> float:
	if PlayerData.xp_to_next_level == 0:
		return 1.0
	return float(PlayerData.current_xp) / float(PlayerData.xp_to_next_level)

func is_max_level() -> bool:
	return PlayerData.level >= 100
