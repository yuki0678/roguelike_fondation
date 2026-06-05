extends Node
## EnemyDatabase - Base de données des ennemis REÉQUILIBRÉE
## Auteur : Vibe Coding Environment
## Date : 2026-06-05
## Compatible : Godot 4.x

const RARETE = {
	"commun": {"pv": 1.0, "att": 1.0, "def": 1.0, "xp": 1.0, "or": 1.0},
	"rare": {"pv": 1.3, "att": 1.2, "def": 1.2, "xp": 1.5, "or": 1.5},
	"epique": {"pv": 1.6, "att": 1.4, "def": 1.4, "xp": 2.0, "or": 2.0},
	"mythique": {"pv": 2.0, "att": 1.6, "def": 1.6, "xp": 2.5, "or": 2.5},
	"legendaire": {"pv": 2.5, "att": 2.0, "def": 2.0, "xp": 3.0, "or": 3.0}
}

const STATUTS = {
	"commun": ["bleed"],
	"rare": ["bleed", "poison"],
	"epique": ["bleed", "poison", "burn", "curse"],
	"mythique": ["bleed", "poison", "burn", "curse", "paralysis"],
	"legendaire": ["bleed", "poison", "burn", "curse", "paralysis", "freeze"]
}

func generer_ennemi(nom: String, vague: int, rareté: String = "commun", type: String = "normal") -> Dictionary:
	var base_pv: int = 50 + (vague * 3)
	var base_att: int = 10 + int(vague * 0.8)
	var base_def: int = 2 + int(vague * 0.3)
	var base_xp: int = vague * 15
	var base_or_min: int = vague * 3
	var base_or_max: int = vague * 5
	var mult = RARETE[rareté]
	var pv: int = int(base_pv * mult["pv"])
	var att: int = int(base_att * mult["att"])
	var def: int = int(base_def * mult["def"])
	var xp: int = int(base_xp * mult["xp"])
	var or_min: int = int(base_or_min * mult["or"])
	var or_max: int = int(base_or_max * mult["or"])
	match type:
		"elite":
			pv = int(pv * 1.5)
			att = int(att * 1.3)
			def = int(def * 1.2)
			xp = int(xp * 1.8)
			or_min = int(or_min * 1.5)
			or_max = int(or_max * 1.5)
		"boss":
			pv = int(pv * 2.5)
			att = int(att * 1.8)
			def = int(def * 1.5)
			xp = int(xp * 2.5)
			or_min = int(or_min * 2.0)
			or_max = int(or_max * 2.0)
	var raretes = ["commun", "rare", "epique", "mythique", "legendaire"]
	var rareté_index = raretes.find_index(r -> r == rareté)
	var statut_chance: float = 0.20 + (0.05 * rareté_index)
	var statuts_possibles: Array = STATUTS[rareté]
	return {
		"id": nom.to_lower().replace(" ", "_"),
		"name": nom,
		"tier": type,
		"hp": pv,
		"max_hp": pv,
		"attack": att,
		"defense": def,
		"precision": 0.70 + (0.05 * rareté_index),
		"evasion": 0.05 + (0.03 * rareté_index),
		"xp_reward": xp,
		"gold_reward_min": or_min,
		"gold_reward_max": or_max,
		"status_chance": statut_chance,
		"possible_statuses": statuts_possibles,
		"can_defend": type == "elite" or type == "boss",
		"can_use_status": true,
		"flavor": "Un %s apparait!" % nom,
		"display": "[%s]" % nom.to_upper()
	}

func _get_normal_enemies() -> Array:
	return [
		generer_ennemi("Gobelin", 1, "commun"),
		generer_ennemi("Rat Géant", 2, "commun"),
		generer_ennemi("Squelette", 3, "commun"),
		generer_ennemi("Loup Sauvage", 4, "commun"),
		generer_ennemi("Brigand", 5, "commun"),
		generer_ennemi("Araignée Noire", 6, "commun"),
		generer_ennemi("Champignon Fou", 7, "rare"),
		generer_ennemi("Spectre", 8, "rare"),
		generer_ennemi("Orque", 9, "rare"),
		generer_ennemi("Banshee", 9, "rare")
	]

