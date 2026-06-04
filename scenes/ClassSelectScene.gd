extends Node
# ─────────────────────────────────────────
#  ClassSelectScene v3
#  Sélection de classe avec stats détaillées et choix de trait.
# ─────────────────────────────────────────

@onready var title_label   : Label         = $VBox/TitleLabel
@onready var class_panel   : GridContainer = $VBox/ClassPanel
@onready var desc_label    : RichTextLabel = $VBox/DescLabel
@onready var trait_panel   : VBoxContainer = $VBox/TraitPanel
@onready var trait_title   : Label         = $VBox/TraitPanel/TraitTitle
@onready var traits_grid   : GridContainer = $VBox/TraitPanel/TraitsGrid
@onready var btn_confirm   : Button        = $VBox/BtnConfirm
@onready var btn_back      : Button        = $VBox/BtnBack

# Stats de base civil (référence)
const BASE = {"pv":100,"att":30,"def":15,"cha":0.05,"prec":0.80,"esq":0.02,"mana":10}

# Données des classes : stats calculées depuis la base
const CLASSES = [
	{"id":"civil","icon":"🧑","label":"Civil",
	 "pv":100,"att":30,"def":15,"cha":5,"prec":80,"esq":2,"mana":10,
	 "desc":""},
	{"id":"guerrier","icon":"⚔️","label":"Guerrier",
	 "pv":125,"att":37.5,"def":18.75,"cha":0,"prec":70,"esq":2,"mana":10,
	 "desc":"[color=#50a050]+25% ATT  +25% DEF  +25% PV[/color]\n[color=#c84040]-5% CHA  -10% PREC[/color]"},
	{"id":"voleur","icon":"🗡️","label":"Voleur",
	 "pv":75,"att":37.5,"def":11.25,"cha":5,"prec":80,"esq":10,"mana":10,
	 "desc":"[color=#50a050]+25% ATT  +8% ESQ[/color]\n[color=#c84040]-25% DEF  -25% PV[/color]"},
	{"id":"mage","icon":"🧙","label":"Mage",
	 "pv":75,"att":30,"def":11.25,"cha":5,"prec":90,"esq":2,"mana":20,
	 "desc":"[color=#50a050]+10 MANA  +25 ATT sur parchemins actifs[/color]\n[color=#c84040]-25% DEF  -25% PV[/color]"},
	{"id":"chanceux","icon":"🍀","label":"Chanceux",
	 "pv":90,"att":27,"def":13.5,"cha":10,"prec":80,"esq":2,"mana":10,
	 "desc":"[color=#50a050]+5% CHA[/color]\n[color=#c84040]-10% PV  -10% ATT  -10% DEF[/color]"},
	{"id":"erudit","icon":"🎓","label":"Érudit",
	 "pv":75,"att":30,"def":15,"cha":5,"prec":90,"esq":2,"mana":10,
	 "desc":"[color=#50a050]+50% XP gagné[/color]\n[color=#c84040]-25% PV[/color]"},
	{"id":"archer","icon":"🏹","label":"Archer",
	 "pv":100,"att":30,"def":15,"cha":5,"prec":100,"esq":2,"mana":10,
	 "desc":"[color=#50a050]+20% PREC[/color]\n[color=#c84040]+25% de subir un statut[/color]"},
	{"id":"berserker","icon":"🩸","label":"Berserker",
	 "pv":75,"att":52.5,"def":11.25,"cha":5,"prec":80,"esq":2,"mana":10,
	 "desc":"[color=#50a050]+75% ATT[/color]\n[color=#c84040]-25% DEF  -25% PV[/color]"},
	{"id":"vampire","icon":"🧛","label":"Vampire",
	 "pv":100,"att":30,"def":15,"cha":5,"prec":80,"esq":0,"mana":10,
	 "desc":"[color=#50a050]Vole 10% des dégâts en PV[/color]\n[color=#c84040]0% ESQ  +25% de subir un statut[/color]"},
]

