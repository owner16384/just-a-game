extends Camera3D

@export var target: CharacterBody3D
@export var follow_offset: Vector3 = Vector3(0.8, 0.3, 0)
@export var speed: float = 0.3
@export var mouse_sens: float = 0.004
@export var distance: float = 8
@export var camera_collision: bool = true

var yaw: float
var pitch: float
var quat: Quaternion

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(_delta: float) -> void:
	var target_pos = target.position+follow_offset.x*basis.x+follow_offset.y*basis.y+basis.z*follow_offset.z
	position = target_pos
	target_pos += basis.z*distance
	position = position.lerp(target_pos, speed)
	
	var nextposquat = quaternion.slerp(quat, 0.2)
	basis = Basis(nextposquat.normalized())

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var relative = event.relative*mouse_sens
		if EventBus.currentState & EventBus.state.DRAW:
			relative *= 0.1
			return # sonra sil
		
		pitch -= relative.y
		yaw -= relative.x
		
		yaw = fposmod(yaw, TAU)
		pitch = clampf(pitch, -1, 0.5)
		
		quat = Quaternion.from_euler(Vector3(pitch, yaw, 0))
		
		target.cam_basis = basis
		
		position = target.position+follow_offset.x*basis.x+follow_offset.y*basis.y+basis.z*distance+basis.z*follow_offset.z
