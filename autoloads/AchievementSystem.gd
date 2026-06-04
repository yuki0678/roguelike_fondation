extends Node
# ─────────────────────────────────────────
#  AchievementSystem — Singleton (Autoload)
#  Gère les succès débloqués par le joueur.
# ─────────────────────────────────────────

signal achievement_unlocked(achievement: Dictionary)

# Structure : { id, name, desc, icon, unlocked, secret }
const ACHIEVEMENTS = [
	# ── Progression ──
	{"id": "first_blood",    "name": "Premier Sang",      "icon": "⚔️",  "desc": "Terminer ton premier combat.",                    "secret": false},
	{"id": "wave_10",        "name": "Survivant",          "icon": "🌊",  "desc": "Atteindre la vague 10.",                          "secret": false},
	{"id": "wave_25",        "name": "Guerrier Aguerri",   "icon": "🛡️", "desc": "Atteindre la vague 25.",                          "secret": false},
	{"id": "wave_50",        "name": "Mi-Chemin",          "icon": "🏔️", "desc": "Atteindre la vague 50.",                          "secret": false},
	{"id": "wave_100",       "name": "Le Sans-Nom Vaincu", "icon": "🏆",  "desc": "Terminer une run complète (vague 100).",          "secret": false},
	# ── Combat ──
	{"id": "first_critical", "name": "Coup de Chance",     "icon": "⭐",  "desc": "Réussir ton premier critique.",                   "secret": false},
	{"id": "crit_10",        "name": "Chanceux Né",        "icon": "🎯",  "desc": "Réussir 10 critiques en une run.",                "secret": false},
	{"id": "boss_killer",    "name": "Chasseur de Boss",   "icon": "👑",  "desc": "Tuer ton premier boss.",                          "secret": false},
	{"id": "boss_3",         "name": "Pourfendeur",        "icon": "💀",  "desc": "Tuer 3 boss en une run.",                        "secret": false},
	{"id": "no_damage",      "name": "Intouchable",        "icon": "💨",  "desc": "Finir un combat sans prendre de dégâts.",         "secret": true},
	{"id": "fumble_3",       "name": "Maladroit",          "icon": "🤦", "desc": "Faire 3 échecs critiques en une run.",            "secret": false},
	{"id": "kill_50",        "name": "Bain de Sang",       "icon": "🩸",  "desc": "Tuer 50 ennemis en une run.",                    "secret": false},
	# ── Build ──
	{"id": "two_traits",     "name": "Double Malédiction", "icon": "✨",  "desc": "Avoir 2 traits actifs simultanément.",            "secret": false},
	{"id": "sword_shield",   "name": "Paladin",            "icon": "⚔️🛡️","desc": "Équiper une épée ET un bouclier.",                "secret": false},
	{"id": "scroll_master",  "name": "Archiviste",         "icon": "📜",  "desc": "Équiper 2 sorts actifs en même temps.",          "secret": false},
	{"id": "use_scroll_10",  "name": "Lanceur de Sorts",   "icon": "🔮",  "desc": "Utiliser 10 parchemins en une run.",              "secret": false},
	# ── Classes ──
	{"id": "win_mage",       "name": "Archmage",           "icon": "🧙",  "desc": "Terminer une run avec le Mage.",                  "secret": false},
	{"id": "win_vampire",    "name": "Seigneur des Nuits", "icon": "🧛",  "desc": "Terminer une run avec le Vampire.",               "secret": false},
	{"id": "win_berserker",  "name": "Rage Pure",          "icon": "🩸",  "desc": "Terminer une run avec le Berserker.",             "secret": false},
	{"id": "all_classes",    "name": "Polyvalent",         "icon": "🎭",  "desc": "Terminer une run avec chaque classe.",            "secret": false},
	# ── Secrets ──
	{"id": "gold_hoarder",   "name": "Avare",              "icon": "💰",  "desc": "Avoir 500 or simultanément.",                    "secret": true},
	{"id": "death_door",     "name": "Au Bord du Gouffre", "icon": "💀",  "desc": "Survivre avec 1 PV.",                            "secret": true},
	{"id": "chaotic_win",    "name": "Le Chaos Règne",     "icon": "🎲",  "desc": "Terminer une run avec le trait Chaotique.",       "secret": true},
	{"id": "pacifist",       "name": "Pacifiste",          "icon": "🕊️", "desc": "Fuir 5 combats en une run (Téléportation).",      "secret": true},
]

