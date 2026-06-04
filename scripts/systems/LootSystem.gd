extends Node
# ─────────────────────────────────────────
#  LootSystem — Singleton (Autoload)
#  Génère le loot après combat, gère les raretés et le trésor.
# ─────────────────────────────────────────

# Probabilités de rareté (en %)
const RARITY_WEIGHTS = {
	"common":    70,
	"rare":      20,
	"epic":       7,
	"mythic":     2.5,
	"legendary":  0.5,
}

# ─────────────────────────────────────────
#  TIRAGE DE RARETÉ
# ─────────────────────────────────────────
func roll_rarity() -> String:
	var roll = randf() * 100.0
	var cumul = 0.0
	for rarity in RARITY_WEIGHTS:
		cumul += RARITY_WEIGHTS[rarity]
		if roll < cumul:
			return rarity
	return "common"

# ─────────────────────────────────────────
#  LOOT POST-COMBAT : 3 choix de stat
# ─────────────────────────────────────────
# Retourne 3 propositions d'augmentation de stats
# La qualité dépend du tier de l'ennemi
func generate_stat_choices(enemy_tier: String) -> Array:
	var multiplier = 1.0
	match enemy_tier:
		"elite": multiplier = 1.5
		"boss":  multiplier = 2.5

	var all_stats = ["attack", "defense", "hp", "mana", "chance", "precision", "evasion"]
	all_stats.shuffle()
	var chosen_stats = all_stats.slice(0, 3)

	var choices = []
	for stat in chosen_stats:
		choices.append(_make_stat_choice(stat, multiplier))
	return choices

func _make_stat_choice(stat: String, multiplier: float) -> Dictionary:
	match stat:
		"attack":
			var val = int(randi_range(2, 5) * multiplier)
			return {"stat": "attack", "value": val, "label": "+ %d Attaque" % val}
		"defense":
			var val = int(randi_range(1, 4) * multiplier)
			return {"stat": "defense", "value": val, "label": "+ %d Défense" % val}
		"hp":
			var val = int(randi_range(5, 15) * multiplier)
			return {"stat": "hp", "value": val, "label": "+ %d PV max" % val}
		"mana":
			var val = int(randi_range(1, 3) * multiplier)
			return {"stat": "mana", "value": val, "label": "+ %d Mana max" % val}
		"chance":
			var val = round(randi_range(1, 3) * multiplier) / 100.0
			return {"stat": "chance", "value": val, "label": "+ %.0f%% Chance" % (val * 100)}
		"precision":
			var val = round(randi_range(2, 6) * multiplier) / 100.0
			return {"stat": "precision", "value": val, "label": "+ %.0f%% Précision" % (val * 100)}
		"evasion":
			var val = round(randi_range(1, 3) * multiplier) / 100.0
			return {"stat": "evasion", "value": val, "label": "+ %.0f%% Esquive" % (val * 100)}
	return {"stat": "attack", "value": 1, "label": "+ 1 Attaque"}

# Applique le choix de stat sélectionné par le joueur
func apply_stat_choice(choice: Dictionary) -> void:
	var val = choice["value"]
	match choice["stat"]:
		"attack":    PlayerData.attack += val
		"defense":   PlayerData.defense += val
		"hp":
			PlayerData.max_hp += val
			PlayerData.current_hp += val  # on augmente aussi les HP actuels
		"mana":
			PlayerData.max_mana += val
			PlayerData.current_mana += val
		"chance":    PlayerData.chance = clamp(PlayerData.chance + val, 0.0, 1.0)
		"evasion":
			PlayerData.evasion = min(1.0, PlayerData.evasion + val)
		"precision":
			PlayerData.precision = min(1.0, PlayerData.precision + val)

	# Passif Toucher Chanceux : 10% de chance de doubler le loot
	_check_double_loot()

func _check_double_loot() -> void:
	for scroll in PlayerData.passive_scrolls:
		if scroll.passive_type == "double_loot":
			if randf() < scroll.value:
				# Annonce à la scène que le loot est doublé (signal ou flag)
				print("Toucher Chanceux : loot doublé !")
				# TODO : signal vers CombatScene pour afficher un message

# ─────────────────────────────────────────
#  LOOT OR
# ─────────────────────────────────────────
func generate_gold_reward_from_dict(enemy: Dictionary) -> int:
	var base = randi_range(
		enemy.get("gold_reward_min", 5),
		enemy.get("gold_reward_max", 15)
	)
	if "cupide" in PlayerData.traits:
		base *= 2
	return base

