extends Node
# ─────────────────────────────────────────
#  EnemyAI — Singleton
#  Décide de l'action d'un ennemi à chaque tour.
#  Retourne un Dictionary décrivant l'action choisie.
# ─────────────────────────────────────────

enum EnemyAction {
	ATTACK,
	DEFEND,
	STATUS_ATTACK,  # attaque avec chance d'infliger un statut
	HEAVY_ATTACK,   # attaque puissante mais lente (prévenu)
	HEAL,           # se soigne
	TAUNT,          # provocation : réduit la défense du joueur
	SKIP,           # passe son tour
}

# ─────────────────────────────────────────
#  DÉCISION D'ACTION
# ─────────────────────────────────────────
func decide_action(enemy: Dictionary, turn: int) -> Dictionary:
	var tier = enemy.get("tier", "normal")
	match tier:
		"normal":  return _decide_normal(enemy, turn)
		"elite":   return _decide_elite(enemy, turn)
		"boss":    return _decide_boss(enemy, turn)
		_:         return _decide_normal(enemy, turn)

func _decide_normal(enemy: Dictionary, _turn: int) -> Dictionary:
	# Les ennemis normaux attaquent surtout, défendent rarement
	var roll = randi() % 100
	if enemy.get("can_use_status", false) and roll < 20:
		return _make_action(EnemyAction.STATUS_ATTACK, enemy)
	elif enemy.get("can_defend", false) and roll < 30:
		return _make_action(EnemyAction.DEFEND, enemy)
	else:
		return _make_action(EnemyAction.ATTACK, enemy)

func _decide_elite(enemy: Dictionary, turn: int) -> Dictionary:
	var hp_ratio = float(enemy["hp"]) / float(enemy["max_hp"])
	# Élite enragée sous 30% PV
	if hp_ratio < 0.30:
		return _make_action(EnemyAction.HEAVY_ATTACK, enemy)
	# Pattern : attaque lourde tous les 3 tours
	if turn % 3 == 0:
		return _make_action(EnemyAction.HEAVY_ATTACK, enemy)
	var roll = randi() % 100
	if enemy.get("can_use_status", false) and roll < 30:
		return _make_action(EnemyAction.STATUS_ATTACK, enemy)
	elif roll < 20:
		return _make_action(EnemyAction.DEFEND, enemy)
	else:
		return _make_action(EnemyAction.ATTACK, enemy)

func _decide_boss(enemy: Dictionary, turn: int) -> Dictionary:
	var hp_ratio = float(enemy["hp"]) / float(enemy["max_hp"])
	var phase = _get_boss_phase(hp_ratio)

	match phase:
		1: # Phase 1 : > 66% PV — attaques normales avec patterns
			if turn % 4 == 0:
				return _make_action(EnemyAction.TAUNT, enemy)
			elif turn % 2 == 0 and enemy.get("can_use_status", false):
				return _make_action(EnemyAction.STATUS_ATTACK, enemy)
			else:
				return _make_action(EnemyAction.ATTACK, enemy)
		2: # Phase 2 : 33-66% PV — plus agressif
			if turn % 3 == 0:
				return _make_action(EnemyAction.HEAVY_ATTACK, enemy)
			elif turn % 5 == 0:
				return _make_action(EnemyAction.HEAL, enemy)
			else:
				return _make_action(EnemyAction.ATTACK, enemy)
		3: # Phase 3 : < 33% PV — enragé
			if turn % 2 == 0:
				return _make_action(EnemyAction.HEAVY_ATTACK, enemy)
			elif enemy.get("can_use_status", false):
				return _make_action(EnemyAction.STATUS_ATTACK, enemy)
			else:
				return _make_action(EnemyAction.ATTACK, enemy)
	return _make_action(EnemyAction.ATTACK, enemy)

func _get_boss_phase(hp_ratio: float) -> int:
	if hp_ratio > 0.66: return 1
	if hp_ratio > 0.33: return 2
	return 3

