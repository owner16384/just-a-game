extends Node3D

@onready var immediate_mesh: ImmediateMesh = $"3D Drawing Mesh".mesh
@onready var camera: Camera3D = $"Ultra Cinematic Camera"

func _ready() -> void:
	EventBus.connect("get_drawability_nodes", get_drawability_nodes)

func get_drawability_nodes(function: Callable):
	function.call(immediate_mesh, camera)
