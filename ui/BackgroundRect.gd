extends ColorRect
# ─────────────────────────────────────────
#  BackgroundRect.gd
#  À attacher à un ColorRect couvrant toute la fenêtre.
#  Donne un fond sombre uniforme à toutes les scènes.
# ─────────────────────────────────────────

func _ready() -> void:
	color = Color("#0d0f14")
	anchor_right  = 1.0
	anchor_bottom = 1.0
	offset_left   = 0
	offset_top    = 0
	offset_right  = 0
	offset_bottom = 0
	# Derrière tout le reste
	z_index = -1
