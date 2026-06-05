extends Node
# ─────────────────────────────────────────
#  InventoryScene v3
#  Correction déséquipement et retour inventaire
# ─────────────────────────────────────────

@onready var equipped_label   : RichTextLabel = $VBox/EquippedPanel/EquippedLabel
@onready var inventory_list   : VBoxContainer = $VBox/ScrollContainer/InventoryList
@onready var info_label       : Label         = $VBox/InfoLabel
@onready var stats_label      : RichTextLabel = $VBox/StatsDetailLabel
@onready var back_btn         : Button        = $VBox/BackBtn

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	# Connexion persistante (pas ONE_SHOT)
	equipped_label.meta_clicked.connect(_on_equipped_meta_clicked)
	_refresh_all()

func _refresh_all() -> void:
	_refresh_equipped()
	_refresh_stats()
	_build_inventory()

# ─────────────────────────────────────────
#  ÉQUIPEMENT — avec liens [Retirer]
# ─────────────────────────────────────────
func _refresh_equipped() -> void:
	var txt = "[b]— Équipement actuel —[/b]\n\n"

	var wpn = PlayerData.equipped_weapon
	if wpn:
		txt += "⚔️ [b]%s[/b]  ATT+%d  [url=unequip_weapon][color=#c84040][Retirer][/color][/url]\n" % [
			wpn.get_meta("item_name","?"), wpn.get_meta("attack_bonus",0)]
	else:
		txt += "⚔️ Arme : —\n"

	var arm = PlayerData.equipped_armor
	if arm:
		txt += "🛡️ [b]%s[/b]  DEF+%d  [url=unequip_armor][color=#c84040][Retirer][/color][/url]\n" % [
			arm.get_meta("item_name","?"), arm.get_meta("defense_bonus",0)]
	else:
		txt += "🛡️ Armure : —\n"

	var s1 = PlayerData.equipped_scroll_1
	if s1:
		txt += "🔮 [b]%s[/b] (%d mana)  [url=unequip_scroll1][color=#c84040][Retirer][/color][/url]\n" % [s1.scroll_name, s1.mana_cost]
	else:
		txt += "🔮 Sort 1 : —\n"

	var s2 = PlayerData.equipped_scroll_2
	if s2:
		txt += "🔮 [b]%s[/b] (%d mana)  [url=unequip_scroll2][color=#c84040][Retirer][/color][/url]\n" % [s2.scroll_name, s2.mana_cost]
	else:
		txt += "🔮 Sort 2 : —\n"

	if PlayerData.passive_scrolls.is_empty():
		txt += "📜 Passifs : —\n"
	else:
		for i in PlayerData.passive_scrolls.size():
			var ps = PlayerData.passive_scrolls[i]
			txt += "📜 [b]%s[/b]  [url=unequip_passive_%d][color=#c84040][Retirer][/color][/url]\n" % [ps.scroll_name, i]

	equipped_label.parse_bbcode(txt)

func _on_equipped_meta_clicked(meta: Variant) -> void:
	var action = str(meta)
	match action:
		"unequip_weapon":
			if PlayerData.equipped_weapon:
				PlayerData.inventory.append(PlayerData.equipped_weapon)
				PlayerData.equipped_weapon = null
				info_label.text = "⚔️ Arme retirée et placée dans l'inventaire."
		"unequip_armor":
			if PlayerData.equipped_armor:
				PlayerData.inventory.append(PlayerData.equipped_armor)
				PlayerData.equipped_armor = null
				info_label.text = "🛡️ Armure retirée et placée dans l'inventaire."
		"unequip_scroll1":
			if PlayerData.equipped_scroll_1:
				PlayerData.inventory.append(PlayerData.equipped_scroll_1)
				PlayerData.equipped_scroll_1 = null
				info_label.text = "🔮 Sort 1 retiré."
		"unequip_scroll2":
			if PlayerData.equipped_scroll_2:
				PlayerData.inventory.append(PlayerData.equipped_scroll_2)
				PlayerData.equipped_scroll_2 = null
				info_label.text = "🔮 Sort 2 retiré."
		_:
			if action.begins_with("unequip_passive_"):
				var idx = int(action.split("_")[-1])
				if idx < PlayerData.passive_scrolls.size():
					PlayerData.inventory.append(PlayerData.passive_scrolls[idx])
					PlayerData.passive_scrolls.remove_at(idx)
					info_label.text = "📜 Passif retiré."
	_refresh_all()

# ─────────────────────────────────────────
#  STATS EFFECTIVES
# ─────────────────────────────────────────
func _refresh_stats() -> void:
	var txt = "[b]— Stats effectives —[/b]\n"
	txt += "❤️ PV [b]%d/%d[/b]   💧 Mana [b]%d/%d[/b]\n" % [
		PlayerData.current_hp, PlayerData.max_hp,
		PlayerData.current_mana, PlayerData.max_mana]
	txt += "⚔️ ATT [b]%d[/b]   🛡️ DEF [b]%d[/b]   🎯 PREC [b]%.0f%%[/b]   👟 ESQ [b]%.0f%%[/b]\n" % [
		PlayerData.get_effective_attack(),
		PlayerData.get_effective_defense(),
		PlayerData.get_effective_precision() * 100,
		PlayerData.get_effective_evasion() * 100]
	txt += "🍀 CHA [b]%.0f%%[/b]   ⭐ Niv.[b]%d[/b]   💰 [b]%d[/b] or\n" % [
		PlayerData.chance * 100, PlayerData.level, PlayerData.gold]
	if not PlayerData.traits.is_empty():
		txt += "✨ Traits : [b]" + "  •  ".join(PlayerData.traits) + "[/b]\n"
	stats_label.parse_bbcode(txt)

