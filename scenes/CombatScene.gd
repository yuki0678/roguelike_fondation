extends Node
# ─────────────────────────────────────────
#  CombatScene.gd — CORRIGÉ
#  Fixes :
#  1. Guards is_inside_tree() sur tous les await
#  2. _resolve_player_turn : guard avant timer
#  3. _pick_loot level up : guard avant timer
#  4. _on_combat_victory : guard avant timer
#  5. _handle_scroll_result : guard avant timer flee
# ─────────────────────────────────────────

@onready var log_label       : RichTextLabel = $VBox/LogPanel/LogLabel
@onready var hp_label        : Label         = $VBox/StatsBar/HPLabel
@onready var mana_label      : Label         = $VBox/StatsBar/ManaLabel
@onready var xp_label        : Label         = $VBox/StatsBar/XPLabel
@onready var level_label     : Label         = $VBox/StatsBar/LevelLabel
@onready var enemy_label     : RichTextLabel = $VBox/EnemyPanel/EnemyLabel
@onready var status_label    : Label         = $VBox/StatsBar/StatusLabel
@onready var action_panel    : VBoxContainer = $VBox/ActionPanel
@onready var btn_attack      : Button        = $VBox/ActionPanel/BtnAttack
@onready var btn_defend      : Button        = $VBox/ActionPanel/BtnDefend
@onready var btn_attack_def  : Button        = $VBox/ActionPanel/BtnAttackDefend
@onready var btn_scroll1     : Button        = $VBox/ActionPanel/BtnScroll1
@onready var btn_scroll2     : Button        = $VBox/ActionPanel/BtnScroll2
@onready var btn_roll        : Button        = $VBox/ActionPanel/BtnRoll
@onready var loot_panel      : VBoxContainer = $VBox/LootPanel
@onready var loot_title      : Label         = $VBox/LootPanel/LootTitle
@onready var btn_loot1       : Button        = $VBox/LootPanel/BtnLoot1
@onready var btn_loot2       : Button        = $VBox/LootPanel/BtnLoot2
@onready var btn_loot3       : Button        = $VBox/LootPanel/BtnLoot3

var enemies: Array = []
var pending_action: String = ""
var defense_bonus_this_turn: int = 0
var shield_value: int = 0
var combat_over: bool = false
var last_roll: int = 0
var turn_counter: int = 0
var _levelup_queue: Array = []
var _waiting_levelup: bool = false

func _ready() -> void:
	CombatSystem.combat_log.connect(_on_combat_log)
	CombatSystem.player_died.connect(_on_player_died)
	XPSystem.level_up.connect(_on_level_up)
	btn_attack.pressed.connect(_on_btn_attack_pressed)
	btn_defend.pressed.connect(_on_btn_defend_pressed)
	btn_attack_def.pressed.connect(_on_btn_attack_defend_pressed)
	btn_scroll1.pressed.connect(_on_btn_scroll1_pressed)
	btn_scroll2.pressed.connect(_on_btn_scroll2_pressed)
	btn_roll.pressed.connect(_on_btn_roll_pressed)
	btn_loot1.pressed.connect(_on_btn_loot1_pressed)
	btn_loot2.pressed.connect(_on_btn_loot2_pressed)
	btn_loot3.pressed.connect(_on_btn_loot3_pressed)
	_spawn_enemies()
	_refresh_ui()
	_show_action_buttons()
	_log("[b]⚔️ Combat commence ![/b]")
	for e in enemies:
		_log("Un [b]%s[/b] apparaît ! (PV: %d)" % [e["name"], e["hp"]])

