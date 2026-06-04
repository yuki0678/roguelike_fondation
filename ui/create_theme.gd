@tool
extends EditorScript
# ─────────────────────────────────────────
#  create_theme.gd
#  Lance ce script depuis Godot : Fichier → Exécuter le script
#  Il crée res://ui/theme_dark.tres avec toute la palette.
# ─────────────────────────────────────────

func _run() -> void:
	var theme = Theme.new()

	# ── PALETTE ──
	var bg_dark    = Color("#0d0f14")   # fond principal
	var bg_panel   = Color("#151820")   # panneaux
	var bg_hover   = Color("#1e2330")   # survol
	var accent     = Color("#c8a96e")   # or / accent principal
	var accent_dim = Color("#8a7048")   # or sombre
	var text_main  = Color("#e8dcc8")   # texte principal (parchemin)
	var text_dim   = Color("#7a7060")   # texte secondaire
	var red_hp     = Color("#c94040")   # PV / danger
	var blue_mana  = Color("#4080c8")   # mana
	var green_ok   = Color("#50a050")   # succès
	var border     = Color("#2a2e3a")   # bordures

	# ── FONT SIZES ──
	theme.default_font_size = 15

	# ── PANEL ──
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = bg_panel
	panel_style.border_width_left   = 1
	panel_style.border_width_right  = 1
	panel_style.border_width_top    = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = border
	panel_style.corner_radius_top_left     = 4
	panel_style.corner_radius_top_right    = 4
	panel_style.corner_radius_bottom_left  = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.content_margin_left   = 10
	panel_style.content_margin_right  = 10
	panel_style.content_margin_top    = 8
	panel_style.content_margin_bottom = 8
	theme.set_stylebox("panel", "Panel", panel_style)
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	# ── BUTTON NORMAL ──
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = bg_hover
	btn_normal.border_width_left   = 1
	btn_normal.border_width_right  = 1
	btn_normal.border_width_top    = 1
	btn_normal.border_width_bottom = 1
	btn_normal.border_color = accent_dim
	btn_normal.corner_radius_top_left     = 4
	btn_normal.corner_radius_top_right    = 4
	btn_normal.corner_radius_bottom_left  = 4
	btn_normal.corner_radius_bottom_right = 4
	btn_normal.content_margin_left   = 12
	btn_normal.content_margin_right  = 12
	btn_normal.content_margin_top    = 8
	btn_normal.content_margin_bottom = 8

	# BUTTON HOVER
	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color("#252a38")
	btn_hover.border_width_left   = 1
	btn_hover.border_width_right  = 1
	btn_hover.border_width_top    = 1
	btn_hover.border_width_bottom = 1
	btn_hover.border_color = accent
	btn_hover.corner_radius_top_left     = 4
	btn_hover.corner_radius_top_right    = 4
	btn_hover.corner_radius_bottom_left  = 4
	btn_hover.corner_radius_bottom_right = 4
	btn_hover.content_margin_left   = 12
	btn_hover.content_margin_right  = 12
	btn_hover.content_margin_top    = 8
	btn_hover.content_margin_bottom = 8

	# BUTTON PRESSED
	var btn_pressed = StyleBoxFlat.new()
	btn_pressed.bg_color = Color("#1a1e28")
	btn_pressed.border_width_left   = 2
	btn_pressed.border_width_right  = 2
	btn_pressed.border_width_top    = 2
	btn_pressed.border_width_bottom = 2
	btn_pressed.border_color = accent
	btn_pressed.corner_radius_top_left     = 4
	btn_pressed.corner_radius_top_right    = 4
	btn_pressed.corner_radius_bottom_left  = 4
	btn_pressed.corner_radius_bottom_right = 4
	btn_pressed.content_margin_left   = 12
	btn_pressed.content_margin_right  = 12
	btn_pressed.content_margin_top    = 8
	btn_pressed.content_margin_bottom = 8

	# BUTTON DISABLED
	var btn_disabled = StyleBoxFlat.new()
	btn_disabled.bg_color = Color("#101318")
	btn_disabled.border_width_left   = 1
	btn_disabled.border_width_right  = 1
	btn_disabled.border_width_top    = 1
	btn_disabled.border_width_bottom = 1
	btn_disabled.border_color = Color("#252830")
	btn_disabled.corner_radius_top_left     = 4
	btn_disabled.corner_radius_top_right    = 4
	btn_disabled.corner_radius_bottom_left  = 4
	btn_disabled.corner_radius_bottom_right = 4
	btn_disabled.content_margin_left   = 12
	btn_disabled.content_margin_right  = 12
	btn_disabled.content_margin_top    = 8
	btn_disabled.content_margin_bottom = 8

	theme.set_stylebox("normal",   "Button", btn_normal)
	theme.set_stylebox("hover",    "Button", btn_hover)
	theme.set_stylebox("pressed",  "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)

	# BUTTON COLORS
	theme.set_color("font_color",          "Button", text_main)
	theme.set_color("font_hover_color",    "Button", accent)
	theme.set_color("font_pressed_color",  "Button", accent)
	theme.set_color("font_disabled_color", "Button", text_dim)

	# ── LABEL ──
	theme.set_color("font_color", "Label", text_main)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))

	# ── RICH TEXT LABEL ──
	theme.set_color("default_color", "RichTextLabel", text_main)
	theme.set_color("font_shadow_color", "RichTextLabel", Color(0, 0, 0, 0.5))
	var rtl_bg = StyleBoxFlat.new()
	rtl_bg.bg_color = bg_panel
	rtl_bg.corner_radius_top_left     = 4
	rtl_bg.corner_radius_top_right    = 4
	rtl_bg.corner_radius_bottom_left  = 4
	rtl_bg.corner_radius_bottom_right = 4
	rtl_bg.content_margin_left   = 8
	rtl_bg.content_margin_right  = 8
	rtl_bg.content_margin_top    = 6
	rtl_bg.content_margin_bottom = 6
	theme.set_stylebox("normal", "RichTextLabel", rtl_bg)

	# ── SEPARATOR ──
	var sep_style = StyleBoxLine.new()
	sep_style.color = border
	sep_style.thickness = 1
	theme.set_stylebox("separator", "HSeparator", sep_style)

	# ── SCROLL CONTAINER ──
	var scroll_bg = StyleBoxFlat.new()
	scroll_bg.bg_color = bg_dark
	theme.set_stylebox("panel", "ScrollContainer", scroll_bg)

	# ── PROGRESS BAR ──
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = bg_hover
	pb_bg.corner_radius_top_left     = 3
	pb_bg.corner_radius_top_right    = 3
	pb_bg.corner_radius_bottom_left  = 3
	pb_bg.corner_radius_bottom_right = 3
	var pb_fill = StyleBoxFlat.new()
	pb_fill.bg_color = accent
	pb_fill.corner_radius_top_left     = 3
	pb_fill.corner_radius_top_right    = 3
	pb_fill.corner_radius_bottom_left  = 3
	pb_fill.corner_radius_bottom_right = 3
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill",       "ProgressBar", pb_fill)
	theme.set_color("font_color", "ProgressBar", text_main)

	# ── Sauvegarde ──
	var err = ResourceSaver.save(theme, "res://ui/theme_dark.tres")
	if err == OK:
		print("✅ Thème sauvegardé dans res://ui/theme_dark.tres")
	else:
		print("❌ Erreur sauvegarde thème : ", err)
