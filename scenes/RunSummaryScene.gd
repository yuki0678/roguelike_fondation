extends Node

@onready var title_label    : Label         = $VBox/TitleLabel
@onready var wave_label     : Label         = $VBox/WaveLabel
@onready var class_label    : Label         = $VBox/ClassLabel
@onready var stats_label    : RichTextLabel = $VBox/StatsLabel
@onready var highlight_label: Label         = $VBox/HighlightLabel
@onready var btn_continue   : Button        = $VBox/BtnContinue

func _ready() -> void:
	btn_continue.pressed.connect(_on_continue)
	RunStats.update_wave(GameManager.current_wave)
	_build_ui()

func _build_ui() -> void:
	var s       = RunStats.get_summary()
	var victory = GameManager.pending_node_type == "victory"

	title_label.text = "🏆 VICTOIRE !" if victory else "💀 FIN DE RUN"
	wave_label.text  = "Vague atteinte : %d / %d" % [GameManager.current_wave, GameManager.max_waves]
	class_label.text = "%s  •  Niveau %d" % [PlayerData.player_class.capitalize(), PlayerData.level]

	var txt = ""
	txt += "⚔️  Dégâts infligés    [b]%d[/b]\n"  % s["damage_dealt"]
	txt += "💔  Dégâts reçus       [b]%d[/b]\n"  % s["damage_received"]
	txt += "💀  Ennemis tués        [b]%d[/b]"   % s["enemies_killed"]
	if s["bosses_killed"] > 0:
		txt += "  (dont [b]%d[/b] boss)" % s["bosses_killed"]
	txt += "\n"
	txt += "🔮  Sorts utilisés      [b]%d[/b]\n"  % s["scrolls_used"]
	txt += "⭐  Critiques           [b]%d[/b]\n"  % s["criticals"]
	txt += "💀  Échecs critiques    [b]%d[/b]\n"  % s["fumbles"]
	txt += "💚  Soins reçus         [b]%d PV[/b]\n" % s["heals_received"]
	txt += "💰  Or gagné            [b]%d[/b]\n"  % s["gold_earned"]
	txt += "🛒  Items achetés       [b]%d[/b]\n"  % s["items_bought"]
	txt += "⏱️  Tours survécus      [b]%d[/b]\n"  % s["turns_survived"]
	if not PlayerData.traits.is_empty():
		txt += "✨  Traits : [b]" + "  •  ".join(PlayerData.traits) + "[/b]\n"
	stats_label.parse_bbcode(txt)

	if s["best_damage"] > 0:
		highlight_label.text = "💥 Meilleur coup : %d dégâts (%s)" % [s["best_damage"], s["best_damage_source"]]
	else:
		highlight_label.text = ""

func _on_continue() -> void:
	if GameManager.pending_node_type == "victory":
		get_tree().change_scene_to_file("res://scenes/VictoryScene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MetaProgressionScene.tscn")
