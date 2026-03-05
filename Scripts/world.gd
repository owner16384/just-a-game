extends Node3D

@onready var mesh_scene: PackedScene = preload("res://Scenes/3d_drawing_mesh.tscn")

func _ready() -> void:
	EventBus.connect("create_new_mesh", create_new_mesh)

func create_new_mesh(function: Callable):
	# creates a new mesh for drawing
	
	var new_mesh: MeshInstance3D = mesh_scene.instantiate()
	new_mesh.mesh = new_mesh.mesh.duplicate()
	add_child(new_mesh)
	
	function.call(new_mesh)
