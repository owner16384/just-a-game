class_name inputMovement
extends Node

@export var max_speed: float = 2
@export var acceleration: float = 0.2
@export var friction: float = 0.1
var cam_basis: Basis

func move(player):
	if !cam_basis: return
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down").normalized()
	
	if input_dir:
		player.velocity = player.velocity.move_toward((player.basis.z * input_dir.y + player.basis.x * input_dir.x) * max_speed, acceleration)
		
		var newbasis = Basis(Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized(), Vector3(0, cam_basis.y.y, 0).normalized(), Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()).get_rotation_quaternion()
		var newquat = player.quaternion.slerp(newbasis, 0.1)
		player.basis = Basis(newquat)
	else:
		player.velocity = player.velocity.move_toward(Vector3.ZERO, friction)
	
	player.move_and_slide()
