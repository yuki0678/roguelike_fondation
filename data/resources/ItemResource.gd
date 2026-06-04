extends Resource
class_name ItemResource

# ─────────────────────────────────────────
#  ItemResource
#  Fichier .tres à créer dans Godot pour chaque item du jeu.
#  Exemple : res://data/items/epee_rouillée.tres
# ─────────────────────────────────────────

# --- Identité ---
@export var item_name: String = "Item sans nom"
@export var description: String = ""
@export_enum("weapon", "armor", "consumable", "special") var item_type: String = "weapon"

# --- Rareté ---
@export_enum("common", "rare", "epic", "mythic", "legendary") var rarity: String = "common"

# --- Bonus de stats ---
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var hp_bonus: int = 0           # bonus PV max permanent
@export var mana_bonus: int = 0
@export var chance_bonus: float = 0.0
@export var precision_bonus: float = 0.0
@export var evasion_bonus: float = 0.0

# --- Effets spéciaux ---
@export var special_effect: String = ""
# Exemples de valeurs : "revive", "restart_combat", "heal_on_pickup",
#                       "gold_on_kill", "double_loot", etc.

@export var effect_value: float = 0.0   # valeur numérique de l'effet si besoin

# --- Combo arme+bouclier ---
# Si l'arme a cette propriété à true ET que l'armure équipée est un bouclier
# → le joueur peut attaquer ET défendre le même tour
@export var is_sword: bool = false
@export var is_shield: bool = false

# --- Économie ---
@export var base_price: int = 10        # prix de base au marché

# ─────────────────────────────────────────
#  UTILITAIRES
# ─────────────────────────────────────────
func get_rarity_color() -> Color:
	match rarity:
		"common":    return Color("#AAAAAA")
		"rare":      return Color("#4488FF")
		"epic":      return Color("#AA44FF")
		"mythic":    return Color("#FF4444")
		"legendary": return Color("#FFD700")
		_:           return Color("#FFFFFF")

func get_rarity_label() -> String:
	match rarity:
		"common":    return "Commun"
		"rare":      return "Rare"
		"epic":      return "Épique"
		"mythic":    return "Mythique"
		"legendary": return "Légendaire"
		_:           return "?"

func get_market_price(visits: int) -> int:
	# Inflation : +10% par visite au marché
	var multiplier = 1.0 + (visits * 0.10)
	# Trait Cupide : marché 2x plus cher
	if "cupide" in PlayerData.traits:
		multiplier *= 2.0
	return int(base_price * multiplier)

func get_tooltip() -> String:
	var lines = []
	lines.append("[b]" + item_name + "[/b]  [" + get_rarity_label() + "]")
	lines.append(description)
	if attack_bonus != 0:   lines.append("ATT : +" + str(attack_bonus))
	if defense_bonus != 0:  lines.append("DEF : +" + str(defense_bonus))
	if hp_bonus != 0:       lines.append("PV max : +" + str(hp_bonus))
	if mana_bonus != 0:     lines.append("Mana : +" + str(mana_bonus))
	if special_effect != "": lines.append("Effet : " + special_effect)
	return "\n".join(lines)