var unlocked_ids: Array = []
var _run_unlocked: Array = []   # débloqués cette run (pour éviter les doublons)
var _classes_won: Array = []    # classes avec lesquelles on a gagné

func _ready() -> void:
	_load()
	achievement_unlocked.connect(_on_achievement_unlocked)

func try_unlock(id: String) -> void:
	if id in unlocked_ids:
		return
	for ach in ACHIEVEMENTS:
		if ach["id"] == id:
			unlocked_ids.append(id)
			_run_unlocked.append(id)
			emit_signal("achievement_unlocked", ach)
			_save()
			return

func _on_achievement_unlocked(ach: Dictionary) -> void:
	Notifier.show_notif("🏅 Succès : %s %s" % [ach["icon"], ach["name"]], Color("#FFD700"))

func is_unlocked(id: String) -> bool:
	return id in unlocked_ids

func reset_run_tracking() -> void:
	_run_unlocked.clear()

# ─── Vérifications automatiques ───────────────────────────────────────────────
func check_wave(wave: int) -> void:
	if wave >= 10:  try_unlock("wave_10")
	if wave >= 25:  try_unlock("wave_25")
	if wave >= 50:  try_unlock("wave_50")
	if wave >= 100: try_unlock("wave_100")

func check_combat_end(no_damage_taken: bool) -> void:
	try_unlock("first_blood")
	if no_damage_taken:
		try_unlock("no_damage")

func check_critical(total_crits: int) -> void:
	try_unlock("first_critical")
	if total_crits >= 10:
		try_unlock("crit_10")

func check_boss_kill(total_bosses: int) -> void:
	try_unlock("boss_killer")
	if total_bosses >= 3:
		try_unlock("boss_3")

func check_kills(total_kills: int) -> void:
	if total_kills >= 50:
		try_unlock("kill_50")

func check_fumbles(total_fumbles: int) -> void:
	if total_fumbles >= 3:
		try_unlock("fumble_3")

func check_scrolls_used(total: int) -> void:
	if total >= 10:
		try_unlock("use_scroll_10")

func check_traits(traits: Array) -> void:
	if traits.size() >= 2:
		try_unlock("two_traits")
	if "chaotique" in traits:
		pass  # vérifié à la victoire

func check_equipment() -> void:
	var has_sword  = PlayerData.equipped_weapon != null and PlayerData.equipped_weapon.get_meta("is_sword", false)
	var has_shield = PlayerData.equipped_armor  != null and PlayerData.equipped_armor.get_meta("is_shield", false)
	if has_sword and has_shield:
		try_unlock("sword_shield")
	if PlayerData.equipped_scroll_1 != null and PlayerData.equipped_scroll_2 != null:
		try_unlock("scroll_master")

func check_gold(gold: int) -> void:
	if gold >= 500:
		try_unlock("gold_hoarder")

func check_low_hp(hp: int) -> void:
	if hp <= 1:
		try_unlock("death_door")

func check_victory(player_class: String, traits: Array) -> void:
	check_wave(100)
	if player_class == "mage":     try_unlock("win_mage")
	if player_class == "vampire":  try_unlock("win_vampire")
	if player_class == "berserker":try_unlock("win_berserker")
	if "chaotique" in traits:      try_unlock("chaotic_win")
	if not _classes_won.has(player_class):
		_classes_won.append(player_class)
		_save()
	var all = ["civil","guerrier","voleur","mage","chanceux","erudit","archer","berserker","vampire"]
	if all.all(func(c): return _classes_won.has(c)):
		try_unlock("all_classes")

func check_flee_count(count: int) -> void:
	if count >= 5:
		try_unlock("pacifist")

# ─── Sauvegarde ───────────────────────────────────────────────────────────────
const SAVE_PATH = "user://achievements.json"

func _save() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify({
		"unlocked":      unlocked_ids,
		"classes_won":   _classes_won,
	}, "\t"))
	file.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null: return
	unlocked_ids  = data.get("unlocked", [])
	_classes_won  = data.get("classes_won", [])

# ─── Affichage (pour AchievementsScene) ──────────────────────────────────────
func get_all_for_display() -> Array:
	var result = []
	for ach in ACHIEVEMENTS:
		var entry = ach.duplicate()
		entry["unlocked"] = ach["id"] in unlocked_ids
		# Cache les secrets non débloqués
		if ach["secret"] and not entry["unlocked"]:
			entry["name"] = "???"
			entry["desc"] = "Secret — continue à jouer pour découvrir."
			entry["icon"] = "🔒"
		result.append(entry)
	return result
