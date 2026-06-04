extends Node
# ─────────────────────────────────────────
#  EnemyDatabase — Singleton (Autoload)
#  Charge toutes les EnemyResource et expose des méthodes de tirage.
#  Contient aussi la base de données des boss (BossDatabase intégré).
# ─────────────────────────────────────────

var _normal_enemies: Array = []
var _elite_enemies: Array = []
var _boss_enemies: Array = []

func _ready() -> void:
	_load_all_enemies()

func _load_all_enemies() -> void:
	var dirs = {
		"normal": "res://data/enemies/normal/",
		"elite":  "res://data/enemies/elite/",
		"boss":   "res://data/enemies/boss/",
	}
	for tier in dirs:
		var dir = DirAccess.open(dirs[tier])
		if dir == null:
			continue
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if fname.ends_with(".tres"):
				var res = load(dirs[tier] + fname)
				if res is EnemyResource:
					match tier:
						"normal": _normal_enemies.append(res)
						"elite":  _elite_enemies.append(res)
						"boss":   _boss_enemies.append(res)
			fname = dir.get_next()

func get_random_enemy(tier: String) -> EnemyResource:
	var pool: Array
	match tier:
		"normal": pool = _normal_enemies
		"elite":  pool = _elite_enemies
		"boss":   pool = _boss_enemies
		_:        pool = _normal_enemies
	if pool.is_empty():
		push_error("EnemyDatabase: pool vide pour tier = " + tier)
		return null
	return pool[randi() % pool.size()]

func get_boss_for_wave(wave: int) -> EnemyResource:
	if _boss_enemies.is_empty():
		return get_random_enemy("normal")
	var index = int(wave / 10) - 1
	index = clamp(index, 0, _boss_enemies.size() - 1)
	return _boss_enemies[index]

func should_spawn_duo() -> bool:
	var base_chance = 0.25
	if "traqueur" in PlayerData.traits:
		base_chance = min(0.99, base_chance * 1.5)
	return randf() < base_chance

# ─────────────────────────────────────────
#  BOSS DATABASE (intégré)
# ─────────────────────────────────────────
func get_boss_dict_for_wave(wave: int) -> Dictionary:
	var tier = int(wave / 10)
	match tier:
		1:  return _boss_gobelin_king()
		2:  return _boss_stone_golem()
		3:  return _boss_plague_witch()
		4:  return _boss_iron_knight()
		5:  return _boss_shadow_assassin()
		6:  return _boss_frost_wyrm()
		7:  return _boss_blood_cultist()
		8:  return _boss_void_titan()
		9:  return _boss_death_herald()
		_:
			var base = _boss_final()
			var mult = 1.0 + max(0, tier - 10) * 0.3
			base["hp"]     = int(base["hp"] * mult)
			base["max_hp"] = base["hp"]
			base["attack"] = int(base["attack"] * mult)
			base["name"]   = "Titan Abyssal Niv.%d" % tier
			return base

func _boss_gobelin_king() -> Dictionary:
	return {"id": "boss_0", "name": "Roi Gobelin", "tier": "boss",
		"hp": 180, "max_hp": 180, "attack": 18, "defense": 8,
		"precision": 0.75, "evasion": 0.08,
		"xp_reward": 150, "gold_reward_min": 40, "gold_reward_max": 70,
		"status_chance": 0.15, "possible_statuses": ["bleed"], "statuses": [],
		"can_defend": true, "can_use_status": true,
		"mechanic": "summon", "mechanic_triggered": false,
		"flavor": "Il rugit et appelle ses sbires !", "display": "[ROI GOBELIN]"}

func _boss_stone_golem() -> Dictionary:
	return {"id": "boss_0", "name": "Golem de Pierre", "tier": "boss",
		"hp": 320, "max_hp": 320, "attack": 25, "defense": 20,
		"precision": 0.60, "evasion": 0.02,
		"xp_reward": 250, "gold_reward_min": 65, "gold_reward_max": 100,
		"status_chance": 0.10, "possible_statuses": ["paralysis"], "statuses": [],
		"can_defend": true, "can_use_status": false,
		"mechanic": "armor_phase", "mechanic_triggered": false,
		"flavor": "Sa peau de pierre durcit encore !", "display": "[GOLEM DE PIERRE]"}

