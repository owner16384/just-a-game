extends Node

var spells_path: String = "res://Spells/Resources/"

var spell_resources: Array[Spell]
var spells: Array[SpellManager] = []

func _ready() -> void:
	spell_resources = load_all_spells()

func load_all_spells() -> Array[Spell]:
	var all_spells: Array[Spell] = []
	var dir = DirAccess.open(spells_path)
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".tres"):
			var current_spell = load(spells_path + file_name)
			all_spells.append(current_spell)
		file_name = dir.get_next()
	return all_spells

func add_new_spell(step: int, coords: Array[Vector2i]):
	var new_spell = SpellManager.new(spell_resources[step], coords)
	spells.append(new_spell)
	
	if spell_resources.size() > step+1:
		return spell_resources[step+1].name
