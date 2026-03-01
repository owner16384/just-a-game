class_name SpellManager
extends Resource

var spell: Spell
var coords: Array[Vector2i]

var level: int = 1
var xp: int = 0:
	set(value):
		xp = value
		check_level()

func _init(newspell, newcoords) -> void:
	spell = newspell
	coords = newcoords

func check_level():
	var needed_xp = (level-1)*50 + level*50
	level = int(xp/needed_xp)

#region Some Callable Functions
func get_coords() -> Array[Vector2i]:
	return coords
func get_spell() -> Spell:
	return spell
func get_level() -> int:
	return level
func get_xp() -> int:
	return xp

func set_coords(new: Array[Vector2i]):
	coords = new
func set_level(new: int):
	level = new
func set_xp(new: int):
	xp = new
#endregion