func _boss_plague_witch() -> Dictionary:
	return {"id": "boss_0", "name": "Sorcière de la Peste", "tier": "boss",
		"hp": 260, "max_hp": 260, "attack": 22, "defense": 10,
		"precision": 0.80, "evasion": 0.12,
		"xp_reward": 350, "gold_reward_min": 80, "gold_reward_max": 130,
		"status_chance": 0.60, "possible_statuses": ["poison", "burn", "curse"], "statuses": [],
		"can_defend": false, "can_use_status": true,
		"mechanic": "multi_status", "mechanic_triggered": false,
		"flavor": "Elle ricane en répandant ses miasmes !", "display": "[SORCIERE DE LA PESTE]"}

func _boss_iron_knight() -> Dictionary:
	return {"id": "boss_0", "name": "Chevalier de Fer", "tier": "boss",
		"hp": 400, "max_hp": 400, "attack": 30, "defense": 25,
		"precision": 0.70, "evasion": 0.05,
		"xp_reward": 450, "gold_reward_min": 100, "gold_reward_max": 160,
		"status_chance": 0.20, "possible_statuses": ["bleed", "paralysis"], "statuses": [],
		"can_defend": true, "can_use_status": true,
		"mechanic": "parry", "mechanic_triggered": false, "parry_threshold": 15,
		"flavor": "Son armure dévie les coups trop faibles !", "display": "[CHEVALIER DE FER]"}

func _boss_shadow_assassin() -> Dictionary:
	return {"id": "boss_0", "name": "Assassin de l'Ombre", "tier": "boss",
		"hp": 300, "max_hp": 300, "attack": 40, "defense": 8,
		"precision": 0.92, "evasion": 0.35,
		"xp_reward": 550, "gold_reward_min": 120, "gold_reward_max": 190,
		"status_chance": 0.30, "possible_statuses": ["bleed", "poison"], "statuses": [],
		"can_defend": false, "can_use_status": true,
		"mechanic": "dodge_phase", "mechanic_triggered": false, "dodge_turn": 0,
		"flavor": "Il disparaît dans l'ombre !", "display": "[ASSASSIN DE L'OMBRE]"}

func _boss_frost_wyrm() -> Dictionary:
	return {"id": "boss_0", "name": "Wyrm de Glace", "tier": "boss",
		"hp": 500, "max_hp": 500, "attack": 35, "defense": 15,
		"precision": 0.72, "evasion": 0.08,
		"xp_reward": 650, "gold_reward_min": 140, "gold_reward_max": 220,
		"status_chance": 0.50, "possible_statuses": ["freeze", "bleed"], "statuses": [],
		"can_defend": false, "can_use_status": true,
		"mechanic": "aoe_freeze", "mechanic_triggered": false,
		"flavor": "Son souffle glacial envahit la pièce !", "display": "[WYRM DE GLACE]"}

func _boss_blood_cultist() -> Dictionary:
	return {"id": "boss_0", "name": "Cultiste du Sang", "tier": "boss",
		"hp": 420, "max_hp": 420, "attack": 38, "defense": 12,
		"precision": 0.78, "evasion": 0.10,
		"xp_reward": 750, "gold_reward_min": 160, "gold_reward_max": 250,
		"status_chance": 0.40, "possible_statuses": ["bleed", "curse"], "statuses": [],
		"can_defend": false, "can_use_status": true,
		"mechanic": "lifesteal", "mechanic_triggered": false,
		"flavor": "Il boit votre force vitale !", "display": "[CULTISTE DU SANG]"}

func _boss_void_titan() -> Dictionary:
	return {"id": "boss_0", "name": "Titan du Vide", "tier": "boss",
		"hp": 600, "max_hp": 600, "attack": 45, "defense": 18,
		"precision": 0.75, "evasion": 0.06,
		"xp_reward": 900, "gold_reward_min": 180, "gold_reward_max": 290,
		"status_chance": 0.35, "possible_statuses": ["curse", "paralysis"], "statuses": [],
		"can_defend": true, "can_use_status": true,
		"mechanic": "mana_drain", "mechanic_triggered": false,
		"flavor": "Le vide absorbe votre magie !", "display": "[TITAN DU VIDE]"}