func _get_elite_enemies() -> Array:
	return [
		generer_ennemi("Gobelin Champion", 15, "rare", "elite"),
		generer_ennemi("Troll des Marais", 20, "rare", "elite"),
		generer_ennemi("Chevalier Noir", 25, "epique", "elite"),
		generer_ennemi("Sorcier Fou", 30, "epique", "elite"),
		generer_ennemi("Assassin Masqué", 35, "epique", "elite"),
		generer_ennemi("Géant de Pierre", 40, "epique", "elite")
	]

func _get_bosses() -> Array:
	return [
		{"id":"boss_gobelin_king","name":"Roi Gobelin","tier":"boss","hp":200,"max_hp":200,"attack":20,"defense":10,"precision":0.75,"evasion":0.10,"xp_reward":200,"gold_reward_min":50,"gold_reward_max":80,"status_chance":0.20,"possible_statuses":["bleed"],"can_defend":true,"can_use_status":true,"mechanic":"summon","mechanic_triggered":false,"summon_hp_threshold":0.5,"flavor":"Il rugit et appelle ses sbires !","display":"[ROI GOBELIN]"},
		{"id":"boss_stone_golem","name":"Golem de Pierre","tier":"boss","hp":350,"max_hp":350,"attack":28,"defense":25,"precision":0.65,"evasion":0.05,"xp_reward":350,"gold_reward_min":80,"gold_reward_max":120,"status_chance":0.15,"possible_statuses":["paralysis"],"can_defend":true,"can_use_status":false,"mechanic":"armor_phase","mechanic_triggered":false,"armor_threshold":0.5,"flavor":"Sa peau de pierre durcit encore !","display":"[GOLEM DE PIERRE]"},
		{"id":"boss_plague_witch","name":"Sorcière de la Peste","tier":"boss","hp":280,"max_hp":280,"attack":25,"defense":12,"precision":0.80,"evasion":0.15,"xp_reward":450,"gold_reward_min":100,"gold_reward_max":150,"status_chance":0.50,"possible_statuses":["poison","curse"],"can_defend":false,"can_use_status":true,"mechanic":"multi_status","mechanic_triggered":false,"flavor":"Elle ricane en répandant ses miasmes !","display":"[SORCIERE DE LA PESTE]"},
		{"id":"boss_iron_knight","name":"Chevalier de Fer","tier":"boss","hp":450,"max_hp":450,"attack":32,"defense":30,"precision":0.75,"evasion":0.10,"xp_reward":550,"gold_reward_min":120,"gold_reward_max":180,"status_chance":0.25,"possible_statuses":["bleed","paralysis"],"can_defend":true,"can_use_status":true,"mechanic":"parry","mechanic_triggered":false,"parry_threshold":15,"flavor":"Son armure dévie les coups trop faibles !","display":"[CHEVALIER DE FER]"},
		{"id":"boss_shadow_assassin","name":"Assassin de l'Ombre","tier":"boss","hp":320,"max_hp":320,"attack":42,"defense":12,"precision":0.90,"evasion":0.35,"xp_reward":650,"gold_reward_min":140,"gold_reward_max":200,"status_chance":0.35,"possible_statuses":["bleed","poison"],"can_defend":false,"can_use_status":true,"mechanic":"dodge_phase","mechanic_triggered":false,"dodge_turn":0,"flavor":"Il disparaît dans l'ombre !","display":"[ASSASSIN DE L'OMBRE]"},
		{"id":"boss_frost_wyrm","name":"Wyrm de Glace","tier":"boss","hp":550,"max_hp":550,"attack":38,"defense":18,"precision":0.75,"evasion":0.10,"xp_reward":750,"gold_reward_min":160,"gold_reward_max":240,"status_chance":0.45,"possible_statuses":["freeze","bleed"],"can_defend":false,"can_use_status":true,"mechanic":"aoe_freeze","mechanic_triggered":false,"flavor":"Son souffle glacial envahit la pièce !","display":"[WYRM DE GLACE]"},
		{"id":"boss_blood_cultist","name":"Cultiste du Sang","tier":"boss","hp":450,"max_hp":450,"attack":40,"defense":15,"precision":0.80,"evasion":0.12,"xp_reward":850,"gold_reward_min":180,"gold_reward_max":260,"status_chance":0.45,"possible_statuses":["bleed","curse"],"can_defend":false,"can_use_status":true,"mechanic":"lifesteal","mechanic_triggered":false,"lifesteal_percent":0.30,"flavor":"Il boit votre force vitale !","display":"[CULTISTE DU SANG]"},
		{"id":"boss_void_titan","name":"Titan du Vide","tier":"boss","hp":650,"max_hp":650,"attack":48,"defense":22,"precision":0.80,"evasion":0.10,"xp_reward":950,"gold_reward_min":200,"gold_reward_max":300,"status_chance":0.40,"possible_statuses":["curse","paralysis"],"can_defend":true,"can_use_status":true,"mechanic":"mana_drain","mechanic_triggered":false,"mana_drain":2,"flavor":"Le vide absorbe votre magie !","display":"[TITAN DU VIDE]"},
		{"id":"boss_death_herald","name":"Héraut de la Mort","tier":"boss","hp":750,"max_hp":750,"attack":55,"defense":25,"precision":0.85,"evasion":0.15,"xp_reward":1100,"gold_reward_min":220,"gold_reward_max":340,"status_chance":0.55,"possible_statuses":["poison","bleed","curse","burn"],"can_defend":true,"can_use_status":true,"mechanic":"execute","mechanic_triggered":false,"execute_threshold":0.20,"flavor":"Il lève sa faux vers vous !","display":"[HERAUT DE LA MORT]"},
		{"id":"boss_nameless","name":"Le Sans-Nom","tier":"boss","hp":1200,"max_hp":1200,"attack":65,"defense":30,"precision":0.90,"evasion":0.20,"xp_reward":2000,"gold_reward_min":300,"gold_reward_max":500,"status_chance":0.65,"possible_statuses":["poison","bleed","curse","burn","freeze","paralysis"],"can_defend":true,"can_use_status":true,"mechanic":"all_mechanics","mechanic_triggered":false,"flavor":"Il est partout. Il est tout. Il est la fin.","display":"[LE SANS-NOM]"}
	]

