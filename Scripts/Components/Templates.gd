extends Node

var spells_path: String = "res://Spells/Resources/"

var spell_resources: Array[Spell]
var spells: Array[SpellManager] = []

func _ready() -> void:
	spell_resources = load_all_spells()

func load_all_spells() -> Array[Spell]:
	var dir = DirAccess.open(spells_path)
	var all_spells_for_levels: Dictionary[int, Array] = {}
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".tres"):
			var current_spell = load(spells_path + file_name)
			var level = current_spell.level
			if all_spells_for_levels.has(level):
				all_spells_for_levels.get(level).append(current_spell)
			else:
				all_spells_for_levels.set(level, [current_spell])
		file_name = dir.get_next()
	
	var all_spells: Array[Spell] = []
	all_spells_for_levels.sort()
	for spell_box in all_spells_for_levels.values():
		for spell in spell_box:
			all_spells.append(spell)
	return all_spells

func add_new_spell(step: int, coords: Array[Vector2i]):
	var new_spell = SpellManager.new(spell_resources[step], coords)
	spells.append(new_spell)
	
	if spell_resources.size() > step+1:
		return spell_resources[step+1].name