# ─────────────────────────────────────────
#  INVENTAIRE
# ─────────────────────────────────────────
func _build_inventory() -> void:
	# Nettoie la liste
	for child in inventory_list.get_children():
		child.queue_free()

	if PlayerData.inventory.is_empty():
		var lbl = Label.new()
		lbl.text = "Inventaire vide."
		inventory_list.add_child(lbl)
		return

	for item in PlayerData.inventory:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.autowrap_mode       = TextServer.AUTOWRAP_WORD
		btn.text                = _item_label(item)
		btn.pressed.connect(_on_item_pressed.bind(item))
		inventory_list.add_child(btn)

func _item_label(item) -> String:
	if item is ScrollResource:
		if item.scroll_type == "active":
			return "🔮 %s  [Actif - %d mana]  %s" % [item.scroll_name, item.mana_cost, item.description]
		return "📜 %s  [Passif]  %s" % [item.scroll_name, item.description]
	if item is Object and item.has_meta("item_name"):
		var tags = []
		if item.get_meta("is_sword",  false): tags.append("Épée")
		if item.get_meta("is_shield", false): tags.append("Bouclier")
		var tag = "  [%s]" % "  ".join(tags) if not tags.is_empty() else ""
		return "%s%s  ATT+%d  DEF+%d" % [
			item.get_meta("item_name","?"), tag,
			item.get_meta("attack_bonus",0),
			item.get_meta("defense_bonus",0)]
	return "Item inconnu"

func _on_item_pressed(item) -> void:
	if item is ScrollResource:
		_equip_scroll(item)
		_refresh_all()
		return
	if not (item is Object and item.has_meta("item_name")):
		return
	# Consommables et équipables gérés dans _equip_gear
	# (qui vérifie special en priorité)
	_equip_gear(item)
	_refresh_all()

func _equip_scroll(scroll: ScrollResource) -> void:
	if scroll.scroll_type == "passive":
		PlayerData.add_passive_scroll(scroll)
		info_label.text = "📜 Passif équipé : %s" % scroll.scroll_name
		return
	# Slot 1 libre → slot 1, sinon slot 2, sinon swap slot 1
	if PlayerData.equipped_scroll_1 == null:
		PlayerData.equip_scroll(scroll, 1)
		info_label.text = "🔮 Sort équipé en slot 1."
	elif PlayerData.equipped_scroll_2 == null:
		PlayerData.equip_scroll(scroll, 2)
		info_label.text = "🔮 Sort équipé en slot 2."
	else:
		PlayerData.inventory.append(PlayerData.equipped_scroll_1)
		PlayerData.equipped_scroll_1 = scroll
		PlayerData.inventory.erase(scroll)
		info_label.text = "🔄 Sort 1 remplacé."
	AchievementSystem.check_equipment()

func _equip_gear(item) -> void:
	# Vérifie d'abord si c'est un consommable
	var special = item.get_meta("special", "")
	match special:
		"heal_on_pickup":
			var hp = item.get_meta("hp_bonus", 0)
			PlayerData.heal(hp)
			Notifier.heal_notif(hp)
			PlayerData.inventory.erase(item)
			info_label.text = "💚 Potion utilisée : +%d PV !" % hp
			return
		"revive":
			PlayerData.has_revive_item = true
			PlayerData.inventory.erase(item)
			info_label.text = "✨ Orbe de résurrection activé !"
			return
		"restart_combat":
			PlayerData.has_restart_combat_item = true
			PlayerData.inventory.erase(item)
			info_label.text = "🔄 Cristal de reset activé !"
			return

	# Sinon équipement normal
	var atk      = item.get_meta("attack_bonus",  0)
	var def_val  = item.get_meta("defense_bonus", 0)
	var is_sword  = item.get_meta("is_sword",  false)
	var is_shield = item.get_meta("is_shield", false)
	if atk > 0 or is_sword:
		if PlayerData.equipped_weapon != null:
			PlayerData.inventory.append(PlayerData.equipped_weapon)
		PlayerData.equipped_weapon = item
		PlayerData.inventory.erase(item)
		info_label.text = "⚔️ Arme équipée : %s" % item.get_meta("item_name","?")
	elif def_val > 0 or is_shield:
		if PlayerData.equipped_armor != null:
			PlayerData.inventory.append(PlayerData.equipped_armor)
		PlayerData.equipped_armor = item
		PlayerData.inventory.erase(item)
		info_label.text = "🛡️ Armure équipée : %s" % item.get_meta("item_name","?")
	else:
		info_label.text = "❓ Non équipable directement."
	AchievementSystem.check_equipment()

func _on_back() -> void:
	# Retourne vers la scène d'origine
	match GameManager.previous_scene:
		"combat": get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
		"market": get_tree().change_scene_to_file("res://scenes/MarketScene.tscn")
		_:        get_tree().change_scene_to_file("res://scenes/MapScene.tscn")
