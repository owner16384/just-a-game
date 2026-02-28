extends SpringArm3D

@export var target: CharacterBody3D
@export var follow_offset: Vector3 = Vector3(5, 3, 0)
@export var speed: float = 0.3
@export var mouse_sens: float = 0.005

var yaw: float
var pitch: float
var quat: Quaternion

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(_delta: float) -> void:
	position = position.lerp(target.position+follow_offset.x*basis.x+follow_offset.y*basis.y+follow_offset.z*basis.z, speed)
	
	var nextposquat = quaternion.slerp(quat, 0.2)
	basis = Basis(nextposquat.normalized())

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and !(EventBus.currentState & EventBus.state.DRAW):
		var relative = event.relative*mouse_sens
		
		pitch -= relative.y
		yaw -= relative.x
		
		yaw = fposmod(yaw, TAU)
		pitch = clampf(pitch, -1, 0.5)
		
		quat = Quaternion.from_euler(Vector3(pitch, yaw, 0))
		
		target.cam_basis = basis