func generate_gold_reward(enemy: EnemyResource) -> int:
	var base = randi_range(enemy.gold_reward_min, enemy.gold_reward_max)
	# Trait Cupide : +100% or
	if "cupide" in PlayerData.traits:
		base *= 2
	return base

# ─────────────────────────────────────────
#  TRÉSOR
# ─────────────────────────────────────────
func generate_treasure_loot() -> void:
	var rarity = roll_rarity()
	# Tire un item aléatoire du pool du MarketScene
	var pool = [
		{"name": "Épée rouillée",     "type": "weapon",    "rarity": "common",  "attack_bonus": 5,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 15, "is_sword": true,  "is_shield": false, "special": ""},
		{"name": "Bouclier de bois",  "type": "armor",     "rarity": "common",  "attack_bonus": 0,  "defense_bonus": 4,  "hp_bonus": 0,  "price": 12, "is_sword": false, "is_shield": true,  "special": ""},
		{"name": "Dague acérée",      "type": "weapon",    "rarity": "rare",    "attack_bonus": 8,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 25, "is_sword": false, "is_shield": false, "special": ""},
		{"name": "Armure de cuir",    "type": "armor",     "rarity": "common",  "attack_bonus": 0,  "defense_bonus": 6,  "hp_bonus": 5,  "price": 20, "is_sword": false, "is_shield": false, "special": ""},
		{"name": "Potion de vie",     "type": "consumable","rarity": "common",  "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 30, "price": 18, "is_sword": false, "is_shield": false, "special": "heal_on_pickup"},
		{"name": "Épée longue",       "type": "weapon",    "rarity": "rare",    "attack_bonus": 12, "defense_bonus": 0,  "hp_bonus": 0,  "price": 35, "is_sword": true,  "is_shield": false, "special": ""},
		{"name": "Bouclier de fer",   "type": "armor",     "rarity": "rare",    "attack_bonus": 0,  "defense_bonus": 9,  "hp_bonus": 0,  "price": 32, "is_sword": false, "is_shield": true,  "special": ""},
		{"name": "Lame de sang",      "type": "weapon",    "rarity": "epic",    "attack_bonus": 18, "defense_bonus": 0,  "hp_bonus": 0,  "price": 60, "is_sword": true,  "is_shield": false, "special": ""},
		{"name": "Armure de plaques", "type": "armor",     "rarity": "epic",    "attack_bonus": 0,  "defense_bonus": 15, "hp_bonus": 10, "price": 65, "is_sword": false, "is_shield": false, "special": ""},
	]
	# Filtre par rareté si possible
	var filtered = pool.filter(func(i): return i["rarity"] == rarity)
	if filtered.is_empty():
		filtered = pool
	var item = filtered[randi() % filtered.size()]
	# Applique l'item directement
	if item["attack_bonus"] > 0:  PlayerData.attack += item["attack_bonus"]
	if item["defense_bonus"] > 0: PlayerData.defense += item["defense_bonus"]
	if item["hp_bonus"] > 0:
		PlayerData.max_hp += item["hp_bonus"]
		PlayerData.current_hp += item["hp_bonus"]
	# Tout va dans l'inventaire, le joueur choisit quoi équiper
	PlayerData.add_item(_make_item_object(item))
	# Stocke le message pour affichage
	last_treasure_message = "🎁 Trésor [%s] : %s  (ATT+%d DEF+%d PV+%d)" % [
		rarity, item["name"], item["attack_bonus"], item["defense_bonus"], item["hp_bonus"]
	]

var last_treasure_message: String = ""

func _make_item_object(item: Dictionary) -> Object:
	var obj = RefCounted.new()
	obj.set_meta("item_name",     item["name"])
	obj.set_meta("attack_bonus",  item["attack_bonus"])
	obj.set_meta("defense_bonus", item["defense_bonus"])
	obj.set_meta("is_sword",      item.get("is_sword", false))
	obj.set_meta("is_shield",     item.get("is_shield", false))
	return obj

# ─────────────────────────────────────────
#  MARCHÉ — GÉNÉRATION DE 3 ITEMS
# ─────────────────────────────────────────
func generate_market_items() -> Array:
	var items = []
	# Trait Maudit : items de rang supérieur accessibles
	var rarity_boost = "maudit" in PlayerData.traits
	for i in 3:
		var rarity = roll_rarity()
		if rarity_boost:
			rarity = _upgrade_rarity(rarity)
		# TODO : tirer depuis l'ItemDatabase
		items.append({"rarity": rarity, "item": null})
	return items

func _upgrade_rarity(rarity: String) -> String:
	match rarity:
		"common":  return "rare"
		"rare":    return "epic"
		"epic":    return "mythic"
		"mythic":  return "legendary"
		_:         return rarity
