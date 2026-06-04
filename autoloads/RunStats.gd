extends Node
# ─────────────────────────────────────────
#  RunStats — Singleton (Autoload)
#  Suit les statistiques de la run en cours.
# ─────────────────────────────────────────

var damage_dealt:     int = 0
var damage_received:  int = 0
var enemies_killed:   int = 0
var bosses_killed:    int = 0
var scrolls_used:     int = 0
var criticals:        int = 0
var fumbles:          int = 0
var statuses_applied: int = 0
var gold_earned:      int = 0
var items_bought:     int = 0
var best_damage:      int = 0
var best_damage_source: String = ""
var highest_wave:     int = 0
var turns_survived:   int = 0
var heals_received:   int = 0

func reset() -> void:
	damage_dealt     = 0
	damage_received  = 0
	enemies_killed   = 0
	bosses_killed    = 0
	scrolls_used     = 0
	criticals        = 0
	fumbles          = 0
	statuses_applied = 0
	gold_earned      = 0
	items_bought     = 0
	best_damage      = 0
	best_damage_source = ""
	highest_wave     = 0
	turns_survived   = 0
	heals_received   = 0

func record_damage(amount: int, source: String = "Attaque") -> void:
	damage_dealt += amount
	if amount > best_damage:
		best_damage = amount
		best_damage_source = source

func record_hit_received(amount: int) -> void:
	damage_received += amount

func record_kill(tier: String) -> void:
	enemies_killed += 1
	if tier == "boss":
		bosses_killed += 1

func record_scroll_used() -> void:
	scrolls_used += 1

func record_critical() -> void:
	criticals += 1

func record_fumble() -> void:
	fumbles += 1

func record_status() -> void:
	statuses_applied += 1

func record_gold(amount: int) -> void:
	gold_earned += amount

func record_item_bought() -> void:
	items_bought += 1

func record_heal(amount: int) -> void:
	heals_received += amount

func record_turn() -> void:
	turns_survived += 1

func update_wave(wave: int) -> void:
	if wave > highest_wave:
		highest_wave = wave

func get_summary() -> Dictionary:
	return {
		"damage_dealt":      damage_dealt,
		"damage_received":   damage_received,
		"enemies_killed":    enemies_killed,
		"bosses_killed":     bosses_killed,
		"scrolls_used":      scrolls_used,
		"criticals":         criticals,
		"fumbles":           fumbles,
		"statuses_applied":  statuses_applied,
		"gold_earned":       gold_earned,
		"items_bought":      items_bought,
		"best_damage":       best_damage,
		"best_damage_source": best_damage_source,
		"highest_wave":      highest_wave,
		"turns_survived":    turns_survived,
		"heals_received":    heals_received,
	}