var _normal_enemies: Array = []
var _elite_enemies: Array = []
var _boss_enemies: Array = []

func _ready() -> void:
	_normal_enemies = _get_normal_enemies()
	_elite_enemies = _get_elite_enemies()
	_boss_enemies = _get_bosses()

func get_random_enemy(tier: String = "normal") -> Dictionary:
	match tier:
		"normal": return _normal_enemies[randi() % _normal_enemies.size()]
		"elite": return _elite_enemies[randi() % _elite_enemies.size()]
		"boss": return _boss_enemies[randi() % _boss_enemies.size()]
		_: return _normal_enemies[0]

func get_boss_for_wave(wave: int) -> Dictionary:
	if wave <= 0: return _boss_enemies[0]
	var index: int = min(int(wave / 10) - 1, _boss_enemies.size() - 1)
	return _boss_enemies[index]

func generate_enemy_from_base(base: Dictionary, wave: int = 1) -> Dictionary:
	var enemy = base.duplicate()
	var wave_multiplier: float = 1.0 + (wave * 0.02)
	enemy["hp"] = int(enemy["hp"] * wave_multiplier)
	enemy["max_hp"] = enemy["hp"]
	enemy["attack"] = int(enemy["attack"] * wave_multiplier)
	enemy["defense"] = int(enemy["defense"] * wave_multiplier)
	enemy["xp_reward"] = int(enemy["xp_reward"] * wave_multiplier)
	enemy["gold_reward_min"] = int(enemy["gold_reward_min"] * wave_multiplier)
	enemy["gold_reward_max"] = int(enemy["gold_reward_max"] * wave_multiplier)
	return enemy
