extends CanvasLayer
# ─────────────────────────────────────────
#  Notifier.gd — Autoload
#  Affiche des notifications flottantes temporaires.
#  Usage : Notifier.show("⭐ CRITIQUE !", Color("#FFD700"))
# ─────────────────────────────────────────

const DURATION   = 2.0   # secondes
const FLOAT_DIST = 60.0  # pixels vers le haut
const MAX_NOTIFS = 5

var _active: Array = []

func _ready() -> void:
	layer = 20  # au-dessus de tout

func show_notif(text: String, color: Color = Color("#e8dcc8")) -> void:
	# Limite le nombre de notifs simultanées
	if _active.size() >= MAX_NOTIFS:
		var oldest = _active.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Position : centre haut de l'écran, décalé selon le nombre actif
	var vp = get_viewport().get_visible_rect()
	lbl.position = Vector2(
		vp.size.x / 2.0 - 150,
		vp.size.y * 0.25 + _active.size() * 32
	)
	lbl.size = Vector2(300, 30)
	add_child(lbl)
	_active.append(lbl)

	# Animation : monte et disparaît
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - FLOAT_DIST, DURATION)
	tween.tween_property(lbl, "modulate:a", 0.0, DURATION).set_delay(DURATION * 0.5)
	tween.tween_callback(func():
		_active.erase(lbl)
		if is_instance_valid(lbl):
			lbl.queue_free()
	).set_delay(DURATION)

# ── Raccourcis thématiques ──
func critical(text: String = "⭐ CRITIQUE !") -> void:
	show_notif(text, Color("#FFD700"))

func level_up_notif(level: int) -> void:
	show_notif("⬆️ NIVEAU %d !" % level, Color("#50c878"))

func status_notif(status: String) -> void:
	show_notif(status, Color("#c85050"))

func gold_notif(amount: int) -> void:
	show_notif("+%d 💰" % amount, Color("#c8a96e"))

func heal_notif(amount: int) -> void:
	show_notif("+%d ❤️" % amount, Color("#50a050"))

func damage_notif(amount: int) -> void:
	show_notif("-%d 💔" % amount, Color("#c84040"))
