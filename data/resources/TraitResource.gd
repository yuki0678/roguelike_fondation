extends Resource
class_name TraitResource

# ─────────────────────────────────────────
#  TraitResource
#  Définit un trait de run.
# ─────────────────────────────────────────

@export var trait_id: String = ""
@export var trait_name: String = "Trait inconnu"
@export var bonus_text: String = ""    # affiché dans l'UI
@export var malus_text: String = ""    # affiché dans l'UI
@export var rarity: String = "mythic"  # les traits sont toujours Mythique au marché
@export var base_price: int = 80

func get_market_price(visits: int) -> int:
	var multiplier = 1.0 + (visits * 0.10)
	if "cupide" in PlayerData.traits:
		multiplier *= 2.0
	return int(base_price * multiplier)
