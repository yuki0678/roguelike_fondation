extends Resource
class_name ClassResource

# ─────────────────────────────────────────
#  ClassResource
#  Définit une classe joueur (pour l'écran de sélection).
# ─────────────────────────────────────────

@export var class_id: String = "civil"
@export var class_name_display: String = "Civil"
@export var description: String = ""
@export var strengths: Array[String] = []
@export var weaknesses: Array[String] = []

# Modificateurs de stats (appliqués via PlayerData.apply_class)
# Les vraies valeurs sont dans PlayerData.apply_class()
# Ici c'est juste pour l'affichage dans l'UI
@export var stat_preview: Dictionary = {}
# ex: { "attack": +15, "defense": +10, "hp": +20 }