# ─────────────────────────────────────────
#  SPAWN ENNEMIS
# ─────────────────────────────────────────
func _spawn_enemies() -> void:
	var node_type  = GameManager.pending_node_type
	var diff       = GameManager.get_difficulty_multiplier()
	var enemy_data = GameManager.pending_enemy_data

	if node_type == "boss":
		var boss = EnemyDatabase.get_boss_dict_for_wave(GameManager.current_wave + 1)
		enemies.append(boss)
		BossSystem.boss_mechanic_triggered.connect(_on_boss_mechanic)
		BossSystem.boss_summon_enemy.connect(_on_boss_summon)
		_log("[b][color=red]👑 BOSS — %s[/color][/b]" % boss["name"])
		_log("[color=orange]%s[/color]" % BossSystem.get_boss_intro(boss))
		return

	if enemy_data is Dictionary:
		var shp  = int(enemy_data["hp"]      * diff)
		var satk = int(enemy_data["attack"]  * diff)
		var sdef = int(enemy_data["defense"] * diff)
		enemies.append({
			"id": enemy_data["id"], "name": enemy_data["name"],
			"hp": shp, "max_hp": shp, "attack": satk, "defense": sdef,
			"precision": enemy_data["precision"], "evasion": enemy_data["evasion"],
			"xp_reward": enemy_data["xp_reward"],
			"gold_reward_min": enemy_data["gold_reward_min"],
			"gold_reward_max": enemy_data["gold_reward_max"],
			"status_chance": enemy_data["status_chance"],
			"possible_statuses": enemy_data["possible_statuses"].duplicate(),
			"statuses": [], "tier": enemy_data["tier"],
			"can_defend": enemy_data.get("can_defend", false),
			"can_use_status": enemy_data.get("can_use_status", false),
		})
	else:
		enemies.append({
			"id":"enemy_0","name":"Gobelin",
			"hp":int(40*diff),"max_hp":int(40*diff),
			"attack":int(8*diff),"defense":int(3*diff),
			"precision":0.70,"evasion":0.05,
			"xp_reward":20,"gold_reward_min":5,"gold_reward_max":12,
			"status_chance":0.10,"possible_statuses":[],"statuses":[],
			"tier":"normal","can_defend":false,"can_use_status":false,
		})

	if EnemyDatabase.should_spawn_duo() and node_type != "boss":
		var second = enemies[0].duplicate()
		second["id"]       = "enemy_1"
		second["name"]     = enemies[0]["name"] + " #2"
		second["statuses"] = []
		enemies.append(second)
		_log("⚠️ Deux ennemis apparaissent !")

# ─────────────────────────────────────────
#  BOUTONS D'ACTION
# ─────────────────────────────────────────
func _show_action_buttons() -> void:
	if _waiting_levelup:
		return
	loot_panel.visible     = false
	action_panel.visible   = true
	btn_roll.visible       = false
	btn_attack.visible     = true
	btn_defend.visible     = true
	btn_attack_def.visible = CombatSystem.can_attack_and_defend()
	var s1 = PlayerData.equipped_scroll_1
	var s2 = PlayerData.equipped_scroll_2
	btn_scroll1.visible = s1 != null
	btn_scroll2.visible = s2 != null
	if s1:
		btn_scroll1.text     = "🔮 %s (%d mana)" % [s1.scroll_name, s1.mana_cost]
		btn_scroll1.disabled = not s1.is_usable()
	if s2:
		btn_scroll2.text     = "🔮 %s (%d mana)" % [s2.scroll_name, s2.mana_cost]
		btn_scroll2.disabled = not s2.is_usable()

func _show_roll_button() -> void:
	btn_attack.visible     = false
	btn_defend.visible     = false
	btn_attack_def.visible = false
	btn_scroll1.visible    = false
	btn_scroll2.visible    = false
	btn_roll.visible       = true
	btn_roll.text          = "🎲 Lancer le D%d !" % CombatSystem.get_die_max()

# ─────────────────────────────────────────
#  CHOIX D'ACTION
# ─────────────────────────────────────────
func _on_btn_attack_pressed() -> void:
	pending_action = "attack"
	_log("Tu choisis d'[b]attaquer[/b]. Lance le dé !")
	_show_roll_button()

func _on_btn_defend_pressed() -> void:
	pending_action = "defend"
	_log("Tu choisis de te [b]défendre[/b]. Lance le dé !")
	_show_roll_button()

func _on_btn_attack_defend_pressed() -> void:
	pending_action = "attack_defend"
	_log("⚔️🛡️ Combo épée+bouclier ! Lance le dé !")
	_show_roll_button()

func _on_btn_scroll1_pressed() -> void:
	pending_action = "scroll1"
	_log("Tu prépares [b]%s[/b]. Lance le dé !" % PlayerData.equipped_scroll_1.scroll_name)
	_show_roll_button()

func _on_btn_scroll2_pressed() -> void:
	pending_action = "scroll2"
	_log("Tu prépares [b]%s[/b]. Lance le dé !" % PlayerData.equipped_scroll_2.scroll_name)
	_show_roll_button()

# ─────────────────────────────────────────
#  RÉSOLUTION DU TOUR
# ─────────────────────────────────────────
func _on_btn_roll_pressed() -> void:
	last_roll = CombatSystem.roll_d20()
	_log("🎲 Résultat : [b]%d[/b] / %d" % [last_roll, CombatSystem.get_die_max()])
	btn_roll.visible = false
	_resolve_player_turn()

