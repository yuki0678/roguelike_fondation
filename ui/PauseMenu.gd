extends CanvasLayer
# ─────────────────────────────────────────
#  PauseMenu.gd
#  Overlay de pause accessible via Échap depuis n'importe quelle scène.
#  Ajouter ce nœud en enfant de chaque scène de jeu.
# ─────────────────────────────────────────

@onready var overlay      : ColorRect     = $Overlay
@onready var panel        : PanelContainer = $Panel
@onready var stats_label  : RichTextLabel = $Panel/VBox/StatsLabel
@onready var btn_resume   : Button        = $Panel/VBox/BtnResume
@onready var btn_inventory: Button        = $Panel/VBox/BtnInventory
@onready var btn_abandon  : Button        = $Panel/VBox/BtnAbandon

var _paused: bool = false

func _ready() -> void:
	panel.visible = false
	overlay.visible = false
	btn_resume.pressed.connect(_on_resume)
	btn_inventory.pressed.connect(_on_inventory)
	btn_abandon.pressed.connect(_on_abandon)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _paused:
			_on_resume()
		else:
			_pause()

func _pause() -> void:
	_paused = true
	get_tree().paused = true
	overlay.visible = true
	panel.visible   = true
	_refresh_stats()

func _on_resume() -> void:
	_paused = false
	get_tree().paused = false
	overlay.visible = false
	panel.visible   = false

func _on_inventory() -> void:
	_on_resume()
	# Détecte la scène actuelle pour pouvoir y revenir
	var current_scene = get_tree().current_scene.scene_file_path
	if "Market" in current_scene:
		GameManager.previous_scene = "market"
	elif "Combat" in current_scene:
		GameManager.previous_scene = "combat"
	else:
		GameManager.previous_scene = "map"
	get_tree().change_scene_to_file("res://scenes/InventoryScene.tscn")

func _on_abandon() -> void:
	_on_resume()
	GameManager.on_player_death()

func _refresh_stats() -> void:
	var txt  = "[b]— Pause —[/b]\n\n"
	txt += "[b]%s[/b]  Niv.[b]%d[/b]\n" % [PlayerData.player_class.capitalize(), PlayerData.level]
	txt += "❤️  %d / %d PV\n" % [PlayerData.current_hp, PlayerData.max_hp]
	txt += "💧  %d / %d Mana\n" % [PlayerData.current_mana, PlayerData.max_mana]
	txt += "💰  %d or\n\n" % PlayerData.gold
	txt += "⚔️  ATT  [b]%d[/b]     🛡️  DEF  [b]%d[/b]\n" % [PlayerData.get_effective_attack(), PlayerData.get_effective_defense()]
	txt += "🎯  PREC [b]%.0f%%[/b]   👟  ESQ  [b]%.0f%%[/b]\n\n" % [PlayerData.get_effective_precision() * 100, PlayerData.get_effective_evasion() * 100]
	txt += "🌊  Vague [b]%d / %d[/b]\n" % [GameManager.current_wave, GameManager.max_waves]
	if not PlayerData.traits.is_empty():
		txt += "✨  Traits : [b]" + "  •  ".join(PlayerData.traits) + "[/b]\n"
	var wpn = PlayerData.equipped_weapon
	var arm = PlayerData.equipped_armor
	txt += "\n⚔️  %s\n" % (wpn.get_meta("item_name", "—") if wpn else "—")
	txt += "🛡️  %s\n" % (arm.get_meta("item_name", "—") if arm else "—")
	var s1 = PlayerData.equipped_scroll_1
	var s2 = PlayerData.equipped_scroll_2
	if s1: txt += "🔮  %s\n" % s1.scroll_name
	if s2: txt += "🔮  %s\n" % s2.scroll_name
	stats_label.parse_bbcode(txt)
