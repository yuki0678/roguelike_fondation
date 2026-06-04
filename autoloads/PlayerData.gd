extends Node

# --- Identité ---
var player_name: String = "Héros"
var player_class: String = "civil"

# --- Stats de base ---
var max_hp: int = 100
var current_hp: int = 100
var attack: int = 30
var defense: int = 15
var chance: float = 0.05
var precision: float = 0.80
var evasion: float = 0.02
var max_mana: int = 10
var current_mana: int = 10

# --- Niveau & XP ---
var level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 100

# --- Équipement ---
var equipped_weapon = null
var equipped_armor = null
var equipped_scroll_1 = null
var equipped_scroll_2 = null
var passive_scrolls: Array = []

# --- Inventaire ---
var inventory: Array = []

# --- Traits ---
var traits: Array = []

# --- Statuts ---
var active_statuses: Array = []

# --- Économie ---
var gold: int = 0

# --- Flags ---
var has_revive_item: bool = false
var has_restart_combat_item: bool = false
var markets_visited: int = 0

# ─────────────────────────────────────────
#  INITIALISATION PAR CLASSE
# ─────────────────────────────────────────
func apply_class(new_class: String) -> void:
	player_class = new_class
	match new_class:
		"civil":
			pass  # stats de base inchangées
		"guerrier":
			max_hp    = int(max_hp  * 1.25)
			attack    = int(attack  * 1.25)
			defense   = int(defense * 1.25)
			chance   = 0.0
			precision -= 0.10
			current_hp = max_hp
		"voleur":
			max_hp    = int(max_hp  * 0.75)
			attack    = int(attack  * 1.25)
			defense   = int(defense * 0.75)
			evasion  += 0.08
			current_hp = max_hp
		"mage":
			max_hp    = int(max_hp  * 0.75)
			defense   = int(defense * 0.75)
			max_mana += 10
			current_mana = max_mana
			current_hp = max_hp
			# +25 ATT sur parchemins : géré dans ScrollSystem via flag
		"chanceux":
			max_hp    = int(max_hp  * 0.90)
			attack    = int(attack  * 0.90)
			defense   = int(defense * 0.90)
			chance   += 0.05
			current_hp = max_hp
		"erudit":
			max_hp    = int(max_hp  * 0.75)
			current_hp = max_hp
			# +50% XP géré dans XPSystem
		"archer":
			precision += 0.20
			# +25% risque statuts géré dans CombatSystem / EnemyAI
		"berserker":
			max_hp    = int(max_hp  * 0.75)
			attack    = int(attack  * 1.75)
			defense   = int(defense * 0.75)
			current_hp = max_hp
		"vampire":
			evasion   = 0.0
			# vole 10% dégâts : géré dans CombatSystem
			# +25% risque statuts : géré dans CombatSystem


# ─────────────────────────────────────────
#  HP & MANA
# ─────────────────────────────────────────
func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	AchievementSystem.check_low_hp(current_hp)

func heal(amount: int) -> void:
	if "frenesie" in traits:
		var cap = int(max_hp * 0.5)
		current_hp = min(cap, current_hp + amount)
	else:
		current_hp = min(max_hp, current_hp + amount)
	RunStats.record_heal(amount)

func heal_percent(percent: float) -> void:
	heal(int(max_hp * percent))

func spend_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		return true
	return false

func restore_mana(amount: int) -> void:
	current_mana = min(max_mana, current_mana + amount)

func is_dead() -> bool:
	return current_hp <= 0

# ─────────────────────────────────────────
#  INVENTAIRE
# ─────────────────────────────────────────
func add_item(item) -> void:
	inventory.append(item)

func remove_item(item) -> void:
	inventory.erase(item)

func equip_weapon(item) -> void:
	# L'ancienne arme retourne dans l'inventaire sans toucher aux stats
	if equipped_weapon != null:
		inventory.append(equipped_weapon)
	equipped_weapon = item
	inventory.erase(item)

func equip_armor(item) -> void:
	if equipped_armor != null:
		inventory.append(equipped_armor)
	equipped_armor = item
	inventory.erase(item)

