class_name SpellManager
extends Resource

var spell: Spell
var coords: Array[Vector2i]

func _init(newspell, newcoords) -> void:
	spell = newspell
	coords = newcoords

func get_coords() -> Array[Vector2i]:
	return coords

func get_spell() -> Spell:
	return spell