func _boss_death_herald() -> Dictionary:
	return {"id": "boss_0", "name": "Héraut de la Mort", "tier": "boss",
		"hp": 700, "max_hp": 700, "attack": 50, "defense": 20,
		"precision": 0.82, "evasion": 0.15,
		"xp_reward": 1100, "gold_reward_min": 200, "gold_reward_max": 340,
		"status_chance": 0.50, "possible_statuses": ["poison", "bleed", "curse", "burn"], "statuses": [],
		"can_defend": true, "can_use_status": true,
		"mechanic": "execute", "mechanic_triggered": false,
		"flavor": "Il lève sa faux vers vous !", "display": "[HERAUT DE LA MORT]"}

func _boss_final() -> Dictionary:
	return {"id": "boss_0", "name": "Le Sans-Nom", "tier": "boss",
		"hp": 1000, "max_hp": 1000, "attack": 60, "defense": 25,
		"precision": 0.85, "evasion": 0.20,
		"xp_reward": 2000, "gold_reward_min": 300, "gold_reward_max": 500,
		"status_chance": 0.60, "possible_statuses": ["poison", "bleed", "curse", "burn", "freeze"], "statuses": [],
		"can_defend": true, "can_use_status": true,
		"mechanic": "all_mechanics", "mechanic_triggered": false,
		"flavor": "Il est partout. Il est tout. Il est la fin.", "display": "[LE SANS-NOM]"}

# ─────────────────────────────────────────
#  POOL D'ENNEMIS NORMAUX (codés en dur)
#  Utilisé quand les .tres sont vides
# ─────────────────────────────────────────
func get_random_enemy_dict(tier: String) -> Dictionary:
	match tier:
		"normal":  return _normal_pool[randi() % _normal_pool.size()]
		"elite":   return _elite_pool[randi() % _elite_pool.size()]
		_:         return _normal_pool[0]

const _normal_pool = [
	{"id":"e0","name":"Gobelin",       "tier":"normal","hp":40, "max_hp":40, "attack":8,  "defense":3,  "precision":0.70,"evasion":0.05,"xp_reward":20, "gold_reward_min":5,  "gold_reward_max":12, "status_chance":0.10,"possible_statuses":[],"statuses":[],"can_defend":false,"can_use_status":false},
	{"id":"e1","name":"Rat Géant",      "tier":"normal","hp":25, "max_hp":25, "attack":6,  "defense":1,  "precision":0.80,"evasion":0.10,"xp_reward":12, "gold_reward_min":2,  "gold_reward_max":7,  "status_chance":0.20,"possible_statuses":["bleed"],"statuses":[],"can_defend":false,"can_use_status":true},
	{"id":"e2","name":"Squelette",      "tier":"normal","hp":35, "max_hp":35, "attack":10, "defense":5,  "precision":0.65,"evasion":0.02,"xp_reward":18, "gold_reward_min":4,  "gold_reward_max":10, "status_chance":0.05,"possible_statuses":[],"statuses":[],"can_defend":true, "can_use_status":false},
	{"id":"e3","name":"Loup Sauvage",   "tier":"normal","hp":30, "max_hp":30, "attack":12, "defense":2,  "precision":0.85,"evasion":0.15,"xp_reward":16, "gold_reward_min":3,  "gold_reward_max":8,  "status_chance":0.15,"possible_statuses":["bleed"],"statuses":[],"can_defend":false,"can_use_status":true},
	{"id":"e4","name":"Brigand",        "tier":"normal","hp":45, "max_hp":45, "attack":9,  "defense":4,  "precision":0.75,"evasion":0.08,"xp_reward":22, "gold_reward_min":8,  "gold_reward_max":18, "status_chance":0.10,"possible_statuses":["poison"],"statuses":[],"can_defend":true, "can_use_status":false},
	{"id":"e5","name":"Araignée Noire", "tier":"normal","hp":22, "max_hp":22, "attack":7,  "defense":2,  "precision":0.90,"evasion":0.20,"xp_reward":14, "gold_reward_min":3,  "gold_reward_max":9,  "status_chance":0.35,"possible_statuses":["poison"],"statuses":[],"can_defend":false,"can_use_status":true},
	{"id":"e6","name":"Champignon Fou", "tier":"normal","hp":50, "max_hp":50, "attack":7,  "defense":6,  "precision":0.60,"evasion":0.01,"xp_reward":20, "gold_reward_min":4,  "gold_reward_max":11, "status_chance":0.25,"possible_statuses":["poison","burn"],"statuses":[],"can_defend":false,"can_use_status":true},
	{"id":"e7","name":"Spectre",        "tier":"normal","hp":28, "max_hp":28, "attack":11, "defense":0,  "precision":0.70,"evasion":0.30,"xp_reward":25, "gold_reward_min":6,  "gold_reward_max":14, "status_chance":0.20,"possible_statuses":["curse"],"statuses":[],"can_defend":false,"can_use_status":true},
	{"id":"e8","name":"Orque",          "tier":"normal","hp":55, "max_hp":55, "attack":13, "defense":7,  "precision":0.65,"evasion":0.02,"xp_reward":28, "gold_reward_min":7,  "gold_reward_max":16, "status_chance":0.05,"possible_statuses":[],"statuses":[],"can_defend":true, "can_use_status":false},
	{"id":"e9","name":"Banshee",        "tier":"normal","hp":32, "max_hp":32, "attack":9,  "defense":3,  "precision":0.75,"evasion":0.12,"xp_reward":22, "gold_reward_min":5,  "gold_reward_max":13, "status_chance":0.30,"possible_statuses":["paralysis","curse"],"statuses":[],"can_defend":false,"can_use_status":true},
]

