extends Node
# ─────────────────────────────────────────
#  AchievementsScene.gd
#  Affiche tous les succès (débloqués et verrouillés).
# ─────────────────────────────────────────

@onready var title_label    : Label         = $VBox/TitleLabel
@onready var progress_label : Label         = $VBox/ProgressLabel
@onready var scroll_container: ScrollContainer = $VBox/ScrollContainer
@onready var list_panel     : VBoxContainer = $VBox/ScrollContainer/ListPanel
@onready var back_btn       : Button        = $VBox/BackBtn

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	_build_list()

func _build_list() -> void:
	var all = AchievementSystem.get_all_for_display()
	var unlocked_count = all.filter(func(a): return a["unlocked"]).size()
	title_label.text    = "🏅 Succès"
	progress_label.text = "%d / %d débloqués" % [unlocked_count, all.size()]

	for ach in all:
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 50)

		var icon_lbl = Label.new()
		icon_lbl.text = ach["icon"]
		icon_lbl.custom_minimum_size = Vector2(40, 0)

		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl = Label.new()
		name_lbl.text = ach["name"]
		if ach["unlocked"]:
			name_lbl.add_theme_color_override("font_color", Color("#c8a96e"))
		else:
			name_lbl.add_theme_color_override("font_color", Color("#555566"))

		var desc_lbl = Label.new()
		desc_lbl.text = ach["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color("#7a7060"))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD

		var status_lbl = Label.new()
		status_lbl.text = "✅" if ach["unlocked"] else "🔒"
		status_lbl.custom_minimum_size = Vector2(30, 0)

		text_vbox.add_child(name_lbl)
		text_vbox.add_child(desc_lbl)
		hbox.add_child(icon_lbl)
		hbox.add_child(text_vbox)
		hbox.add_child(status_lbl)

		var sep = HSeparator.new()
		list_panel.add_child(hbox)
		list_panel.add_child(sep)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenuScene.tscn")
