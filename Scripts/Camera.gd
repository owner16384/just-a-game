extends SpringArm3D

@export var target: CharacterBody3D
@export var follow_offset: Vector3 = Vector3(0.8, 0.3, 0)
@export var follow_sensitivity: float = 50
@export var rotate_sensitivity: float = 25
@export var mouse_sensitivity: float = 0.004
@export var sens_multipler_when_draw: float = 0.05

var yaw: float
var pitch: float
var quat: Quaternion

var min_yaw: float
var max_yaw: float

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Hide Mouse

func _physics_process(delta: float) -> void:
	var target_pos = target.position+follow_offset.x*basis.x+follow_offset.y*basis.y+basis.z*follow_offset.z
	position = position.lerp(target_pos, follow_sensitivity * delta)
	
	var nextposquat = quaternion.slerp(quat, rotate_sensitivity * delta)
	basis = Basis(nextposquat.normalized())

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var is_drawing = EventBus.currentState & EventBus.state.DRAW
		var draw_smoothness = abs(is_drawing-1)+is_drawing*sens_multipler_when_draw # it equals that: sens_multipler_when_draw if drawing else: 1
		var relative = event.relative*mouse_sensitivity*draw_smoothness
		
		pitch -= relative.y
		yaw -= relative.x
		
		if is_drawing:
			# then apply 60 degrees limit
			if min_yaw == max_yaw:
				min_yaw = yaw-PI/6 # 30 degres
				max_yaw = yaw+PI/6 # 30 degres
			
			yaw = clampf(yaw, min_yaw, max_yaw)
		else:
			min_yaw = max_yaw
			yaw = fposmod(yaw, TAU) # TAU == 2 * PI
		pitch = clampf(pitch, -1, 0.5)
		
		quat = Quaternion.from_euler(Vector3(pitch, yaw, 0))
		target.cam_basis = basis
