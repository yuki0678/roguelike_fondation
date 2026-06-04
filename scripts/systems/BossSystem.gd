extends Node
# ─────────────────────────────────────────
#  BossSystem — Singleton
#  Gère les mécaniques spéciales des boss.
#  Appelé depuis CombatScene à chaque tour.
# ─────────────────────────────────────────

signal boss_mechanic_triggered(message: String)
signal boss_summon_enemy(enemy: Dictionary)

# ─────────────────────────────────────────
#  VÉRIFIE ET DÉCLENCHE LES MÉCANIQUES
#  Retourne un message de log si quelque chose se passe
# ─────────────────────────────────────────
func process_mechanic(boss: Dictionary, turn: int) -> String:
	var mechanic = boss.get("mechanic", "")
	var hp_ratio = float(boss["hp"]) / float(boss["max_hp"])
	var msg = ""

	match mechanic:

		"summon":
			# Invoque un gobelin à 50% PV (une seule fois)
			if hp_ratio <= 0.50 and not boss.get("mechanic_triggered", false):
				boss["mechanic_triggered"] = true
				var minion = {
					"id": "boss_minion", "name": "Sbire Gobelin", "tier": "normal",
					"hp": 40, "max_hp": 40, "attack": 10, "defense": 3,
					"precision": 0.70, "evasion": 0.05,
					"xp_reward": 0, "gold_reward_min": 0, "gold_reward_max": 0,
					"status_chance": 0.0, "possible_statuses": [], "statuses": []
				}
				emit_signal("boss_summon_enemy", minion)
				msg = "💢 " + boss.get("flavor", "Le boss appelle des renforts !")

		"armor_phase":
			# Défense doublée sous 50% PV
			if hp_ratio <= 0.50 and not boss.get("mechanic_triggered", false):
				boss["mechanic_triggered"] = true
				boss["defense"] = int(boss["defense"] * 2)
				msg = "🪨 " + boss.get("flavor", "Sa défense double !")

		"multi_status":
			# Inflige 2 statuts aléatoires chaque tour
			if turn % 2 == 0:
				var possible = boss.get("possible_statuses", ["poison"])
				var shuffled = possible.duplicate()
				shuffled.shuffle()
				for i in min(2, shuffled.size()):
					StatusSystem.apply_status({"is_player": true}, shuffled[i], 2)
				msg = "☠️ La sorcière répand ses miasmes !"

		"parry":
			# Géré dans CombatScene : les dégâts < seuil sont ignorés
			pass

		"dodge_phase":
			# Esquive parfaite tous les 4 tours
			boss["dodge_turn"] = boss.get("dodge_turn", 0) + 1
			if boss["dodge_turn"] % 4 == 0:
				boss["invincible_this_turn"] = true
				msg = "🌑 " + boss.get("flavor", "Il disparaît dans l'ombre !")
			else:
				boss["invincible_this_turn"] = false

		"aoe_freeze":
			# Gèle le joueur tous les 3 tours
			if turn % 3 == 0:
				StatusSystem.apply_status({"is_player": true}, "freeze", 1)
				msg = "❄️ " + boss.get("flavor", "Son souffle vous glace !")

		"lifesteal":
			# Géré dans execute_action : le boss se soigne
			pass

		"mana_drain":
			# Vole 2 mana au joueur chaque tour
			PlayerData.current_mana = max(0, PlayerData.current_mana - 2)
			msg = "🌀 " + boss.get("flavor", "Le vide absorbe votre magie ! -2 Mana")

		"execute":
			# Tue si joueur < 20% PV
			var hp_player = float(PlayerData.current_hp) / float(PlayerData.max_hp)
			if hp_player < 0.20:
				msg = "💀 " + boss.get("flavor", "Il vous exécute !")
				PlayerData.current_hp = 0
				CombatSystem.emit_signal("player_died")

		"all_mechanics":
			# Boss final : combine plusieurs mécaniques selon le tour
			if turn % 3 == 0:
				PlayerData.current_mana = max(0, PlayerData.current_mana - 1)
				msg = "🌀 Le Sans-Nom draine votre mana !"
			if turn % 4 == 0:
				StatusSystem.apply_status({"is_player": true}, "curse", 2)
				msg += "\n🌑 Il vous maudit !"
			if turn % 6 == 0:
				boss["invincible_this_turn"] = true
				msg += "\n✨ Il devient intouchable !"
			else:
				boss["invincible_this_turn"] = false
			var hp_player = float(PlayerData.current_hp) / float(PlayerData.max_hp)
			if hp_player < 0.15 and not boss.get("mechanic_triggered", false):
				boss["mechanic_triggered"] = true
				PlayerData.current_hp = 0
				CombatSystem.emit_signal("player_died")
				msg += "\n💀 Exécution !"

	if msg != "":
		emit_signal("boss_mechanic_triggered", msg)
	return msg

# ─────────────────────────────────────────
#  APPLIQUE LES DÉGÂTS EN TENANT COMPTE DES MÉCANIQUES
# ─────────────────────────────────────────
func apply_damage_to_boss(boss: Dictionary, damage: int) -> Dictionary:
	var result = {"damage_dealt": damage, "blocked": false, "message": ""}

	# Invincibilité (dodge_phase, all_mechanics)
	if boss.get("invincible_this_turn", false):
		result["damage_dealt"] = 0
		result["blocked"] = true
		result["message"] = "✨ Le boss est intouchable ce tour !"
		return result

	# Parade (iron_knight) : dégâts faibles ignorés
	if boss.get("mechanic", "") == "parry":
		var threshold = boss.get("parry_threshold", 15)
		if damage < threshold:
			result["damage_dealt"] = 0
			result["blocked"] = true
			result["message"] = "🛡️ " + boss.get("flavor", "Il pare votre coup !")
			return result

	# Lifesteal (blood_cultist) : le boss se soigne
	if boss.get("mechanic", "") == "lifesteal":
		var heal = int(damage * 0.30)
		boss["hp"] = min(boss["max_hp"], boss["hp"] + heal)
		result["message"] = "🩸 Le Cultiste se soigne de %d PV !" % heal

	boss["hp"] = max(0, boss["hp"] - damage)
	result["damage_dealt"] = damage
	return result

# ─────────────────────────────────────────
#  INTRO DU BOSS
# ─────────────────────────────────────────
func get_boss_intro(boss: Dictionary) -> String:
	var mechanic_hint = ""
	match boss.get("mechanic", ""):
		"summon":      mechanic_hint = "⚠️ Il peut invoquer des renforts."
		"armor_phase": mechanic_hint = "⚠️ Sa défense peut changer en cours de combat."
		"multi_status": mechanic_hint = "⚠️ Elle inflige de multiples altérations."
		"parry":       mechanic_hint = "⚠️ Les attaques faibles sont inutiles contre lui."
		"dodge_phase": mechanic_hint = "⚠️ Il disparaît parfois."
		"aoe_freeze":  mechanic_hint = "⚠️ Son souffle peut vous paralyser."
		"lifesteal":   mechanic_hint = "⚠️ Il se soigne en vous frappant."
		"mana_drain":  mechanic_hint = "⚠️ Il draine votre mana."
		"execute":     mechanic_hint = "⚠️ Restez au-dessus de 20% PV."
		"all_mechanics": mechanic_hint = "⚠️ Il maîtrise toutes les arts obscurs."
	return "%s\n%s" % [boss.get("flavor", ""), mechanic_hint]
