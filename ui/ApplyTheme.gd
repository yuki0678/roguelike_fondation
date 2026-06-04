extends Node
# ─────────────────────────────────────────
#  ApplyTheme.gd
#  Autoload — applique le thème global à toute nouvelle scène.
# ─────────────────────────────────────────

const THEME_PATH = "res://ui/theme_dark.tres"
var _theme: Theme = null

func _ready() -> void:
	_load_theme()
	get_tree().node_added.connect(_on_node_added)

func _load_theme() -> void:
	if ResourceLoader.exists(THEME_PATH):
		_theme = load(THEME_PATH)

func _on_node_added(node: Node) -> void:
	if _theme == null:
		return
	if node is Control:
		if node.theme == null:
			node.theme = _theme
