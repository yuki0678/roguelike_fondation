extends Node

@onready var wave_label  : Label = $VBox/WaveLabel
@onready var stats_label : Label = $VBox/StatsLabel
@onready var btn_retry   : Button = $VBox/BtnRetry
@onready var btn_menu    : Button = $VBox/BtnMenu

func _ready() -> void:
	wave_label.text  = "💀 Mort à la vague %d" % GameManager.current_wave
	stats_label.text = "Niveau atteint : %d\nOr gagné : %d" % [
		PlayerData.level, PlayerData.gold
	]
	SaveManager.on_run_ended(GameManager.current_wave, PlayerData.gold)

func _on_btn_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MetaProgressionScene.tscn")

func _on_btn_menu_pressed() -> void:
	GameManager.go_to_scene("main_menu")
