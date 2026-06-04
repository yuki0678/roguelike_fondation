extends Node
# ─────────────────────────────────────────
#  EventScene.gd
#  Événement interactif : question Q&A avec bonus/malus.
# ─────────────────────────────────────────

@onready var wave_label    : Label         = $VBox/WaveLabel
@onready var question_label: Label         = $VBox/QuestionLabel
@onready var btn_a         : Button        = $VBox/ChoicesPanel/BtnA
@onready var btn_b         : Button        = $VBox/ChoicesPanel/BtnB
@onready var btn_c         : Button        = $VBox/ChoicesPanel/BtnC
@onready var btn_d         : Button        = $VBox/ChoicesPanel/BtnD
@onready var result_label  : Label         = $VBox/ResultLabel
@onready var reward_label  : Label         = $VBox/RewardLabel
@onready var continue_btn  : Button        = $VBox/ContinueBtn
@onready var stats_label   : Label         = $VBox/StatsLabel

var questions: Array = []
var current_question: Dictionary = {}
var answered: bool = false

func _ready() -> void:
	continue_btn.visible = false
	result_label.text    = ""
	reward_label.text    = ""
	_load_questions()
	_pick_question()
	_refresh_ui()
	btn_a.pressed.connect(_on_btn_a_pressed)
	btn_b.pressed.connect(_on_btn_b_pressed)
	btn_c.pressed.connect(_on_btn_c_pressed)
	btn_d.pressed.connect(_on_btn_d_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)

func _load_questions() -> void:
	var file = FileAccess.open("res://questions/questions.json", FileAccess.READ)
	if file == null:
		push_error("EventScene: impossible de lire questions.json")
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Array:
		questions = data

func _pick_question() -> void:
	if questions.is_empty():
		current_question = {
			"q": "Combien font 2 + 2 ?",
			"a": "4",
			"choices": ["3", "4", "5", "6"]
		}
	else:
		current_question = questions[randi() % questions.size()]

	wave_label.text    = "🎲 Événement  —  Vague %d" % GameManager.current_wave
	question_label.text = current_question["q"]

	var choices = current_question["choices"]
	btn_a.text = "A) " + choices[0]
	btn_b.text = "B) " + choices[1]
	btn_c.text = "C) " + choices[2]
	btn_d.text = "D) " + choices[3]

func _on_btn_a_pressed() -> void: _answer(current_question["choices"][0])
func _on_btn_b_pressed() -> void: _answer(current_question["choices"][1])
func _on_btn_c_pressed() -> void: _answer(current_question["choices"][2])
func _on_btn_d_pressed() -> void: _answer(current_question["choices"][3])

func _answer(choice: String) -> void:
	if answered:
		return
	answered = true
	btn_a.disabled = true
	btn_b.disabled = true
	btn_c.disabled = true
	btn_d.disabled = true

	var correct = choice == current_question["a"]
	var beni = "beni" in PlayerData.traits

	if correct:
		result_label.text = "✅ BONNE RÉPONSE !"
		_apply_reward(beni)
	else:
		result_label.text = "❌ Mauvaise réponse ! La bonne réponse était : " + current_question["a"]
		_apply_malus(beni)

	continue_btn.visible = true
	_refresh_ui()

func _apply_reward(beni: bool) -> void:
	var gold = 20
	var hp   = 10
	if beni:
		gold *= 2
		hp   *= 2
	PlayerData.gold += gold
	PlayerData.heal(hp)
	reward_label.text = "🎁 Récompense : +%d or, +%d PV" % [gold, hp]

func _apply_malus(beni: bool) -> void:
	var damage = 15
	var gold   = 10
	if beni:
		# 2x punitif seulement, pas de bonus
		damage *= 2
		gold   *= 2
	PlayerData.take_damage(damage)
	PlayerData.gold = max(0, PlayerData.gold - gold)
	reward_label.text = "💀 Malus : -%d PV, -%d or" % [damage, gold]

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

func _refresh_ui() -> void:
	stats_label.text = "❤️ %d/%d   💰 %d or" % [
		PlayerData.current_hp, PlayerData.max_hp, PlayerData.gold
	]