func _resolve_player_turn() -> void:
	# Vérifie les statuts joueur avant d'agir (gel/paralysie)
	var can_act = StatusSystem.process_statuses({"is_player": true})
	if not can_act:
		_log("[color=red]⚡ Tu es paralysé/gelé et ne peux pas agir ![/color]")
		_refresh_ui()
		if not combat_over:
			if not is_inside_tree(): return
			await get_tree().create_timer(0.5).timeout
			if not is_inside_tree(): return
			_enemy_turn()
		return

	defense_bonus_this_turn = 0
	var target = _get_current_target()

	match pending_action:
		"attack":
			var result = CombatSystem.player_attack(last_roll, target)
			if result["hit"]:
				if target.get("tier") == "boss":
					var br = BossSystem.apply_damage_to_boss(target, result["damage"])
					if br["blocked"] or br["message"] != "": _log(br["message"])
				else:
					target["hp"] -= result["damage"]
		"defend":
			var result = CombatSystem.player_defend(last_roll)
			defense_bonus_this_turn = result["defense_bonus"]
		"attack_defend":
			var roll_def = CombatSystem.roll_d20()
			_log("🎲 Dé défense : [b]%d[/b]" % roll_def)
			var atk = CombatSystem.player_attack(last_roll, target)
			if atk["hit"]:
				if target.get("tier") == "boss":
					var br = BossSystem.apply_damage_to_boss(target, atk["damage"])
					if br["blocked"] or br["message"] != "": _log(br["message"])
				else:
					target["hp"] -= atk["damage"]
			var def = CombatSystem.player_defend(roll_def)
			defense_bonus_this_turn = def["defense_bonus"]
		"scroll1":
			var result = CombatSystem.player_cast_scroll(PlayerData.equipped_scroll_1, last_roll, enemies)
			await _handle_scroll_result(result, target)
		"scroll2":
			var result = CombatSystem.player_cast_scroll(PlayerData.equipped_scroll_2, last_roll, enemies)
			await _handle_scroll_result(result, target)

	_refresh_ui()
	_check_enemies_alive()
	if not combat_over:
		# FIX : guard is_inside_tree avant chaque await
		if not is_inside_tree(): return
		await get_tree().create_timer(0.5).timeout
		if not is_inside_tree(): return
		_enemy_turn()

func _handle_scroll_result(result: Dictionary, target: Dictionary) -> void:
	if not result["success"]:
		return
	var values = result.get("values", [])
	if values.is_empty():
		return
	if typeof(values[0]) == TYPE_STRING and values[0] == "flee":
		combat_over = true
		if not is_inside_tree(): return
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree(): return
		GameManager.go_to_map()
		return
	if typeof(values[0]) == TYPE_INT and values[0] > 0:
		if target.get("tier") == "boss":
			var br = BossSystem.apply_damage_to_boss(target, values[0])
			if br["blocked"] or br["message"] != "": _log(br["message"])
		else:
			target["hp"] -= values[0]
	var scroll = PlayerData.equipped_scroll_1 if pending_action == "scroll1" else PlayerData.equipped_scroll_2
	if scroll != null and scroll.effect_type == "shield":
		shield_value = values[0] if not values.is_empty() else 0

# ─────────────────────────────────────────
#  TOUR ENNEMI
# ─────────────────────────────────────────
func _enemy_turn() -> void:
	turn_counter += 1
	RunStats.record_turn()
	RunStats.update_wave(GameManager.current_wave)
	_log("[color=red]— Tour ennemi —[/color]")
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		StatusSystem.process_statuses(enemy)
		if enemy["hp"] <= 0:
			continue
		if enemy.get("tier") == "boss":
			var boss_msg = BossSystem.process_mechanic(enemy, turn_counter)
			if boss_msg != "":
				_log("[color=orange]%s[/color]" % boss_msg)
			if combat_over:
				return
		var action = EnemyAI.decide_action(enemy, turn_counter)
		if action.get("preview","") != "":
			_log(action["preview"])
		var msg = EnemyAI.execute_action(action, enemy, defense_bonus_this_turn)
		if msg != "":
			_log(msg)
		if shield_value > 0:
			_log("🔵 Le bouclier arcanique absorbe les dégâts !")
			shield_value = 0
	defense_bonus_this_turn = 0
	_refresh_ui()
	if _levelup_queue.size() > 0:
		_process_levelup_queue()
		return
	if not combat_over:
		if not is_inside_tree(): return
		await get_tree().create_timer(0.3).timeout
		if not is_inside_tree(): return
		_show_action_buttons()

# ─────────────────────────────────────────
#  LEVEL UP — choix de stat
# ─────────────────────────────────────────
func _on_level_up(new_level: int) -> void:
	Notifier.level_up_notif(new_level)
	_levelup_queue.append(new_level)
	_refresh_ui()