# ─────────────────────────────────────────
#  CONSTRUCTION DE L'ACTION
# ─────────────────────────────────────────
func _make_action(action: EnemyAction, enemy: Dictionary) -> Dictionary:
	match action:
		EnemyAction.ATTACK:
			return {
				"type": "attack",
				"damage_multiplier": 1.0,
				"preview": "",   # rien de prévisible
				"status": ""
			}
		EnemyAction.HEAVY_ATTACK:
			return {
				"type": "attack",
				"damage_multiplier": 1.8,
				"preview": "💢 L'ennemi prépare une attaque puissante !",
				"status": ""
			}
		EnemyAction.DEFEND:
			return {
				"type": "defend",
				"defense_bonus": int(enemy.get("defense", 5) * 0.5),
				"preview": "🛡️ L'ennemi se met en garde.",
				"status": ""
			}
		EnemyAction.STATUS_ATTACK:
			var possible = enemy.get("possible_statuses", [])
			var status = possible[randi() % possible.size()] if not possible.is_empty() else "burn"
			return {
				"type": "status_attack",
				"damage_multiplier": 0.7,
				"preview": "",
				"status": status
			}
		EnemyAction.HEAL:
			var heal_amount = int(enemy.get("max_hp", 50) * 0.15)
			return {
				"type": "heal",
				"heal_amount": heal_amount,
				"preview": "✨ L'ennemi récupère des forces...",
				"status": ""
			}
		EnemyAction.TAUNT:
			return {
				"type": "taunt",
				"defense_debuff": 3,
				"preview": "😤 L'ennemi vous provoque !",
				"status": ""
			}
		EnemyAction.SKIP:
			return {
				"type": "skip",
				"preview": "💤 L'ennemi hésite.",
				"status": ""
			}
	return {"type": "attack", "damage_multiplier": 1.0, "preview": "", "status": ""}

# ─────────────────────────────────────────
#  EXÉCUTION DE L'ACTION
#  Retourne un message de log
# ─────────────────────────────────────────
func execute_action(action: Dictionary, enemy: Dictionary, player_defense_bonus: int) -> String:
	match action["type"]:

		"attack":
			var roll = randi_range(1, 20)
			var ratio = float(roll) / 20.0
			var raw = int(enemy.get("attack", 10) * ratio * action.get("damage_multiplier", 1.0))
			var total_def = PlayerData.get_effective_defense() + player_defense_bonus
			var dmg = max(1, raw - total_def)
			# Reflect passif
			for scroll in PlayerData.passive_scrolls:
				if scroll.passive_type == "reflect_damage":
					var reflected = int(dmg * scroll.value)
					enemy["hp"] = max(0, enemy["hp"] - reflected)
			PlayerData.take_damage(dmg)
			# Classe Archer : +risque statut
			var status_chance = enemy.get("status_chance", 0.0)
			if PlayerData.player_class == "archer":  status_chance = min(1.0, status_chance * 1.5)
			if PlayerData.player_class == "vampire": status_chance = min(1.0, status_chance * 1.3)
			if randf() < status_chance:
				var possible = enemy.get("possible_statuses", [])
				if not possible.is_empty():
					StatusSystem.apply_status({"is_player": true}, possible[randi() % possible.size()], 2)
			return "⚔️ %s inflige %d dégâts ! (%d/%d PV)" % [
				enemy["name"], dmg, PlayerData.current_hp, PlayerData.max_hp]

		"status_attack":
			var roll = randi_range(1, 20)
			var ratio = float(roll) / 20.0
			var raw = int(enemy.get("attack", 10) * ratio * 0.7)
			var dmg = max(1, raw - PlayerData.get_effective_defense())
			PlayerData.take_damage(dmg)
			var status = action.get("status", "burn")
			StatusSystem.apply_status({"is_player": true}, status, 3)
			return "⚔️ %s inflige %d dégâts et applique %s !" % [
				enemy["name"], dmg, StatusSystem.get_status_label(status)]

		"defend":
			enemy["defense_bonus_turn"] = action.get("defense_bonus", 0)
			return "🛡️ %s se défend ce tour." % enemy["name"]

		"heal":
			var amount = action.get("heal_amount", 10)
			enemy["hp"] = min(enemy["max_hp"], enemy["hp"] + amount)
			return "✨ %s récupère %d PV ! (%d/%d)" % [
				enemy["name"], amount, enemy["hp"], enemy["max_hp"]]

		"taunt":
			var debuff = action.get("defense_debuff", 3)
			PlayerData.defense = max(0, PlayerData.defense - debuff)
			return "😤 %s vous provoque ! -DEF %d" % [enemy["name"], debuff]

		"skip":
			return "💤 %s passe son tour." % enemy["name"]

	return ""

# ─────────────────────────────────────────
#  PRÉVISUALISATION (affiché AVANT le tour ennemi)
#  Certaines actions donnent un indice, d'autres non
# ─────────────────────────────────────────
func get_preview(enemy: Dictionary, turn: int) -> String:
	var tier = enemy.get("tier", "normal")
	# Les ennemis normaux n'annoncent rien
	if tier == "normal":
		return ""
	# Élites et boss annoncent leurs attaques puissantes
	var action = decide_action(enemy, turn)
	return action.get("preview", "")
