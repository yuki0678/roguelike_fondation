extends Node

signal combat_log(message: String)
signal player_died

func roll_d20() -> int:
	if "chaotique" in PlayerData.traits:
		return randi_range(1, 30)
	return randi_range(1, 20)

func get_die_max() -> int:
	return 30 if "chaotique" in PlayerData.traits else 20

func is_critical_success(roll: int) -> bool:
	return roll == get_die_max()

func is_critical_failure(roll: int) -> bool:
	if "chaotique" in PlayerData.traits:
		return roll <= 5
	return roll == 1

func get_roll_ratio(roll: int) -> float:
	return float(roll) / float(get_die_max())

func player_attack(roll: int, target: Dictionary) -> Dictionary:
	var result = { "hit": false, "damage": 0, "critical": false, "fumble": false, "message": "" }
	if is_critical_failure(roll):
		result["fumble"] = true
		result["message"] = "💀 Échec critique ! Tu trébuches et perds ton tour."
		emit_signal("combat_log", result["message"])
		return result
	var effective_precision = PlayerData.get_effective_precision()
	if randf() > effective_precision:
		result["message"] = "❌ Attaque manquée ! (Précision %.0f%%)" % (effective_precision * 100)
		emit_signal("combat_log", result["message"])
		return result
	result["hit"] = true
	var ratio = get_roll_ratio(roll)
	var base_attack = PlayerData.get_effective_attack()
	var raw_damage = int(base_attack * (0.5 + ratio * 0.75))
	var enemy_defense = target.get("defense", 0)
	var damage = max(1, raw_damage - enemy_defense)
	if is_critical_success(roll):
		damage *= 2
		result["critical"] = true
		Notifier.critical()
		result["message"] = "⭐ CRITIQUE ! "
	if PlayerData.player_class == "vampire":
		var lifesteal = max(1, int(damage * 0.10))
		PlayerData.heal(lifesteal)
		Notifier.heal_notif(lifesteal)
		result["message"] += "(+%d PV) " % lifesteal
	result["damage"] = damage
	RunStats.record_damage(damage, "Attaque")
	if is_critical_success(roll): RunStats.record_critical()
	AchievementSystem.check_critical(RunStats.criticals)
	if is_critical_failure(roll): RunStats.record_fumble()
	AchievementSystem.check_fumbles(RunStats.fumbles)
	result["message"] += "Tu infliges %d dégâts ! (D20: %d)" % [damage, roll]
	emit_signal("combat_log", result["message"])
	return result

func player_defend(roll: int) -> Dictionary:
	var result = { "defense_bonus": 0, "message": "" }
	if is_critical_failure(roll):
		result["defense_bonus"] = -int(PlayerData.get_effective_defense() * 0.5)
		result["message"] = "💀 Échec critique ! Garde brisée, tu subis +50% dégâts ce tour."
		emit_signal("combat_log", result["message"])
		return result
	var ratio = get_roll_ratio(roll)
	var base_def = PlayerData.get_effective_defense()
	var bonus = int(base_def * ratio)
	if is_critical_success(roll):
		bonus = int(base_def * 1.5)
		result["message"] = "⭐ Parade parfaite ! Défense x1.5 ce tour."
	else:
		result["message"] = "🛡️ Tu te défends. Défense +%d ce tour. (D20: %d)" % [bonus, roll]
	result["defense_bonus"] = bonus
	emit_signal("combat_log", result["message"])
	return result

func player_cast_scroll(scroll, roll: int, targets: Array) -> Dictionary:
	var result = { "success": false, "message": "", "values": [] }
	if not scroll.is_usable():
		result["message"] = "❌ Mana insuffisant ! (%d/%d)" % [PlayerData.current_mana, scroll.mana_cost]
		emit_signal("combat_log", result["message"])
		return result
	PlayerData.spend_mana(scroll.mana_cost)
	result["success"] = true
	var ratio = get_roll_ratio(roll)
	match scroll.effect_type:
		"damage":
			var damage = int(scroll.base_value * (0.5 + ratio * 0.75))
			if is_critical_success(roll):
				damage *= 2
				Notifier.critical("⭐ Sort critique !")
				result["message"] = "⭐ Sort critique ! "
			if roll >= scroll.d20_high_threshold and scroll.d20_high_effect != "":
				for t in targets:
					StatusSystem.apply_status(t, scroll.d20_high_effect, scroll.status_duration)
				result["message"] += "[%s !] " % scroll.d20_high_effect
			elif roll <= scroll.d20_low_threshold and scroll.d20_low_effect != "":
				StatusSystem.apply_status({"is_player": true}, scroll.d20_low_effect, scroll.status_duration)
				damage = 0
				result["message"] += "[retourné sur toi !] "