func equip_scroll(scroll, slot: int) -> void:
	if slot == 1:
		if equipped_scroll_1 != null:
			inventory.append(equipped_scroll_1)
		equipped_scroll_1 = scroll
	elif slot == 2:
		if equipped_scroll_2 != null:
			inventory.append(equipped_scroll_2)
		equipped_scroll_2 = scroll
	inventory.erase(scroll)

func add_passive_scroll(scroll) -> void:
	passive_scrolls.append(scroll)
	inventory.erase(scroll)

# ─────────────────────────────────────────
#  TRAITS
# ─────────────────────────────────────────
func add_trait(trait_id: String) -> bool:
	if traits.size() >= 2:
		return false
	if trait_id in traits:
		return false
	traits.append(trait_id)
	_apply_trait_effects(trait_id)
	AchievementSystem.check_traits(traits)
	return true

func _apply_trait_effects(trait_id: String) -> void:
	match trait_id:
		"berserker":
			# +50% ATT, -25% PV, -50% DEF
			attack  = int(attack  * 1.50)
			max_hp  = int(max_hp  * 0.75)
			defense = int(defense * 0.50)
			current_hp = min(current_hp, max_hp)
		"beni":
			# +15% CHA, événements 2x punitifs (géré dans EventScene)
			chance = min(1.0, chance + 0.15)
		"traqueur":
			# +5% PREC, duos +50% fréquents (géré dans EnemyDatabase)
			precision = min(1.0, precision + 0.05)
		"fantome":
			# +13% ESQ, -40% PV max
			evasion = min(0.95, evasion + 0.13)
			max_hp  = int(max_hp * 0.60)
			current_hp = min(current_hp, max_hp)
		"frenesie":
			# 2 actions/tour (géré dans CombatScene), PV max -50%
			max_hp = int(max_hp * 0.50)
			current_hp = min(current_hp, max_hp)
		"cupide":
			# +100% pièces, inflation sévère (géré dans LootSystem/MarketScene)
			pass
		"chaotique":
			# D20→D30, 1-5 = fumble (géré dans CombatSystem)
			pass
		"maudit":
			# Items rang+, 1 item détruit/10 vagues (géré dans RunManager)
			pass

# ─────────────────────────────────────────
#  STATS EFFECTIVES
# ─────────────────────────────────────────
func get_effective_attack() -> int:
	var total = attack
	if equipped_weapon != null:
		total += equipped_weapon.get_meta("attack_bonus", 0)
	# Passif instinct prédateur
	for scroll in passive_scrolls:
		if scroll.passive_type == "attack_low_hp":
			if float(current_hp) / float(max_hp) < 0.30:
				total = int(total * (1.0 + scroll.value))
	return total

func get_effective_defense() -> int:
	var total = defense
	if equipped_armor != null:
		total += equipped_armor.get_meta("defense_bonus", 0)
	for scroll in passive_scrolls:
		if scroll.passive_type == "defense_bonus":
			total += int(total * scroll.value)
	return total

func get_effective_evasion() -> float:
	var total = evasion
	for scroll in passive_scrolls:
		if scroll.passive_type == "evasion_bonus":
			total += scroll.value
	return clamp(total, 0.0, 0.95)

func get_effective_precision() -> float:
	var total = precision
	for scroll in passive_scrolls:
		if scroll.passive_type == "precision_bonus":
			total += scroll.value
	return clamp(total, 0.0, 1.0)

# ─────────────────────────────────────────
#  RESET
# ─────────────────────────────────────────
func reset_for_new_run() -> void:
	player_class = "civil"
	max_hp = 100
	current_hp = 100
	attack = 30
	defense = 15
	chance = 0.05
	precision = 0.80
	evasion = 0.02
	max_mana = 10
	current_mana = 10
	level = 1
	current_xp = 0
	xp_to_next_level = 100
	equipped_weapon = null
	equipped_armor = null
	equipped_scroll_1 = null
	equipped_scroll_2 = null
	passive_scrolls.clear()
	inventory.clear()
	traits.clear()
	active_statuses.clear()
	gold = 0
	has_revive_item = false
	has_restart_combat_item = false
	markets_visited = 0
	RunStats.reset()
