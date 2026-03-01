class_name inputMovement
extends Node

@export var max_speed: float = 2
@export var acceleration: float = 10
@export var friction: float = 7

@export var jump_power: float = 4
@export var gravity: float = 12

var cam_basis: Basis

func move(delta, player):
	if !cam_basis: return
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down").normalized()
	
	if input_dir:
		player.velocity = player.velocity.move_toward((player.basis.z * input_dir.y + player.basis.x * input_dir.x) * max_speed + Vector3.UP*player.velocity.y, acceleration * delta)
		
		var newbasis = Basis(Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized(), Vector3(0, cam_basis.y.y, 0).normalized(), Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()).get_rotation_quaternion()
		var newquat = player.quaternion.slerp(newbasis, 0.1)
		player.basis = Basis(newquat)
		
		EventBus.currentState |= EventBus.state.WALK
	else:
		player.velocity = player.velocity.move_toward(Vector3(0, player.velocity.y, 0), friction * delta)
		
		EventBus.currentState &= ~EventBus.state.WALK
		EventBus.currentState &= ~EventBus.state.RUN
	
	player.velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y += jump_power
	
	player.move_and_slide()
