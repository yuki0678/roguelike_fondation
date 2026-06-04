extends Node
# HeritageScene — redirige correctement selon victoire ou défaite

@onready var title_label       : Label         = $VBox/TitleLabel
@onready var info_label        : Label         = $VBox/InfoLabel
@onready var items_panel       : VBoxContainer = $VBox/ItemsPanel
@onready var skip_btn          : Button        = $VBox/SkipBtn
@onready var instability_label : Label         = $VBox/InstabilityLabel

var heritable_items: Array = []
var _is_victory: bool = false

func _ready() -> void:
	_is_victory = (GameManager.pending_node_type == "victory")
	title_label.text = "🏺 Héritage de Run"
	_build_item_list()
	if SaveManager.heritage_instability > 0:
		instability_label.text = "⚠️ Instabilité : %d" % SaveManager.heritage_instability
	else:
		instability_label.text = ""
	skip_btn.pressed.connect(_on_skip)

func _build_item_list() -> void:
	heritable_items = []
	for item in PlayerData.inventory:
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
		var atk = item.get_meta("attack_bonus", 0)
		var def = item.get_meta("defense_bonus", 0)
		btn.text = "%s   ATT+%d  DEF+%d" % [name_txt, atk, def]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.pressed.connect(_on_item_chosen.bind(item))
		items_panel.add_child(btn)

func _on_item_chosen(item: Object) -> void:
	SaveManager.set_heritage_item(item)
	_go_next()

func _on_skip() -> void:
	_go_next()

func _go_next() -> void:
	if _is_victory:
		get_tree().change_scene_to_file("res://scenes/VictoryScene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MetaProgressionScene.tscn")
