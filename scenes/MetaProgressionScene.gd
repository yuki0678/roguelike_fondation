extends Node
# ─────────────────────────────────────────
#  MetaProgressionScene.gd
#  Upgrades permanents entre les runs, achetés avec l'or accumulé.
# ─────────────────────────────────────────

@onready var title_label  : Label         = $VBox/TitleLabel
@onready var gold_label   : Label         = $VBox/GoldLabel
@onready var best_label   : Label         = $VBox/BestLabel
@onready var runs_label   : Label         = $VBox/RunsLabel
@onready var upgrades_panel: VBoxContainer = $VBox/UpgradesPanel
@onready var continue_btn : Button        = $VBox/ContinueBtn
@onready var log_label    : Label         = $VBox/LogLabel

const UPGRADES = [
	{"key": "max_hp_bonus",   "label": "❤️ PV max",          "desc": "+5 PV max par niveau",        "icon": "❤️"},
	{"key": "attack_bonus",   "label": "⚔️ Attaque",         "desc": "+2 Attaque par niveau",        "icon": "⚔️"},
	{"key": "defense_bonus",  "label": "🛡️ Défense",         "desc": "+1 Défense par niveau",        "icon": "🛡️"},
	{"key": "start_gold",     "label": "💰 Or de départ",     "desc": "+10 or au début de chaque run","icon": "💰"},
	{"key": "xp_multiplier",  "label": "⭐ XP Bonus",         "desc": "+10% XP par niveau",           "icon": "⭐"},
]

var upgrade_buttons: Array = []

func _ready() -> void:
	title_label.text = "🏆 Meta-Progression"
	gold_label.text  = "💰 Or disponible : %d" % PlayerData.gold
	best_label.text  = "Meilleure vague : %d / %d" % [SaveManager.best_wave_reached, GameManager.max_waves]
	runs_label.text  = "Runs complétées : %d" % SaveManager.runs_completed
	continue_btn.pressed.connect(_on_continue_pressed)
	_build_upgrades()
	var btn_back = Button.new()
	btn_back.text = "← Menu Principal"
	btn_back.custom_minimum_size = Vector2(0, 44)
	btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn"))
	$VBox.add_child(btn_back)

func _build_upgrades() -> void:
	for child in upgrades_panel.get_children():
		child.queue_free()
	upgrade_buttons.clear()

	for upg in UPGRADES:
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 50)

		var info = Label.new()
		var current_level = SaveManager.meta_upgrades.get(upg["key"], 0)
		var cost = SaveManager.get_upgrade_cost(upg["key"])
		# Un seul emoji + label
		info.text = "%s  Niv.%d  —  %s" % [upg["icon"], current_level, upg["desc"]]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.autowrap_mode = TextServer.AUTOWRAP_WORD

		var btn = Button.new()
		btn.text = "💰 %d" % cost
		btn.custom_minimum_size = Vector2(100, 0)
		btn.disabled = PlayerData.gold < cost
		btn.pressed.connect(_on_upgrade_bought.bind(upg["key"]))

		hbox.add_child(info)
		hbox.add_child(btn)
		upgrades_panel.add_child(hbox)
		upgrade_buttons.append({"btn": btn, "key": upg["key"]})

func _on_upgrade_bought(key: String) -> void:
	if SaveManager.buy_upgrade(key):
		var cost = SaveManager.get_upgrade_cost(key)
		log_label.text = "✅ Upgrade acheté ! Or restant : %d" % PlayerData.gold
		gold_label.text = "💰 Or disponible : %d" % PlayerData.gold
		# Rebuild pour mettre à jour les coûts
		_build_upgrades()
	else:
		log_label.text = "❌ Pas assez d'or !"

func _on_continue_pressed() -> void:
	GameManager.start_new_run()
