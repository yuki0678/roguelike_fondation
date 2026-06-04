extends Node

# ─────────────────────────────────────────
#  SaveManager — Singleton
#  Gère la sauvegarde de la meta-progression (persiste entre les runs).
# ─────────────────────────────────────────

const SAVE_PATH = "user://save_data.json"

# ─── Meta-progression ───
var total_gold_earned: int = 0       # or total gagné sur toutes les runs
var meta_upgrades: Dictionary = {    # upgrades permanents achetés
	"max_hp_bonus":    0,
	"attack_bonus":    0,
	"defense_bonus":   0,
	"start_gold":      0,
	"xp_multiplier":   0,            # paliers de +10% XP
}
var runs_completed: int = 0
var best_wave_reached: int = 0
var infinite_run_unlocked: bool = false

# ─────────────────────────────────────────
#  CHARGEMENT
# ─────────────────────────────────────────
func _ready() -> void:
	load_data()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json_string = file.get_as_text()
	file.close()
	var data = JSON.parse_string(json_string)
	if data == null:
		return
	total_gold_earned      = data.get("total_gold_earned", 0)
	meta_upgrades          = data.get("meta_upgrades", meta_upgrades)
	runs_completed         = data.get("runs_completed", 0)
	best_wave_reached      = data.get("best_wave_reached", 0)
	infinite_run_unlocked  = data.get("infinite_run_unlocked", false)

# ─────────────────────────────────────────
#  SAUVEGARDE
# ─────────────────────────────────────────
func save_data() -> void:
	var data = {
		"total_gold_earned":     total_gold_earned,
		"meta_upgrades":         meta_upgrades,
		"runs_completed":        runs_completed,
		"best_wave_reached":     best_wave_reached,
		"infinite_run_unlocked": infinite_run_unlocked,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: impossible d'écrire le fichier de sauvegarde")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

# ─────────────────────────────────────────
#  FIN DE RUN
# ─────────────────────────────────────────
func on_run_ended(wave_reached: int, gold_earned: int) -> void:
	runs_completed += 1
	total_gold_earned += gold_earned
	if wave_reached > best_wave_reached:
		best_wave_reached = wave_reached
	if wave_reached >= 100:
		infinite_run_unlocked = true
	save_data()

# ─────────────────────────────────────────
#  META UPGRADES
# ─────────────────────────────────────────
func get_upgrade_cost(upgrade_key: String) -> int:
	var current_level = meta_upgrades.get(upgrade_key, 0)
	return 50 + (current_level * 30)   # coût croissant

func buy_upgrade(upgrade_key: String) -> bool:
	var cost = get_upgrade_cost(upgrade_key)
	if PlayerData.gold >= cost:
		PlayerData.gold -= cost
		meta_upgrades[upgrade_key] += 1
		save_data()
		return true
	return false

# Applique les bonus méta au début d'une run
func apply_meta_bonuses() -> void:
	PlayerData.max_hp    += meta_upgrades["max_hp_bonus"] * 5
	PlayerData.current_hp = PlayerData.max_hp
	PlayerData.attack    += meta_upgrades["attack_bonus"] * 2
	PlayerData.defense   += meta_upgrades["defense_bonus"] * 1
	PlayerData.gold      += meta_upgrades["start_gold"] * 10