func _process_levelup_queue() -> void:
	if _levelup_queue.is_empty():
		_waiting_levelup = false
		_show_action_buttons()
		return
	_levelup_queue.pop_front()
	_waiting_levelup = true
	_show_levelup_choices()

func _show_levelup_choices() -> void:
	action_panel.visible = false
	loot_panel.visible   = true
	loot_title.text      = "⬆️ Niveau supérieur ! Choisis une amélioration :"
	var options = [
		{"stat":"attack",    "value":3,    "label":"⚔️  +3 Attaque"},
		{"stat":"defense",   "value":2,    "label":"🛡️  +2 Défense"},
		{"stat":"max_hp",    "value":10,   "label":"❤️  +10 PV max"},
		{"stat":"precision", "value":0.02, "label":"🎯  +2% Précision"},
		{"stat":"evasion",   "value":0.01, "label":"👟  +1% Esquive"},
		{"stat":"max_mana",  "value":2,    "label":"💧  +2 Mana max"},
	]
	# Retire les stats déjà cappées à 100%
	options = options.filter(func(o):
		if o["stat"] == "precision" and PlayerData.precision >= 1.0: return false
		if o["stat"] == "evasion"   and PlayerData.evasion   >= 1.0: return false
		return true
	)
	options.shuffle()
	var choices = options.slice(0, 3)
	btn_loot1.text = choices[0]["label"]
	btn_loot2.text = choices[1]["label"]
	btn_loot3.text = choices[2]["label"]
	btn_loot1.set_meta("choice", choices[0])
	btn_loot2.set_meta("choice", choices[1])
	btn_loot3.set_meta("choice", choices[2])
	btn_loot1.set_meta("is_levelup", true)
	btn_loot2.set_meta("is_levelup", true)
	btn_loot3.set_meta("is_levelup", true)
	btn_loot1.disabled = false
	btn_loot2.disabled = false
	btn_loot3.disabled = false

func _apply_level_stat(choice: Dictionary) -> void:
	match choice["stat"]:
		"attack":    PlayerData.attack  += choice["value"]
		"defense":   PlayerData.defense += choice["value"]
		"max_hp":
			PlayerData.max_hp    += choice["value"]
			PlayerData.current_hp = min(PlayerData.current_hp + choice["value"], PlayerData.max_hp)
		"precision": PlayerData.precision = min(1.0, PlayerData.precision + choice["value"])
		"evasion":   PlayerData.evasion   = min(1.0, PlayerData.evasion   + choice["value"])
		"max_mana":
			PlayerData.max_mana    += choice["value"]
			PlayerData.current_mana = min(PlayerData.current_mana + choice["value"], PlayerData.max_mana)
	_refresh_ui()

# ─────────────────────────────────────────
#  BOUTONS LOOT / LEVEL UP
# ─────────────────────────────────────────
func _on_btn_loot1_pressed() -> void: _pick_loot(btn_loot1)
func _on_btn_loot2_pressed() -> void: _pick_loot(btn_loot2)
func _on_btn_loot3_pressed() -> void: _pick_loot(btn_loot3)

