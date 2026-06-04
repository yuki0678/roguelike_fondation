extends Node

# ─────────────────────────────────────────
#  MarketScene.gd
# ─────────────────────────────────────────

@onready var wave_label    : Label         = $VBox/WaveLabel
@onready var gold_label    : Label         = $VBox/GoldLabel
@onready var stats_label   : RichTextLabel = $VBox/StatsLabel
@onready var items_panel   : VBoxContainer = $VBox/ItemsPanel
@onready var sauna_btn     : Button        = $VBox/SaunaBtn
@onready var trait_btn     : Button        = $VBox/TraitBtn
@onready var leave_btn     : Button        = $VBox/LeaveBtn
@onready var log_label     : Label         = $VBox/LogLabel

var market_items: Array = []
# On sépare les boutons du marché et les éléments de l'interface pour éviter les crashs d'index
var market_buttons: Array = [] 
var cleanup_elements: Array = []

const SAUNA_BASE_PRICE = 30

const ITEM_POOL = [
	{"name": "Épée rouillée",        "type": "weapon",        "rarity": "common",  "attack_bonus": 5,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 15, "is_sword": true,  "is_shield": false, "special": ""},
	{"name": "Bouclier de bois",     "type": "armor",         "rarity": "common",  "attack_bonus": 0,  "defense_bonus": 4,  "hp_bonus": 0,  "price": 12, "is_sword": false, "is_shield": true,  "special": ""},
	{"name": "Dague acérée",         "type": "weapon",        "rarity": "rare",    "attack_bonus": 8,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 25, "is_sword": false, "is_shield": false, "special": ""},
	{"name": "Armure de cuir",       "type": "armor",         "rarity": "common",  "attack_bonus": 0,  "defense_bonus": 6,  "hp_bonus": 5,  "price": 20, "is_sword": false, "is_shield": false, "special": ""},
	{"name": "Potion de vie",        "type": "consumable",    "rarity": "common",  "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 30, "price": 18, "is_sword": false, "is_shield": false, "special": "heal_on_pickup"},
	{"name": "Amulette chanceux",    "type": "consumable",    "rarity": "rare",    "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 30, "is_sword": false, "is_shield": false, "special": "double_loot"},
	{"name": "Épée longue",          "type": "weapon",        "rarity": "rare",    "attack_bonus": 12, "defense_bonus": 0,  "hp_bonus": 0,  "price": 35, "is_sword": true,  "is_shield": false, "special": ""},
	{"name": "Bouclier de fer",      "type": "armor",         "rarity": "rare",    "attack_bonus": 0,  "defense_bonus": 9,  "hp_bonus": 0,  "price": 32, "is_sword": false, "is_shield": true,  "special": ""},
	{"name": "Anneau de mana",       "type": "consumable",    "rarity": "rare",    "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 28, "is_sword": false, "is_shield": false, "special": "mana_bonus"},
	{"name": "Lame de sang",         "type": "weapon",        "rarity": "epic",    "attack_bonus": 18, "defense_bonus": 0,  "hp_bonus": 0,  "price": 60, "is_sword": true,  "is_shield": false, "special": ""},
	{"name": "Armure de plaques",    "type": "armor",         "rarity": "epic",    "attack_bonus": 0,  "defense_bonus": 15, "hp_bonus": 10, "price": 65, "is_sword": false, "is_shield": false, "special": ""},
	{"name": "Orbe de résurrection", "type": "special",        "rarity": "epic",    "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 80, "is_sword": false, "is_shield": false, "special": "revive"},
	{"name": "Cristal de reset",     "type": "special",        "rarity": "rare",    "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 45, "is_sword": false, "is_shield": false, "special": "restart_combat"},
	{"name": "Parchemin : Boule de Feu",    "type": "scroll_active",  "rarity": "rare",    "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 30, "is_sword": false, "is_shield": false, "special": "scroll_fireball"},
	{"name": "Parchemin : Soin",            "type": "scroll_active",  "rarity": "rare",    "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 28, "is_sword": false, "is_shield": false, "special": "scroll_heal"},
	{"name": "Parchemin : Bouclier Arcanique", "type": "scroll_active", "rarity": "rare",  "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 32, "is_sword": false, "is_shield": false, "special": "scroll_shield"},
	{"name": "Parchemin : Malédiction",     "type": "scroll_active",  "rarity": "epic",    "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 55, "is_sword": false, "is_shield": false, "special": "scroll_curse"},
	{"name": "Parchemin : Téléportation",   "type": "scroll_active",  "rarity": "epic",    "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 60, "is_sword": false, "is_shield": false, "special": "scroll_flee"},
	{"name": "Parchemin : Peau de Pierre",  "type": "scroll_passive", "rarity": "rare",    "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 25, "is_sword": false, "is_shield": false, "special": "scroll_stone_skin"},
	{"name": "Parchemin : Oeil de Lynx",    "type": "scroll_passive", "rarity": "rare",    "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 25, "is_sword": false, "is_shield": false, "special": "scroll_lynx_eye"},
	{"name": "Parchemin : Régénération",    "type": "scroll_passive", "rarity": "rare",    "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 28, "is_sword": false, "is_shield": false, "special": "scroll_regen"},
	{"name": "Parchemin : Résonance Magique","type": "scroll_passive", "rarity": "epic",   "attack_bonus": 0,  "defense_bonus": 0,  "hp_bonus": 0,  "price": 45, "is_sword": false, "is_shield": false, "special": "scroll_mana_resonance"},
]

const TRAIT_POOL = [
	{"id": "berserker", "label": "🩸 Berserker",  "desc": "+50% ATT / -40% DEF",                       "price": 80},
	{"id": "beni",      "label": "🍀 Béni",        "desc": "+40% CHA / Événements 2x plus extrêmes",     "price": 80},
	{"id": "traqueur",  "label": "👁️ Traqueur",   "desc": "+35% PREC / Duos +50% fréquents",            "price": 80},
	{"id": "fantome",   "label": "🌀 Fantôme",     "desc": "+40% ESQ / -30% PV max",                    "price": 80},
	{"id": "frenesie",  "label": "⚡ Frénésie",    "desc": "2 actions/tour / PV bloqués à 50%",          "price": 80},
	{"id": "cupide",    "label": "💎 Cupide",       "desc": "+100% or / Marché 2x plus cher",             "price": 80},
	{"id": "chaotique", "label": "🎲 Chaotique",   "desc": "D20→D30 / 1-5 = fumble catastrophique",      "price": 80},
	{"id": "maudit",    "label": "💀 Maudit",       "desc": "Items rang+ / 1 item détruit/10 vagues",     "price": 80},
]

var available_trait: Dictionary = {}

# ─────────────────────────────────────────
func _ready() -> void:
	PlayerData.markets_visited += 1
	_generate_market()
	_refresh_ui()
	_build_ui()
	sauna_btn.pressed.connect(_on_sauna_pressed)
	trait_btn.pressed.connect(_on_trait_pressed)
	leave_btn.pressed.connect(_on_leave_pressed)

func _generate_market() -> void:
	var pool = ITEM_POOL.duplicate()
	pool.shuffle()
	market_items = pool.slice(0, 3)
	var available_traits = TRAIT_POOL.filter(func(t): return not (t["id"] in PlayerData.traits))
	if not available_traits.is_empty():
		available_trait = available_traits[randi() % available_traits.size()]
	else:
		available_trait = {}

func _get_price(base_price: int) -> int:
	var visits = PlayerData.markets_visited
	var multiplier = 1.0 + (visits - 1) * 0.10
	if "cupide" in PlayerData.traits:
		multiplier = 1.0 + (visits - 1) * 0.30
	return int(base_price * multiplier)

# ─────────────────────────────────────────
func _build_ui() -> void:
	# 1. Nettoyage complet
	for btn in market_buttons:
		if is_instance_valid(btn): btn.queue_free()
	market_buttons.clear()

	for node in cleanup_elements:
		if is_instance_valid(node): node.queue_free()
	cleanup_elements.clear()

	# 2. Génération des objets du marché (Achat)
	for i in market_items.size():
		var item = market_items[i]
		var price = _get_price(item["price"])
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 50)
		var rarity_icon = _rarity_icon(item["rarity"])
		btn.text = "%s %s  [%s]  +ATT:%d +DEF:%d +PV:%d  —  💰 %d" % [
			rarity_icon, item["name"], item["rarity"],
			item["attack_bonus"], item["defense_bonus"], item["hp_bonus"], price
		]
		btn.disabled = PlayerData.gold < price
		btn.pressed.connect(_on_item_bought.bind(i, price))
		items_panel.add_child(btn)
		market_buttons.append(btn)

	# 3. Section vente
	var sell_title = Label.new()
	sell_title.text = "💰 Vendre un item :"
	items_panel.add_child(sell_title)
	cleanup_elements.append(sell_title)

	for item in PlayerData.inventory:
		if item is Object and item.has_meta("item_name"):
			var sell_btn = Button.new()
			var sell_price = int(item.get_meta("base_price", 10) * 0.5)
			sell_btn.text = "Vendre : %s  +%d or" % [item.get_meta("item_name", "?"), sell_price]
			sell_btn.custom_minimum_size = Vector2(0, 40)
			sell_btn.pressed.connect(_on_item_sold.bind(item, sell_price))
			items_panel.add_child(sell_btn)
			cleanup_elements.append(sell_btn)

	# 4. Mise à jour du bouton Sauna
	var sauna_price = _get_price(SAUNA_BASE_PRICE)
	sauna_btn.text = "🛁 Sauna — Heal 100%% PV  —  💰 %d" % sauna_price
	sauna_btn.disabled = PlayerData.gold < sauna_price or PlayerData.current_hp == PlayerData.max_hp
	sauna_btn.set_meta("price", sauna_price)

	# 5. Mise à jour du bouton Trait Mythique
	if not available_trait.is_empty() and PlayerData.traits.size() < 2:
		var trait_price = _get_price(available_trait["price"])
		trait_btn.text = "🌟 TRAIT MYTHIQUE : %s\n%s  —  💰 %d" % [
			available_trait["label"], available_trait["desc"], trait_price
		]
		trait_btn.disabled = PlayerData.gold < trait_price
		trait_btn.set_meta("price", trait_price)
		trait_btn.visible = true
	else:
		trait_btn.visible = false


func _on_item_sold(item, price: int) -> void:
	PlayerData.gold += price
	PlayerData.inventory.erase(item)
	_set_log("💰 Vendu pour %d or !" % price)
	_refresh_ui()
	_build_ui() # On reconstruit l'UI pour actualiser la liste des ventes

func _rarity_icon(rarity: String) -> String:
	match rarity:
		"common":    return "⬜"
		"rare":      return "🔵"
		"epic":      return "🟣"
		"mythic":    return "🔴"
		"legendary": return "🟡"
		_:           return "⬜"

# ─────────────────────────────────────────
func _on_item_bought(index: int, price: int) -> void:
	if PlayerData.gold < price:
		_set_log("❌ Pas assez d'or !")
		return
	PlayerData.gold -= price
	RunStats.record_item_bought()
	AchievementSystem.check_gold(PlayerData.gold)
	var item = market_items[index]
	_apply_item(item)
	
	# Désactive uniquement le bouton cliqué
	market_buttons[index].disabled = true
	market_buttons[index].text = "✅ " + market_buttons[index].text
	_set_log("✅ Acheté : %s !" % item["name"])
	
	_refresh_ui()
	_build_ui() # Il vaut mieux reconstruire pour mettre à jour la partie "Vente" directement

func _apply_item(item: Dictionary) -> void:
	match item["special"]:
		"heal_on_pickup", "revive", "restart_combat":
			PlayerData.add_item(_dict_to_fake_resource(item))
		"double_loot":
			pass
		"mana_bonus":
			PlayerData.max_mana += 3
			PlayerData.restore_mana(3)
		"scroll_fireball":
			PlayerData.add_item(_make_scroll_fireball())
			_set_log("🔮 Parchemin ajouté à l'inventaire !")
		"scroll_heal":
			PlayerData.add_item(_make_scroll_heal())
			_set_log("🔮 Parchemin ajouté à l'inventaire !")
		"scroll_shield":
			PlayerData.add_item(_make_scroll_shield())
			_set_log("🔮 Parchemin ajouté à l'inventaire !")
		"scroll_curse":
			PlayerData.add_item(_make_scroll_curse())
			_set_log("🔮 Parchemin ajouté à l'inventaire !")
		"scroll_flee":
			PlayerData.add_item(_make_scroll_flee())
			_set_log("🔮 Parchemin ajouté à l'inventaire !")
		"scroll_stone_skin":
			PlayerData.add_item(_make_scroll_passive("Peau de Pierre", "defense_bonus", 0.15, "+15% Défense permanente"))
			_set_log("📜 Parchemin passif ajouté à l'inventaire !")
		"scroll_lynx_eye":
			PlayerData.add_item(_make_scroll_passive("Oeil de Lynx", "precision_bonus", 0.20, "+20% Précision permanente"))
			_set_log("📜 Parchemin passif ajouté à l'inventaire !")
		"scroll_regen":
			PlayerData.add_item(_make_scroll_passive("Régénération Lente", "hp_regen", 2.0, "Récupère 2 PV par vague"))
			_set_log("📜 Parchemin passif ajouté à l'inventaire !")
		"scroll_mana_resonance":
			PlayerData.add_item(_make_scroll_passive("Résonance Magique", "mana_max_bonus", 1.0, "+1 Mana max par sort actif"))
			_set_log("📜 Parchemin passif ajouté à l'inventaire !")
		_:
			# CAS PAR DÉFAUT UNIQUE : Pour les armes, armures et objets sans spécialités
			if item["attack_bonus"] > 0:  PlayerData.attack += item["attack_bonus"]
			if item["defense_bonus"] > 0: PlayerData.defense += item["defense_bonus"]
			if item["hp_bonus"] > 0:
				PlayerData.max_hp += item["hp_bonus"]
				PlayerData.current_hp = min(PlayerData.current_hp + item["hp_bonus"], PlayerData.max_hp)
			if item.get("mana_bonus", 0) > 0:
				PlayerData.max_mana += item["mana_bonus"]
			if item["type"] in ["weapon", "armor"]:
				PlayerData.add_item(_dict_to_fake_resource(item))

# ─────────────────────────────────────────
#  FABRICATION DES PARCHEMINS
# ─────────────────────────────────────────
func _make_scroll_fireball() -> ScrollResource:
	var s = ScrollResource.new()
	s.scroll_name = "Boule de Feu"
	s.description = "Dégâts magiques élevés"
	s.scroll_type = "active"
	s.mana_cost = 3
	s.effect_type = "damage"
	s.base_value = 25
	s.d20_high_threshold = 15
	s.d20_high_effect = "burn"
	s.status_duration = 2
	return s

func _make_scroll_heal() -> ScrollResource:
	var s = ScrollResource.new()
	s.scroll_name = "Soin"
	s.description = "Restaure des PV"
	s.scroll_type = "active"
	s.mana_cost = 3
	s.effect_type = "heal"
	s.base_value = 30
	s.d20_high_threshold = 18
	s.d20_low_threshold = 0
	return s

func _make_scroll_shield() -> ScrollResource:
	var s = ScrollResource.new()
	s.scroll_name = "Bouclier Arcanique"
	s.description = "Absorbe les dégâts du prochain tour"
	s.scroll_type = "active"
	s.mana_cost = 2
	s.effect_type = "shield"
	s.base_value = 20
	s.d20_high_threshold = 18
	s.d20_low_threshold = 5
	s.d20_low_effect = "shield_break"
	return s

func _make_scroll_curse() -> ScrollResource:
	var s = ScrollResource.new()
	s.scroll_name = "Malédiction"
	s.description = "Réduit les stats ennemies pour 3 tours"
	s.scroll_type = "active"
	s.mana_cost = 3
	s.effect_type = "debuff"
	s.base_value = 0
	s.d20_high_threshold = 20
	s.d20_low_threshold = 3
	s.d20_low_effect = "curse"
	s.status_duration = 3
	return s

func _make_scroll_flee() -> ScrollResource:
	var s = ScrollResource.new()
	s.scroll_name = "Téléportation"
	s.description = "Fuis le combat sans pénalité"
	s.scroll_type = "active"
	s.mana_cost = 4
	s.effect_type = "flee"
	s.base_value = 0
	s.d20_low_threshold = 10
	return s

func _make_scroll_passive(sname: String, ptype: String, val: float, desc: String) -> ScrollResource:
	var s = ScrollResource.new()
	s.scroll_name = sname
	s.description = desc
	s.scroll_type = "passive"
	s.passive_type = ptype
	s.value = val
	return s

# ─────────────────────────────────────────
func _dict_to_fake_resource(item: Dictionary) -> Object:
	var obj = RefCounted.new()
	obj.set_meta("attack_bonus",  item["attack_bonus"])
	obj.set_meta("defense_bonus", item["defense_bonus"])
	obj.set_meta("is_sword",      item.get("is_sword", false))
	obj.set_meta("is_shield",     item.get("is_shield", false))
	obj.set_meta("item_name",     item["name"])
	obj.set_meta("special",        item.get("special", ""))
	obj.set_meta("hp_bonus",      item.get("hp_bonus", 0))
	obj.set_meta("mana_bonus",    item.get("mana_bonus", 0))
	obj.set_meta("base_price", item.get("price", 10))
	return obj

func _on_sauna_pressed() -> void:
	var price = sauna_btn.get_meta("price")
	if PlayerData.gold < price:
		_set_log("❌ Pas assez d'or !")
		return
	PlayerData.gold -= price
	PlayerData.heal_percent(1.0)
	sauna_btn.disabled = true
	sauna_btn.text = "✅ " + sauna_btn.text
	_set_log("🛁 Soin complet ! PV restaurés à %d/%d" % [PlayerData.current_hp, PlayerData.max_hp])
	_refresh_ui()
	_update_buttons()

func _on_trait_pressed() -> void:
	var price = trait_btn.get_meta("price")
	if PlayerData.gold < price:
		_set_log("❌ Pas assez d'or !")
		return
	if PlayerData.traits.size() >= 2:
		_set_log("❌ Tu as déjà 2 traits !")
		return
	PlayerData.gold -= price
	PlayerData.add_trait(available_trait["id"])
	trait_btn.disabled = true
	trait_btn.text = "✅ Trait obtenu : " + available_trait["label"]
	_set_log("🌟 Trait obtenu : %s !" % available_trait["label"])
	_refresh_ui()
	_update_buttons()

func _on_leave_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MapScene.tscn")

# ─────────────────────────────────────────
func _refresh_ui() -> void:
	wave_label.text = "🏪 Marché  —  Vague %d" % GameManager.current_wave
	gold_label.text = "💰 Or : %d" % PlayerData.gold
	var txt = "❤️ %d/%d   💧 %d/%d   ATT %d   DEF %d" % [
		PlayerData.current_hp, PlayerData.max_hp,
		PlayerData.current_mana, PlayerData.max_mana,
		PlayerData.get_effective_attack(), PlayerData.get_effective_defense()
	]
	if not PlayerData.traits.is_empty():
		txt += "\nTraits : " + "  ".join(PlayerData.traits)
	stats_label.parse_bbcode(txt)

func _update_buttons() -> void:
	# Ne vérifie désormais que les boutons de la boutique d'achat (qui font toujours la taille de market_items)
	for i in market_buttons.size():
		if not market_buttons[i].disabled:
			var price = _get_price(market_items[i]["price"])
			market_buttons[i].disabled = PlayerData.gold < price
			
	var sauna_price = sauna_btn.get_meta("price") if sauna_btn.has_meta("price") else SAUNA_BASE_PRICE
	if not sauna_btn.disabled:
		sauna_btn.disabled = PlayerData.gold < sauna_price or PlayerData.current_hp == PlayerData.max_hp
		
	if trait_btn.visible and not trait_btn.disabled:
		var trait_price = trait_btn.get_meta("price") if trait_btn.has_meta("price") else 80
		trait_btn.disabled = PlayerData.gold < trait_price or PlayerData.traits.size() >= 2

func _set_log(text: String) -> void:
	log_label.text = text
