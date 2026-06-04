extends Node

var path_history: Array = []
var waves_since_last_destruction: int = 0

const NODE_WEIGHTS = {
	"combat":   40,
	"elite":    12,
	"event":    15,
	"sauna":    10,
	"treasure": 18,
	"special":   5,
}

func generate_path_choices(wave_number: int) -> Array:
	if wave_number > 0 and wave_number % 10 == 0:
		return [_make_node("boss"), _make_node("boss")]
	if wave_number > 0 and wave_number % 5 == 0:
		return [_make_node("market"), _make_node("market")]
	var node_a = _make_random_node(wave_number)
	var node_b = _make_random_node(wave_number)
	var attempts = 0
	while node_b["type"] == node_a["type"] and attempts < 10:
		node_b = _make_random_node(wave_number)
		attempts += 1
	return [node_a, node_b]

func _make_random_node(wave: int) -> Dictionary:
	var weights = NODE_WEIGHTS.duplicate()
	if wave < 10:
		weights["elite"] = 3
	elif wave > 50:
		weights["elite"] = 20
		weights["combat"] = 35
	var total = 0
	for w in weights.values():
		total += w
	var roll = randi() % total
	var cumul = 0
	for node_type in weights:
		cumul += weights[node_type]
		if roll < cumul:
			return _make_node(node_type if node_type != "special" else "treasure")
	return _make_node("combat")

func _make_node(type: String) -> Dictionary:
	var enemy_data = null
	match type:
		"combat": enemy_data = EnemyDatabase.get_random_enemy_dict("normal")
		"elite":  enemy_data = EnemyDatabase.get_random_enemy_dict("elite")
	return { "type": type, "enemy_data": enemy_data, "revealed": false }

func on_wave_completed(wave: int) -> void:
	path_history.append(wave)
	if "maudit" in PlayerData.traits:
		waves_since_last_destruction += 1
		if waves_since_last_destruction >= 10:
			waves_since_last_destruction = 0
			_destroy_random_item()

func _destroy_random_item() -> void:
	var all_items = PlayerData.inventory.duplicate()
	if PlayerData.equipped_weapon:   all_items.append(PlayerData.equipped_weapon)
	if PlayerData.equipped_armor:    all_items.append(PlayerData.equipped_armor)
	if PlayerData.equipped_scroll_1: all_items.append(PlayerData.equipped_scroll_1)
	if PlayerData.equipped_scroll_2: all_items.append(PlayerData.equipped_scroll_2)
	all_items.append_array(PlayerData.passive_scrolls)
	if all_items.is_empty():
		return
	var target = all_items[randi() % all_items.size()]
	PlayerData.inventory.erase(target)
	if PlayerData.equipped_weapon   == target: PlayerData.equipped_weapon   = null
	if PlayerData.equipped_armor    == target: PlayerData.equipped_armor    = null
	if PlayerData.equipped_scroll_1 == target: PlayerData.equipped_scroll_1 = null
	if PlayerData.equipped_scroll_2 == target: PlayerData.equipped_scroll_2 = null
	PlayerData.passive_scrolls.erase(target)
	var item_name = ""
	if target is ScrollResource:
		item_name = target.scroll_name
	elif target is Object and target.has_meta("item_name"):
		item_name = target.get_meta("item_name")
	Notifier.show_notif("💀 Trait Maudit : %s détruit !" % item_name, Color("#c84040"))

func reset_for_new_run() -> void:
	path_history.clear()
	waves_since_last_destruction = 0
