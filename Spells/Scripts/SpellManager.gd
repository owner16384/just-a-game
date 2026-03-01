class_name SpellManager
extends Resource

var spell: Spell
var coords: Array[Vector2i]

var level: int = 1:
	set(value):
		level = value
		check_power()
var xp: int = 0:
	set(value):
		xp = value
		check_level()

var power: float

func _init(newspell, newcoords) -> void:
	spell = newspell
	coords = newcoords
	
	power = spell.default_power

func check_level():
	var needed_xp: float = (level-1)*50 + level*50
	level = int(float(xp)/needed_xp)
func check_power():
	power = spell.default_power + spell.default_power/level

#region --Callable Functions
func get_coords() -> Array[Vector2i]:
	return coords
func get_spell() -> Spell:
	return spell
func get_level() -> int:
	return level
func get_xp() -> int:
	return xp
func get_power() -> float:
	return power

func set_coords(new: Array[Vector2i]):
	coords = new
func set_xp(new: int):
	xp = new
#endregion
