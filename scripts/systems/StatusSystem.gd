extends Node
# ─────────────────────────────────────────
#  StatusSystem — Singleton (Autoload)
#  Gère les altérations d'état.
# ─────────────────────────────────────────

func apply_status(target: Dictionary, status_type: String, duration: int) -> void:
	var status_list = _get_status_list(target)
	if status_list == null:
		return
	for existing in status_list:
		if existing["type"] == status_type:
			if status_type == "bleed":
				existing["stacks"] += 1
			else:
				existing["duration"] = max(existing["duration"], duration)
			return
	status_list.append({ "type": status_type, "duration": duration, "stacks": 1 })

func process_statuses(target: Dictionary) -> Dictionary:
	var status_list = _get_status_list(target)
	if status_list == null:
		return { "can_act": true, "messages": [] }
	var can_act = true
	var messages = []
	var to_remove = []
	for status in status_list:
		match status["type"]:
			"burn":
				var dmg = 5
				_apply_damage(target, dmg)
				messages.append("🔥 [b]Brûlure[/b] inflige %d dégâts !" % dmg)
				if target.get("is_player", false):
					PlayerData.attack = max(1, PlayerData.attack - 2)
			"poison":
				var dmg = 4
				_apply_damage(target, dmg)
				messages.append("☠️ [b]Poison[/b] inflige %d dégâts !" % dmg)
				if target.get("is_player", false):
					PlayerData.current_mana = max(0, PlayerData.current_mana - 1)
			"freeze":
				can_act = false
				messages.append("❄️ [b]Gel[/b] : tu es paralysé !")
			"paralysis":
				if randf() < 0.60:
					can_act = false
					messages.append("⚡ [b]Paralysie[/b] : tu es paralysé !")
			"bleed":
				var dmg = 3 * status["stacks"]
				_apply_damage(target, dmg)
				messages.append("🩸 [b]Saignement[/b] inflige %d dégâts !" % dmg)
			"curse":
				if target.get("is_player", false):
					PlayerData.attack  = max(1, int(PlayerData.attack * 0.80))
					PlayerData.defense = max(0, int(PlayerData.defense * 0.80))
					messages.append("🌑 [b]Malédiction[/b] : tes statistiques sont réduites !")
		status["duration"] -= 1
		if status["duration"] <= 0:
			to_remove.append(status)
	for s in to_remove:
		status_list.erase(s)
	return { "can_act": can_act, "messages": messages }

func _get_status_list(target: Dictionary):
	if target.get("is_player", false):
		return PlayerData.active_statuses
	elif target.has("statuses"):
		return target["statuses"]
	return null

func _get_target_id(target: Dictionary) -> String:
	if target.get("is_player", false):
		return "player"
	return target.get("id", "enemy")

func _apply_damage(target: Dictionary, dmg: int) -> void:
	if target.get("is_player", false):
		PlayerData.take_damage(dmg)
	else:
		target["hp"] = max(0, target.get("hp", 1) - dmg)

func get_status_label(status_type: String) -> String:
	match status_type:
		"burn":      return "🔥 Brûlure"
		"poison":    return "☠️ Poison"
		"freeze":    return "❄️ Gel"
		"paralysis": return "⚡ Paralysie"
		"bleed":     return "🩸 Saignement"
		"curse":     return "🌑 Malédiction"
		_:           return status_type

func has_status(status_type: String) -> bool:
	for s in PlayerData.active_statuses:
		if s["type"] == status_type:
			return true
	return false
