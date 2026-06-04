extends Node

enum GameState {
	MAIN_MENU, CLASS_SELECT, TRAIT_SELECT, MAP,
	COMBAT, MARKET, EVENT, GAME_OVER, VICTORY, INFINITE_RUN
}

var current_state: GameState = GameState.MAIN_MENU
var current_wave: int = 0
var max_waves: int = 100
var pending_node_type: String = ""
var pending_enemy_data = null
var previous_scene: String = "map"

const SCENES = {
	"main_menu":    "res://scenes/MainMenuScene.tscn",
	"class_select": "res://scenes/ClassSelectScene.tscn",
	"trait_select": "res://scenes/TraitSelectScene.tscn",
	"map":          "res://scenes/MapScene.tscn",
	"combat":       "res://scenes/CombatScene.tscn",
	"market":       "res://scenes/MarketScene.tscn",
	"event":        "res://scenes/EventScene.tscn",
	"game_over":    "res://scenes/GameOverScene.tscn",
	"victory":      "res://scenes/VictoryScene.tscn",
	"meta":         "res://scenes/MetaProgressionScene.tscn",
	"summary": "res://scenes/RunSummaryScene.tscn",
}

func go_to_scene(scene_key: String) -> void:
	if scene_key in SCENES:
		get_tree().change_scene_to_file(SCENES[scene_key])
	else:
		push_error("GameManager: scène inconnue → " + scene_key)

func start_new_run() -> void:
	PlayerData.reset_for_new_run()
	RunManager.reset_for_new_run()
	current_wave = 0
	current_state = GameState.CLASS_SELECT
	go_to_scene("class_select")

func go_to_map() -> void:
	current_state = GameState.MAP
	go_to_scene("map")

func enter_node(node_type: String, enemy_data = null) -> void:
	pending_node_type  = node_type
	pending_enemy_data = enemy_data   # Dictionary depuis RunManager ou null
	match node_type:
		"combat", "elite", "boss":
			current_state = GameState.COMBAT
			go_to_scene("combat")
		"market":
			current_wave += 1
			RunManager.on_wave_completed(current_wave)
			current_state = GameState.MARKET
			go_to_scene("market")
		"event":
			current_wave += 1
			RunManager.on_wave_completed(current_wave)
			current_state = GameState.EVENT
			go_to_scene("event")
		"sauna":
			current_wave += 1
			RunManager.on_wave_completed(current_wave)
			var heal_amount = int(PlayerData.max_hp * 0.25)
			PlayerData.heal(heal_amount)
			Notifier.heal_notif(heal_amount)
			go_to_map()
		"treasure":
			current_wave += 1
			RunManager.on_wave_completed(current_wave)
			LootSystem.generate_treasure_loot()
			go_to_map()

func on_combat_won() -> void:
	current_wave += 1
	RunManager.on_wave_completed(current_wave)
	if current_wave >= max_waves:
		current_state = GameState.VICTORY
		go_to_scene("victory")
		return
	go_to_map()

func on_player_death() -> void:
	if PlayerData.has_revive_item:
		PlayerData.has_revive_item = false
		PlayerData.heal_percent(0.30)
		Notifier.heal_notif(int(PlayerData.max_hp * 0.30))
		return
	SaveManager.on_run_ended(current_wave, PlayerData.gold)
	pending_node_type = "game_over"
	get_tree().change_scene_to_file("res://scenes/RunSummaryScene.tscn")

func on_combat_restart_requested() -> bool:
	if PlayerData.has_restart_combat_item:
		PlayerData.has_restart_combat_item = false
		return true
	return false

func is_boss_wave() -> bool:
	return current_wave > 0 and current_wave % 10 == 0

func is_market_wave() -> bool:
	return current_wave > 0 and current_wave % 5 == 0

func get_difficulty_multiplier() -> float:
	var tier = int(current_wave / 10.0)
	return 1.0 + (tier * 0.15)
