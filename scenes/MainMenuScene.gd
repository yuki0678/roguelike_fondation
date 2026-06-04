extends Node

@onready var btn_play         : Button = $VBox/BtnPlay
@onready var btn_stats        : Button = $VBox/BtnStats
@onready var btn_achievements : Button = $VBox/BtnAchievements
@onready var btn_quit         : Button = $VBox/BtnQuit
@onready var best_label       : Label  = $VBox/BestLabel
@onready var version_label    : Label  = $VBox/VersionLabel

func _ready() -> void:
	best_label.text    = "Meilleure vague : %d / 100" % SaveManager.best_wave_reached
	version_label.text = "v0.1 — Prototype"
	btn_play.pressed.connect(func(): GameManager.start_new_run())
	btn_stats.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MetaProgressionScene.tscn"))
	btn_achievements.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/AchievementsScene.tscn"))
	btn_quit.pressed.connect(func(): get_tree().quit())