const TRAITS = [
	{"id":"berserker","label":"🩸 Berserker", "desc":"+50% ATT / -25% PV / -50% DEF"},
	{"id":"beni",     "label":"🍀 Béni",       "desc":"+15% CHA / Événements 2x punitifs"},
	{"id":"traqueur", "label":"👁️ Traqueur",  "desc":"+5% PREC / Duos +50% fréquents"},
	{"id":"fantome",  "label":"🌀 Fantôme",    "desc":"+13% ESQ / -40% PV max"},
	{"id":"frenesie", "label":"⚡ Frénésie",   "desc":"2 actions/tour / -50% PV max"},
	{"id":"cupide",   "label":"💎 Cupide",      "desc":"+100% pièces / Inflation sévère"},
	{"id":"chaotique","label":"🎲 Chaotique",  "desc":"D20→D30 / 1-5 = fumble"},
	{"id":"maudit",   "label":"💀 Maudit",      "desc":"Items rang+ / 1 item détruit/10 vagues"},
]

var selected_class: Dictionary = {}
var selected_trait: String = ""
var _trait_buttons: Array = []

func _ready() -> void:
	title_label.text    = "⚔️  Choisis ta classe"
	desc_label.visible  = false
	trait_panel.visible = false
	btn_confirm.visible = false
	btn_confirm.pressed.connect(_on_confirm)
	btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn"))

	# Génère les boutons de classe
	for c in CLASSES:
		var btn = Button.new()
		btn.text = "%s %s" % [c["icon"], c["label"]]
		btn.custom_minimum_size = Vector2(150, 48)
		btn.pressed.connect(_on_class_selected.bind(c))
		class_panel.add_child(btn)

func _on_class_selected(c: Dictionary) -> void:
	selected_class  = c
	selected_trait  = ""
	btn_confirm.visible = false
	desc_label.visible  = true

	# Stats formatées dans l'ordre demandé
	var stats = "PV [b]%d[/b]   ATT [b]%d[/b]   DEF [b]%d[/b]   CHA [b]%d%%[/b]   PREC [b]%d%%[/b]   ESQ [b]%d%%[/b]   MANA [b]%d[/b]" % [
		c["pv"], c["att"], c["def"], c["cha"], c["prec"], c["esq"], c["mana"]
	]
	var txt = "[b]%s %s[/b]\n%s\n" % [c["icon"], c["label"], stats]
	if c["desc"] != "":
		txt += c["desc"]
	desc_label.parse_bbcode(txt)

	# Affiche le choix de trait
	trait_panel.visible = true
	trait_title.text    = "Choisis ton trait de départ :"
	# Nettoie les anciens boutons
	for btn in _trait_buttons:
		btn.queue_free()
	_trait_buttons.clear()

	var available = TRAITS.filter(func(t): return not (t["id"] in PlayerData.traits))
	for t in available:
		var btn = Button.new()
		btn.text = "%s\n%s" % [t["label"], t["desc"]]
		btn.custom_minimum_size = Vector2(180, 55)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.toggle_mode = true
		btn.pressed.connect(_on_trait_selected.bind(t["id"], btn))
		traits_grid.add_child(btn)
		_trait_buttons.append(btn)

func _on_trait_selected(trait_id: String, pressed_btn: Button) -> void:
	selected_trait = trait_id
	# Désélectionne les autres
	for btn in _trait_buttons:
		btn.button_pressed = (btn == pressed_btn)
	btn_confirm.visible = not selected_class.is_empty()

func _on_confirm() -> void:
	if selected_class.is_empty():
		return
	PlayerData.apply_class(selected_class["id"])
	if selected_trait != "":
		PlayerData.add_trait(selected_trait)
	SaveManager.apply_meta_bonuses()
	AchievementSystem.reset_run_tracking()
	GameManager.current_state = GameManager.GameState.MAP
	GameManager.go_to_scene("map")