# Bonus Mage : +25 ATT sur les dégâts de parchemin
			if PlayerData.player_class == "mage":
				damage += 25
			result["values"] = [damage]
			result["message"] += "🔮 %s inflige %d dégâts ! (D20: %d)" % [scroll.scroll_name, damage, roll]
		"heal":
			var heal_amount = int(scroll.base_value * (0.5 + ratio * 0.75))
			if roll >= scroll.d20_high_threshold:
				heal_amount = int(scroll.base_value * 2.0)
				result["message"] = "⭐ Soin massif ! "
			PlayerData.heal(heal_amount)
			Notifier.heal_notif(heal_amount)
			result["values"] = [heal_amount]
			result["message"] += "💚 %s restaure %d PV. (D20: %d)" % [scroll.scroll_name, heal_amount, roll]
		"shield":
			var shield_val = int(scroll.base_value * ratio)
			if roll >= scroll.d20_high_threshold:
				shield_val *= 2
				result["message"] = "⭐ Double bouclier ! "
			elif roll <= scroll.d20_low_threshold:
				shield_val = 0
				result["message"] = "💔 Le bouclier se brise ! "
			result["values"] = [shield_val]
			result["message"] += "🔵 %s : bouclier de %d. (D20: %d)" % [scroll.scroll_name, shield_val, roll]
		"debuff":
			if roll <= scroll.d20_low_threshold:
				StatusSystem.apply_status({"is_player": true}, "curse", scroll.status_duration)
				result["message"] = "💀 La malédiction se retourne ! (D20: %d)" % roll
			else:
				for t in targets:
					StatusSystem.apply_status(t, "curse", scroll.status_duration)
				result["message"] = "🌑 %s : stats ennemies réduites %d tours. (D20: %d)" % [scroll.scroll_name, scroll.status_duration, roll]
		"flee":
			if roll <= scroll.d20_low_threshold:
				PlayerData.restore_mana(int(scroll.mana_cost * 0.5))
				result["success"] = false
				result["message"] = "❌ Téléportation ratée ! (D20: %d)" % roll
			else:
				result["values"] = ["flee"]
				result["message"] = "✨ Téléportation réussie !"
	emit_signal("combat_log", result["message"])
	return result

func enemy_attack(enemy: Dictionary, defense_bonus: int = 0) -> Dictionary:
	var result = { "hit": false, "damage": 0, "message": "" }
	if randf() < PlayerData.get_effective_evasion():
		result["message"] = "💨 Tu esquives l'attaque de %s !" % enemy.get("name", "l'ennemi")
		emit_signal("combat_log", result["message"])
		return result
	if randf() > enemy.get("precision", 0.70):
		result["message"] = "❌ %s rate son attaque !" % enemy.get("name", "L'ennemi")
		emit_signal("combat_log", result["message"])
		return result
	var enemy_roll = randi_range(1, 20)
	var ratio = float(enemy_roll) / 20.0
	var raw_damage = int(enemy.get("attack", 10) * (0.5 + ratio * 0.75))
	var total_defense = PlayerData.get_effective_defense() + defense_bonus
	var damage = max(1, raw_damage - total_defense)
	for scroll in PlayerData.passive_scrolls:
		if scroll.passive_type == "reflect_damage":
			var reflected = int(damage * scroll.value)
			enemy["hp"] = enemy.get("hp", 1) - reflected
			result["message"] += "(🪃 %d réfléchis) " % reflected
	var status_chance = enemy.get("status_chance", 0.0)
	if PlayerData.player_class == "archer":
		status_chance = min(1.0, status_chance * 1.5)
	if PlayerData.player_class == "vampire":
		status_chance = min(1.0, status_chance * 1.3)
	if randf() < status_chance:
		var possible = enemy.get("possible_statuses", [])
		if not possible.is_empty():
			var status_type = possible[randi() % possible.size()]
			StatusSystem.apply_status({"is_player": true}, status_type, 2)
			Notifier.status_notif(StatusSystem.get_status_label(status_type))
			result["message"] += "[%s !] " % status_type
	PlayerData.take_damage(damage)
	RunStats.record_hit_received(damage)
	Notifier.damage_notif(damage)
	result["hit"] = true
	result["damage"] = damage
	result["message"] += "⚔️ %s inflige %d dégâts ! (%d/%d PV)" % [
		enemy.get("name", "L'ennemi"), damage,
		PlayerData.current_hp, PlayerData.max_hp
	]
	emit_signal("combat_log", result["message"])
	return result

func can_attack_and_defend() -> bool:
	var has_sword  = PlayerData.equipped_weapon != null and PlayerData.equipped_weapon.get_meta("is_sword", false)
	var has_shield = PlayerData.equipped_armor  != null and PlayerData.equipped_armor.get_meta("is_shield", false)
	return has_sword and has_shield

func on_enemy_defeated(enemy: Dictionary) -> void:
	var xp = enemy.get("xp_reward", 20)
	XPSystem.gain_xp(xp)
	var gold = LootSystem.generate_gold_reward_from_dict(enemy)
	RunStats.record_kill(enemy.get("tier", "normal"))
	AchievementSystem.check_kills(RunStats.enemies_killed)
	AchievementSystem.check_boss_kill(RunStats.bosses_killed)
	RunStats.record_gold(gold)
	PlayerData.gold += gold
	Notifier.gold_notif(gold)
	emit_signal("combat_log", "✅ Victoire ! +%d XP, +%d pièces." % [xp, gold])
	for scroll in PlayerData.passive_scrolls:
		if scroll.passive_type == "hp_regen":
			PlayerData.heal(int(scroll.value))
