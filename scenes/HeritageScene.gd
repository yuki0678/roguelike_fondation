extends Node
# ─────────────────────────────────────────
#  HeritageScene.gd
#  Affiché en fin de run (Game Over ou Victoire).
#  Le joueur choisit 1 item de bas rang à conserver.
# ─────────────────────────────────────────

@onready var title_label    : Label         = $VBox/TitleLabel
@onready var info_label     : Label         = $VBox/InfoLabel
@onready var items_panel    : VBoxContainer = $VBox/ItemsPanel
@onready var skip_btn       : Button        = $VBox/SkipBtn
@onready var instability_label : Label      = $VBox/InstabilityLabel

# Items héritables = communs et rares uniquement
var heritable_items: Array = []

func _ready() -> void:
	title_label.text = "🏺 Héritage de Run"
	_build_item_list()

	if SaveManager.heritage_item != null:
		var inst = SaveManager.heritage_instability
		if inst > 0:
			instability_label.text = "⚠️ Instabilité actuelle : %d (effets négatifs possibles au départ)" % inst
		else:
			instability_label.text = ""
	else:
		instability_label.text = ""

	skip_btn.pressed.connect(_on_skip_pressed)

func _build_item_list() -> void:
	# Collecte tous les items communs/rares de l'inventaire + équipés
	var all_items = PlayerData.inventory.duplicate()
	# On ne propose que ceux qui ont une meta item_name (créés via MarketScene)
	heritable_items = []
	for item in all_items:
		if item is Object and item.has_meta("item_name"):
			heritable_items.append(item)

	if heritable_items.is_empty():
		info_label.text = "Aucun item héritable dans ton inventaire."
		skip_btn.text   = "➡️ Continuer sans héritage"
		return

	info_label.text = "Choisis 1 item à conserver pour ta prochaine run :"

	for item in heritable_items:
		var btn = Button.new()
		var name_txt = item.get_meta("item_name", "Item")
		var atk  = item.get_meta("attack_bonus", 0)
		var def  = item.get_meta("defense_bonus", 0)
		btn.text = "%s   ATT+%d  DEF+%d" % [name_txt, atk, def]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.pressed.connect(_on_item_chosen.bind(item))
		items_panel.add_child(btn)

func _on_item_chosen(item: Object) -> void:
	SaveManager.set_heritage_item(item)
	_go_next()

func _on_skip_pressed() -> void:
	_go_next()

func _go_next() -> void:
	# Après le choix d'héritage → écran meta-progression / game over
	var destination = GameManager.pending_node_type  # réutilisé comme flag
	if destination == "victory":
		get_tree().change_scene_to_file("res://scenes/VictoryScene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/GameOverScene.tscn")