func _pick_loot(btn: Button) -> void:
	var choice     = btn.get_meta("choice")
	var is_levelup = btn.get_meta("is_levelup", false)

	if is_levelup:
		_apply_level_stat(choice)
		_log("⬆️ %s !" % choice["label"])
		loot_panel.visible = false
		btn_loot1.set_meta("is_levelup", false)
		btn_loot2.set_meta("is_levelup", false)
		btn_loot3.set_meta("is_levelup", false)
		# FIX : guard avant timer level up
		if not is_inside_tree(): return
		await get_tree().create_timer(0.2).timeout
		if not is_inside_tree(): return
		_process_levelup_queue()
		return

	# Loot post-combat classique
	btn_loot1.disabled = true
	btn_loot2.disabled = true
	btn_loot3.disabled = true
	LootSystem.apply_stat_choice(choice)
	_log("✨ %s !" % choice["label"])
	_refresh_ui()
	loot_panel.visible = false
	GameManager.current_wave += 1
	RunManager.on_wave_completed(GameManager.current_wave)
	if GameManager.current_wave >= GameManager.max_waves:
		GameManager.pending_node_type = "victory"
		get_tree().change_scene_to_file("res://scenes/RunSummaryScene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

# ─────────────────────────────────────────
#  FIN DE COMBAT
# ─────────────────────────────────────────
func _check_enemies_alive() -> void:
	for enemy in enemies:
		if enemy["hp"] > 0:
			return
	_on_combat_victory()

func _on_combat_victory() -> void:
	combat_over = true
	action_panel.visible = false
	_log("[b][color=green]✅ VICTOIRE ![/color][/b]")
	for enemy in enemies:
		CombatSystem.on_enemy_defeated(enemy)
	_refresh_ui()
	Notifier.gold_notif(PlayerData.gold)
	AchievementSystem.check_combat_end(RunStats.damage_received == 0)
	AchievementSystem.check_wave(GameManager.current_wave)
	AchievementSystem.check_boss_kill(RunStats.bosses_killed)
	AchievementSystem.check_kills(RunStats.enemies_killed)
	AchievementSystem.check_equipment()
	# FIX : guard avant timer victoire
	if not is_inside_tree(): return
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree(): return
	_show_loot_choices()

func _show_loot_choices() -> void:
	var tier    = enemies[0].get("tier", "normal")
	var choices = LootSystem.generate_stat_choices(tier)
	loot_panel.visible   = true
	action_panel.visible = false
	loot_title.text      = "🎁 Choisis ta récompense :"
	btn_loot1.text = choices[0]["label"]
	btn_loot2.text = choices[1]["label"]
	btn_loot3.text = choices[2]["label"]
	btn_loot1.set_meta("choice", choices[0])
	btn_loot2.set_meta("choice", choices[1])
	btn_loot3.set_meta("choice", choices[2])
	btn_loot1.set_meta("is_levelup", false)
	btn_loot2.set_meta("is_levelup", false)
	btn_loot3.set_meta("is_levelup", false)
	btn_loot1.disabled = false
	btn_loot2.disabled = false
	btn_loot3.disabled = false
	_log("[b]Choisis ta récompense :[/b]")

# ─────────────────────────────────────────
#  MORT
# ─────────────────────────────────────────
func _on_player_died() -> void:
	if combat_over:
		return
	combat_over = true
	action_panel.visible = false
	_log("[b][color=red]💀 TU ES MORT.[/color][/b]")
	# FIX : guard avant timer mort
	if not is_inside_tree(): return
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree(): return
	GameManager.on_player_death()

# ─────────────────────────────────────────
#  CALLBACKS BOSS
# ─────────────────────────────────────────
func _on_boss_mechanic(message: String) -> void:
	_log("[color=orange]%s[/color]" % message)

func _on_boss_summon(enemy: Dictionary) -> void:
	enemies.append(enemy)
	_log("💢 Un [b]%s[/b] apparaît !" % enemy["name"])
	_refresh_ui()

# ─────────────────────────────────────────
#  UTILITAIRES
# ─────────────────────────────────────────
func _get_current_target() -> Dictionary:
	for enemy in enemies:
		if enemy["hp"] > 0:
			return enemy
	return enemies[0]

func _on_combat_log(message: String) -> void:
	_log(message)

func _log(text: String) -> void:
	# FIX : guard is_inside_tree sur tous les await
	if not is_inside_tree(): return
	log_label.append_text(text + "\n")
	if not is_inside_tree(): return
	await get_tree().process_frame
	if not is_inside_tree(): return
	log_label.scroll_to_line(log_label.get_line_count())

func _refresh_ui() -> void:
	hp_label.text    = "❤️ %d/%d" % [PlayerData.current_hp, PlayerData.max_hp]
	mana_label.text  = "💧 %d/%d" % [PlayerData.current_mana, PlayerData.max_mana]
	level_label.text = "⭐ Niv.%d" % PlayerData.level
	xp_label.text    = "XP %d/%d" % [PlayerData.current_xp, PlayerData.xp_to_next_level]
	var st = []
	for s in PlayerData.active_statuses:
		st.append(StatusSystem.get_status_label(s["type"]))
	status_label.text = "  ".join(st)
	var txt = ""
	for enemy in enemies:
		if enemy["hp"] > 0:
			var prefix = "👑 " if enemy.get("tier") == "boss" else ""
			txt += "%s[b]%s[/b]  %s  %d/%d PV\n" % [
				prefix, enemy["name"],
				_make_hp_bar(enemy["hp"], enemy["max_hp"]),
				enemy["hp"], enemy["max_hp"]
			]
			if enemy.get("tier") == "boss":
				txt += "  [i]Mécanique : %s[/i]\n" % enemy.get("mechanic","?")
		else:
			txt += "[s]%s[/s] 💀\n" % enemy["name"]
	enemy_label.parse_bbcode(txt)

func _make_hp_bar(current: int, maximum: int) -> String:
	var filled = clamp(int(float(current) / float(maximum) * 10.0), 0, 10)
	return "[color=red]" + "█".repeat(filled) + "[/color]" + "░".repeat(10 - filled)
