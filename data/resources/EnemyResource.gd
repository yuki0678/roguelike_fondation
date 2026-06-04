extends Resource
class_name EnemyResource

# ─────────────────────────────────────────
#  EnemyResource
#  Définit un ennemi. Chaque fichier .tres = un type d'ennemi.
# ─────────────────────────────────────────

# --- Identité ---
@export var enemy_name: String = "Ennemi"
@export var description: String = ""
@export_enum("normal", "elite", "boss") var enemy_tier: String = "normal"

# --- Stats de base ---
@export var max_hp: int = 50
@export var attack: int = 10
@export var defense: int = 5
@export var precision: float = 0.70
@export var evasion: float = 0.05
@export var xp_reward: int = 20
@export var gold_reward_min: int = 5
@export var gold_reward_max: int = 15

# --- Comportement ---
# Actions possibles de l'ennemi (la logique est dans EnemyAI)
@export var can_attack: bool = true
@export var can_defend: bool = false
@export var can_use_status: bool = false

# Statuts que l'ennemi peut infliger
@export var possible_statuses: Array[String] = []
# ex: ["burn", "poison", "bleed"]

@export var status_chance: float = 0.20    # chance d'infliger un statut

# --- Loot ---
@export var loot_table_id: String = "normal"
# Référence à une entrée dans LootDatabase

# --- Apparence (texte pour l'instant) ---
@export var display_text: String = "[ENNEMI]"   # remplacé par sprite plus tard
@export var flavor_text: String = ""            # description narrative

# ─────────────────────────────────────────
#  SCALING DE DIFFICULTÉ
# ─────────────────────────────────────────
func get_scaled_stats(difficulty_multiplier: float) -> Dictionary:
	return {
		"hp":      int(max_hp * difficulty_multiplier),
		"attack":  int(attack * difficulty_multiplier),
		"defense": int(defense * difficulty_multiplier),
	}
