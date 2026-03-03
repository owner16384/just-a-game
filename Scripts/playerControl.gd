extends CharacterBody3D

@onready var input_Movement: inputMovement = $inputMovement
@onready var paint_component: drawability = $drawability

var cam_basis: Basis:
	set(value):
		cam_basis = value
		input_Movement.cam_basis = value

func _physics_process(delta: float) -> void:
	input_Movement.move(delta, self)