const _elite_pool = [
	{"id":"el0","name":"Gobelin Champion",  "tier":"elite","hp":90, "max_hp":90, "attack":18,"defense":8,  "precision":0.75,"evasion":0.08,"xp_reward":60, "gold_reward_min":20,"gold_reward_max":40,"status_chance":0.15,"possible_statuses":["bleed"],"statuses":[],"can_defend":true,"can_use_status":true},
	{"id":"el1","name":"Troll des Marais",  "tier":"elite","hp":120,"max_hp":120,"attack":20,"defense":12, "precision":0.65,"evasion":0.03,"xp_reward":75, "gold_reward_min":25,"gold_reward_max":50,"status_chance":0.10,"possible_statuses":["poison"],"statuses":[],"can_defend":false,"can_use_status":true},
	{"id":"el2","name":"Chevalier Noir",    "tier":"elite","hp":100,"max_hp":100,"attack":22,"defense":15, "precision":0.70,"evasion":0.05,"xp_reward":80, "gold_reward_min":30,"gold_reward_max":55,"status_chance":0.15,"possible_statuses":["bleed","curse"],"statuses":[],"can_defend":true,"can_use_status":true},
	{"id":"el3","name":"Sorcier Fou",       "tier":"elite","hp":75, "max_hp":75, "attack":25,"defense":5,  "precision":0.80,"evasion":0.10,"xp_reward":70, "gold_reward_min":22,"gold_reward_max":45,"status_chance":0.40,"possible_statuses":["burn","poison","curse"],"statuses":[],"can_defend":false,"can_use_status":true},
	{"id":"el4","name":"Assassin Masqué",   "tier":"elite","hp":80, "max_hp":80, "attack":28,"defense":6,  "precision":0.90,"evasion":0.25,"xp_reward":85, "gold_reward_min":28,"gold_reward_max":52,"status_chance":0.25,"possible_statuses":["bleed","poison"],"statuses":[],"can_defend":false,"can_use_status":true},
	{"id":"el5","name":"Géant de Pierre",   "tier":"elite","hp":150,"max_hp":150,"attack":24,"defense":18, "precision":0.55,"evasion":0.01,"xp_reward":90, "gold_reward_min":35,"gold_reward_max":60,"status_chance":0.10,"possible_statuses":["paralysis"],"statuses":[],"can_defend":true,"can_use_status":false},
]
