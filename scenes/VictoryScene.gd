extends Node

@onready var stats_label : Label = $VBox/StatsLabel
@onready var btn_infinite : Button = $VBox/BtnInfinite
@onready var btn_menu    : Button = $VBox/BtnMenu

func _ready() -> void:
	stats_label.text = "Niveau atteint : %d\nOr total : %d" % [
		PlayerData.level, PlayerData.gold
	]
	SaveManager.on_run_ended(100, PlayerData.gold)
	AchievementSystem.check_victory(PlayerData.player_class, PlayerData.traits)
	btn_infinite.visible = SaveManager.infinite_run_unlocked

func _on_btn_infinite_pressed() -> void:
	GameManager.max_waves = 999999
	GameManager.go_to_map()

func _on_btn_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MetaProgressionScene.tscn")
