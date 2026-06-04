extends Resource
class_name ScrollResource

# ─────────────────────────────────────────
#  ScrollResource
#  Définit un parchemin actif (sort avec mana) ou passif (effet permanent).
# ─────────────────────────────────────────

# --- Identité ---
@export var scroll_name: String = "Parchemin inconnu"
@export var description: String = ""
@export_enum("active", "passive") var scroll_type: String = "active"
@export_enum("common", "rare", "epic", "mythic", "legendary") var rarity: String = "rare"

# --- Parchemin ACTIF ---
@export var mana_cost: int = 2
@export_enum("damage", "heal", "shield", "debuff", "utility", "flee") var effect_type: String = "damage"
@export var base_value: int = 0          # dégâts, soin, etc.
@export var targets_all_enemies: bool = false

# Interaction D20
@export var d20_high_threshold: int = 15   # D20 ≥ threshold → effet bonus
@export var d20_high_effect: String = ""   # ex: "burn", "freeze", "double", "bleed"
@export var d20_low_threshold: int = 3     # D20 ≤ threshold → effet malus
@export var d20_low_effect: String = ""    # ex: "self_curse", "shield_break", "fail"

# Durée des effets de statut infligés (en tours)
@export var status_duration: int = 2

# --- Parchemin PASSIF ---
@export var passive_type: String = ""
@export var value: float = 0.0   # valeur du bonus passif

# --- Économie ---
@export var base_price: int = 20

# ─────────────────────────────────────────
#  UTILITAIRES
# ─────────────────────────────────────────
func get_market_price(visits: int) -> int:
	var multiplier = 1.0 + (visits * 0.10)
	if "cupide" in PlayerData.traits:
		multiplier *= 2.0
	return int(base_price * multiplier)

func is_usable() -> bool:
	return scroll_type == "active" and PlayerData.current_mana >= mana_cost

func get_tooltip() -> String:
	var lines = []
	lines.append("[b]" + scroll_name + "[/b]")
	lines.append(description)
	if scroll_type == "active":
		lines.append("Coût mana : " + str(mana_cost))
		if d20_high_effect != "":
			lines.append("D20 ≥ " + str(d20_high_threshold) + " → " + d20_high_effect)
		if d20_low_effect != "":
			lines.append("D20 ≤ " + str(d20_low_threshold) + " → " + d20_low_effect)
	else:
		lines.append("Passif : " + passive_type + " +" + str(value))
	return "\n".join(lines)
