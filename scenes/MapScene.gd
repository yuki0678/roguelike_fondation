extends Node
# ─────────────────────────────────────────
#  MapScene.gd  v2
#  Affiche le chemin, les stats, l'historique et le choix de nœud.
# ─────────────────────────────────────────

@onready var wave_label     : Label         = $VBox/WaveLabel
@onready var progress_label : Label         = $VBox/ProgressLabel
@onready var stats_label    : RichTextLabel = $VBox/StatsLabel
@onready var history_label  : Label         = $VBox/HistoryLabel
@onready var choice_label   : Label         = $VBox/ChoiceLabel
@onready var btn_node_a     : Button        = $VBox/ChoicePanel/BtnNodeA
@onready var btn_node_b     : Button        = $VBox/ChoicePanel/BtnNodeB
@onready var tip_label      : Label         = $VBox/TipLabel

var choices: Array = []

const NODE_DESCRIPTIONS = {
	"combat":   {"icon": "⚔️",  "name": "Combat",        "desc": "Un ennemi vous attend. Victoire = loot + XP."},
	"elite":    {"icon": "💀",  "name": "Combat Élite",   "desc": "Ennemi puissant aux patterns imprévisibles. Meilleure récompense."},
	"boss":     {"icon": "👑",  "name": "BOSS",           "desc": "Boss de palier. Mécanique unique. Soyez prêt."},
	"market":   {"icon": "🏪",  "name": "Marché",         "desc": "3 items à acheter, sauna payant, trait mythique disponible."},
	"event":    {"icon": "🎲",  "name": "Événement",      "desc": "Question Q&A. Bonne réponse = bonus. Mauvaise = malus."},
	"sauna":    {"icon": "🛁",  "name": "Sauna",          "desc": "Restaure 25% de vos PV. Gratuit."},
	"treasure": {"icon": "🎁",  "name": "Trésor",         "desc": "Item gratuit aléatoire. Rareté variable."},
}

# ─────────────────────────────────────────
func _ready() -> void:
	$VBox/BtnInventory.pressed.connect(_on_inventory_pressed)
	if LootSystem.last_treasure_message != "":
		tip_label.text = LootSystem.last_treasure_message
		LootSystem.last_treasure_message = ""
	choices = RunManager.generate_path_choices(GameManager.current_wave + 1)
	btn_node_a.pressed.connect(_on_btn_node_a_pressed)
	btn_node_b.pressed.connect(_on_btn_node_b_pressed)
	_refresh_ui()

func _refresh_ui() -> void:
	var wave = GameManager.current_wave
	var max_w = GameManager.max_waves

	# Vague et progression
	wave_label.text = "Vague %d / %d" % [wave, max_w]
	var pct = int(float(wave) / float(max_w) * 100)
	progress_label.text = _make_progress_bar(wave, max_w) + "  %d%%" % pct

	# Stats joueur
	var hp_bar = _make_bar(PlayerData.current_hp, PlayerData.max_hp, 12, "❤️")
	var mp_bar = _make_bar(PlayerData.current_mana, PlayerData.max_mana, 8, "💧")
	var txt = "[b]%s[/b]  •  Niv.[b]%d[/b]  •  XP %d/%d\n" % [
		PlayerData.player_class.capitalize(),
		PlayerData.level,
		PlayerData.current_xp,
		PlayerData.xp_to_next_level
	]
	txt += "%s  %d/%d PV\n" % [hp_bar, PlayerData.current_hp, PlayerData.max_hp]
	txt += "%s  %d/%d Mana   💰 %d or\n" % [mp_bar, PlayerData.current_mana, PlayerData.max_mana, PlayerData.gold]
	txt += "ATT [b]%d[/b]   DEF [b]%d[/b]   PREC [b]%.0f%%[/b]   ESQ [b]%.0f%%[/b]\n" % [
		PlayerData.get_effective_attack(),
		PlayerData.get_effective_defense(),
		PlayerData.get_effective_precision() * 100,
		PlayerData.get_effective_evasion() * 100
	]
	if not PlayerData.traits.is_empty():
		txt += "Traits : [b]" + "  •  ".join(PlayerData.traits) + "[/b]\n"
	if PlayerData.active_statuses.size() > 0:
		var st = []
		for s in PlayerData.active_statuses:
			st.append(StatusSystem.get_status_label(s["type"]))
		txt += "Statuts : " + "  ".join(st) + "\n"
	stats_label.parse_bbcode(txt)

	# Historique des 8 derniers nœuds
	var hist = RunManager.path_history
	if hist.is_empty():
		history_label.text = "Chemin : (début de run)"
	else:
		var recent = hist.slice(max(0, hist.size() - 8))
		history_label.text = "Chemin : " + "  →  ".join(recent.map(func(v): return str(v)))

	# Choix
	choice_label.text = "— Choisis ton prochain nœud —"
	_update_choice_buttons()

func _update_choice_buttons() -> void:
	_set_node_button(btn_node_a, choices[0])
	_set_node_button(btn_node_b, choices[1])

func _set_node_button(btn: Button, node: Dictionary) -> void:
	var info = NODE_DESCRIPTIONS.get(node["type"], {"icon": "❓", "name": "Inconnu", "desc": ""})
	btn.text = "%s  %s\n%s" % [info["icon"], info["name"], info["desc"]]
	# Colore selon le danger
	match node["type"]:
		"boss":    btn.modulate = Color(1.0, 0.4, 0.4)
		"elite":   btn.modulate = Color(1.0, 0.7, 0.4)
		"market":  btn.modulate = Color(0.4, 1.0, 0.6)
		"sauna":   btn.modulate = Color(0.4, 0.8, 1.0)
		"treasure":btn.modulate = Color(1.0, 0.9, 0.3)
		_:         btn.modulate = Color(1.0, 1.0, 1.0)

func _on_btn_node_a_pressed() -> void: _enter_node(choices[0])
func _on_btn_node_b_pressed() -> void: _enter_node(choices[1])

func _enter_node(node: Dictionary) -> void:
	btn_node_a.disabled = true
	btn_node_b.disabled = true
	# Tip selon le nœud choisi
	var info = NODE_DESCRIPTIONS.get(node["type"], {"desc": ""})
	tip_label.text = info["desc"]
	GameManager.enter_node(node["type"], node.get("enemy_data", null))

# ─────────────────────────────────────────
#  UTILITAIRES VISUELS
# ─────────────────────────────────────────
func _make_progress_bar(current: int, maximum: int) -> String:
	var filled = int(float(current) / float(maximum) * 20)
	filled = clamp(filled, 0, 20)
	return "[" + "█".repeat(filled) + "░".repeat(20 - filled) + "]"

func _make_bar(current: int, maximum: int, size: int, _icon: String) -> String:
	if maximum <= 0:
		return "░".repeat(size)
	var filled = int(float(current) / float(maximum) * float(size))
	filled = clamp(filled, 0, size)
	return "█".repeat(filled) + "░".repeat(size - filled)

func _on_inventory_pressed() -> void:
	GameManager.previous_scene = "map"
	get_tree().change_scene_to_file("res://scenes/InventoryScene.tscn")
